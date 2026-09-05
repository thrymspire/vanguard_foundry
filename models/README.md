# Models Drop-In Directory

Place any quantized `.gguf` model file directly into this folder.

### How It Works
1. Download any `.gguf` file from Hugging Face (e.g. from quantizers like **bartowski**, **unsloth**, or **TheBloke**).
2. Save the `.gguf` file in this directory (`Ollama-Vanguard\models\`).
3. Run `Register-Models.bat` (or click **"Scan & Register Models"** inside the Vanguard dashboard).
4. The system automatically creates the optimal Ollama Modelfile and registers the model into your local library.
5. The new model will instantly appear in the Vanguard dashboard dropdown!

### Recommended Quantizations for AMD Ryzen Z1 Extreme (24 GB RAM)
* **`Q4_K_M`** or **`Q4_0`**: The golden ratio for speed and intelligence (~35–45 tokens/sec for 3B, ~20 tokens/sec for 7B/8B).
* **`Q5_K_M`**: Slightly higher precision, slightly larger memory footprint.
* Avoid 16-bit unquantized (`FP16`/`BF16`) or raw `.safetensors` files. Always use `.gguf`.
