
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

Este mini curso apresenta os conceitos fundamentais do PowerShell.
