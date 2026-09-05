#!/usr/bin/env bash
# ==============================================================================
# OLLAMA VANGUARD // UNIVERSAL LINUX ENVIRONMENT SETUP ENGINE
# Supports: Debian/Ubuntu, Fedora/RHEL/CentOS, Arch/Manjaro, openSUSE, Alpine
# Configures: Ollama daemon, Python runtime, ROCm / CUDA / AVX-512 hardware tuning
# ==============================================================================

set -uo pipefail

# ANSI Color Palette (Alien Purple / Bio-Cyan theme)
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
echo -e "${C_BRIGHT}${C_BOLD}        OLLAMA VANGUARD // LINUX ENVIRONMENT PROVISIONER${C_RESET}"
echo -e "${C_DIM}        Universal Cross-Distribution Setup & Hardware Acceleration${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo ""

# ------------------------------------------------------------------------------
# 1. Privileges & Sudo Helper
# ------------------------------------------------------------------------------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    elif command -v doas >/dev/null 2>&1; then
        SUDO="doas"
    else
        echo -e "${C_WARN}[!] Warning: Not running as root and neither 'sudo' nor 'doas' was found.${C_RESET}"
        echo -e "${C_DIM}    Some system-wide package installations may require manual privileges.${C_RESET}"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Linux Distribution Identification
# ------------------------------------------------------------------------------
echo -e "${C_BIO}[*] Detecting Linux distribution...${C_RESET}"

DISTRO_ID="generic"
DISTRO_FAMILY=""

if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-generic}"
    DISTRO_FAMILY="${ID_LIKE:-}"
    DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
else
    DISTRO_NAME="Generic Linux ($(uname -s) $(uname -m))"
fi

echo -e "${C_INK}    Detected: ${C_BRIGHT}${DISTRO_NAME}${C_RESET} (${DISTRO_ID}${DISTRO_FAMILY:+ / $DISTRO_FAMILY})"

# ------------------------------------------------------------------------------
# 3. Package Manager & Dependency Resolution
# ------------------------------------------------------------------------------
install_package() {
    local PKG_NAME="$1"
    echo -e "${C_BIO}[*] Installing dependency '${PKG_NAME}' via native package manager...${C_RESET}"

    if command -v apt-get >/dev/null 2>&1; then
        $SUDO apt-get update -qq && $SUDO apt-get install -y -qq "$PKG_NAME"
    elif command -v dnf >/dev/null 2>&1; then
        $SUDO dnf install -y -q "$PKG_NAME"
    elif command -v yum >/dev/null 2>&1; then
        $SUDO yum install -y -q "$PKG_NAME"
    elif command -v pacman >/dev/null 2>&1; then
        $SUDO pacman -Sy --noconfirm "$PKG_NAME"
    elif command -v zypper >/dev/null 2>&1; then
        $SUDO zypper --quiet install -y "$PKG_NAME"
    elif command -v apk >/dev/null 2>&1; then
        $SUDO apk add --no-cache "$PKG_NAME"
    elif command -v xbps-install >/dev/null 2>&1; then
        $SUDO xbps-install -y "$PKG_NAME"
    else
        echo -e "${C_WARN}[!] Automatic package manager not recognized. Please install '${PKG_NAME}' manually.${C_RESET}"
        return 1
    fi
}

# Verify / Install curl
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${C_WARN}[!] 'curl' is required but not installed.${C_RESET}"
    install_package "curl" || true
else
    echo -e "${C_BIO}[+] 'curl' is installed.${C_RESET}"
fi

# Verify / Install Python 3
if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${C_WARN}[!] 'python3' is required for the Vanguard Bridge and registrar.${C_RESET}"
    if command -v apt-get >/dev/null 2>&1; then
        install_package "python3" && install_package "python3-pip" || true
    else
        install_package "python3" || true
    fi
else
    PY_VER=$(python3 --version 2>&1)
    echo -e "${C_BIO}[+] Python runtime found: ${C_INK}${PY_VER}${C_RESET}"
fi

# Check for xdg-open / browser opener
if ! command -v xdg-open >/dev/null 2>&1; then
    echo -e "${C_DIM}[*] Optional 'xdg-utils' not found. Installing for 1-click browser launch...${C_RESET}"
    install_package "xdg-utils" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# 4. Ollama Runtime Engine Installation
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BIO}[*] Verifying Ollama engine installation...${C_RESET}"

if ! command -v ollama >/dev/null 2>&1; then
    echo -e "${C_WARN}[!] Ollama is not installed on this system.${C_RESET}"
    echo -e "${C_BRIGHT}[*] Running official Ollama installation script (https://ollama.com/install.sh)...${C_RESET}"
    
    if curl -fsSL https://ollama.com/install.sh | sh; then
        echo -e "${C_BIO}[+] Ollama installed successfully.${C_RESET}"
    else
        echo -e "${C_WARN}[!] Automatic installation failed or was interrupted.${C_RESET}"
        echo -e "${C_DIM}    Please run: curl -fsSL https://ollama.com/install.sh | sh manually.${C_RESET}"
    fi
else
    OLLAMA_VER=$(ollama --version 2>&1 || echo "installed")
    echo -e "${C_BIO}[+] Ollama is present: ${C_INK}${OLLAMA_VER}${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 5. Hardware Profiling & Compute Acceleration Detection
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BIO}[*] Profiling hardware accelerators (ROCm, CUDA, AVX-512)...${C_RESET}"

ROCM_GFX_OVERRIDE=""
ACCELERATION_MODE="CPU (Zen/AVX)"

# 5a. Check NVIDIA CUDA
if command -v nvidia-smi >/dev/null 2>&1; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -n 1 || echo "NVIDIA GPU")
    ACCELERATION_MODE="NVIDIA CUDA ($GPU_NAME)"
    echo -e "${C_BIO}[+] NVIDIA GPU Detected:${C_RESET} ${C_INK}${GPU_NAME}${C_RESET}"
fi

# 5b. Check AMD ROCm / RDNA APU / Discrete GPU
if lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -iq 'AMD\|Advanced Micro Devices'; then
    AMD_CARD=$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -i 'AMD' | head -n 1 | sed 's/.*: //')
    echo -e "${C_BIO}[+] AMD Graphics Processor Detected:${C_RESET} ${C_INK}${AMD_CARD}${C_RESET}"
    
    # Check for RDNA 3 / Phoenix / Hawk Point / Ryzen Z1 Extreme / Radeon 780M / 760M
    if echo "$AMD_CARD" | grep -qiE 'Phoenix|Hawk|780M|760M|Z1|RDNA3|gfx1103|7840|8840'; then
        ROCM_GFX_OVERRIDE="11.0.0"
        ACCELERATION_MODE="AMD ROCm / RDNA 3 iGPU (gfx1100 override)"
        echo -e "${C_BRIGHT}[+] AMD RDNA 3 APU detected! Applying HSA_OVERRIDE_GFX_VERSION=11.0.0 for full hardware offloading.${C_RESET}"
    elif echo "$AMD_CARD" | grep -qiE 'Rembrandt|680M|660M|RDNA2|gfx103'; then
        ROCM_GFX_OVERRIDE="10.3.0"
        ACCELERATION_MODE="AMD ROCm / RDNA 2 APU (gfx1030 override)"
        echo -e "${C_BRIGHT}[+] AMD RDNA 2 APU detected! Applying HSA_OVERRIDE_GFX_VERSION=10.3.0.${C_RESET}"
    fi
fi

# 5c. Check CPU Features (AVX-512, AVX2, Core Count)
if [ -f /proc/cpuinfo ]; then
    CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
    THREAD_COUNT=$(nproc 2>/dev/null || grep -c "^processor" /proc/cpuinfo)
    echo -e "${C_BIO}[+] CPU Architecture:${C_RESET} ${C_INK}${CPU_MODEL} (${THREAD_COUNT} threads)${C_RESET}"

    if grep -q "avx512" /proc/cpuinfo; then
        echo -e "${C_BIO}[+] AVX-512 Vector Extensions Detected:${C_RESET} ${C_BRIGHT}Enabled (VNNI hardware acceleration active)${C_RESET}"
    elif grep -q "avx2" /proc/cpuinfo; then
        echo -e "${C_BIO}[+] AVX2 Vector Extensions Detected:${C_RESET} ${C_INK}Supported${C_RESET}"
    fi
fi

echo -e "${C_BIO}[*] Selected Primary Compute Target:${C_RESET} ${C_BRIGHT}${ACCELERATION_MODE}${C_RESET}"

# ------------------------------------------------------------------------------
# 6. Generate Tuned Runtime Environment Configuration (vanguard-env.sh)
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BIO}[*] Generating tuned runtime environment file (vanguard-env.sh)...${C_RESET}"

cat << 'EOF' > vanguard-env.sh
#!/usr/bin/env bash
# ==============================================================================
# OLLAMA VANGUARD // LINUX RUNTIME ENVIRONMENT SPECIFICATION
# Auto-generated by setup-linux.sh
# ==============================================================================

# 1. Performance & Compute Flags
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_IGPU_ENABLE=1
export OLLAMA_KV_CACHE_TYPE=f16
export OLLAMA_KEEP_ALIVE=30m
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_CONTEXT_LENGTH=8192

# 2. Network & Air-Gapped Security
export OLLAMA_ORIGINS="*"
export OLLAMA_NO_CLOUD=1
export OLLAMA_NOPRUNE=1

# 3. Vanguard Custom Ports & Paths
export VANGUARD_BRIDGE_PORT=11435
export VANGUARD_GLOBAL_DIR="${HOME}/Desktop/Alien Artifacts"
EOF

if [ -n "$ROCM_GFX_OVERRIDE" ]; then
    echo "" >> vanguard-env.sh
    echo "# AMD ROCm APU Architecture Target Override" >> vanguard-env.sh
    echo "export HSA_OVERRIDE_GFX_VERSION=${ROCM_GFX_OVERRIDE}" >> vanguard-env.sh
    echo "export ROCM_PATH=/opt/rocm" >> vanguard-env.sh
fi

chmod +x vanguard-env.sh
echo -e "${C_BIO}[+] Wrote:${C_RESET} ${C_INK}${SCRIPT_DIR}/vanguard-env.sh${C_RESET}"

# ------------------------------------------------------------------------------
# 7. Systemd Service Drop-In Configuration (Optional for Systemd Hosts)
# ------------------------------------------------------------------------------
if command -v systemctl >/dev/null 2>&1 && [ -d /etc/systemd/system ]; then
    echo ""
    echo -e "${C_BIO}[*] Checking systemd Ollama service configuration...${C_RESET}"
    SYSTEMD_DIR="/etc/systemd/system/ollama.service.d"
    
    mkdir -p systemd 2>/dev/null || true
    cat << EOF > systemd/override.conf
[Service]
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_IGPU_ENABLE=1"
Environment="OLLAMA_KV_CACHE_TYPE=f16"
Environment="OLLAMA_KEEP_ALIVE=30m"
Environment="OLLAMA_NUM_PARALLEL=1"
Environment="OLLAMA_CONTEXT_LENGTH=8192"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_NO_CLOUD=1"
Environment="OLLAMA_NOPRUNE=1"
${ROCM_GFX_OVERRIDE:+Environment="HSA_OVERRIDE_GFX_VERSION=$ROCM_GFX_OVERRIDE"}
EOF

    echo -e "${C_DIM}    Created local systemd template in systemd/override.conf${C_RESET}"

    if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        if [ -f /etc/systemd/system/ollama.service ] || systemctl list-unit-files | grep -q "ollama.service"; then
            echo -e "${C_BIO}[*] Installing systemd drop-in override into ${SYSTEMD_DIR}/override.conf...${C_RESET}"
            $SUDO mkdir -p "$SYSTEMD_DIR"
            $SUDO cp systemd/override.conf "$SYSTEMD_DIR/override.conf"
            $SUDO systemctl daemon-reload
            $SUDO systemctl restart ollama.service 2>/dev/null || true
            echo -e "${C_BIO}[+] Systemd service updated and reloaded with Vanguard flags.${C_RESET}"
        fi
    fi
fi

# ------------------------------------------------------------------------------
# 8. Set Execution Permissions on Helper Scripts
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BIO}[*] Granting execution permissions to shell utilities...${C_RESET}"
chmod +x setup-linux.sh start-vanguard.sh register-models.sh 2>/dev/null || true

# ------------------------------------------------------------------------------
# 9. Register Existing Staged Models
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_BIO}[*] Triggering automated model registration scan for staged .gguf files...${C_RESET}"
if command -v python3 >/dev/null 2>&1; then
    python3 src/register_model.py || true
else
    echo -e "${C_WARN}[!] Python 3 not active; skipping initial model registration.${C_RESET}"
fi

# ------------------------------------------------------------------------------
# 10. Summary & Launch Instructions
# ------------------------------------------------------------------------------
echo ""
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo -e "${C_BIO}${C_BOLD} [+] OLLAMA VANGUARD LINUX ENVIRONMENT READY!${C_RESET}"
echo -e "${C_SIGNAL}-----------------------------------------------------------------------${C_RESET}"
echo -e "${C_INK}  * Launch Cockpit:   ${C_BRIGHT}./start-vanguard.sh${C_RESET}"
echo -e "${C_INK}  * Register Models:  ${C_BRIGHT}./register-models.sh${C_RESET}"
echo -e "${C_INK}  * Web Studio URI:   ${C_BRIGHT}src/vanguard.html${C_RESET}"
echo -e "${C_INK}  * Dual-Bus Bridge:  ${C_BRIGHT}http://127.0.0.1:11435${C_RESET}"
echo -e "${C_INK}  * Model Foundry:    ${C_BRIGHT}${SCRIPT_DIR}/models/${C_RESET}"
echo -e "${C_INK}  * Artifact Storage: ${C_BRIGHT}${SCRIPT_DIR}/artifacts/${C_RESET}"
echo -e "${C_SIGNAL}=======================================================================${C_RESET}"
echo ""
