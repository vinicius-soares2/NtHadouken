# Windows Kernel Callbacks
Neste tutorial, vamos explorar as **rotinas de callback no Kernel do Windows**, explicando o que são, como funcionam e como podemos utilizá-las em drivers. Este tutorial servirá como um primeiro contato com rotinas de callback, e vamos usar a rotina **PsSetCreateProcessNotifyRoutine** como exemplo de implementação.

### O que são as rotinas de Callback?

As **rotinas de callback** no Kernel do Windows fornecem uma maneira eficiente para os drivers receberem notificações quando eventos específicos acontecem no sistema. Elas permitem que um driver **escute eventos** sem precisar ficar verificando constantemente o estado do sistema, o que ajuda a melhorar a performance e a segurança.

Algumas rotinas de callback importantes para fins exemplares incluem:
1.  **PsSetCreateProcessNotifyRoutineEx()**: Notifica quando um processo é criado ou finalizado.
2.  **PsSetCreateThreadNotifyRoutine()**: Notifica quando uma thread é criada ou finalizada.
3.  **PsSetLoadImageNotifyRoutine()**: Notifica quando uma imagem (como um driver ou DLL) é carregada no sistema.
4.  **PsCreateSystemThread()**: Cria e gerencia threads no espaço do kernel.

### **Rotina PsSetCreateProcessNotifyRoutine**

A função **PsSetCreateProcessNotifyRoutine** permite que o Kernel do Windows notifique um driver sempre que um processo for criado ou finalizado no sistema. Para fins de exemplo, utilizaremos esta função neste tutorial.

> **Nota:** A Microsoft não recomenda o uso dessa função em ambientes de produção devido a possíveis impactos na performance e segurança. Consulte a [documentação oficial](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/ntddk/nf-ntddk-pssetcreateprocessnotifyroutine) para alternativas e melhores práticas.

### **Passo 1: Configuração do Driver**

Antes de começarmos a implementação da rotina de callback, é necessário configurar o ambiente básico do driver. Vamos criar um driver simples com a estrutura inicial.
```c
#include <ntddk.h>

// Declaração de variáveis globais
PVOID g_ProcessNotifyHandle = NULL;

// Protótipos
NTSTATUS DriverEntry(_In_ PDRIVER_OBJECT DriverObject, _In_ PUNICODE_STRING RegistryPath);
VOID UnloadDriver(_In_ PDRIVER_OBJECT DriverObject);
VOID PcreateProcessNotifyRoutine(HANDLE ParentId, HANDLE ProcessId, BOOLEAN Create);

NTSTATUS DriverEntry(PDRIVER_OBJECT DriverObject, PUNICODE_STRING RegistryPath)
{
    UNREFERENCED_PARAMETER(RegistryPath);

    // Registra a rotina de notificação de criação de processos
    NTSTATUS status = PsSetCreateProcessNotifyRoutine(PcreateProcessNotifyRoutine, FALSE);
    if (!NT_SUCCESS(status)) {
        DbgPrint("Erro ao registrar a rotina de notificação de processo.\n");
        return status;
    }

    // Configura o unload do driver
    DriverObject->DriverUnload = UnloadDriver;

    return STATUS_SUCCESS;
}

VOID UnloadDriver(PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);

    // Remove a rotina de notificação de criação de processos
    PsSetCreateProcessNotifyRoutine(PcreateProcessNotifyRoutine, TRUE);
    DbgPrint("Driver descarregado com sucesso.\n");
}
```

### **Passo 2: Implementação da Rotina de Callback**

Agora, implementamos a função `PcreateProcessNotifyRoutine`, que será chamada sempre que um processo for criado ou finalizado no sistema.

```c
void PcreateProcessNotifyRoutine(HANDLE ParentId, HANDLE ProcessId, BOOLEAN Create)
{
	KdPrint(("ProcessParent: %llu\n", (unsigned long long)ParentId));
	KdPrint(("ProcessId: %llu\n", (unsigned long long)ProcessId));
	if (Create)
	{
		KdPrint(("Processo criado\n"));
	}
	else
	{
		KdPrint(("Processo finalizado\n"));
	}
}
```
### Conclusão
Neste tutorial, exploramos o conceito de **rotinas de callback no Windows Kernel** e como utilizá-las em drivers para monitorar eventos específicos, como a criação e finalização de processos. Usamos a função **PsSetCreateProcessNotifyRoutine** como exemplo prático para ilustrar como implementar uma rotina de callback que notifica o driver sempre que um processo é criado ou finalizado no sistema.
Este tutorial serviu como um ponto de partida para o aprendizado sobre callbacks no Windows Kernel, mas há muitas outras rotinas que podem ser exploradas, como aquelas para threads e imagens carregadas. Esperamos que este tutorial tenha sido útil para introduzi-lo ao mundo das rotinas de callback no Windows Kernel.
