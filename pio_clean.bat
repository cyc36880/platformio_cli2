@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PYTHON=%SCRIPT_DIR%\python\python.exe"
set "PLATFORMIO_CORE_DIR=%SCRIPT_DIR%\.platformio"
set "PROJECT_DIR=%SCRIPT_DIR%\project\src"

echo ========================================
echo   Cleaning caches (safe, no re-download needed)
echo ========================================

:: Build artifacts (will be rebuilt next compile)
if exist "%PROJECT_DIR%\.pio\build" (
    echo Removing build cache...
    rmdir /s /q "%PROJECT_DIR%\.pio\build"
)

:: PlatformIO download archives (cached tarballs, can be large)
if exist "%PLATFORMIO_CORE_DIR%\.cache" (
    echo Removing PlatformIO download cache...
    rmdir /s /q "%PLATFORMIO_CORE_DIR%\.cache"
)

:: PlatformIO temp files
if exist "%PLATFORMIO_CORE_DIR%\tmp" (
    echo Removing PlatformIO tmp...
    rmdir /s /q "%PLATFORMIO_CORE_DIR%\tmp"
)

:: -f: also remove downloaded libraries (requires network to restore)
if /i "%1"=="-f" (
    echo/
    echo Force mode: removing libdeps (will need network to restore)...
    if exist "%PROJECT_DIR%\.pio" (
        rmdir /s /q "%PROJECT_DIR%\.pio"
    )
)

echo/
echo ========================================
echo   Clean complete.
echo ========================================
exit /b 0
