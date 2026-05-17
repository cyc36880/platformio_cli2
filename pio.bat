@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PYTHON=%SCRIPT_DIR%\python\python.exe"
set "PLATFORMIO_CORE_DIR=%SCRIPT_DIR%\.platformio"
set "PROJECT_DIR=%SCRIPT_DIR%\project\src"

if not exist "%PYTHON%" (
    echo Error: Python not found at %PYTHON%
    echo Run pio_init.bat first to set up the environment.
    exit /b 1
)

"%PYTHON%" -m platformio %* --project-dir "%PROJECT_DIR%"
