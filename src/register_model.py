import os
import re
import sys
import glob
import subprocess
import tempfile

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BASE_DIR, "models")

def sanitize_model_name(filename):
    name = os.path.splitext(filename)[0].lower()
    # Remove common quantization clutter from tag name
    name = re.sub(r'[\.\-_]?(q4_k_m|q4_0|q4_1|q5_k_m|q8_0|gguf|instruct|chat)', '', name)
    name = re.sub(r'[^a-z0-9_\-]+', '-', name).strip('-')
    if not name:
        name = "custom-model"
    return f"local-{name}:latest"

def get_registered_ollama_models():
    try:
        res = subprocess.run(["ollama", "list"], capture_output=True, text=True, check=True)
        lines = res.stdout.strip().splitlines()
        models = set()
        for line in lines[1:]:
            parts = line.split()
            if parts:
                models.add(parts[0])
        return models
    except Exception as e:
        print(f"[WARN] Could not retrieve existing Ollama models: {e}")
        return set()

def scan_and_register_models(context_window=4096, threads=8):
    os.makedirs(MODELS_DIR, exist_ok=True)
    gguf_files = glob.glob(os.path.join(MODELS_DIR, "*.gguf"))

    if not gguf_files:
        print(f"[INFO] No .gguf files found in: {MODELS_DIR}")
        print("[INFO] Drop any .gguf file into the 'models' folder and run this script again.")
        return []

    existing_models = get_registered_ollama_models()
    registered = []

    for filepath in gguf_files:
        filename = os.path.basename(filepath)
        tag = sanitize_model_name(filename)

        if tag in existing_models:
            print(f"[SKIP] Model already registered in Ollama: {tag} ({filename})")
            registered.append(tag)
            continue

        print(f"[REGISTERING] Creating Ollama model: {tag} from {filename}...")

        # Build optimized Modelfile for Ryzen APU / Zen 4 hardware
        modelfile_content = f"""FROM "{filepath}"
PARAMETER num_ctx {context_window}
PARAMETER num_thread {threads}
PARAMETER temperature 0.2
"""
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".modelfile", encoding="utf-8") as tf:
            tf.write(modelfile_content)
            temp_path = tf.name

        try:
            cmd = ["ollama", "create", tag, "-f", temp_path]
            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode == 0:
                print(f"[SUCCESS] Registered: {tag}")
                registered.append(tag)
            else:
                print(f"[ERROR] Failed to register {tag}: {res.stderr}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    return registered

if __name__ == "__main__":
    print("=" * 60)
    print("OLLAMA VANGUARD // AUTOMATED MODEL REGISTRATION ENGINE")
    print("=" * 60)
    scan_and_register_models()
    print("\nScan complete. Open vanguard.html to use your registered models.")
