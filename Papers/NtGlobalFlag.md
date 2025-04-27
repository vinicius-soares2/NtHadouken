# NtGlobalFlag
<p><img src="https://github.com/lnt2eh/NtHadouken/blob/main/assets/NtGlobalFlag.png"/></p>
O NtGlobalFlag é um campo dentro da estrutura PEB do Windows, ela permite que debuggers controlem algumas flags de destruição de heap e afins em caso de overflows. Alguns malwares utilizaram deste método para identificação de debuggers e assim ocultar ou se autodestruir de analistas de malwares iniciantes. De qualquer modo, conhecer a NtGlobalFlag é um dos passos a trilhar o longo caminho do Windows Internals.

## Introdução

Durante a depuração o sistema expõe algumas flags, como a:
 * FLG_HEAP_VALIDATE_PARAMETERS, 
 * FLG_HEAP_ENABLE_TAIL_CHECK, 
 * FLG_HEAP_ENABLE_FREE_CHECK 
 
 O depurador utiliza essas flags para controlar a destruição da pilha durante overflows. A máscara de bit 0x70 é utilizada para definir essas flags no campo NtGlobalFlag. Para fins de exemplos, podemos utilizar este código didático para visualizar na prática, o código faz utilização de funções intrísecas da Microsoft, portanto, utilize o Microsoft Visual Studio para fins de compilação.

``` C
// Código para x64

DWORD pNtGlobalFlag = NULL;
PPEB pPeb = (PPEB)__readgsqword(0x60);
pNtGlobalFlag = *(PDWORD)((PBYTE)pPeb + 0xBC);

if ((pNtGlobalFlag & 0x70) != 0)
{
    printf("O debugger foi detectado\n");
}
``` 

### Localização 
O deslocamento da NtGlobalFlag no PEB(x86) é 0x68 e para PEB(x64) é 0xBC.

## Estrutura PEB
| Offset (x86) | Offset (x64) | Definition                        | Versions           |
|:------------:|:------------:|-----------------------------------|--------------------|
| 0x3C         | 0x70         | ULONG TlsExpansionCounter         | all                |
|              | 0x74         | UCHAR Padding2 [4]                | 6.3 and higher     |
| 0x40         | 0x78         | PVOID TlsBitmap                   | all                |
| 0x44         | 0x80         | ULONG TlsBitmapBits [2]           | all                |
| 0x4C         | 0x88         | PVOID ReadOnlySharedMemoryBase    | all                |
| 0x50         | 0x90         | PVOID ReadOnlySharedMemoryHeap    | 3.10 to 5.2        |
| 0x50         | 0x90         | PVOID HotpatchInformation         | 6.0 to 6.2         |
| 0x50         | 0x90         | PVOID SparePvoid0                 | 6.3 to 1607        |
| 0x50         | 0x90         | PVOID SharedData                  | 1703 and higher    |
| 0x54         | 0x98         | PVOID *ReadOnlyStaticServerData   | all                |
| 0x58         | 0xA0         | PVOID AnsiCodePageData            | all                |
| 0x5C         | 0xA8         | PVOID OemCodePageData             | all                |
| 0x60         | 0xB0         | PVOID UnicodeCaseTableData        | all                |
| 0x64         | 0xB8         | ULONG NumberOfProcessors          | 3.51 and higher    |
| 0x68         | 0xBC         | ULONG NtGlobalFlag                | 3.51 and higher    |
| 0x68         |              | ULONG NtGlobalFlag                | 3.10 to 3.50       |
| 0x70         | 0xC0         | LARGE_INTEGER CriticalSectionTimeout | all            |

Fonte: [PEB Structure](https://geoffchappellmirror.github.io/studies/windows/km/ntoskrnl/inc/api/pebteb/peb/index.htm)

---
