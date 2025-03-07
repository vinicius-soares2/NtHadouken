
# Mini Curso de PowerShell - NtHadouken

## Introdução ao PowerShell

O **PowerShell** é uma poderosa linguagem de automação e linha de comando desenvolvida pela Microsoft, baseada no framework .NET. Ele oferece funcionalidades avançadas para administração de sistemas, manipulação de arquivos e gerenciamento de redes, sendo amplamente utilizado por profissionais de TI, administradores de sistemas e entusiastas da automação.

Diferente do Prompt de Comando (cmd), o PowerShell trabalha com **objetos** em vez de simples texto, o que permite realizar operações mais complexas e eficientes. Ele também suporta comandos do CMD, tornando a transição entre as ferramentas mais simples.

| Nota: Este não é um curso completo. Trata-se de um mini curso com conceitos iniciais do PowerShell, abordando desde comandos básicos até aspectos intermediários que podem ser aplicados no desenvolvimento e na automação. Se você procura um aprendizado mais profundo, continue explorando e praticando os conceitos que aqui são apresentados.
----------

## O que são Cmdlets?

Os **Cmdlets** são comandos internos do PowerShell, projetados para realizar operações específicas. Eles seguem o formato **Verbo-Substantivo**, o que facilita a leitura e compreensão dos comandos.

Exemplo:

```powershell
Get-Command -CommandType Cmdlet

```

Alguns cmdlets comuns incluem:

-   **Get-Help** – Obtém ajuda sobre um comando.
-   **Get-Command** – Lista comandos disponíveis.
-   **Get-Service** – Mostra serviços do sistema.
-   **Stop-Service** – Para um serviço em execução.

### Obtendo Ajuda

Antes de usar um cmdlet, é recomendável verificar sua documentação:

```powershell
Get-Help NomeDoCmdlet

```

Para atualizar a base de dados de ajuda:

```powershell
Update-Help

```

----------

## Cmdlets, Funções e Alias

1.  **Cmdlets:** Comandos embutidos no PowerShell.
    
    ```powershell
    Get-Command -CommandType Cmdlet
    
    ```
    
2.  **Funções:** Blocos de código reutilizáveis.
    
    ```powershell
    Get-Command -CommandType Function
    
    ```
    
3.  **Alias:** Apelidos para comandos mais longos.
    
    ```powershell
    Get-Command -CommandType Alias
    
    ```
    
    Criando um alias personalizado:
    
    ```powershell
    Set-Alias limpar Clear-Host
    
    ```
    

----------

## Controle de Exibição

### Redirecionadores:

-   **`|`** – Passa a saída de um comando para outro.
-   **`>`** – Redireciona saída para um arquivo (substitui conteúdo).
-   **`>>`** – Anexa a saída em um arquivo existente.
-   **`2>`** – Redireciona erros para um arquivo.
-   **`2>>`** – Anexa erros em um arquivo.
-   **`2>&1`** – Redireciona erros para a saída padrão.

Exemplo:

```powershell
Get-Process | Out-File "processos.txt"

```

----------

## Filtrando Resultados com Where-Object

Para filtrar saídas, usamos **Where-Object**:

```powershell
Get-ChildItem | Where-Object {$_.Mode -like "*a*"}

```

### Operadores de Comparação

-   `-lt` (Menor que)
-   `-le` (Menor ou igual)
-   `-gt` (Maior que)
-   `-ge` (Maior ou igual)
-   `-eq` (Igual)
-   `-ne` (Diferente de)
-   `-like` (Permite Wildcards)

----------

## Módulos no PowerShell

Os módulos adicionam funcionalidades ao PowerShell.

-   Listar módulos disponíveis:
    
    ```powershell
    Get-Module -ListAvailable
    
    ```
    
-   Instalar um módulo:
    
    ```powershell
    Install-Module -Name NomeDoModulo
    
    ```
    
-   Importar um módulo:
    
    ```powershell
    Import-Module NomeDoModulo
    
    ```
    

----------

## Variáveis no PowerShell

Variáveis armazenam dados temporários:

```powershell
$nome = "NtHadouken"
Write-Host "Bem-vindo, $nome"

```

----------

## Arrays

Os arrays armazenam coleções de dados indexados.

```powershell
$array = @("Pedro", "Maria", "João")

```

Acessando elementos:

```powershell
$array[0]  # Retorna "Pedro"

```

----------

## Hash Tables

As Hash Tables armazenam pares chave-valor.

```powershell
$equipamentos = @{Server1 = "192.168.2.1"; Router = "192.168.2.254"}

```

Adicionar e remover valores:

```powershell
$equipamentos["Server2"] = "192.168.1.10"
$equipamentos.Remove("Server1")

```

Exemplo de script utilizando Hash Table:

```powershell
Clear-Host
$equipamentos = [ordered] @{Server1="192.168.2.1"; Router="192.168.2.254"}
$equipamentos["Loopback"]="127.0.0.1"
Test-Connection $equipamentos.Router -Count 1
$equipamentos.Values

```

----------

## Select-String

O **Select-String** busca padrões dentro de arquivos:

```powershell
Get-Content "log.txt" | Select-String "Erro"

```

Ou:

```powershell
Select-String -Path "log.txt" -Pattern "Erro"

```

----------

## IF-ELSE
Controle de fluxo de operação do script via condições

Exemplo de utilização:

```powershell
Clear-Host
$service = Get-Service -Name spooler

if ($service.Status -eq "Running")
{
Write-Host "Serviço em execução"
}

else
{
Write-Host "Serviço parado"
}

```

## Looping
-   For
    
    for(Inicio; condição; proximo valor)
    
    {
    
    Código de repetição
    
    }
    
-   FOREACH
    
	   ForEach($variavel e itens da coleção)
    
    {
    
	    Código de repetição
    
    }
    
-   While
    
    While(Condição)
    
    {
    
		   Código de repetição
    
    }
    

### Script exemplar:

```powershell
# Exemplo comando FOR

Clear-Host
$conn = 0
$falhas = 0
$success = 0

for($counter=1; $counter -le 1; $counter++)
{
    Write-Host "Pingando para 192.168.2.$counter"
    $conn = Test-Connection 192.168.1.$counter -Quiet
    if($conn -eq "true")
    {
        Write-Host "A conexao para 192.168.2.$counter foi realizada" -ForegroundColor Green
        $success++
    }
    else
    {
        Write-Host "A conexao para 192.168.2.$counter falhou" -ForegroundColor Yellow
        $falhas++
    }
}
Write-Host "O total de sucesso foi $success" -ForegroundColor Green
Write-Host "Total de falhas: $falhas" -ForegroundColor Yellow

# Exemplo de FOREACH
Write-Host 
foreach($arquivos in Get-Process)
{
    if($arquivos.ProcessName -like "Notepad*")
    {
        Write-Host Processo $arquivos.ProcessName.ToUpper() "aberto" -ForegroundColor Yellow
    }
}

# Exemplo usando WHILE

Write-Host
$i = 0
while($i -le 5)
{
    Write-Host $i
    $i++
}

```
## Funções
Funções são comandos em um script que dura apenas durante a sessão em que estiver sendo executado.

-   Longos comandos.
-   Tarefas repetidas
-   Uso de parâmetros

## Exemplo:

```powershell
Function somar
{
    param($a, $b)
    $resultado = $a + $b
    Write-Host $resultado
}

```
## Workflows
Criação de scripts de longa execução gerenciáveis

Pode ser utilizado para

-   Interromper
-   Suspender
-   Reiniciar
-   Repetir
-   Execução paralela

Para utilização com máquinas remotas, é importante a utilização de “Write-Output” pois, o cmdlet “Write-Host” imprime diretamente no host interativo e não em host remoto.

## New-Objects com WScript.Shell
## WScriptShell

Você pode usar New-Object para trabalhar com componentes COM(Component Object Model). Os componentes variam desde as várias bibliotecas incluídas no WSH(Windows Script Host) até os aplicativos de ActiveX como o Internet Explorer.

-   New-Object -ComObject WScript.Shell
-   New-Object -ComObject WScript.Network
-   New-Object -ComObject Scripting.Dictionary
-   New-Object -ComObject Scripting.FileSystemObject

## Exemplo

```powershell
$wshell = New-Object -ComObject WScript.Shell

$wshell | Get-Member

$wshell.Popup("NtHadouken", 0, "PowerShell", 0x1) 

$wshell.Run("cmd")
$wshell.AppActivate("Notepad")
Start-Sleep -Seconds 2
$wshell.SendKeys("echo NtHadouken ~")

```
Este mini curso apresenta os conceitos fundamentais do PowerShell. Ele serve como um ponto de partida para você explorar o potencial dessa ferramenta incrível. Continue praticando e experimentando diferentes cmdlets para aprofundar seu conhecimento!
