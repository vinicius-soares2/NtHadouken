# Estruturas de Kernel do Windows - EPROCESS e ETHREAD

## Introdução

No coração do sistema operacional Windows, existem estruturas de dados fundamentais que gerenciam e representam processos e threads em execução. Enquanto o Process Environment Block (PEB) e o Thread Environment Block (TEB) são estruturas acessíveis no espaço do usuário (user-mode), suas contrapartes no espaço do kernel (kernel-mode) são as estruturas EPROCESS e ETHREAD. Estas estruturas são críticas para o funcionamento do sistema operacional e contêm informações detalhadas que o kernel usa para gerenciar processos e threads.

Este artigo explora em profundidade as estruturas EPROCESS e ETHREAD, seus campos mais importantes, como elas se relacionam com outras estruturas do sistema, e suas implicações para desenvolvimento de drivers, análise forense e segurança. Compreender estas estruturas é essencial para qualquer pessoa interessada em Windows Internals em nível de kernel, desenvolvimento de drivers, análise de malware ou investigações forenses digitais.

## Visão Geral das Estruturas de Kernel

O Windows utiliza um modelo de objetos para representar recursos do sistema. Processos e threads são representados como objetos de kernel, cada um com sua própria estrutura de dados que contém informações específicas. Estas estruturas são acessíveis apenas no modo kernel e são fundamentais para o funcionamento do sistema operacional.

### Hierarquia de Objetos

No Windows, os objetos seguem uma hierarquia:

1. **DISPATCHER_HEADER**: Cabeçalho comum a todos os objetos despachados pelo kernel.
2. **OBJECT_HEADER**: Contém informações sobre o tipo de objeto, contagem de referências, etc.
3. **Estrutura específica do objeto**: Como EPROCESS para processos ou ETHREAD para threads.

### Relação com Estruturas de Modo Usuário

Existe uma relação direta entre as estruturas de kernel e as estruturas de modo usuário:

- **EPROCESS** contém um ponteiro para o PEB do processo correspondente.
- **ETHREAD** contém um ponteiro para o TEB da thread correspondente.

Esta relação permite que o kernel acesse informações de modo usuário quando necessário, e vice-versa (através de chamadas de sistema).

## A Estrutura EPROCESS

A estrutura EPROCESS (Executive Process) é a representação de um processo no modo kernel. Ela contém todas as informações que o kernel precisa para gerenciar um processo, incluindo seus recursos, permissões, estatísticas e muito mais.

### Definição da Estrutura

A estrutura EPROCESS é complexa e contém numerosos campos. Abaixo está uma versão simplificada da estrutura para Windows 10/11 (64 bits), com foco nos campos mais importantes:

```c
typedef struct _EPROCESS {
    KPROCESS Pcb;                          // 0x000 - Kernel Process Control Block
    EX_PUSH_LOCK ProcessLock;              // 0x438
    LARGE_INTEGER CreateTime;              // 0x440
    LARGE_INTEGER ExitTime;                // 0x448
    EX_RUNDOWN_REF RundownProtect;         // 0x450
    HANDLE UniqueProcessId;                // 0x458 - Process ID
    LIST_ENTRY ActiveProcessLinks;         // 0x460 - Links to other processes
    SIZE_T MinimumWorkingSetSize;          // 0x470
    SIZE_T MaximumWorkingSetSize;          // 0x478
    PVOID Cookie;                          // 0x480
    ULONG_PTR Flags;                       // 0x488
    // ... (muitos outros campos omitidos por brevidade)
    PVOID SectionObject;                   // 0x520
    PVOID SectionBaseAddress;              // 0x528
    // ... (mais campos omitidos)
    PVOID Peb;                             // 0x550 - Pointer to PEB
    // ... (mais campos omitidos)
    PVOID VadRoot;                         // 0x7d8 - VAD tree root
    // ... (mais campos omitidos)
    HANDLE DebugPort;                      // 0x5e0
    // ... (mais campos omitidos)
    PVOID WoW64Process;                    // 0x818 - Pointer to WOW64 process data
    // ... (mais campos omitidos)
    ULONG Protection;                      // 0x87a - Process protection level
    // ... (mais campos omitidos)
} EPROCESS, *PEPROCESS;
```

É importante notar que a estrutura exata do EPROCESS pode variar entre diferentes versões do Windows. A estrutura acima é uma representação simplificada e os offsets podem mudar.

### Campos Críticos e Suas Funções

Vamos analisar alguns dos campos mais importantes do EPROCESS:

#### 1. Pcb (0x000)

A estrutura KPROCESS (Kernel Process Control Block) é a primeira parte do EPROCESS e contém informações relacionadas ao escalonamento e gerenciamento de recursos do processo. Ela inclui campos como:

- **DirectoryTableBase**: Endereço físico da tabela de páginas do processo (CR3).
- **ThreadListHead**: Lista de threads pertencentes ao processo.
- **ProcessLock**: Spinlock para sincronização de acesso à estrutura.

#### 2. UniqueProcessId (0x458)

Este campo contém o identificador único do processo (PID). É o mesmo valor retornado por funções como `GetCurrentProcessId()` em modo usuário.

```c
// Exemplo de código de driver para obter o PID de um processo
HANDLE GetProcessId(PEPROCESS Process) {
    return Process->UniqueProcessId;
}
```

#### 3. ActiveProcessLinks (0x460)

Este campo é uma entrada de lista duplamente encadeada que conecta todos os processos ativos no sistema. O kernel usa esta lista para enumerar processos.

```c
// Exemplo de código de driver para enumerar processos
void EnumerateProcesses() {
    PEPROCESS CurrentProcess = PsInitialSystemProcess; // Processo do sistema
    PEPROCESS Process = CurrentProcess;
    
    do {
        // Processar informações do processo
        DbgPrint("Process: %p, PID: %llu\n", Process, (ULONG64)Process->UniqueProcessId);
        
        // Avançar para o próximo processo na lista
        Process = CONTAINING_RECORD(Process->ActiveProcessLinks.Flink, EPROCESS, ActiveProcessLinks);
        
    } while (Process != CurrentProcess);
}
```

#### 4. Peb (0x550)

Ponteiro para o Process Environment Block (PEB) do processo. Este campo permite que o kernel acesse informações de modo usuário do processo.

```c
// Exemplo de código de driver para acessar o PEB de um processo
PPEB GetProcessPeb(PEPROCESS Process) {
    return (PPEB)Process->Peb;
}
```

#### 5. VadRoot (0x7d8)

Ponteiro para a raiz da árvore VAD (Virtual Address Descriptor) do processo. A árvore VAD é uma estrutura de dados que rastreia as regiões de memória virtual alocadas pelo processo.

#### 6. DebugPort (0x5e0)

Ponteiro para a porta de depuração do processo, se houver. Este campo é usado pelo mecanismo de depuração do Windows.

#### 7. WoW64Process (0x818)

Ponteiro para dados específicos do WOW64, usado quando um processo de 32 bits está sendo executado em um sistema de 64 bits.

#### 8. Protection (0x87a)

Nível de proteção do processo. Este campo é usado para implementar recursos como Protected Process Light (PPL) e outros mecanismos de segurança.

## A Estrutura ETHREAD

A estrutura ETHREAD (Executive Thread) é a representação de uma thread no modo kernel. Ela contém todas as informações que o kernel precisa para gerenciar uma thread, incluindo seu estado de execução, prioridade, estatísticas e muito mais.

### Definição da Estrutura

A estrutura ETHREAD é complexa e contém numerosos campos. Abaixo está uma versão simplificada da estrutura para Windows 10/11 (64 bits), com foco nos campos mais importantes:

```c
typedef struct _ETHREAD {
    KTHREAD Tcb;                           // 0x000 - Kernel Thread Control Block
    LARGE_INTEGER CreateTime;              // 0x430
    union {
        LARGE_INTEGER ExitTime;            // 0x438
        LIST_ENTRY KeyedWaitChain;         // 0x438
    };
    // ... (campos omitidos)
    HANDLE ClientId;                       // 0x478 - Thread ID
    // ... (campos omitidos)
    PVOID Win32Thread;                     // 0x4e0
    // ... (campos omitidos)
    PVOID Teb;                             // 0x4f0 - Pointer to TEB
    // ... (muitos outros campos omitidos por brevidade)
    BOOLEAN HasTerminated;                 // 0x6c4
    // ... (mais campos omitidos)
} ETHREAD, *PETHREAD;
```

É importante notar que a estrutura exata do ETHREAD pode variar entre diferentes versões do Windows. A estrutura acima é uma representação simplificada e os offsets podem mudar.

### Campos Críticos e Suas Funções

Vamos analisar alguns dos campos mais importantes do ETHREAD:

#### 1. Tcb (0x000)

A estrutura KTHREAD (Kernel Thread Control Block) é a primeira parte do ETHREAD e contém informações relacionadas ao escalonamento e execução da thread. Ela inclui campos como:

- **State**: Estado atual da thread (Running, Ready, Waiting, etc.).
- **Priority**: Prioridade da thread.
- **WaitListEntry**: Entrada de lista para filas de espera.
- **StackBase/StackLimit**: Limites da pilha da thread.

#### 2. CreateTime (0x430)

Timestamp de quando a thread foi criada.

#### 3. ExitTime (0x438)

Timestamp de quando a thread terminou. Se a thread ainda está em execução, este campo pode ser usado para outros propósitos (como KeyedWaitChain).

#### 4. ClientId (0x478)

Identificador único da thread (TID). É o mesmo valor retornado por funções como `GetCurrentThreadId()` em modo usuário.

```c
// Exemplo de código de driver para obter o TID de uma thread
HANDLE GetThreadId(PETHREAD Thread) {
    return Thread->ClientId;
}
```

#### 5. Win32Thread (0x4e0)

Ponteiro para estruturas específicas do subsistema Win32 relacionadas à thread.

#### 6. Teb (0x4f0)

Ponteiro para o Thread Environment Block (TEB) da thread. Este campo permite que o kernel acesse informações de modo usuário da thread.

```c
// Exemplo de código de driver para acessar o TEB de uma thread
PTEB GetThreadTeb(PETHREAD Thread) {
    return (PTEB)Thread->Teb;
}
```

#### 7. HasTerminated (0x6c4)

Indica se a thread terminou sua execução.

## Acesso e Manipulação em Modo Kernel

### Obtenção de Ponteiros para EPROCESS e ETHREAD

No desenvolvimento de drivers, você pode obter ponteiros para estruturas EPROCESS e ETHREAD de várias maneiras:

#### 1. Funções do Kernel

O Windows fornece várias funções para obter ponteiros para estas estruturas:

```c
// Obter o EPROCESS atual
PEPROCESS CurrentProcess = PsGetCurrentProcess();

// Obter o ETHREAD atual
PETHREAD CurrentThread = PsGetCurrentThread();

// Obter o EPROCESS de um processo específico por PID
PEPROCESS TargetProcess;
NTSTATUS status = PsLookupProcessByProcessId(ProcessId, &TargetProcess);
if (NT_SUCCESS(status)) {
    // Usar TargetProcess
    // ...
    
    // Liberar a referência quando terminar
    ObDereferenceObject(TargetProcess);
}

// Obter o ETHREAD de uma thread específica por TID
PETHREAD TargetThread;
status = PsLookupThreadByThreadId(ThreadId, &TargetThread);
if (NT_SUCCESS(status)) {
    // Usar TargetThread
    // ...
    
    // Liberar a referência quando terminar
    ObDereferenceObject(TargetThread);
}
```

#### 2. Callbacks do Kernel

O Windows permite que drivers registrem callbacks para eventos relacionados a processos e threads:

```c
// Callback para criação de processo
VOID ProcessCreateCallback(
    PEPROCESS Process,
    HANDLE ProcessId,
    PPS_CREATE_NOTIFY_INFO CreateInfo
) {
    if (CreateInfo) {
        // Processo sendo criado
        DbgPrint("Process %llu created: %wZ\n", 
                 (ULONG64)ProcessId, 
                 CreateInfo->ImageFileName);
    } else {
        // Processo sendo terminado
        DbgPrint("Process %llu terminated\n", (ULONG64)ProcessId);
    }
}

// Registrar o callback
PVOID RegHandle;
PsSetCreateProcessNotifyRoutineEx(ProcessCreateCallback, FALSE);
```

### Manipulação de Processos e Threads

Drivers em modo kernel podem manipular processos e threads de várias maneiras:

#### 1. Terminação de Processo/Thread

```c
// Terminar um processo
NTSTATUS status = ZwTerminateProcess(ProcessHandle, STATUS_SUCCESS);

// Terminar uma thread
status = ZwTerminateThread(ThreadHandle, STATUS_SUCCESS);
```

#### 2. Suspensão/Resumo de Thread

```c
// Suspender uma thread
NTSTATUS status = PsSuspendThread(ThreadHandle, NULL);

// Resumir uma thread
status = PsResumeThread(ThreadHandle, NULL);
```

#### 3. Alteração de Prioridade

```c
// Alterar a prioridade de uma thread
KPRIORITY OldPriority;
KeSetPriorityThread((PKTHREAD)Thread->Tcb, NewPriority, &OldPriority);
```

## Relação com PEB e TEB

Como mencionado anteriormente, existe uma relação direta entre as estruturas de kernel e as estruturas de modo usuário:

### EPROCESS e PEB

O campo `Peb` do EPROCESS aponta para o PEB do processo. Isso permite que o kernel acesse informações de modo usuário do processo, como módulos carregados, parâmetros de linha de comando, etc.

```c
// Exemplo de código de driver para acessar informações do PEB
VOID ExaminePeb(PEPROCESS Process) {
    KAPC_STATE ApcState;
    
    // Anexar ao espaço de endereçamento do processo alvo
    KeStackAttachProcess((PKPROCESS)Process, &ApcState);
    
    // Acessar o PEB
    PPEB Peb = PsGetProcessPeb(Process);
    if (Peb) {
        // Verificar se o processo está sendo depurado
        DbgPrint("Process %llu is %s debugged\n", 
                 (ULONG64)Process->UniqueProcessId, 
                 Peb->BeingDebugged ? "being" : "not");
        
        // Acessar outros campos do PEB
        // ...
    }
    
    // Desanexar do espaço de endereçamento do processo
    KeUnstackDetachProcess(&ApcState);
}
```

### ETHREAD e TEB

O campo `Teb` do ETHREAD aponta para o TEB da thread. Isso permite que o kernel acesse informações de modo usuário da thread, como pilha de exceções, slots TLS, etc.

```c
// Exemplo de código de driver para acessar informações do TEB
VOID ExamineTeb(PETHREAD Thread) {
    KAPC_STATE ApcState;
    
    // Obter o processo ao qual a thread pertence
    PEPROCESS Process = IoThreadToProcess(Thread);
    
    // Anexar ao espaço de endereçamento do processo
    KeStackAttachProcess((PKPROCESS)Process, &ApcState);
    
    // Acessar o TEB
    PTEB Teb = PsGetThreadTeb(Thread);
    if (Teb) {
        // Acessar informações do TEB
        DbgPrint("Thread %llu stack: Base=%p, Limit=%p\n", 
                 (ULONG64)Thread->ClientId, 
                 Teb->NtTib.StackBase, 
                 Teb->NtTib.StackLimit);
        
        // Acessar outros campos do TEB
        // ...
    }
    
    // Desanexar do espaço de endereçamento do processo
    KeUnstackDetachProcess(&ApcState);
}
```

## Implicações para Desenvolvimento de Drivers

### 1. Acesso Seguro a Estruturas

Ao acessar estruturas EPROCESS e ETHREAD em drivers, é importante seguir práticas seguras:

- **Verificar Ponteiros**: Sempre verifique se os ponteiros são válidos antes de acessá-los.
- **Gerenciar Referências**: Use `ObReferenceObject()` e `ObDereferenceObject()` para gerenciar referências a objetos.
- **Sincronização**: Use mecanismos apropriados de sincronização ao acessar estruturas compartilhadas.

### 2. Anexação a Processos

Para acessar memória de modo usuário de outro processo, você precisa anexar ao seu espaço de endereçamento:

```c
VOID AccessUserModeMemory(PEPROCESS TargetProcess, PVOID UserAddress, SIZE_T Size) {
    KAPC_STATE ApcState;
    
    // Anexar ao espaço de endereçamento do processo alvo
    KeStackAttachProcess((PKPROCESS)TargetProcess, &ApcState);
    
    __try {
        // Acessar memória de modo usuário
        // Usar ProbeForRead/ProbeForWrite para validar endereços
        ProbeForRead(UserAddress, Size, sizeof(UCHAR));
        
        // Copiar dados
        RtlCopyMemory(KernelBuffer, UserAddress, Size);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        // Lidar com exceções
        status = GetExceptionCode();
    }
    
    // Desanexar do espaço de endereçamento do processo
    KeUnstackDetachProcess(&ApcState);
}
```

### 3. Monitoramento de Processos e Threads

Drivers podem monitorar a criação e terminação de processos e threads usando callbacks:

```c
// Callback para criação de processo
VOID ProcessNotifyCallback(
    PEPROCESS Process,
    HANDLE ProcessId,
    PPS_CREATE_NOTIFY_INFO CreateInfo
) {
    // Implementação do callback
}

// Callback para criação de thread
VOID ThreadNotifyCallback(
    HANDLE ProcessId,
    HANDLE ThreadId,
    BOOLEAN Create
) {
    // Implementação do callback
}

// Registrar callbacks
NTSTATUS RegisterCallbacks() {
    NTSTATUS status;
    
    // Registrar callback de processo
    status = PsSetCreateProcessNotifyRoutineEx(ProcessNotifyCallback, FALSE);
    if (!NT_SUCCESS(status)) return status;
    
    // Registrar callback de thread
    status = PsSetCreateThreadNotifyRoutine(ThreadNotifyCallback);
    if (!NT_SUCCESS(status)) {
        // Limpar recursos em caso de falha
        PsSetCreateProcessNotifyRoutineEx(ProcessNotifyCallback, TRUE);
        return status;
    }
    
    return STATUS_SUCCESS;
}
```

## Implicações para Segurança e Análise Forense

### 1. Detecção de Rootkits

Rootkits frequentemente manipulam estruturas EPROCESS e ETHREAD para ocultar processos e threads maliciosos. Técnicas comuns incluem:

- **Desvinculação da Lista de Processos**: Remover um processo da lista `ActiveProcessLinks` para ocultá-lo de ferramentas de enumeração.
- **Manipulação de Handles**: Fechar ou redirecionar handles de depuração para evitar análise.
- **Hooking de Callbacks**: Interceptar callbacks de notificação para ocultar atividades maliciosas.

Ferramentas de segurança podem detectar estas manipulações verificando inconsistências nas estruturas de kernel.

### 2. Análise de Memória Forense

Em análise forense de memória, as estruturas EPROCESS e ETHREAD são fundamentais para reconstruir o estado do sistema:

- **Enumeração de Processos**: Percorrer a lista `ActiveProcessLinks` para encontrar todos os processos visíveis.
- **Detecção de Processos Ocultos**: Usar técnicas como pool scanning para encontrar estruturas EPROCESS que foram desvinculadas da lista principal.
- **Análise de Threads**: Examinar threads para entender o comportamento de processos.
- **Reconstrução de Memória**: Usar o campo `DirectoryTableBase` do KPROCESS para mapear o espaço de endereçamento de um processo.

### 3. Técnicas Anti-Forense

Atacantes podem usar conhecimento sobre estas estruturas para implementar técnicas anti-forense:

- **Process Hollowing**: Substituir o conteúdo de um processo legítimo por código malicioso.
- **Direct Kernel Object Manipulation (DKOM)**: Modificar diretamente objetos de kernel para ocultar atividades maliciosas.
- **Manipulação de VAD**: Modificar a árvore VAD para ocultar regiões de memória maliciosas.

## Conclusão

As estruturas EPROCESS e ETHREAD são componentes fundamentais do sistema operacional Windows, servindo como representações de processos e threads no modo kernel. Compreender estas estruturas é essencial para desenvolvimento de drivers, análise de segurança, investigações forenses e qualquer trabalho que envolva Windows Internals em nível de kernel.

Este artigo forneceu uma visão detalhada das estruturas EPROCESS e ETHREAD, incluindo seus campos críticos, métodos de acesso e manipulação, e implicações para desenvolvimento e segurança. No entanto, é importante lembrar que estas estruturas são internas do Windows e podem mudar entre diferentes versões do sistema operacional. Além disso, o acesso direto a estas estruturas deve ser feito com cuidado, seguindo práticas seguras de programação e respeitando as políticas de segurança do Windows.

Para um estudo mais aprofundado, recomenda-se consultar recursos como o livro "Windows Internals" de Mark Russinovich, ou explorar o Windows Driver Kit (WDK) e suas documentações.

## Referências

1. Russinovich, M., Solomon, D., & Ionescu, A. (2012). Windows Internals, Part 1 (6th ed.). Microsoft Press.
2. Yosifovich, P., Ionescu, A., Russinovich, M., & Solomon, D. (2017). Windows Internals, Part 1 (7th ed.). Microsoft Press.
3. Microsoft. (2023). Windows Driver Kit Documentation. Microsoft Learn.
4. Schreiber, S. B. (2021). Undocumented Windows NT. Foster City, CA: IDG Books Worldwide.
5. The Volatility Framework: Open-source memory forensics framework.
6. OSR Online: Resources for Windows driver developers.
