@echo off
chcp 65001
:: Verificando se o script está sendo executado com permissões de administrador
openfiles >nul 2>nul
if %errorlevel% NEQ 0 (
    echo Este script precisa de permissões de administrador. Iniciando com elevacao...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb runAs"
    exit /b
)

color 0a
chcp 65001
cls
echo.
echo.
echo d8b   db d888888b db   db  .d8b.  d8888b.  .d88b.  db    db db   dD d88888b d8b   db 
echo 888o  88 `~~88~~' 88   88 d8' `8b 88  `8D .8P  Y8. 88    88 88 ,8P' 88'     888o  88 
echo 88V8o 88    88    88ooo88 88ooo88 88   88 88    88 88    88 88,8P   88ooooo 88V8o 88 
echo 88 V8o88    88    88~~~88 88~~~88 88   88 88    88 88    88 88`8b   88~~~~~ 88 V8o88 
echo 88  V888    88    88   88 88   88 88  .8D `8b  d8' 88b  d88 88 `88. 88.     88  V888 
echo VP   V8P    YP    YP   YP YP   YP Y8888D'  `Y88P'  ~Y8888P' YP   YD Y88888P VP   V8P 
echo.
echo.

echo Baixando o arquivo do GitHub...
curl -L -o "%USERPROFILE%\Downloads\master.zip" https://github.com/lololosys/windbg-theme/archive/refs/heads/master.zip

echo Extraindo o arquivo...
cd /d "%USERPROFILE%\Downloads"
tar -xf master.zip

echo Instalando os temas...
copy /Y "%USERPROFILE%\Downloads\windbg-theme-master\dark.reg" "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\themes"
copy /Y "%USERPROFILE%\Downloads\windbg-theme-master\dark.wew" "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\themes"

echo Registrando o tema...
regedit /s "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\themes\dark.reg"

echo Finalizado com sucesso!
pause
