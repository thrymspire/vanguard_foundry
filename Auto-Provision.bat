@echo off
setlocal

cd /d "%~dp0"

where python >nul 2>&1
if errorlevel 1 (
    echo [!] Python was not detected on PATH.
    echo [*] Attempting fallback to py launcher...
    py src\hardware_probe.py --provision %*
) else (
    python src\hardware_probe.py --provision %*
)

echo.
pause
