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

if not exist "%PROJECT_DIR%\platformio.ini" (
    echo Error: Project not found at %PROJECT_DIR%
    echo Please add your PlatformIO project to project\src\
    exit /b 1
)

if not exist "%PROJECT_DIR%\.pio\libdeps" (
    echo Error: Dependencies not installed.
    echo Run pio_init.bat first to download libraries and tools.
    exit /b 1
)

"%PYTHON%" -m platformio run --project-dir "%PROJECT_DIR%" %*
