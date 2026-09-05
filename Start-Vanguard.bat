@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo =======================================================================
echo         VANGUARD FOUNDRY // UNIVERSAL LAUNCHER
echo =======================================================================
echo.

:: =======================================================================
:: FINE-TUNED OLLAMA USE CASE FLAGS & PROMPT CACHING (Ryzen Z1 Extreme / 780M)
:: =======================================================================
set OLLAMA_FLASH_ATTENTION=1
set OLLAMA_IGPU_ENABLE=1
set OLLAMA_KV_CACHE_TYPE=f16
set OLLAMA_KEEP_ALIVE=30m
set OLLAMA_NUM_PARALLEL=1
set OLLAMA_CONTEXT_LENGTH=8192
set OLLAMA_ORIGINS=*
set OLLAMA_NO_CLOUD=1
set OLLAMA_NOPRUNE=1

:: 1. Verify Ollama Daemon
echo [*] Checking Ollama daemon...
ollama list >nul 2>&1
if errorlevel 1 (
    echo [!] Ollama is not currently running.
    echo [*] Starting Ollama server in the background...
    start "" ollama serve
    ping 127.0.0.1 -n 3 >nul
) else (
    echo [+] Ollama daemon is active and responsive.
)

:: 2. Verify Local Vanguard Bridge (Port 11435)
echo [*] Checking local Vanguard Bridge on port 11435...
netstat -ano | findstr ":11435" >nul
if errorlevel 1 (
    echo [*] Launching Vanguard Bridge [src\bridge.py]...
    where pythonw >nul 2>&1
    if not errorlevel 1 (
        start "" pythonw src\bridge.py
    ) else (
        where python >nul 2>&1
        if not errorlevel 1 (
            start /b python src\bridge.py >nul 2>&1
        ) else (
            echo [!] Warning: Python interpreter not found on PATH.
        )
    )
    ping 127.0.0.1 -n 2 >nul
    echo [+] Vanguard Bridge started.
) else (
    echo [+] Vanguard Bridge is already running on port 11435.
)

:: 3. Launch Dashboard in Browser
echo [*] Opening Vanguard Foundry dashboard in your default browser...
start "" "%~dp0src\vanguard.html"

echo.
echo =======================================================================
echo  [+] Vanguard Foundry is ready!
echo  ---------------------------------------------------------------------
echo  * Web Dashboard:  src\vanguard.html
echo  * Bridge Server:  http://127.0.0.1:11435
echo  * Models Folder:  %~dp0models\
echo  * Local Outputs:  %~dp0artifacts\
echo  * Global Mirror:  C:\Users\Thrym\Desktop\Alien Artifacts\
echo =======================================================================
echo.
ping 127.0.0.1 -n 4 >nul
