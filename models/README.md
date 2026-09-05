# Models Drop-In Directory

Place any quantized `.gguf` model file directly into this folder or organized inside model family subfolders.

### Organized Model Structure
```text
models/
├── Gemma/       # Gemma models (e.g. gemma-4-12b-it-qat-q4_0.gguf)
├── Llama/       # Llama models (e.g. Llama-3.2-3B.gguf)
├── Nemotron/    # NVIDIA Nemotron models (e.g. NVIDIA-Nemotron3-Nano-4B-Q4_K_M.gguf)
├── Phi/         # Microsoft Phi models (e.g. phi-3.5-mini-instruct-3.8b.gguf)
├── Qwen/        # Qwen models (e.g. Qwen3.8-27B-i1-IQ4_XS-GGUF-Smaller.gguf)
└── *.gguf       # Root drop-in support (auto-discovered recursively)
```

### How It Works
1. Download any `.gguf` file from Hugging Face (e.g. from quantizers like **bartowski**, **unsloth**, or **TheBloke**).
2. Save the `.gguf` file into its model family subfolder or directly in `models\`.
3. Run `Register-Models.bat` (or click **"Scan & Register Dropped Models"** inside the Vanguard dashboard).
4. The system automatically creates the optimal Ollama Modelfile with Prompt Caching (`num_keep`), tuned context windows, and AVX-512 parameters.
5. The new model will instantly appear in the Vanguard dashboard dropdown!

### Recommended Quantizations for AMD Ryzen Z1 Extreme (24 GB RAM)
* **`Q4_K_M`** or **`Q4_0`**: The golden ratio for speed and intelligence (~35–45 tokens/sec for 3B/4B, ~20 tokens/sec for 7B/12B).
* **`IQ4_XS`** / **`Q4_K_S`**: High compression for larger models (e.g. 27B) to fit within UMA VRAM limits.
* **`Q5_K_M`**: Slightly higher precision for smaller parameter sizes.
