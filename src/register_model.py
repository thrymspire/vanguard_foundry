import os
import re
import sys
import glob
import subprocess
import tempfile

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BASE_DIR, "models")

def sanitize_model_name(filepath):
    filename = os.path.basename(filepath)
    name = os.path.splitext(filename)[0].lower()
    parent_dir = os.path.basename(os.path.dirname(filepath)).lower()
    
    # Clean family-specific tags
    if "gemma" in name or "gemma" in parent_dir:
        m = re.search(r'(\d+b)', name)
        size = m.group(1) if m else "12b"
        return f"local-gemma-{size}:latest"
    elif "nemotron" in name or "nemotron" in parent_dir:
        m = re.search(r'(\d+b)', name)
        size = m.group(1) if m else "4b"
        return f"local-nemotron-{size}:latest"
    elif "phi" in name or "phi" in parent_dir:
        return "local-phi-3.5:latest"
    elif "qwen" in name or "qwen" in parent_dir:
        m = re.search(r'(\d+b)', name)
        size = m.group(1) if m else "27b"
        return f"local-qwen-{size}:latest"
    elif "llama" in name or "llama" in parent_dir:
        m = re.search(r'(\d+b)', name)
        size = m.group(1) if m else "3b"
        return f"local-llama-{size}:latest"

    # Remove common quantization clutter from tag name
    name = re.sub(r'[\.\-_]?(q4_k_m|q4_0|q4_1|q5_k_m|q8_0|iq4_xs|iq\w+|gguf|instruct|chat|it|qat|i1)', '', name)
    name = re.sub(r'[^a-z0-9_\-]+', '-', name).strip('-')
    if not name:
        name = "custom-model"
    return f"local-{name}:latest"

def get_registered_ollama_models():
    try:
        res = subprocess.run(["ollama", "list"], capture_output=True, text=True, encoding="utf-8", errors="replace", check=True)
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

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

try:
    import hardware_probe
    _TOTAL_RAM, _ = hardware_probe.get_system_memory_gb()
    _COMPUTE = hardware_probe.get_compute_topology()
    DEFAULT_THREADS = _COMPUTE["threads"]
    DEFAULT_CTX = 8192 if _TOTAL_RAM >= 14.0 else (4096 if _TOTAL_RAM >= 6.0 else 2048)
except Exception:
    DEFAULT_THREADS = os.cpu_count() or 4
    DEFAULT_CTX = 4096

def scan_and_register_models(context_window=None, threads=None):
    if threads is None:
        threads = DEFAULT_THREADS
    if context_window is None:
        context_window = DEFAULT_CTX

    os.makedirs(MODELS_DIR, exist_ok=True)
    # Recursive search across subdirectories (e.g. models/Gemma/, models/Qwen/, etc.)
    gguf_files = glob.glob(os.path.join(MODELS_DIR, "**", "*.gguf"), recursive=True)

    if not gguf_files:
        print(f"[INFO] No .gguf files found in: {MODELS_DIR}")
        print("[INFO] Checking if hardware-tailored model can be provisioned from library...")
        try:
            import hardware_probe
            hardware_probe.auto_provision(pull_if_empty=True)
        except Exception as e:
            print(f"[INFO] Drop any .gguf file into models/ or pull a model via Ollama: {e}")
        return []

    existing_models = get_registered_ollama_models()
    registered = []

    for filepath in gguf_files:
        filename = os.path.basename(filepath)
        tag = sanitize_model_name(filepath)

        if tag in existing_models:
            print(f"[SKIP] Model already registered in Ollama: {tag} ({filename})")
            registered.append(tag)
            continue

        print(f"[REGISTERING] Creating Ollama model: {tag} from {filename}...")

        # Build optimized Modelfile with Prompt Caching anchor (num_keep) and Ryzen Zen 4 AVX-512 parameters
        modelfile_content = f"""FROM "{filepath}"
PARAMETER num_ctx {context_window}
PARAMETER num_thread {threads}
PARAMETER temperature 0.2
PARAMETER top_p 0.9
PARAMETER top_k 40
PARAMETER repeat_penalty 1.1
PARAMETER num_keep 24
"""
        with tempfile.NamedTemporaryFile("w", delete=False, suffix=".modelfile", encoding="utf-8") as tf:
            tf.write(modelfile_content)
            temp_path = tf.name

        try:
            cmd = ["ollama", "create", tag, "-f", temp_path]
            res = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
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
    print("VANGUARD FOUNDRY // AUTOMATED MODEL REGISTRATION ENGINE")
    print("=" * 60)
    scan_and_register_models()
    print("\nScan complete. Open vanguard.html to use your registered models.")
