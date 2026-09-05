#!/usr/bin/env bash
# ==============================================================================
# OLLAMA VANGUARD // GGUF AUTO-REGISTRATION TOOL (LINUX)
# Scans models/ recursively, compiles hardware-tuned Modelfiles, and registers
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
echo -e "${C_BRIGHT}${C_BOLD}     OLLAMA VANGUARD // GGUF AUTO-REGISTRATION TOOL (LINUX)${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo ""

# Source runtime environment if available
if [ -f "vanguard-env.sh" ]; then
    # shellcheck disable=SC1091
    source "./vanguard-env.sh"
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${C_WARN}[!] Python 3 was not detected on PATH.${C_RESET}"
    echo -e "${C_DIM}    Please install Python 3 or run ./setup-linux.sh first.${C_RESET}"
    exit 1
fi

echo -e "${C_BIO}[*] Scanning '${SCRIPT_DIR}/models' for dropped .gguf files...${C_RESET}"
echo ""

python3 src/register_model.py

echo ""
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo -e "${C_BIO}[+] Model registration routine completed.${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
