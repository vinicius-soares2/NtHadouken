# Thread Local Storage Callbacks

Este artigo aborda o que é o recurso TLS(Thread Local Storage) e o mecanismo de chamada de retorno TLS(Thread Local Storage) do Windows. Nele, irei explicar o que é este mecanismo, como funciona e irei deixar um código de utilização prática para aqueles que tiverem interesse em praticar e realizar suas próprias modificações. Este artigo será útil para um futuro post para técnicas anti-reversing em Windows que irei adicionar aqui no projeto **NtHadouken**.

## O que é o TLS(Thread Local Storage)? 
Cada variável local de uma função são exclusivas para cada thread que executa a função. No entanto, as variáveis estáticas e globais são compartilhadas por todos os threads no processo. Vale ressaltar que todos os threads de um processo compartilham seu espaço de endereço virtual. Com o TLS(Thread Local Storage), é possível fornecer dados exclusivos para cada thread que o processo pode acessar usando um índice global. Um thread aloca o índice, que pode ser usado pelos outros threads para recuperar os dados exclusivos associados ao índice.

## Como ele funciona?
Durante a criação de threads, o sistema aloca uma matriz de valores **(LPVOID)** para o TLS, estes por sua vez são inicializados como **NULL**. Antes que um índice possa ser utilizado, ele deve ser alocado por um dos threads.
Cada thread armazena seus dados para um índice TLS na matriz. 

## Retorno de chamada TLS ou TLS Callback
Callbacks TLS é um mecanismo do Windows que permite que um programa defina uma função de chamada quando uma thread for criada. A utilização desses callbacks podem ser diversos, como inicialização de dados específicos da thread ou modificar o comportamento da thread.

Inclusive, essa é uma das técnicas utilizadas por criadores de malware como técnica antidepuração, onde um programa pode utilizar o callback TLS para executar código cantes do Entry Point principal do programa, que é definido no cabeçalho PE. Ou seja, um programa pode utilizar o Callback TLS para detectar se está sendo depurado em caso de afirmativo, pode encerrar o processo ou tomar outras medidas para evitar a depuração. Dificultando assim a engenharia reversa. **Isso será abordado futuramente na seção de [Reversing](https://github.com/lnt2eh/NtHadouken/tree/main/Tutorials/Reverse-Engineering)**

## Código Prático
``` C
    Código de utilização prática

    /*
    Criado por _int2Eh para fins de testes práticos.
    Projeto: **NtHadouken**
    */

    #include <windows.h>
    #include <stdio.h>

    /*
        Prototipação da função de callback TLS.
        Essa função será executada automaticamente durante o ciclo de vida da thread/processo.
    */
    void NTAPI TLSCallback(PVOID DllHandle, DWORD Reason, PVOID Reserved);

    /*
        Definição do ponteiro da função na seção .CRT$XLB.
        Essa seção é usada pelo loader do Windows para localizar e executar callbacks TLS.
    */
    #ifdef _MSC_VER
    // Para compiladores MSVC
    #pragma const_seg(".CRT$XLB")
    EXTERN_C const PIMAGE_TLS_CALLBACK pTLSCallback = TLSCallback;
    #pragma const_seg()
    #else
    // Para compiladores MinGW
    PIMAGE_TLS_CALLBACK pTLSCallback __attribute__((section(".CRT$XLB"))) = TLSCallback;
    #endif

    /*
        Implementação do callback TLS.
        Aqui pode-se executar código antes mesmo do Entry Point principal (main ou WinMain).
    */
    void NTAPI TLSCallback(PVOID DllHandle, DWORD Reason, PVOID Reserved) {
        switch (Reason) {
            case DLL_PROCESS_ATTACH:
                /*
                    Verifica se o processo está sendo depurado.
                    Pode ser usado como técnica anti-debug.
                */
                if (IsDebuggerPresent()) {
                    MessageBoxA(NULL, "Debugger detectado! Encerrando o processo...", "Alerta TLS", MB_ICONERROR);
                    ExitProcess(1);
                } else {
                    MessageBoxA(NULL, "TLS Callback: DLL_PROCESS_ATTACH sem depurador.", "Info TLS", MB_OK);
                }
                break;
            case DLL_THREAD_ATTACH:
                MessageBoxA(NULL, "TLS Callback: DLL_THREAD_ATTACH", "Info TLS", MB_OK);
                break;
            case DLL_THREAD_DETACH:
                MessageBoxA(NULL, "TLS Callback: DLL_THREAD_DETACH", "Info TLS", MB_OK);
                break;
            case DLL_PROCESS_DETACH:
                MessageBoxA(NULL, "TLS Callback: DLL_PROCESS_DETACH", "Info TLS", MB_OK);
                break;
        }
    }

    /*
        Entry Point principal do programa.
        Este código só será executado se nenhum depurador for detectado no TLS Callback.
    */
    int main() {
        MessageBoxA(NULL, "Entry Point Principal (main)", "NtHadouken", MB_OK);
        return 0;
    }

```
