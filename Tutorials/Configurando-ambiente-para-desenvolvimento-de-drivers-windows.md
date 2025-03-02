
# Introdução
#### Neste tutorial de hoje, iremos preparar um ambiente para aqueles que desejam começar no desenvolvimento de drivers, mas não possuem um norte. O objetivo deste tutorial é fornecer as informações necessárias para iniciantes conseguirem preparar seus ambientes e seguirem seu caminho na trilha de Dev Drivers NT. No entanto, vale ressaltar que esse tutorial não ensina a criação de uma máquina virtual e afins.

## 🗺️ Roadmap do tutorial:
* Instalação do Visual Studio 2022 e WDK
* Instalação do SDK
* Instalação do OsrLoader
* Definição do Windows como modo debug e com testsigning on para desabilitar o DSE  
* Download do DebugView
* Desenvolvimento de um driver "Hello World" e visualização do conteúdo do buffer do Kernel no DebugView

## Instalação do Visual Studio 2022
Na página de instalação do VS 2022, conseguimos cobrir os passos 1, 2 e 3. Você pode baixar o instalador do VS 2022, SDK e WDK através do link: [Download WDK](https://learn.microsoft.com/pt-br/windows-hardware/drivers/download-the-wdk). Neste link já contém os passos que você deve seguir.

### Instalação do VS 2022
1. Após iniciar o instalador do VS 2022, na página inicial, selecione a caixa **"Desenvolvimento para desktop com C++"**.
2. Depois de selecionar a caixa, vá para a guia **"Componentes individuais"**, pesquise **"Spectre"** e marque a caixa **"Bibliotecas com mitigações do Spectre do MSVC v143-VS 2022 C++ x64/x86"**.
3. Pesquise por **"WDK"** e selecione a caixa **"Windows Driver Kit (WDK)"**.

## Instalação do SDK
A instalação do SDK é simples, apenas siga os passos de **"Next", "Next"**.

## Instalação do OsrLoader
Você pode baixar o OsrLoader em: [Download OsrLoader](https://www.osronline.com/OsrDown.cfm/osrloaderv30.zip%5Ename=osrloaderv30.zip&id=157)

1. Após descompactar a pasta, vá para **"PASTA-Descompactada\Projects\OsrLoader\kit\WLH\AMD64\FRE"**.
2. Execute **OSRLOADER.exe**.

## Definição do Windows como modo debug e testsigning on para desabilitar o DSE
Após toda essa etapa de instalação, precisamos definir algumas configurações no Windows para poder compilar e carregar nossos drivers no S.O. Isso é necessário devido à política do **DSE (Driver Signature Enforcement)**, que impede a instalação de drivers não assinados digitalmente.

1. Definir o Windows para modo debug:
   ```bash
   bcdedit /set debug on
   ```
2. Definir o Windows com **testsigning on**:
   ```bash
   bcdedit /set testsigning on
   ```
3. Reinicie a máquina para aplicar as configurações.

## Download do DebugView
Você pode obter o DebugView em: [Download DebugView](https://learn.microsoft.com/pt-br/sysinternals/downloads/debugview)

Ele será utilizado para visualizar o buffer de mensagens do Kernel.

## Desenvolvimento de um driver "Hello World" e visualização do buffer do Kernel no DebugView
Agora que estamos com o ambiente pronto, vamos validar se tudo está funcionando corretamente.

### Criar um projeto no Visual Studio
1. Abra o Visual Studio e selecione **"Criar um novo projeto"**.
2. Na caixa de pesquisa de modelos, busque por **"Empty WDM Driver"** e selecione-o.
3. Dê um nome ao projeto (**exemplo: MyDriver1**) e certifique-se de marcar a opção **"Colocar a solução e o projeto no mesmo diretório"**.
4. Clique em **"Criar"**.

### Criar o código do driver
1. No Explorador de Solução, em **"Driver Files"**, exclua o arquivo **.INF**.
2. Clique com o botão direito em **"Driver Files"** > **Adicionar -> Novo Item**.
3. Nomeie o arquivo com extensão **.c** (**exemplo: Hello.c**) e clique em **Adicionar**.

Agora, adicione o seguinte código ao arquivo criado:

```c
#include <ntddk.h>

VOID kernelUnload(_In_ PDRIVER_OBJECT DriverObject)
{
    UNREFERENCED_PARAMETER(DriverObject);
    KdPrint(("Descarregando Driver\n"));
}

NTSTATUS DriverEntry(_In_ PDRIVER_OBJECT DriverObject, _In_ PUNICODE_STRING RegistryPath)
{
    UNREFERENCED_PARAMETER(RegistryPath);
    KdPrint(("Hello, World\n"));
    DriverObject->DriverUnload = kernelUnload;
    return STATUS_SUCCESS;
}
```

### Compilar o driver
Para compilar, pressione **Ctrl + Shift + B** ou vá em **Compilação** > **Compilar Solução**.

### Carregar o driver com o OsrLoader
1. No OsrLoader, clique em **"Browse"** e selecione o arquivo **.sys** gerado na pasta **x64\Debug**.
2. Clique em **"Register Service"**.
3. Abra o **DebugView** como administrador e pressione **Ctrl + K** para habilitar a captura de eventos do Kernel.
4. No OsrLoader, clique em **"Start Service"**.
5. Se tudo ocorrer bem, você verá a mensagem **"Hello, World"** no DebugView.
6. Clique em **"Stop Service"** para descarregar o driver.

## Conclusão
Com isso, configuramos nosso ambiente de desenvolvimento, compilamos e carregamos um driver simples no Windows. Agora, você está pronto para explorar mais sobre desenvolvimento de drivers NT! Boa sorte nos seus estudos.
