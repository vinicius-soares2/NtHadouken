# Anatomia do Process Environment Block (PEB) no Windows

## Introdução

O Process Environment Block (PEB) é uma das estruturas de dados mais fundamentais e críticas no sistema operacional Windows. Localizada no espaço de usuário (user-mode), esta estrutura contém informações vitais sobre um processo em execução e serve como um ponto central de referência para o sistema operacional e para o próprio processo. Apesar de ser criada pelo kernel, a PEB reside na memória de usuário e é acessível tanto pelo código em modo usuário quanto pelo código em modo kernel, tornando-a um componente essencial para entender o funcionamento interno do Windows.

Este artigo explora em profundidade a estrutura do PEB, seus campos mais importantes, como acessá-la programaticamente e suas implicações para desenvolvimento de baixo nível e segurança. Compreender o PEB é fundamental para qualquer pessoa interessada em Windows Internals, desenvolvimento de software de baixo nível, análise de malware ou engenharia reversa.

## Localização e Acesso ao PEB

Cada processo no Windows possui sua própria instância do PEB. Esta estrutura é criada durante a inicialização do processo e permanece válida até o término do mesmo. A localização do PEB pode ser determinada de várias maneiras:

1. **Via registro FS/GS**: 
   - Em arquiteturas x86 (32 bits), o PEB é acessível através do registro FS. Especificamente, `FS:[0x30]` contém um ponteiro para o TEB (Thread Environment Block), e o campo `ProcessEnvironmentBlock` do TEB (offset 0x30) aponta para o PEB.
   - Em arquiteturas x64 (64 bits), o registro GS é usado em vez do FS. O ponteiro para o TEB está em `GS:[0x30]`, e o campo do PEB está no mesmo offset relativo dentro do TEB.

2. **Via API do Windows**:
   - A função `NtQueryInformationProcess` com o parâmetro `ProcessBasicInformation` pode ser usada para obter um ponteiro para o PEB.
   - Este método é mais portável, mas menos direto que o acesso via registros FS/GS.

3. **Via WinDbg**:
   - No depurador WinDbg, o comando `!peb` exibe informações detalhadas sobre o PEB do processo atual.

Exemplo de código em Assembly (x64) para acessar o PEB:

```assembly
; Acesso ao PEB em x64 Assembly
mov rax, gs:[0x60]    ; RAX agora contém o ponteiro para o PEB
```

Exemplo em C/C++:

```c
// Acesso ao PEB em C/C++
#include <windows.h>
#include <winternl.h>

// Definição da função NtQueryInformationProcess
typedef NTSTATUS (NTAPI *pNtQueryInformationProcess)(
    HANDLE ProcessHandle,
    PROCESSINFOCLASS ProcessInformationClass,
    PVOID ProcessInformation,
    ULONG ProcessInformationLength,
    PULONG ReturnLength
);

PPEB GetPEB() {
    PROCESS_BASIC_INFORMATION pbi;
    ZeroMemory(&pbi, sizeof(pbi));
    
    // Obter handle para ntdll.dll
    HMODULE ntdll = GetModuleHandleA("ntdll.dll");
    if (!ntdll) return NULL;
    
    // Obter endereço da função NtQueryInformationProcess
    pNtQueryInformationProcess NtQueryInformationProcess = 
        (pNtQueryInformationProcess)GetProcAddress(ntdll, "NtQueryInformationProcess");
    if (!NtQueryInformationProcess) return NULL;
    
    // Chamar NtQueryInformationProcess para obter informações básicas do processo
    NTSTATUS status = NtQueryInformationProcess(
        GetCurrentProcess(),
        ProcessBasicInformation,
        &pbi,
        sizeof(pbi),
        NULL
    );
    
    if (NT_SUCCESS(status)) {
        return pbi.PebBaseAddress;
    }
    
    return NULL;
}
```

## Estrutura Detalhada do PEB

A estrutura do PEB é complexa e contém numerosos campos. Abaixo está uma versão simplificada da estrutura do PEB para Windows 10/11 (64 bits), com foco nos campos mais importantes:

```c
typedef struct _PEB {
    BOOLEAN InheritedAddressSpace;                // 0x000
    BOOLEAN ReadImageFileExecOptions;             // 0x001
    BOOLEAN BeingDebugged;                        // 0x002
    union {
        BOOLEAN BitField;                         // 0x003
        struct {
            BOOLEAN ImageUsesLargePages : 1;
            BOOLEAN IsProtectedProcess : 1;
            BOOLEAN IsImageDynamicallyRelocated : 1;
            BOOLEAN SkipPatchingUser32Forwarders : 1;
            BOOLEAN IsPackagedProcess : 1;
            BOOLEAN IsAppContainer : 1;
            BOOLEAN IsProtectedProcessLight : 1;
            BOOLEAN IsLongPathAwareProcess : 1;
        };
    };
    PVOID Mutant;                                 // 0x008
    PVOID ImageBaseAddress;                       // 0x010
    PPEB_LDR_DATA Ldr;                            // 0x018
    PRTL_USER_PROCESS_PARAMETERS ProcessParameters; // 0x020
    PVOID SubSystemData;                          // 0x028
    PVOID ProcessHeap;                            // 0x030
    PRTL_CRITICAL_SECTION FastPebLock;            // 0x038
    PVOID AtlThunkSListPtr;                       // 0x040
    PVOID IFEOKey;                                // 0x048
    union {
        ULONG CrossProcessFlags;                  // 0x050
        struct {
            ULONG ProcessInJob : 1;
            ULONG ProcessInitializing : 1;
            ULONG ProcessUsingVEH : 1;
            ULONG ProcessUsingVCH : 1;
            ULONG ProcessUsingFTH : 1;
            ULONG ProcessPreviouslyThrottled : 1;
            ULONG ProcessCurrentlyThrottled : 1;
            ULONG ProcessImagesHotPatched : 1;
            ULONG ReservedBits0 : 24;
        };
    };
    // ... (muitos outros campos omitidos por brevidade)
    PVOID ApiSetMap;                              // 0x068
    // ... (mais campos omitidos)
    PVOID LoaderLock;                             // 0x0A0
    // ... (mais campos omitidos)
    ULONG OSMajorVersion;                         // 0x118
    ULONG OSMinorVersion;                         // 0x11C
    USHORT OSBuildNumber;                         // 0x120
    USHORT OSCSDVersion;                          // 0x122
    ULONG OSPlatformId;                           // 0x124
    // ... (mais campos omitidos)
} PEB, *PPEB;
```

É importante notar que a estrutura exata do PEB pode variar entre diferentes versões do Windows. A estrutura acima é uma representação simplificada e os offsets podem mudar.

## Campos Críticos e Suas Funções

Vamos analisar alguns dos campos mais importantes do PEB:

### 1. BeingDebugged (0x002)

Este campo booleano indica se o processo está sendo depurado. Quando um depurador está anexado ao processo, este campo é definido como `TRUE`. Muitos softwares maliciosos verificam este campo para detectar a presença de um depurador e alterar seu comportamento.

```c
// Verificar se o processo está sendo depurado
PPEB peb = GetPEB();
if (peb && peb->BeingDebugged) {
    // Processo está sendo depurado
}
```

### 2. ImageBaseAddress (0x010)

Contém o endereço base onde a imagem do executável principal do processo foi carregada na memória. Este endereço é crucial para calcular endereços relativos dentro do executável.

```c
// Obter o endereço base da imagem
PPEB peb = GetPEB();
if (peb) {
    PVOID imageBase = peb->ImageBaseAddress;
    // Usar o endereço base para cálculos
}
```

### 3. Ldr (0x018)

Este campo aponta para uma estrutura `PEB_LDR_DATA` que contém informações sobre todos os módulos (DLLs) carregados no processo. Esta estrutura contém listas encadeadas de módulos carregados, que podem ser percorridas para enumerar todas as DLLs.

```c
// Enumerar módulos carregados
PPEB peb = GetPEB();
if (peb && peb->Ldr) {
    PLIST_ENTRY moduleList = &peb->Ldr->InMemoryOrderModuleList;
    PLIST_ENTRY entry = moduleList->Flink;
    
    while (entry != moduleList) {
        LDR_DATA_TABLE_ENTRY* module = CONTAINING_RECORD(entry, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        // Processar informações do módulo
        entry = entry->Flink;
    }
}
```

### 4. ProcessParameters (0x020)

Aponta para uma estrutura `RTL_USER_PROCESS_PARAMETERS` que contém informações sobre os parâmetros do processo, incluindo linha de comando, diretório atual, variáveis de ambiente e muito mais.

```c
// Acessar a linha de comando do processo
PPEB peb = GetPEB();
if (peb && peb->ProcessParameters) {
    UNICODE_STRING commandLine = peb->ProcessParameters->CommandLine;
    // Processar a linha de comando
}
```

### 5. ProcessHeap (0x030)

Ponteiro para o heap padrão do processo. Este é o heap usado por funções como `HeapAlloc` quando nenhum heap específico é fornecido.

```c
// Obter o heap padrão do processo
PPEB peb = GetPEB();
if (peb) {
    HANDLE defaultHeap = peb->ProcessHeap;
    // Usar o heap padrão
}
```

### 6. ApiSetMap (0x068)

Aponta para o mapa de API Set do processo, que é usado para resolver referências a APIs. O API Set Schema é um mecanismo introduzido no Windows 7 que permite um mapeamento mais flexível entre nomes de DLLs e suas implementações reais.

### 7. OSMajorVersion, OSMinorVersion, OSBuildNumber (0x118-0x122)

Estes campos contêm informações sobre a versão do sistema operacional em que o processo está sendo executado.

## Técnicas de Análise e Manipulação

### Análise do PEB em WinDbg

O depurador WinDbg oferece comandos específicos para analisar o PEB:

```
!peb                  # Exibe informações gerais sobre o PEB
dt ntdll!_PEB         # Exibe a definição da estrutura PEB
dt ntdll!_PEB @$peb   # Exibe o conteúdo do PEB atual
```

### Manipulação do PEB para Anti-Debugging

Uma técnica comum usada por malware é manipular o campo `BeingDebugged` para evitar detecção:

```c
// Técnica anti-debugging: limpar o flag BeingDebugged
PPEB peb = GetPEB();
if (peb) {
    peb->BeingDebugged = FALSE;
}
```

### Enumeração de Módulos Carregados

O campo `Ldr` do PEB pode ser usado para enumerar todos os módulos carregados no processo, o que é útil para análise de malware e engenharia reversa:

```c
void EnumerateLoadedModules() {
    PPEB peb = GetPEB();
    if (!peb || !peb->Ldr) return;
    
    PLIST_ENTRY moduleList = &peb->Ldr->InMemoryOrderModuleList;
    PLIST_ENTRY entry = moduleList->Flink;
    
    while (entry != moduleList) {
        LDR_DATA_TABLE_ENTRY* module = CONTAINING_RECORD(entry, LDR_DATA_TABLE_ENTRY, InMemoryOrderLinks);
        
        wprintf(L"Module: %s\n", module->FullDllName.Buffer);
        wprintf(L"  Base Address: 0x%p\n", module->DllBase);
        wprintf(L"  Entry Point:  0x%p\n", module->EntryPoint);
        
        entry = entry->Flink;
    }
}
```

## Implicações para Segurança e Desenvolvimento

### Segurança

1. **Anti-Debugging**: Como mencionado, o campo `BeingDebugged` é frequentemente alvo de técnicas anti-debugging.

2. **DLL Injection**: O conhecimento da estrutura do PEB é crucial para técnicas de injeção de DLL, pois permite manipular as listas de módulos carregados.

3. **Process Hollowing**: Esta técnica avançada de malware envolve a substituição do conteúdo de um processo legítimo por código malicioso, frequentemente manipulando o campo `ImageBaseAddress` do PEB.

4. **API Hooking**: Compreender o PEB é essencial para implementar hooks em APIs do Windows, pois permite localizar e modificar as tabelas de importação e exportação de DLLs.

### Desenvolvimento de Baixo Nível

1. **Loader Personalizado**: Desenvolvedores de loaders personalizados precisam entender e manipular o PEB para carregar corretamente DLLs e resolver dependências.

2. **Depuradores e Ferramentas de Análise**: Ferramentas como depuradores e analisadores de processos dependem do acesso ao PEB para obter informações críticas sobre o processo.

3. **Desenvolvimento de Drivers**: Embora o PEB esteja no espaço de usuário, drivers em modo kernel frequentemente precisam acessá-lo para obter informações sobre processos.

## Conclusão

O Process Environment Block (PEB) é uma estrutura fundamental no sistema operacional Windows, servindo como um repositório central de informações sobre um processo em execução. Compreender sua estrutura, campos e como acessá-lo é essencial para qualquer pessoa envolvida em desenvolvimento de baixo nível, análise de segurança ou engenharia reversa no Windows.

Este artigo forneceu uma visão detalhada do PEB, incluindo sua estrutura, campos críticos, métodos de acesso e implicações para segurança e desenvolvimento. No entanto, é importante lembrar que a estrutura exata do PEB pode variar entre diferentes versões do Windows, e alguns detalhes internos podem não ser documentados oficialmente pela Microsoft.

Para um estudo mais aprofundado, recomenda-se consultar recursos como o livro "Windows Internals" de Mark Russinovich, ou explorar o código-fonte de projetos open-source como o ReactOS, que implementa estruturas compatíveis com o Windows.

## Referências

1. Russinovich, M., Solomon, D., & Ionescu, A. (2012). Windows Internals, Part 1 (6th ed.). Microsoft Press.
2. Yosifovich, P., Ionescu, A., Russinovich, M., & Solomon, D. (2017). Windows Internals, Part 1 (7th ed.). Microsoft Press.
3. [MSDN: Process Environment Block](https://docs.microsoft.com/en-us/windows/win32/api/winternl/ns-winternl-peb)
4. [Geoff Chappell: PEB](https://www.geoffchappell.com/studies/windows/km/ntoskrnl/inc/api/pebteb/peb/index.htm)
5. [NTInternals: PEB Structure](http://undocumented.ntinternals.net/index.html?page=UserMode%2FUndocumented%20Functions%2FNT%20Objects%2FProcess%2FPEB.html)
