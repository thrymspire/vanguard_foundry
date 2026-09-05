#!/usr/bin/env bash
# ==============================================================================
# VANGUARD FOUNDRY // UNIVERSAL HARDWARE ARBITER & AUTO-PROVISIONER
# ==============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if command -v python3 >/dev/null 2>&1; then
    python3 src/hardware_probe.py --provision "$@"
else
    echo "[!] Error: Python 3 not found on PATH. Run ./setup-linux.sh first."
    exit 1
fi
