# Windows Internals: Understanding Thread Execution Through the CONTEXT Structure

Bora abordar um pouco mais a fundo algumas estruturas utilizadas internamente pelo Windows?

Essa semana estive praticando um pouco de Malware Development e uma das técnicas que resolvi revisitar foi a conhecida **Process Hollowing**.

Mas, ao invés de simplesmente implementar a técnica e seguir para a próxima, resolvi parar um pouco e tentar entender o que acontece por baixo dos panos.

Uma das coisas que chama atenção durante o estudo desse tipo de técnica é a manipulação do contexto de execução de uma Thread.

É aqui que entra uma estrutura bastante interessante do Windows: a **CONTEXT**.

## O que é a estrutura CONTEXT?

De forma simples, uma Thread precisa possuir um estado de execução.

A CPU precisa saber, por exemplo, quais valores estavam presentes nos registradores e qual é o ponto de execução associado à Thread naquele determinado momento.

Essas informações fazem parte do seu contexto de execução.

No Windows, a estrutura `CONTEXT` permite representar informações relacionadas ao estado de execução de uma Thread. A estrutura é específica da arquitetura do processador e pode conter informações relacionadas a registradores, flags e outros estados da CPU.

Dependendo da arquitetura, podemos encontrar informações relacionadas aos registradores de propósito geral, flags, ponteiros e outros estados utilizados pela CPU.

No caso de um processo x64, uma das informações particularmente interessantes é o registrador `RIP`.

O `RIP` é o *Instruction Pointer* da arquitetura x64 e está diretamente relacionado ao endereço da próxima instrução que será executada.

E é exatamente aqui que podemos começar a experimentar.

---

# O experimento

Antes de continuar, vale deixar algo claro.

O objetivo deste pequeno laboratório não é implementar uma técnica completa de Process Hollowing, executar shellcode ou injetar código arbitrário em outro processo.

A ideia é justamente fazer o contrário.

Durante o estudo de uma técnica mais complexa, resolvi separar um dos mecanismos envolvidos e observá-lo individualmente.

Neste caso, o mecanismo é a captura do contexto de uma Thread utilizando a estrutura `CONTEXT`.

Para isso, vamos criar uma Thread dentro do nosso próprio processo.

Ela será criada inicialmente suspensa.

Depois, vamos capturar seu contexto e observar algumas informações presentes na estrutura.

Por fim, vamos retomar sua execução normalmente.

---

# Criando uma Thread

Primeiramente, precisamos de uma função que será executada pela nossa Thread.

```c
DWORD WINAPI WorkerThread(LPVOID lpParameter)
{
    for (int i = 0; i < 5; i++)
    {
        printf("[Thread] Executando... %d\n", i);
        Sleep(1000);
    }

    return 0;
}
```

Não existe nada particularmente especial acontecendo aqui.

A Thread simplesmente executa um pequeno loop e imprime algumas informações na tela.

O objetivo dessa função é apenas fornecer algo simples para ser executado durante o experimento.

Agora podemos criar uma Thread utilizando `CreateThread`.

```c
HANDLE hThread;
DWORD threadId;

hThread = CreateThread(
    NULL,
    0,
    WorkerThread,
    NULL,
    CREATE_SUSPENDED,
    &threadId
);
```

A parte interessante aqui é:

```c
CREATE_SUSPENDED
```

Normalmente, quando uma Thread é criada, sua execução pode começar imediatamente.

Ao utilizar `CREATE_SUSPENDED`, a Thread é criada, mas permanece suspensa.

Isso significa que temos uma Thread válida, com um contexto associado à sua execução, mas ela ainda não começou a executar normalmente a função que fornecemos.

E isso é perfeito para o nosso experimento.

---

# A estrutura CONTEXT

Agora precisamos criar uma estrutura que receberá as informações relacionadas ao contexto da Thread.

```c
CONTEXT ctx = { 0 };
```

Entretanto, antes de chamar `GetThreadContext`, precisamos informar quais partes do contexto queremos obter.

Isso é feito através do membro:

```c
ctx.ContextFlags
```

Para este experimento, podemos utilizar:

```c
ctx.ContextFlags = CONTEXT_CONTROL;
```

Essas flags informam ao Windows quais partes do contexto estamos interessados em obter.

A própria estrutura `CONTEXT` pode variar dependendo da arquitetura utilizada, justamente porque os registradores disponíveis também variam entre arquiteturas.

No nosso caso, estamos interessados principalmente em informações relacionadas ao controle da execução.

---

# Obtendo o contexto da Thread

Agora podemos utilizar:

```c
GetThreadContext(hThread, &ctx);
```

A chamada completa fica assim:

```c
if (!GetThreadContext(hThread, &ctx))
{
    printf(
        "GetThreadContext falhou: %lu\n",
        GetLastError()
    );

    CloseHandle(hThread);
    return 1;
}
```

A função recebe um handle para a Thread e um ponteiro para a estrutura `CONTEXT`.

Após a chamada, a estrutura é preenchida com as informações solicitadas através de `ContextFlags`.

Um detalhe importante é que não devemos tentar obter o contexto de uma Thread que está executando normalmente.

A documentação da Microsoft recomenda suspender a Thread antes da chamada para garantir um contexto válido.

No nosso caso, isso já aconteceu naturalmente porque criamos a Thread utilizando `CREATE_SUSPENDED`.

---

# Observando o RIP

Agora começa uma das partes mais interessantes.

Em uma arquitetura x64, podemos observar o valor do `RIP`.

```c
printf(
    "[+] RIP: 0x%llx\n",
    ctx.Rip
);
```

Também podemos observar outros valores relacionados ao contexto.

Por exemplo:

```c
printf(
    "[+] RSP: 0x%llx\n",
    ctx.Rsp
);

printf(
    "[+] RBP: 0x%llx\n",
    ctx.Rbp
);
```

Essas informações representam parte do estado da CPU associado àquela Thread.

O `RIP`, por exemplo, está relacionado ao ponteiro de instrução.

O `RSP` representa o ponteiro atual da stack.

E o `RBP`, dependendo do contexto e das convenções utilizadas pelo código, pode estar relacionado ao frame atual da stack.

Ao observar esses valores, começamos a visualizar algo que normalmente permanece bastante abstrato quando falamos apenas sobre "uma Thread executando".

A Thread não é simplesmente uma função rodando.

Existe um estado associado à sua execução.

E parte desse estado pode ser representado através da estrutura `CONTEXT`.

---

# O código completo

Juntando tudo, temos o seguinte pequeno experimento:

```c
#include <windows.h>
#include <stdio.h>

DWORD WINAPI WorkerThread(LPVOID lpParameter)
{
    for (int i = 0; i < 5; i++)
    {
        printf(
            "[Thread] Executando... %d\n",
            i
        );

        Sleep(1000);
    }

    return 0;
}

int main(void)
{
    HANDLE hThread;
    DWORD threadId;

    CONTEXT ctx = { 0 };

    hThread = CreateThread(
        NULL,
        0,
        WorkerThread,
        NULL,
        CREATE_SUSPENDED,
        &threadId
    );

    if (hThread == NULL)
    {
        printf(
            "Falha ao criar a Thread: %lu\n",
            GetLastError()
        );

        return 1;
    }

    /*
        Informamos quais informações
        relacionadas ao contexto queremos obter.
    */

    ctx.ContextFlags = CONTEXT_CONTROL;

    /*
        Como a Thread foi criada suspensa,
        podemos capturar seu contexto antes
        de iniciar sua execução.
    */

    if (!GetThreadContext(
        hThread,
        &ctx
    ))
    {
        printf(
            "GetThreadContext falhou: %lu\n",
            GetLastError()
        );

        CloseHandle(hThread);

        return 1;
    }

#ifdef _WIN64

    printf(
        "[+] Thread ID: %lu\n",
        threadId
    );

    printf(
        "[+] RIP: 0x%llx\n",
        ctx.Rip
    );

    printf(
        "[+] RSP: 0x%llx\n",
        ctx.Rsp
    );

    printf(
        "[+] RBP: 0x%llx\n",
        ctx.Rbp
    );

#endif

    /*
        Para este experimento, não
        modificamos o contexto.

        O objetivo é apenas observar
        como o Windows disponibiliza
        informações relacionadas ao
        estado de execução da Thread.
    */

    ResumeThread(hThread);

    WaitForSingleObject(
        hThread,
        INFINITE
    );

    CloseHandle(hThread);

    return 0;
}
```

---

# Retomando a execução

Após obter e observar o contexto, podemos simplesmente retomar a Thread.

```c
ResumeThread(hThread);
```

A partir desse momento, ela pode continuar sua execução normalmente.

No nosso caso, a função `WorkerThread` começará a executar e veremos o resultado no console.

Depois, utilizamos:

```c
WaitForSingleObject(
    hThread,
    INFINITE
);
```

Isso faz com que o processo principal aguarde até que a Thread termine sua execução.

Por fim, fechamos o handle.

```c
CloseHandle(hThread);
```

---

# E onde entra a manipulação?

A parte interessante da estrutura `CONTEXT` é que ela não serve apenas para observar o estado de execução.

Dependendo da operação realizada, o contexto também pode ser fornecido novamente ao sistema através de APIs como `SetThreadContext`, permitindo restaurar ou modificar partes do estado de execução de uma Thread.

É justamente esse conceito que me chamou atenção enquanto estudava Process Hollowing.

Ao invés de olhar apenas para a técnica como uma sequência de chamadas de API, comecei a tentar separar os mecanismos envolvidos.

E um desses mecanismos é exatamente a manipulação do contexto de execução.

Dependendo de quais informações forem alteradas, o comportamento da Thread pode ser influenciado de formas completamente diferentes.

Mas, para este laboratório, resolvi manter o experimento limitado à captura e observação do contexto.

A ideia não é fornecer uma implementação operacional de execução arbitrária dentro de outro processo.

O objetivo é observar o mecanismo.

---

# E onde entra o Process Hollowing?

A manipulação do contexto de uma Thread é um conceito que aparece no estudo de diversas técnicas.

O ponto mais interessante para mim foi justamente perceber que, antes de tentar entender uma técnica inteira, vale a pena separar os mecanismos utilizados por ela e estudá-los individualmente.

A estrutura `CONTEXT` é um desses mecanismos.

Você pode olhar para uma técnica e pensar apenas:

> "Ela altera o fluxo de execução."

Mas quando começamos a explorar o que isso significa internamente, aparecem perguntas muito mais interessantes.

Como o Windows representa o estado de execução de uma Thread?

Quais registradores fazem parte desse estado?

Como esse contexto pode ser obtido?

Como o sistema permite selecionar apenas determinadas partes do contexto?

O que acontece quando uma Thread é suspensa?

E como esse estado pode ser observado antes que sua execução seja retomada?

É nesse ponto que, pelo menos para mim, o estudo começa a ficar realmente interessante.

A ideia deste pequeno projeto não foi criar uma implementação completa de uma técnica ofensiva.

Foi pegar uma pequena parte de um mecanismo que aparece durante esse tipo de estudo e observá-lo isoladamente.

No repositório **NtHadouken**, vou deixar o pequeno laboratório utilizado para acompanhar esse estudo.

A ideia continua sendo a mesma:

**Não apenas aprender que uma técnica funciona, mas tentar entender quais mecanismos do sistema operacional ela está utilizando por baixo dos panos.**
