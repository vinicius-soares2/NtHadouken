# Shadow Space na Convenção de Chamada x64 do Windows

## Introdução

A arquitetura x64 (AMD64/Intel 64) trouxe diversas mudanças significativas em relação à sua predecessora x86, não apenas em termos de capacidade de endereçamento e conjunto de instruções expandido, mas também nas convenções de chamada de função. Uma das características mais intrigantes e frequentemente mal compreendidas da convenção de chamada x64 do Windows é o conceito de "Shadow Space" (também conhecido como "Home Space" ou "Register Parameter Home Area").

Este artigo explora em profundidade o Shadow Space, explicando sua finalidade, implementação, impacto no desenvolvimento de baixo nível e otimizações relacionadas. Compreender este mecanismo é essencial para qualquer pessoa que trabalhe com desenvolvimento em Assembly x64, engenharia reversa, análise de malware ou otimização de desempenho em sistemas Windows.

## O que é o Shadow Space?

O Shadow Space é uma área de memória na pilha (stack) que é reservada pelo chamador (caller) de uma função para uso pelo chamado (callee). Especificamente, na convenção de chamada x64 do Windows, o chamador deve alocar pelo menos 32 bytes (4 slots de 8 bytes cada) na pilha antes de chamar uma função, mesmo que a função não tenha parâmetros.

Esta área é chamada de "Shadow Space" porque serve como uma "sombra" ou reflexo dos registradores de parâmetros. Na convenção x64, os primeiros quatro parâmetros de uma função são passados nos registradores RCX, RDX, R8 e R9 (para valores inteiros) ou XMM0-XMM3 (para valores de ponto flutuante). O Shadow Space fornece um local na pilha onde esses valores de registrador podem ser armazenados, se necessário.

## Por que o Shadow Space Existe?

Existem várias razões para a existência do Shadow Space na convenção de chamada x64 do Windows:

1. **Compatibilidade com Depuradores**: Permite que depuradores examinem os valores dos parâmetros mesmo quando eles são passados em registradores.

2. **Espaço para Spill de Registradores**: Fornece um local pré-alocado onde a função chamada pode salvar (spill) os valores dos registradores de parâmetros, se necessário.

3. **Alinhamento de Pilha**: Ajuda a manter o alinhamento adequado da pilha, o que é importante para desempenho e para instruções SIMD que exigem alinhamento.

4. **Simplificação do Compilador**: Simplifica a geração de código pelo compilador, especialmente para funções variádicas (como printf) que precisam acessar parâmetros de forma dinâmica.

5. **Otimização de Chamadas Recursivas**: Em chamadas recursivas, ter um espaço pré-alocado para parâmetros pode reduzir a sobrecarga.

## Implementação Detalhada

### Convenção de Chamada x64 do Windows

Antes de mergulhar no Shadow Space, vamos revisar brevemente a convenção de chamada x64 do Windows:

1. **Passagem de Parâmetros**:
   - Os primeiros 4 parâmetros inteiros/ponteiros são passados nos registradores RCX, RDX, R8 e R9.
   - Os primeiros 4 parâmetros de ponto flutuante são passados nos registradores XMM0-XMM3.
   - Parâmetros adicionais são passados na pilha, empilhados da direita para a esquerda.

2. **Preservação de Registradores**:
   - Registradores voláteis (não preservados pela função chamada): RAX, RCX, RDX, R8-R11, XMM0-XMM5.
   - Registradores não voláteis (preservados pela função chamada): RBX, RBP, RDI, RSI, RSP, R12-R15, XMM6-XMM15.

3. **Valor de Retorno**:
   - Valores inteiros/ponteiros são retornados em RAX (e RDX para valores de 128 bits).
   - Valores de ponto flutuante são retornados em XMM0.

4. **Alinhamento de Pilha**:
   - A pilha deve estar alinhada em 16 bytes antes de chamar uma função.

### O Shadow Space na Prática

Quando uma função é chamada na arquitetura x64 do Windows, a pilha é organizada da seguinte forma (crescendo de endereços altos para baixos):

```
Endereço Alto
+------------------+
| Parâmetro 5      | <- Se houver mais de 4 parâmetros
| Parâmetro 6      |
| ...              |
+------------------+
| Endereço de      | <- Empilhado pela instrução CALL
| Retorno          |
+------------------+
| Shadow Space     | <- RSP aponta aqui após CALL
| para RCX         |    (32 bytes reservados pelo chamador)
| Shadow Space     |
| para RDX         |
| Shadow Space     |
| para R8          |
| Shadow Space     |
| para R9          |
+------------------+
| Variáveis Locais |
| e Spill Space    |
+------------------+
Endereço Baixo
```

O chamador é responsável por alocar o Shadow Space antes de chamar a função, geralmente subtraindo 32 bytes (mais qualquer espaço necessário para parâmetros adicionais) do registrador RSP. Após o retorno da função, o chamador é responsável por desalocar este espaço.

### Exemplo em Assembly x64

Vamos ver como isso funciona na prática com um exemplo em Assembly x64:

```assembly
; Função chamadora (caller)
caller_function:
    ; Prólogo - Salvar registradores não voláteis se necessário
    push rbx
    push rdi
    
    ; Preparar parâmetros para a função chamada
    mov rcx, 1      ; Primeiro parâmetro
    mov rdx, 2      ; Segundo parâmetro
    mov r8, 3       ; Terceiro parâmetro
    mov r9, 4       ; Quarto parâmetro
    
    ; Alocar Shadow Space (32 bytes) e alinhar a pilha em 16 bytes
    sub rsp, 40     ; 32 bytes para Shadow Space + 8 bytes para alinhamento
    
    ; Chamar a função
    call callee_function
    
    ; Desalocar Shadow Space e restaurar alinhamento
    add rsp, 40
    
    ; Epílogo - Restaurar registradores não voláteis
    pop rdi
    pop rbx
    ret

; Função chamada (callee)
callee_function:
    ; A função pode usar o Shadow Space para salvar os registradores de parâmetros
    mov [rsp+8], rcx   ; Salvar primeiro parâmetro no Shadow Space
    mov [rsp+16], rdx  ; Salvar segundo parâmetro no Shadow Space
    mov [rsp+24], r8   ; Salvar terceiro parâmetro no Shadow Space
    mov [rsp+32], r9   ; Salvar quarto parâmetro no Shadow Space
    
    ; Corpo da função
    ; ...
    
    ; Retornar
    ret
```

Observe que `callee_function` não precisa alocar espaço adicional para salvar os registradores de parâmetros, pois o Shadow Space já foi alocado pelo chamador.

## Uso do Shadow Space pelo Compilador

Os compiladores modernos são bastante inteligentes na forma como utilizam o Shadow Space. Vamos examinar como o compilador MSVC (Microsoft Visual C++) gera código para funções simples:

### Exemplo em C/C++

```c
int add(int a, int b, int c, int d, int e) {
    return a + b + c + d + e;
}

int main() {
    return add(1, 2, 3, 4, 5);
}
```

### Código Assembly Gerado (Simplificado)

```assembly
; Função add
add:
    ; O parâmetro 'e' está na pilha em [rsp+40]
    ; Os parâmetros a, b, c, d estão em rcx, rdx, r8, r9
    
    ; Adicionar os primeiros quatro parâmetros
    add ecx, edx    ; a + b
    add ecx, r8d    ; (a + b) + c
    add ecx, r9d    ; (a + b + c) + d
    
    ; Adicionar o quinto parâmetro da pilha
    add ecx, dword ptr [rsp+40]  ; (a + b + c + d) + e
    
    ; Retornar o resultado em eax
    mov eax, ecx
    ret

; Função main
main:
    ; Alocar Shadow Space e espaço para o quinto parâmetro
    sub rsp, 48     ; 32 bytes para Shadow Space + 8 bytes para parâmetro 5 + 8 bytes para alinhamento
    
    ; Preparar parâmetros
    mov ecx, 1      ; a = 1
    mov edx, 2      ; b = 2
    mov r8d, 3      ; c = 3
    mov r9d, 4      ; d = 4
    mov dword ptr [rsp+32], 5  ; e = 5 (quinto parâmetro na pilha)
    
    ; Chamar a função add
    call add
    
    ; Desalocar espaço
    add rsp, 48
    
    ; Retornar (o resultado já está em eax)
    ret
```

Observe que o compilador alocou 32 bytes para o Shadow Space, mais 8 bytes para o quinto parâmetro, e mais 8 bytes para manter o alinhamento de 16 bytes da pilha.

## Otimizações e Considerações de Desempenho

### Leaf Functions

Uma "leaf function" é uma função que não chama outras funções. Para estas funções, o compilador pode otimizar o uso do Shadow Space:

```assembly
; Leaf function otimizada
optimized_leaf_function:
    ; Não precisa alocar Shadow Space porque não chama outras funções
    ; Corpo da função
    ; ...
    ret
```

No entanto, esta otimização só é segura se a função realmente não chamar outras funções e não usar instruções que possam causar exceções que levem a chamadas de função (como divisão por zero).

### Impacto no Desempenho

A alocação e desalocação do Shadow Space adiciona instruções extras a cada chamada de função, o que pode ter um impacto no desempenho, especialmente em código com muitas chamadas de função pequenas. No entanto, os processadores modernos têm recursos avançados de previsão de desvio e execução fora de ordem que minimizam este impacto.

Em código crítico para desempenho, pode ser benéfico:

1. **Reduzir o Número de Chamadas de Função**: Considerar técnicas como inlining para reduzir a sobrecarga de chamadas.

2. **Usar Leaf Functions Quando Possível**: Funções que não chamam outras funções podem ser mais eficientes.

3. **Agrupar Chamadas de Função**: Se várias funções precisam ser chamadas em sequência, pode ser mais eficiente manter o Shadow Space alocado entre as chamadas, em vez de desalocar e realocar repetidamente.

## Diferenças entre Convenções de Chamada

É importante notar que o Shadow Space é específico da convenção de chamada x64 do Windows. Outras convenções de chamada têm abordagens diferentes:

### System V AMD64 ABI (Linux, macOS, FreeBSD, etc.)

A convenção de chamada System V AMD64 ABI, usada em sistemas Unix-like, não tem o conceito de Shadow Space. Nesta convenção:

- Os primeiros 6 parâmetros inteiros são passados em RDI, RSI, RDX, RCX, R8, R9.
- Os primeiros 8 parâmetros de ponto flutuante são passados em XMM0-XMM7.
- Não há espaço reservado na pilha para os registradores de parâmetros.

### x86 (32 bits)

Na convenção de chamada x86 padrão do Windows (cdecl):

- Todos os parâmetros são passados na pilha.
- O chamador é responsável por limpar a pilha após a chamada.
- Não há conceito de Shadow Space.

## Técnicas de Análise e Depuração

### Identificando o Shadow Space em Código Compilado

Ao analisar código Assembly x64 gerado por compiladores ou fazer engenharia reversa, você pode identificar o Shadow Space procurando por:

1. **Instruções `sub rsp, X` no início de funções**: Onde X é geralmente 32 bytes mais qualquer espaço adicional para variáveis locais, parâmetros adicionais e alinhamento.

2. **Acessos à memória relativos a RSP**: Referências como `[rsp+8]`, `[rsp+16]`, etc., frequentemente indicam acesso ao Shadow Space.

3. **Instruções `add rsp, X` antes de retornos**: Correspondendo à alocação no início da função.

### Depuração com WinDbg

O depurador WinDbg pode ser usado para examinar o Shadow Space durante a execução:

```
0:000> dq @rsp L4      # Exibe os 4 quadwords (32 bytes) do Shadow Space
```

## Implicações para Desenvolvimento de Baixo Nível

### Desenvolvimento em Assembly x64

Ao escrever código Assembly x64 para Windows, é crucial seguir a convenção de chamada corretamente:

1. **Alocar Shadow Space**: Sempre alocar pelo menos 32 bytes de Shadow Space antes de chamar funções.

2. **Manter Alinhamento de Pilha**: Garantir que RSP esteja alinhado em 16 bytes antes de instruções CALL.

3. **Preservar Registradores Não Voláteis**: Salvar e restaurar registradores não voláteis conforme necessário.

### Interoperabilidade com Código C/C++

Para funções Assembly que serão chamadas de código C/C++:

1. **Esperar Shadow Space**: Sua função pode assumir que o chamador alocou o Shadow Space.

2. **Usar Convenção de Chamada Correta**: Seguir a convenção de chamada x64 do Windows para parâmetros e valores de retorno.

Para funções Assembly que chamam código C/C++:

1. **Alocar Shadow Space**: Você deve alocar o Shadow Space antes de chamar funções C/C++.

2. **Passar Parâmetros Corretamente**: Usar os registradores apropriados para os primeiros quatro parâmetros.

## Conclusão

O Shadow Space é um aspecto fundamental da convenção de chamada x64 do Windows que, embora possa parecer estranho à primeira vista, serve a propósitos importantes para depuração, geração de código e desempenho. Compreender como e por que o Shadow Space é usado é essencial para qualquer pessoa que trabalhe com desenvolvimento de baixo nível, engenharia reversa ou otimização de desempenho em sistemas Windows x64.

Este artigo forneceu uma visão detalhada do Shadow Space, incluindo sua implementação, uso pelo compilador, otimizações e implicações para desenvolvimento. Armado com este conhecimento, você estará melhor equipado para entender, analisar e otimizar código x64 no ambiente Windows.

## Referências

1. Microsoft. (2023). x64 calling convention. Microsoft Learn. https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention
2. Russinovich, M., Solomon, D., & Ionescu, A. (2012). Windows Internals, Part 1 (6th ed.). Microsoft Press.
3. Intel Corporation. (2021). Intel® 64 and IA-32 Architectures Software Developer's Manual.
4. AMD. (2020). AMD64 Architecture Programmer's Manual.
5. Pietrek, M. (2006). Everything You Need To Know To Start Programming 64-Bit Windows Systems. MSDN Magazine.
6. Reversing the x64 calling convention. (2019). Low Level Pleasure. https://repnz.github.io/posts/x64-calling-convention/
