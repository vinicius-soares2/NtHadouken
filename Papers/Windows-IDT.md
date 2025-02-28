# Interrupt Descriptor Table (IDT)

A  **Interrupt Descriptor Table (IDT)**  é uma estrutura de dados fundamental no sistema operacional, responsável pelo despacho de interrupções. Ela é especificada pelo fabricante da  **CPU**  e deve ser preenchida pelo sistema operacional durante a inicialização. A IDT é usada pela CPU para direcionar interrupções provenientes de dispositivos de hardware ou geradas por software.

<p align="center">
  <img src="https://miro.medium.com/v2/resize:fit:571/1*rFIYG3vgEhu1MCqm-2FL_Q.png" />
</p>

## O que são Interrupções?

Interrupções são sinais enviados ao processador por dispositivos de hardware ou software para indicar que um evento requer atenção imediata. Elas podem ser causadas por erros (exceções), dispositivos de hardware (como teclados ou discos rígidos) ou instruções de software (como a instrução  `INT`  em assembly).

A IDT é essencial para gerenciar essas interrupções, mapeando cada tipo de interrupção para uma rotina de tratamento específica.

## Registrador IDTR

Cada CPU possui um registrador interno chamado  **IDTR**, que armazena o endereço virtual da IDT. Durante a inicialização do sistema, o Windows configura o IDTR para cada CPU em um sistema multiprocessador. Cada CPU possui sua própria cópia da IDT, apontada por seu próprio IDTR.

Aqui está um exemplo de como o IDTR pode ser visualizado no WinDBG:

```nasm
0: kd> r idtr  
idtr=fffff80377268000  
0: kd> ~1  
1: kd> r idtr  
idtr=ffffc481f7274000
```

## Tabela de Descritores de Interrupção

A IDT contém  **256 entradas**, cada uma correspondendo a um vetor de interrupção. Essas entradas são usadas para:

-   **Exceções**: Erros ou eventos anormais, como divisão por zero.
    
-   **Interrupções de Software**: Geradas por instruções como  `INT`.
    
-   **Interrupções de Hardware**: Provenientes de dispositivos como teclados, mouses, etc.
    

Cada entrada na IDT é representada pela estrutura  **KIDTENTRY64**  em sistemas de 64 bits. Aqui está um exemplo de como visualizar uma entrada no WinDBG:

```nasm
0: kd> dt nt!_KIDTENTRY64 fffff80377268000  
   +0x000 OffsetLow        : 0xa200  
   +0x002 Selector         : 0x10  
   +0x004 IstIndex         : 0y000  
   +0x004 Reserved0        : 0y00000 (0)  
   +0x004 Type             : 0y01110 (0xe)  
   +0x004 Dpl              : 0y00  
   +0x004 Present          : 0y1  
   +0x006 OffsetMiddle     : 0x7440  
   +0x008 OffsetHigh       : 0xfffff803  
   +0x00c Reserved1        : 0  
   +0x000 Alignment        : 0x74408e00`0010a200
```

### Campos da Estrutura KIDTENTRY64

-   **OffsetLow**,  **OffsetMiddle**,  **OffsetHigh**: Partes do offset para o endereço da rotina de tratamento de interrupção (ISR).
    
-   **Selector**: Seletor do segmento de código no GDT (Global Descriptor Table).
    
-   **Type**: Tipo de porta (0xE para Interrupt Gate, 0xF para Trap Gate, 0x5 para Task Gate).
    
-   **Dpl**: Nível de privilégio necessário para acessar a porta.
    
-   **Present**: Indica se a entrada está presente e válida.
    

O endereço da ISR é obtido combinando  `OffsetHigh`,  `OffsetMiddle`  e  `OffsetLow`. No exemplo acima, o endereço seria  **0xfffff8037440a200**.

## Tipos de Portas na IDT

A IDT suporta três tipos de portas:

1.  **Interrupt Gate (0xE)**:
    
    -   Usada para interrupções de hardware e algumas interrupções de software.
        
    -   Desabilita outras interrupções enquanto a ISR está em execução.
        
2.  **Trap Gate (0xF)**:
    
    -   Usada para exceções.
        
    -   Permite que outras interrupções ocorram durante o tratamento da exceção.
        
3.  **Task Gate (0x5)**:
    
    -   Usada para trocar para uma nova tarefa.
        
    -   Contém um seletor para uma Task State Segment (TSS).

Vale lembrar que na arquitetura AMD64, Task Gate não é suportado no Long-Mode.

## Análise de Entradas na IDT

Podemos analisar entradas específicas na IDT usando o WinDBG. Por exemplo, para a entrada 0x40:

```nasm
0: kd> dt @idtr + @@c++(0x40 * sizeof(nt!_KIDTENTRY64)) nt!_KIDTENTRY64  
   +0x000 OffsetLow        : 0x1190  
   +0x002 Selector         : 0x10  
   +0x004 IstIndex         : 0y000  
   +0x004 Reserved0        : 0y00000 (0)  
   +0x004 Type             : 0y01110 (0xe)  
   +0x004 Dpl              : 0y00  
   +0x004 Present          : 0y1  
   +0x006 OffsetMiddle     : 0x7440  
   +0x008 OffsetHigh       : 0xfffff803  
   +0x00c Reserved1        : 0  
   +0x000 Alignment        : 0x74408e00`00101190
```

O endereço da ISR para essa entrada é  **0xfffff80374401190**. Podemos desmontar esse endereço para ver as instruções:

```nasm
0: kd> u 0xfffff80374401190  
nt!KiIsrThunk+0x200:  
fffff803`74401190 6a40            push    40h  
fffff803`74401192 55              push    rbp  
fffff803`74401193 e909060000      jmp     nt!KiIsrLinkage (fffff803`744017a1)  
fffff803`74401198 6a41            push    41h  
fffff803`7440119a 55              push    rbp  
fffff803`7440119b e901060000      jmp     nt!KiIsrLinkage (fffff803`744017a1)  
fffff803`744011a0 6a42            push    42h  
fffff803`744011a2 55              push    rbp
```

## Fluxo de Tratamento de Interrupções

1.  Quando uma interrupção ocorre, a CPU usa o vetor de interrupção para indexar a IDT.
    
2.  O endereço da ISR é recuperado a partir da entrada correspondente na IDT.
    
3.  O controle é transferido para  `nt!KiIsrThunk`, que empurra o vetor de interrupção na pilha e redireciona a execução para  `nt!KiIsrLinkage`.
    
4.  `KiIsrLinkage`  localiza a estrutura  **KINTERRUPT**  associada à interrupção, usando a matriz  `InterruptObject`  no  **KPCR.CurrentPrcb**.
    
5.  A ISR registrada é chamada através do campo  `DispatchAddress`  da estrutura  **KINTERRUPT**.
   
## Estrutura KINTERRUPT

A estrutura  **KINTERRUPT**  contém informações essenciais para o despacho de interrupções, incluindo:

-   **ServiceRoutine**: A rotina de serviço de interrupção (ISR) registrada pelo driver.
    
-   **DispatchAddress**: O endereço para o qual o controle será transferido.
   
Aqui está um exemplo de como recuperar o endereço de um objeto  **KINTERRUPT**:
```nasm
0: kd> uf nt!KiGetInterruptObjectAddress  
nt!KiGetInterruptObjectAddress:  
fffff801`671797a0 65488b142520000000 mov   rdx,qword ptr gs:[20h]  
fffff801`671797a9 4881c240310000  add     rdx,3140h  
fffff801`671797b0 8bc1            mov     eax,ecx  
fffff801`671797b2 488d04c2        lea     rax,[rdx+rax*8]  
fffff801`671797b6 c3              ret
```
O offset de  `InterruptObject`  no  **KPRCB**  é  **0x3140**:
```nasm
0: kd> dt @$pcr nt!_KPCR -a Prcb.InterruptObject[50]  
   +0x180 Prcb                     :  
      +0x3140 InterruptObject          : [80] 0xffff8b80`5f730c80 Void
```
## Conclusão

A  **IDT**  é uma estrutura crítica para o funcionamento do sistema operacional, permitindo o tratamento eficiente de interrupções. Desde a inicialização do sistema até o despacho de interrupções, a IDT e suas estruturas associadas, como  **KIDTENTRY64**  e  **KINTERRUPT**, garantem que o sistema possa responder a eventos de hardware e software de forma rápida e confiável. 
