## Introdução

No tutorial de hoje, iremos analisar um arquivo de despejo gerado quando o Sistema Operacional Windows tem um crash ou BSOD(Blue Screen Of Death).

Nota: Este tutorial é para iniciantes que estão tendo seus primeiros contatos com análise de BSOD no Windows.

## 🗺️ Roadmap do Tutorial

1. O que são os arquivos de Despejos e suas variedades.
2. Habilitando arquivos de despejos de Kernel-Mode.
3. Forçando uma falha do sistema.
4. Analisando o crash com o WinDBG

## O que são arquivos de despejos do Windows e suas variedades?

Arquivos de despejos do sistema, é um tipo de arquivos que é gerado pelo Windows quando ele entra em algum estado crítico de pane. Estes arquivos gerados tem como objetivo ajudar um administrador de sistema a entender o que casou e o que ocorreu para o Windows entrar em crash ou a famosa BSOD. 

### Variedades dos arquivos de despejo do Windows

Os arquivos de despejos possui algumas variedades, sendo elas:

1. Despejo de memória do Kernel
2. Despejo de memória pequeno
3. Despejo automático de memória
4. Despejo de memória ativo.

A diferença entre esses arquivos de despejo é de um tamanho. O *Despejo de Memória Completa* é o maior e contém a maioria das informações, incluindo algumas User-Mode memória. O *Despejo de Memória Ativa* é um pouco menor, mas contém informações semelhantes para a maioria das finalidades. O *Despejo de Memória do Kernel* é menor ainda e normalmente omite User-Mode memória, e o *Despejo de Memória Pequena* tem apenas 64 KB de tamanho.

Se você selecionar *Despejo automático de memória*, o arquivo de despejo será o mesmo que um Despejo de Memória do Kernel, mas o Windows terá mais flexibilidade na configuração do tamanho do arquivo de paginação do sistema.

A vantagem para os arquivos maiores é que, como eles contêm mais informações, eles são mais propensos a ajudá-lo a encontrar a causa da falha.

A vantagem dos arquivos menores é que eles são menores e gravados mais rapidamente. A velocidade geralmente é valiosa; se você estiver executando um servidor, talvez queira que o servidor seja reiniciado o mais rápido possível após uma falha e a reinicialização não ocorrerá até que o arquivo de despejo seja gravado.

```nasm
Nota: Depois que um Despejo de Memória Completo ou Despejo de Memória do Kernel tiver sid
o criado, é possível criar um arquivo de despejo de memória pequeno do arquivo de despejo
maior. Você pode consultar o comando **.dump** em [(Criar Dump de Despejo)](https://learn.microsoft.com/pt-br/windows-hardware/drivers/debuggercmds/-dump--create-dump-file-).
```

## Habilitando arquivos de despejo de Kernel-Mode.

Quando ocorre uma falha, as configurações do despejo de memória do Windows irá determinar se um arquivo de despejo será criado e qual será seu tamanho.

Para realizar modificações nas configurações de despejo, você pode fazer o seguinte passo:

1.  **Painel de Controle > Sistema e Sistema de Segurança>**. Selecione **Configurações avançadas do sistema**. Em **Inicialização e Recuperação**, selecione **Configurações**

<p align="center">
  <img src="https://github.com/lnt2eh/NtHadouken/blob/main/assets/Configuring.png" />
</p>

Você pode alterar a configuração do arquivo de despejo em **“Gravando informações de depuração”**

## Forçando um crash do sistema

Após você realizar a configuração adequada do tipo de arquivo de despejo que você busca para seus testes, a maioria das falhas do sistema deverá fazer com que um arquivo de despejo seja gravado e uma tela azul(BSOD) seja exibida.

A Microsoft especifica que:

**No entanto, há momentos em que um sistema congela sem realmente iniciar uma falha de     kernel. Os possíveis sintomas desse congelamento incluem:**

- **O ponteiro do mouse se move, mas não pode fazer nada.**
- **Todo o vídeo está congelado, o ponteiro do mouse não se move, mas a paginação continua.**
- **Não há nenhuma resposta para o mouse ou teclado e nenhum uso do disco.**

Existem diversas formas de você gerar uma BSOD de forma proposital. No entanto, hoje iremos focar no uso do utilitário **NotMyFault** do próprio SysInternals para gerar manualmente um arquivo de despejo.

1. Você pode fazer o download em:  [NotMyFault](https://download.sysinternals.com/files/NotMyFault.zip)
2. Quando você abrir, você vai ter diversas opções de crash para gerar(Buffer overflow, High IRQL fault, Stack Overflow, etc…). Você só precisa selecionar um e clicar em “Crash”. No caso de hoje, eu utilizei “High IRQL Fault(Kernel-Mode)”.

## Analisando o crash com o WinDBG

Agora que realizamos um crash no sistema e após o Windows reinicializar, vamos analisar o arquivo de despejo gerado, normalmente o arquivo de despejo se encontra em **C:\Windows** com o nome “MEMORY.DUMP” que é um arquivo de despejo grande(Onde pode ser igual ao tamanho da RAM), mas também temos os “minidumps”, que podem ser encontrados na pasta **C:\Windows\Minidump** que oferece uma visão mais simplificada do que ocorreu.

Vamos analisar agora um arquivo .DMP dentro da pasta Minidump, para isso vamos seguir os seguintes passos:

1. Abrir o WinDbg como administrador(Isso ocorre pq a pasta que os minidumps ficam armazenadas são privilegiadas).
2. Vamos em File **> Open Crash Dump.** Com isso, irá apresentar um browser para navegarmos e encontrar nosso arquivo .DMP, vamos para C:\Windows\Minidump e selecionar o arquivo que estiver lá(Não existe um nome especifico e varia de quantos erros você já teve no sistema. Se você configurou recentemente a VM e executou o crash com o NotMyFault, provavelmente só existirá um arquivo na pasta.) 
3. Após selecionar e abrir o arquivo no WinDbg, vamos aguardar ele fazer todo o carregamento. Você pode observar se a aba de comando já se encontra como “Kd>” se estiver em “BUSY” é pq ainda não está pronto para receber comandos.
4. Agora que o WinDBG já fez todo o carregamento do arquivo .DUMP vamos executar o comando “!analyze -v” e aguardar toda a impressão de análise do WinDBG.

Após a finalização da análise do WinDBG, ele irá retornar alguns parâmetros interessante para entendermos o que ocorreu na máquina e levou ela a crash, por exemplo:

```nasm
*******************************************************************************
*                                                                             *
*                        Bugcheck Analysis                                    *
*                                                                             *
*******************************************************************************

DRIVER_IRQL_NOT_LESS_OR_EQUAL (d1)
An attempt was made to access a pageable (or completely invalid) address at an
interrupt request level (IRQL) that is too high.  This is usually
caused by drivers using improper addresses.
If kernel debugger is available get stack backtrace.
Arguments:
Arg1: ffffa58b051f7010, memory referenced
Arg2: 0000000000000002, IRQL
Arg3: 0000000000000000, value 0 = read operation, 1 = write operation
Arg4: fffff803708212d0, address which referenced memory

```

Essas informações são suficientes para uma análise básica do que ocorreu na máquina, levando ela a crash.

Pontos importantes a serem verificados:

1. Código do BugCheck, neste caso é (D1) - DRIVER_IRQL_NOT_LESS_OR_EQUAL
2. O comando dando também retorna o que ocorreu para chegar a esta falha, preste atenção nele também.
3. Além disso, a função KeBugCheckEx(Função que causa a BSOD do Windows) pode receber até quatro argumentos para fornecerem informações adicionais, como o endereço e os dados em que ocorreu um erro de corrupção de memória, dependendo do valor de BugCheckCode. Analise e anote cada argumento passado para entender o que ocorreu.
4. A Microsoft oferece uma lista pública com todos os códigos de erros retornados por BugCheck. Você pode acessar em: [**BugCheckList](https://learn.microsoft.com/pt-br/windows-hardware/drivers/debugger/bug-check-code-reference2),** após entrar nesta página com um CTRL + F cole o código de erro que foi retornado para você,  após ser encontrada, você pode clicar nela e abrir a página específica do bug, onde irá retornar e explicar todos os 4 paramêtros retornados por BugCheck, com isso é possível traçar um lista de eventos ocorridos que levaram a máquina a erro crítico.

## Conclusão:

No tutorial de hoje, tivemos um passo inicial na análise de BSODS do Windows. O objetivo deste tutorial, foi fornecer passos iniciais para aqueles que estão iniciando suas jornadas em Windows, espero ter contribuído com seus estudos e nos vemos em breve em outros tutoriais.
