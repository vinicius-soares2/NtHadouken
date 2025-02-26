
## Introdução

Neste tutorial, abordaremos a configuração do WinDbg para debug do Kernel utilizando o KDNET. Ao final deste guia, você será capaz de:

-   Definir o Windows para modo debug
    
-   Instalar o SDK (Software Development Kit) corretamente
    
-   Configurar o KDNET para depuração remota
    
-   Testar e validar a conexão de debug
    

## 🗺️ Roadmap do Tutorial

1.  Definir o Windows para Modo Debug
    
2.  Instalação do SDK
    
3.  Configuração do KDNET
    
4.  Testando o Debug
    
5.  Conclusão
----------
## 1. Definindo o Windows para Modo Debug

Antes de iniciar o debug do Kernel, é necessário configurar o Windows para operar em modo de depuração. Essa configuração permite que o sistema operacional seja monitorado e depurado corretamente.

### Passos:

1.  Abra o **Prompt de Comando** como **Administrador**.
    
2.  Digite o seguinte comando para habilitar o modo debug:
    
    ```
    bcdedit /set debug on
    ```
    
3.  Reinicie o computador para que as alterações tenham efeito.
    

Caso precise desativar a depuração no futuro, utilize:

```
bcdedit /set debug off
```

## 2. Instalação do SDK (Software Development Kit)

O SDK é essencial para o debug do Kernel, pois fornece as ferramentas necessárias para a depuração. Ele deve ser instalado apenas na **máquina hospedeira**, onde o WinDbg será executado.

### Passos:

1.  Baixe o SDK a partir do [site oficial da Microsoft](https://developer.microsoft.com/en-us/windows/downloads/windows-10-sdk/).
    
2.  Execute o instalador e, ao escolher os componentes, selecione apenas **"Debugging Tools for Windows"**.
    
3.  Finalize a instalação e verifique se o diretório do depurador foi criado em:
    
    ```
    C:\Program Files (x86)\Windows Kits\10\Debuggers\x64
    ```
    

## 3. Configuração do KDNET

O KDNET permite a depuração remota via rede. Siga os passos abaixo para configurá-lo:

### Na máquina hospedeira:

1.  Navegue até o diretório:
    
    ```
    C:\Program Files (x86)\Windows Kits\10\Debuggers\x64
    ```
    
2.  Copie os arquivos `Kdnet.exe` e `VerifiedNICList.xml` para um local acessível.
    

### Na máquina alvo:

1.  Crie um diretório chamado `KD` na raiz do drive C: (`C:\KD`).
    
2.  Cole os arquivos `Kdnet.exe` e `VerifiedNICList.xml` dentro de `C:\KD`.
    
3.  Abra o **Prompt de Comando** como **Administrador** e navegue até `C:\KD`:
    
    ```
    cd C:\KD
    ```
    
4.  Execute o seguinte comando para verificar as interfaces de rede compatíveis:
    
    ```
    kdnet.exe
    ```
    
    -   Isso exibirá as NICs suportadas pelo KDNET.
        
5.  Inicie a depuração via rede, substituindo `[ip_host]` pelo IP da máquina hospedeira e `[porta]` pela porta desejada:
    
    ```
    kdnet.exe [ip_host] [porta]
    ```
    
    **Exemplo:**
    
    ```
    kdnet.exe 192.168.2.1 51111
    ```
    
6.  Se a execução for bem-sucedida, uma chave de configuração será exibida, similar a:
    
    ```
    Key=2steg4fzbj2sz.23418vzkd4ko3.1g34ou07z4pev.1sp3yo9yz874p
    ```
    
    Essa chave será utilizada para configurar a conexão no WinDbg.
    

## 4. Testando o Debug

Agora que a chave de configuração foi gerada na máquina alvo, configure o WinDbg na máquina hospedeira para estabelecer a conexão com o Kernel da máquina alvo.

### Passos:

1.  Abra o **WinDbg** na máquina hospedeira.
    
2.  Pressione **CTRL + K** para abrir a janela de configuração do debug do Kernel.
    
3.  Na aba **NET**, insira:
    
    -   **Port Number**: a porta definida no comando `kdnet.exe`.
        
    -   **Key**: a chave de configuração gerada na máquina alvo.
        
4.  Clique em **OK** para confirmar as configurações.
    
5.  Antes de reiniciar a máquina alvo, teste a conexão executando o seguinte comando no prompt da máquina hospedeira:
    
    ```
    windbg -k net:port=51111,key=2steg4fzbj2sz.23418vzkd4ko3.1g34ou07z4pev.1sp3yo9yz874p
    ```
    
6.  Se o WinDbg conectar com sucesso, reinicie a máquina alvo para iniciar a sessão de debug.
    

## 5. Conclusão

Com a configuração do WinDbg via KDNET concluída, você agora dispõe de um ambiente funcional para depuração remota do Kernel. Essa configuração é extremamente útil para desenvolvimento, análise de falhas e estudo do funcionamento interno do sistema operacional. 
