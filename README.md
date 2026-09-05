# Ollama Vanguard // Universal Architecture & Artifact Foundry

A high-performance, modular local AI foundry designed for instant model swapping, multi-turn dialogue, RAM caching, and automated compilation of conversations into glassmorphic **Alien Artifacts**.

---

## 📁 Architecture & File Layout

```text
Ollama-Vanguard/
├── Start-Vanguard.bat        # 1-Click launcher (starts bridge, verifies Ollama, opens UI)
├── Register-Models.bat       # 1-Click registrar (scans models/ and creates Ollama models)
├── README.md                 # This master reference & technical guide
├── models/                   # Drop-in folder for downloaded .gguf model files
│   └── README.md             # Quantization & download guide
├── artifacts/                # Local repository for all forged HTML artifacts
└── src/
    ├── bridge.py             # Local HTTP bridge server (Port 11435)
    ├── register_model.py     # Modelfile synthesizer & hardware optimizer
    └── vanguard.html         # Alien Purple x Material 3 reactive dashboard
```

---

## 🚀 Quick Start (Zero-Configuration)

1. **Launch Vanguard**:
   Double-click `Start-Vanguard.bat`.
   - Checks if Ollama is running (starts it if needed).
   - Launches the local background bridge (`src\bridge.py` on port `11435`).
   - Opens the Vanguard web console in your browser.

2. **Drop-In New Models**:
   - Download any `.gguf` file (e.g. Llama-3.2, Mistral, Qwen2.5, Gemma-2, DeepSeek-R1).
   - Place the `.gguf` file directly inside `Ollama-Vanguard\models\`.
   - Run `Register-Models.bat` **or** click the **"⚡ Scan Dropped GGUFs"** button directly in the Vanguard dashboard header.
   - The model is instantly registered and appears in the Vanguard dropdown!

3. **Multi-Turn Chat & Forge**:
   - Converse with your model in real-time with live token telemetry.
   - Monitor **Context Drift** live via the automatic **Watermark Token Tracker** meter.
   - Click **"⚡ Compile & Forge Artifact"** whenever you wish to transform the conversation into an interactive, self-contained HTML artifact with an integrated **Synthesis Confidence Meter**.
   - Click **"Save to Artifacts"** to persist it to `artifacts\` and mirror it to `Desktop\Alien Artifacts\`.

---

## 🧭 Automatic Watermark Token Tracker & Confidence Meter

### 1. Watermark Token Tracker (Chat Telemetry)
* **Canary Anchor Tracking**: Automatically extracts high-entropy semantic keywords and constraints from user prompts on each turn.
* **Real-time Drift Detection**: Monitors whether the model preserves core instructions and entities across multi-turn context.
* **Context Budget Monitoring**: Tracks token accumulation against your configured context limit (`tokens / num_ctx`), alerting you before attention degradation or context truncation occurs.
* **Status Tiers**:
  * `ANCHOR LOCKED (90-100%)`: Optimal alignment, zero drift.
  * `NOMINAL STABLE (75-89%)`: Solid context retention.
  * `ATTENTION DILUTION (50-74%)`: Context pressure mounting; slight attention dispersion.
  * `CRITICAL DRIFT (<50%)`: High drift offset; recommend clicking **"Re-Anchor"** to inject calibration directives.
* **Re-Anchor Directive**: 1-click button to inject top preserved anchor tokens back into active memory to eliminate drift.

### 2. Synthesis Confidence Meter (Artifact Presentation)
* **Embedded in Viewport & Exported HTML**: Stamped directly into the header of every forged artifact file.
* **Multi-Factor Scoring**: Evaluates session context fidelity, structural completeness (sections, check-pods, code blocks), and context saturation.
* **Transparency Breakdown**:
  * Watermark Anchor Retention %
  * Structural Density Rating
  * Context Saturation Ratio
  * Hallucination Risk Verification (`✓ Zero Hallucination Risk`)

---

## ⚡ Drop-In Model Wiring & Optimization

### Automatic Registration
When `register_model.py` runs (via `Register-Models.bat` or the UI button):
1. It scans `models\*.gguf`.
2. Cleans up file naming clutter (e.g. `llama-3.2-3b-instruct-q4_k_m.gguf` becomes `local-llama-3-2-3b:latest`).
3. Generates a custom hardware-tuned Modelfile targeting your **AMD Ryzen Z1 Extreme**:
   ```dockerfile
   FROM "C:\Users\Thrym\Desktop\Ollama-Vanguard\models\<filename>.gguf"
   PARAMETER num_ctx 4096
   PARAMETER num_thread 8
   PARAMETER temperature 0.2
   ```
4. Executes `ollama create <tag> -f <modelfile>`.

### Manual Custom Wiring (Optional)
If you want to customize system instructions, context sizes, or stop tokens for a specific model manually:

1. Open PowerShell or Command Prompt.
2. Create a file named `Modelfile` anywhere with custom directives:
   ```dockerfile
   FROM "C:\Users\Thrym\Desktop\Ollama-Vanguard\models\your_model.gguf"
   
   # Hardware & Context tuning
   PARAMETER num_ctx 8192
   PARAMETER num_thread 8
   PARAMETER temperature 0.1
   
   # Custom System Prompt
   SYSTEM """
   You are an elite systems architect and security specialist. Provide concise,
   actionable technical responses with clear markdown headers and checkable tasks.
   """
   ```
3. Register into Ollama:
   ```powershell
   ollama create my-custom-model -f Modelfile
   ```
4. Reload the Vanguard dashboard dropdown—it will immediately detect `my-custom-model`.

---

## 🛠️ Wiring Ollama to External Dev Tools & IDEs

Ollama exposes an OpenAI-compatible and native REST API at `http://localhost:11434`. You can connect any of your installed or dropped models to development tools:

### 1. Continue.dev (VS Code / PyCharm)
Add to your `~/.continue/config.json`:
```json
{
  "models": [
    {
      "title": "Vanguard Local Model",
      "provider": "ollama",
      "model": "phi3.5:3.8b",
      "apiBase": "http://localhost:11434"
    }
  ]
}
```

### 2. Python SDK / Scripts
```python
import urllib.request
import json

payload = {
    "model": "phi3.5:3.8b",  # or any registered local model
    "prompt": "Summarize system status",
    "stream": False
}

req = urllib.request.Request(
    "http://localhost:11434/api/generate",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type": "application/json"}
)

with urllib.request.urlopen(req) as response:
    result = json.loads(response.read().decode("utf-8"))
    print(result["response"])
```

### 3. Curl / PowerShell
```powershell
Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body '{"model": "phi3.5:3.8b", "prompt": "Hello", "stream": false}'
```

---

## 🎯 AMD Ryzen Z1 Extreme Performance Specs

| Model Size | Quantization | RAM Usage | Target Throughput |
| :--- | :--- | :--- | :--- |
| **3B - 4B** (Phi-3.5, Llama-3.2-3B) | `Q4_K_M` | ~2.5 GB | **35 – 45 tokens/sec** |
| **7B - 8B** (Llama-3.1-8B, Mistral-7B) | `Q4_K_M` | ~5.2 GB | **20 – 26 tokens/sec** |
| **14B** (Qwen2.5-14B) | `Q4_K_M` | ~9.5 GB | **11 – 15 tokens/sec** |

* **Hardware Recommendation**: Use `Q4_K_M` or `Q5_K_M` quantizations. Avoid unquantized FP16 models as memory bandwidth on APU unified memory will bottleneck execution.
* **Warm RAM Feature**: Toggle **"WARM RAM"** in the Vanguard header to preload weights into system memory (`keep_alive: -1`), eliminating Time-To-First-Token (TTFT) latency on subsequent queries.
