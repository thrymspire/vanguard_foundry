# Contributing to Vanguard Foundry

Thank you for your interest in contributing to **Vanguard Foundry**! This project is built to empower developers with high-performance, air-gapped local AI tools, automated context watermark tracking, and interactive artifact generation.

---

## 🛠️ Development Philosophy

1. **Zero External Dependencies**: Core interfaces must run directly in the browser via standard Web APIs without requiring Node.js build steps, Webpack, or npm bundles.
2. **Local-First & Air-Gapped**: Telemetry, model inference, and artifact generation must never send private prompt data or model weights to cloud servers.
3. **Decoupled Architecture**: Vanguard communicates over standard HTTP to Ollama (:11434) and the lightweight Python bridge (:11435).
4. **Design Integrity**: All UI elements must adhere to the **Alien Purple x Material 3** design tokens (`--void`, `--panel`, `--signal`, `--bio`, `--spore`, polygon cut corners).

---

## 🚀 Getting Started

1. **Fork & Clone**:
   ```bash
   git clone https://github.com/thrymspire/ollama_vanguard.git
   cd ollama_vanguard
   ```

2. **Launch Vanguard Foundry**:
   - **Linux**: `./start-vanguard.sh` (or `make start`)
   - **Windows**: `Start-Vanguard.bat`
   - Or launch manually:
   ```bash
   python3 src/bridge.py
   ```
   and open `src/vanguard.html` in your browser.

3. **Submitting Pull Requests**:
   - Create a feature branch: `git checkout -b feature/your-feature-name`.
   - Ensure clean formatting, comments, and docstrings.
   - Test that model registration (`register_model.py`) and artifact export (`buildStandaloneHtml`) operate without errors.
   - Open a Pull Request detailing your changes and test results.
