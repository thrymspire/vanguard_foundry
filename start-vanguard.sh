#!/usr/bin/env bash
# ==============================================================================
# OLLAMA VANGUARD // LINUX FOUNDRY LAUNCHER
# 1-Click Cockpit Initialization, Daemon Verification & Bridge Orchestration
# ==============================================================================

set -uo pipefail

# ANSI Color Tokens
C_SIGNAL="\033[38;2;157;92;255m"
C_BRIGHT="\033[38;2;192;132;252m"
C_BIO="\033[38;2;95;251;241m"
C_WARN="\033[38;2;255;107;129m"
C_INK="\033[38;2;237;230;255m"
C_DIM="\033[38;2;169;150;214m"
C_BOLD="\033[1m"
C_RESET="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo -e "${C_BRIGHT}${C_BOLD}        OLLAMA VANGUARD // UNIVERSAL FOUNDRY LAUNCHER${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo ""

# ------------------------------------------------------------------------------
# 1. Source Runtime Environment Configuration
# ------------------------------------------------------------------------------
if [ -f "vanguard-env.sh" ]; then
    # shellcheck disable=SC1091
    source "./vanguard-env.sh"
    echo -e "${C_BIO}[+] Sourced runtime environment from vanguard-env.sh${C_RESET}"
else
    # Fallback to default high-throughput compute flags
    export OLLAMA_FLASH_ATTENTION=1
    export OLLAMA_IGPU_ENABLE=1
    export OLLAMA_KV_CACHE_TYPE=f16
    export OLLAMA_KEEP_ALIVE=30m
    export OLLAMA_NUM_PARALLEL=1
    export OLLAMA_CONTEXT_LENGTH=8192
    export OLLAMA_ORIGINS="*"
    export OLLAMA_NO_CLOUD=1
    export OLLAMA_NOPRUNE=1
    export VANGUARD_BRIDGE_PORT=11435
    export VANGUARD_GLOBAL_DIR="${HOME}/Desktop/Alien Artifacts"
    echo -e "${C_DIM}[*] Initialized default high-throughput compute environment flags.${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 2. Verify Ollama Daemon (Port 11434)
# ------------------------------------------------------------------------------
echo -e "${C_BIO}[*] Checking Ollama daemon status...${C_RESET}"

is_ollama_online() {
    if command -v ollama >/dev/null 2>&1; then
        ollama list >/dev/null 2>&1 && return 0
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -s -m 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && return 0
    fi
    return 1
}

if is_ollama_online; then
    echo -e "${C_BIO}[+] Ollama daemon is active and responsive on port 11434.${C_RESET}"
else
    echo -e "${C_WARN}[!] Ollama is not currently responding.${C_RESET}"
    
    # Try systemd service if available
    STARTED_VIA_SYSTEMD=0
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet ollama 2>/dev/null || systemctl list-unit-files | grep -q "ollama.service"; then
            echo -e "${C_DIM}[*] Attempting to start via systemctl start ollama...${C_RESET}"
            systemctl start ollama 2>/dev/null || sudo systemctl start ollama 2>/dev/null || true
            sleep 2
            if is_ollama_online; then
                STARTED_VIA_SYSTEMD=1
                echo -e "${C_BIO}[+] Ollama started successfully via systemd.${C_RESET}"
            fi
        fi
    fi

    # Fallback to background process
    if [ "$STARTED_VIA_SYSTEMD" -eq 0 ]; then
        if command -v ollama >/dev/null 2>&1; then
            echo -e "${C_BRIGHT}[*] Spawning Ollama server daemon in background...${C_RESET}"
            nohup ollama serve >/dev/null 2>&1 &
            sleep 3
            if is_ollama_online; then
                echo -e "${C_BIO}[+] Ollama daemon initialized.${C_RESET}"
            else
                echo -e "${C_WARN}[!] Warning: Ollama daemon still initializing or failed to bind.${C_RESET}"
            fi
        else
            echo -e "${C_WARN}[!] Error: 'ollama' command not found. Run ./setup-linux.sh first.${C_RESET}"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 3. Verify Vanguard Bridge (Port 11435)
# ------------------------------------------------------------------------------
echo -e "${C_BIO}[*] Checking Vanguard Bridge on port 11435...${C_RESET}"

is_bridge_online() {
    python3 -c "import socket; s = socket.socket(); s.settimeout(1); s.connect(('127.0.0.1', 11435)); s.close()" 2>/dev/null && return 0
    return 1
}

if is_bridge_online; then
    echo -e "${C_BIO}[+] Vanguard Bridge is already running on port 11435.${C_RESET}"
else
    echo -e "${C_BRIGHT}[*] Launching Vanguard Bridge (src/bridge.py)...${C_RESET}"
    nohup python3 src/bridge.py >/dev/null 2>&1 &
    sleep 1
    if is_bridge_online; then
        echo -e "${C_BIO}[+] Vanguard Bridge online.${C_RESET}"
    else
        echo -e "${C_WARN}[!] Notice: Vanguard Bridge spawned (verifying background startup).${C_RESET}"
    fi
fi

# ------------------------------------------------------------------------------
# 4. Launch Cockpit Studio in Web Browser
# ------------------------------------------------------------------------------
HTML_PATH="${SCRIPT_DIR}/src/vanguard.html"
echo -e "${C_BIO}[*] Opening Vanguard Cockpit in default browser...${C_RESET}"

open_browser() {
    local TARGET="file://${HTML_PATH}"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$TARGET" >/dev/null 2>&1 && return 0
    elif command -v gio >/dev/null 2>&1; then
        gio open "$TARGET" >/dev/null 2>&1 && return 0
    elif command -v sensible-browser >/dev/null 2>&1; then
        sensible-browser "$TARGET" >/dev/null 2>&1 && return 0
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$TARGET" >/dev/null 2>&1 & return 0
    elif command -v chromium >/dev/null 2>&1; then
        chromium "$TARGET" >/dev/null 2>&1 & return 0
    elif command -v google-chrome >/dev/null 2>&1; then
        google-chrome "$TARGET" >/dev/null 2>&1 & return 0
    fi
    return 1
}

if ! open_browser; then
    echo -e "${C_WARN}[!] Could not automatically trigger browser opener.${C_RESET}"
    echo -e "${C_INK}    Please open manually: ${C_BRIGHT}file://${HTML_PATH}${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 5. Dashboard Status Summary
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo -e "${C_BIO}${C_BOLD} [+] Ollama Vanguard is live and operational!${C_RESET}"
echo -e "${C_SIGNAL}-----------------------------------------------------------------------${C_RESET}"
echo -e "${C_INK}  * Web Dashboard:  ${C_BRIGHT}file://${HTML_PATH}${C_RESET}"
echo -e "${C_INK}  * Bridge Server:  ${C_BRIGHT}http://127.0.0.1:11435${C_RESET}"
echo -e "${C_INK}  * Ollama Engine:  ${C_BRIGHT}http://127.0.0.1:11434${C_RESET}"
echo -e "${C_INK}  * Models Folder:  ${C_BRIGHT}${SCRIPT_DIR}/models/${C_RESET}"
echo -e "${C_INK}  * Local Outputs:  ${C_BRIGHT}${SCRIPT_DIR}/artifacts/${C_RESET}"
echo -e "${C_INK}  * Global Mirror:  ${C_BRIGHT}${VANGUARD_GLOBAL_DIR:-${HOME}/Desktop/Alien Artifacts}${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo ""
