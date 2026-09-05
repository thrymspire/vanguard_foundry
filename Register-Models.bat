@echo off
setlocal

cd /d "%~dp0"

echo =======================================================================
echo     OLLAMA VANGUARD // GGUF AUTO-REGISTRATION TOOL
echo =======================================================================
echo.
echo [*] Scanning "%~dp0models" for dropped .gguf files...
echo.

where python >nul 2>&1
if errorlevel 1 (
    echo [!] Python was not detected on PATH.
    echo [*] Attempting fallback to py launcher...
    py src\register_model.py
) else (
    python src\register_model.py
)

echo.
echo =======================================================================
echo Press any key to exit...
pause >nul
