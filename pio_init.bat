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
echo/
echo Project dir: %PROJECT_DIR%
echo/

:: Step 0: Check project exists
if not exist "%PROJECT_INI%" (
    echo Error: %PROJECT_INI% not found.
    echo/
    echo Please add your PlatformIO project to project\src\ first.
    echo The project must include platformio.ini with board and library config.
    exit /b 1
)

:: Step 1: Set up portable Python
if not exist "%PYTHON%" (
    echo [1/2] Setting up portable Python 3.14...
    echo/

    :: Check for uv
    where uv >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo uv is required but not found.
        echo Install it: powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
        echo Or download from: https://github.com/astral-sh/uv/releases
        exit /b 1
    )

    rem Confine all uv caches to project directory
    set "UV_PYTHON_INSTALL_DIR=%SCRIPT_DIR%\.uv\python"
    set "UV_CACHE_DIR=%SCRIPT_DIR%\.uv\cache"
    set "UV_LINK_MODE=copy"

    rem Install full Python via uv (includes DLLs that embeddable Python lacks)
    echo Installing Python 3.14 via uv...
    uv python install 3.14.5 --no-shim
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install Python.
        exit /b 1
    )

    rem Copy Python from uv-managed location to project python/ directory
    set "UV_PYTHON=!UV_PYTHON_INSTALL_DIR!\cpython-3.14.5-windows-x86_64-none"
    if not exist "!UV_PYTHON!\python.exe" (
        echo Error: Could not locate Python at !UV_PYTHON!
        exit /b 1
    )

    echo Copying Python to project...
    xcopy /e /i /q "!UV_PYTHON!" "%PYTHON_DIR%"
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to copy Python.
        exit /b 1
    )

    :: Remove PEP 668 marker so we can install packages into this Python
    if exist "%PYTHON_DIR%\Lib\EXTERNALLY-MANAGED" (
        del "%PYTHON_DIR%\Lib\EXTERNALLY-MANAGED"
    )

    rem Install pip and platformio via uv (works without pip pre-installed)
    echo Installing pip and platformio...
    uv pip install --python "%PYTHON%" pip platformio
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install packages.
        exit /b 1
    )

    echo Python setup complete.
    echo/
) else (
    echo Python already set up: %PYTHON%
    echo/
)

:: Step 2: Download PlatformIO packages and libraries
echo [2/2] Downloading PlatformIO packages and libraries...
echo/
"%PYTHON%" -m platformio run --project-dir "%PROJECT_DIR%"
if %ERRORLEVEL% neq 0 (
    rem Check if packages were downloaded despite build failure
    if exist "%PLATFORMIO_CORE_DIR%\packages\toolchain-gccarmnoneeabi" (
        echo/
        echo Packages downloaded successfully. Build skipped - no source code or compile error
    ) else (
        echo/
        echo Init failed: packages not installed. Check errors above.
        exit /b 1
    )
)

echo/
echo ========================================
echo   Init complete.
echo   The project folder can now be copied
echo   to any Windows PC and built offline.
echo ========================================
exit /b 0
