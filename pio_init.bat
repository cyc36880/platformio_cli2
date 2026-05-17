@echo off
setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PYTHON_DIR=%SCRIPT_DIR%\python"
set "PYTHON=%PYTHON_DIR%\python.exe"
set "PLATFORMIO_CORE_DIR=%SCRIPT_DIR%\.platformio"
set "PROJECT_DIR=%SCRIPT_DIR%\project\src"
set "PROJECT_INI=%PROJECT_DIR%\platformio.ini"

echo ========================================
echo   PlatformIO Environment Init
echo ========================================
echo.
echo Project dir: %PROJECT_DIR%
echo.

:: Step 0: Check project exists
if not exist "%PROJECT_INI%" (
    echo Error: %PROJECT_INI% not found.
    echo.
    echo Please add your PlatformIO project to project\src\ first.
    echo The project must include platformio.ini with board and library config.
    exit /b 1
)

:: Step 1: Set up portable Python
if not exist "%PYTHON%" (
    echo [1/2] Setting up portable Python 3.14...
    echo.

    :: Check for uv
    where uv >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo uv is required but not found.
        echo Install it: powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
        echo Or download from: https://github.com/astral-sh/uv/releases
        exit /b 1
    )

    :: Install full Python via uv (includes DLLs that embeddable Python lacks)
    echo Installing Python 3.14 via uv...
    uv python install 3.14.5
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install Python.
        exit /b 1
    )

    :: Find uv-managed Python directory
    for /f "delims=" %%i in ('uv python dir') do set "UV_ROOT=%%i"
    set "UV_PYTHON=!UV_ROOT!\cpython-3.14.5-windows-x86_64-none"
    if not exist "!UV_PYTHON!\python.exe" (
        echo Error: Could not locate uv-managed Python at !UV_PYTHON!
        exit /b 1
    )

    :: Copy to project python/ directory
    echo Copying Python to project...
    xcopy /e /i /q "!UV_PYTHON!" "%PYTHON_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to copy Python.
        exit /b 1
    )

    :: Install pip and platformio into portable Python
    echo Installing pip and platformio...
    "%PYTHON%" -m ensurepip 2>nul
    if %ERRORLEVEL% neq 0 (
        uv pip install --python "%PYTHON%" pip
    )
    "%PYTHON%" -m pip install platformio --quiet
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install platformio.
        exit /b 1
    )

    echo Python setup complete.
    echo.
) else (
    echo Python already set up: %PYTHON%
    echo.
)

:: Step 2: Download PlatformIO packages and build
echo [2/2] Downloading PlatformIO packages and libraries...
echo.
"%PYTHON%" -m platformio run --project-dir "%PROJECT_DIR%"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Init failed. Check errors above.
    exit /b 1
)

echo.
echo ========================================
echo   Init complete.
echo   The project folder can now be copied
echo   to any Windows PC and built offline.
echo ========================================
exit /b 0
