#include <ntddk.h>
/*
  Este driver é um exemplo para utilização da rotina PsSetCreateProcessNotifyRoutine.
  Vale relembrar que a utilização desta função para fins de produção não é mais recomendada.
*/


VOID kernelUnload(_In_ PDRIVER_OBJECT DriverObject);
VOID PcreateProcessNotifyRoutine(HANDLE ParentId, HANDLE ProcessId, BOOLEAN Create);

NTSTATUS DriverEntry(_In_ PDRIVER_OBJECT DriverObject, _In_ PUNICODE_STRING RegistryPath)
{
    UNREFERENCED_PARAMETER(RegistryPath);

    NTSTATUS status = PsSetCreateProcessNotifyRoutine(PcreateProcessNotifyRoutine, FALSE);
    if (!NT_SUCCESS(status)) {
        DbgPrint("Erro ao registrar a rotina de notificação de processo.\n");
        return status;
    }

    DriverObject->DriverUnload = kernelUnload;

    return STATUS_SUCCESS;
}

VOID kernelUnload(_In_ PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);

   
    PsSetCreateProcessNotifyRoutine(PcreateProcessNotifyRoutine, TRUE);
    DbgPrint("Driver descarregado com sucesso.\n");
}

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
