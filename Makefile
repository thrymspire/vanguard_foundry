# ==============================================================================
# OLLAMA VANGUARD // UNIVERSAL COMMAND RUNNER
# ==============================================================================

.PHONY: help setup start run models register status clean

help:
	@echo "Ollama Vanguard — Universal Local AI Foundry"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup     - Provision Linux environment and hardware tuning"
	@echo "  make start     - Launch Ollama daemon, bridge, and studio dashboard"
	@echo "  make models    - Scan models/ folder and compile Modelfiles into Ollama"
	@echo "  make status    - Check daemon status and registered models"
	@echo "  make clean     - Clean transient bytecode and temporary files"
	@echo ""

setup:
	@bash setup-linux.sh

start:
	@bash start-vanguard.sh

run: start

models:
	@bash register-models.sh

register: models

status:
	@echo "--- Ollama Daemon Status ---"
	@ollama list 2>/dev/null || echo "Ollama daemon offline"
	@echo ""
	@echo "--- Vanguard Bridge Check ---"
	@python3 -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:11435/ping', timeout=2).read().decode())" 2>/dev/null || echo "Bridge offline (port 11435)"

clean:
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Bytecode cache cleaned."
