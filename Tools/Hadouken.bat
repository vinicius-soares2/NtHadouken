@echo off
color 0a
chcp 65001

:: Verifica privilégios administrativos
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Solicitando privilégios de Administrador...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit
)

:MENU
cls
echo d8b   db d888888b db   db  .d8b.  d8888b.  .d88b.  db    db db   dD d88888b d8b   db
echo 888o  88 `~~88~~' 88   88 d8' `8b 88  `8D .8P  Y8. 88    88 88 ,8P' 88'     888o  88
echo 88V8o 88    88    88ooo88 88ooo88 88   88 88    88 88    88 88,8P   88ooooo 88V8o 88
echo 88 V8o88    88    88~~~88 88~~~88 88   88 88    88 88    88 88`8b   88~~~~~ 88 V8o88
echo 88  V888    88    88   88 88   88 88  .8D `8b  d8' 88b  d88 88 `88. 88.     88  V888
echo VP   V8P    YP    YP   YP YP   YP Y8888D'  `Y88P'  ~Y8888P' YP   YD Y88888P VP   V8P
echo.
echo Escolha uma opcao:
echo 1. Ativar Modo Debug
echo 2. Verificar Drivers Instalados
echo 3. Verificar Arquivos Corrompidos
echo 4. Coletar Informações do Sistema
echo 5. Sair
set /p option=Escolha uma opcao: 

if "%option%"=="1" goto MODE_DEBUG
if "%option%"=="2" goto VERIFY_DRIVERS
if "%option%"=="3" goto VERIFY_FILES
if "%option%"=="4" goto COLLECT_SYSTEM_INFO
if "%option%"=="5" exit

echo Opção inválida. Tente novamente.
pause
goto MENU

:MODE_DEBUG
echo Ativando Modo Debug...
bcdedit /set debug on
bcdedit /set testsigning off
echo Modo Debug ativado com sucesso!
pause
goto MENU

:VERIFY_DRIVERS
echo Verificando drivers instalados...
set "OUTPUT_FILE=%USERPROFILE%\Documents\drivers_instalados.html"

(
echo ^<html^>
echo ^<head^>^<title^>Lista de Drivers Instalados^</title^>^</head^>
echo ^<body^>
echo ^<h1^>Drivers Instalados^</h1^>
echo ^<pre^>
) > "%OUTPUT_FILE%"

driverquery >> "%OUTPUT_FILE%"

(
echo ^</pre^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT_FILE%"

echo A lista de drivers foi salva em: "%OUTPUT_FILE%"
pause
goto MENU

:VERIFY_FILES
echo Verificando arquivos corrompidos...
powershell -Command "sfc /scannow | Tee-Object -FilePath '%USERPROFILE%\Documents\arquivos_corrompidos.txt'"
echo O relatório de arquivos corrompidos foi salvo em: "%USERPROFILE%\Documents\arquivos_corrompidos.txt"
pause
goto MENU

:COLLECT_SYSTEM_INFO
echo Coletando informações do sistema...
set "OUTPUT_FILE=%USERPROFILE%\Documents\informacoes_sistema.html"

(
echo ^<html^>
echo ^<head^>^<title^>Informações do Sistema^</title^>^</head^>
echo ^<body^>
echo ^<h1^>Informações do Sistema^</h1^>
echo ^<pre^>
) > "%OUTPUT_FILE%"

systeminfo >> "%OUTPUT_FILE%"
(
echo.
echo Discos:
) >> "%OUTPUT_FILE%"
wmic logicaldisk get caption, description, size, freespace >> "%OUTPUT_FILE%"

(
echo.
echo Drivers Instalados:
) >> "%OUTPUT_FILE%"
driverquery >> "%OUTPUT_FILE%"

(
echo ^</pre^>
echo ^</body^>
echo ^</html^>
) >> "%OUTPUT_FILE%"

echo As informações do sistema foram salvas em: "%OUTPUT_FILE%"
pause
goto MENU
