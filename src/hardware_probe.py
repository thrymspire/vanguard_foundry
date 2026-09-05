#!/usr/bin/env python3
"""
VANGUARD FOUNDRY // UNIVERSAL HARDWARE RESOURCE ARBITER
Diagnoses host compute topology (RAM, CPU, GPU, AVF / Debian VM, ARM64 / x86_64),
dynamically calculates optimal inference tiers, and auto-provisions baseline models.
Zero external pip dependencies (Pure Python 3 Standard Library).
"""

import os
import sys
import platform
import subprocess
import re
import json

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BASE_DIR, "models")


def get_system_memory_gb():
    """Detect total and available physical RAM across Linux, Android VM, Windows, and macOS."""
    total_gb = 8.0
    avail_gb = 6.0

    system = platform.system().lower()
    if system == "linux":
        # Standard Linux & Android Debian AVF VM
        if os.path.exists("/proc/meminfo"):
            try:
                mem = {}
                with open("/proc/meminfo", "r", encoding="utf-8") as f:
                    for line in f:
                        parts = line.split(":")
                        if len(parts) == 2:
                            mem[parts[0].strip()] = parts[1].strip()
                if "MemTotal" in mem:
                    kb = int(re.sub(r"[^\d]", "", mem["MemTotal"]))
                    total_gb = round(kb / (1024 * 1024), 2)
                if "MemAvailable" in mem:
                    kb = int(re.sub(r"[^\d]", "", mem["MemAvailable"]))
                    avail_gb = round(kb / (1024 * 1024), 2)
                else:
                    avail_gb = round(total_gb * 0.75, 2)
                return total_gb, avail_gb
            except Exception:
                pass

    elif system == "windows":
        try:
            import ctypes
            class MEMORYSTATUSEX(ctypes.Structure):
                _fields_ = [
                    ("dwLength", ctypes.c_uint),
                    ("dwMemoryLoad", ctypes.c_uint),
                    ("ullTotalPhys", ctypes.c_ulonglong),
                    ("ullAvailPhys", ctypes.c_ulonglong),
                    ("ullTotalPageFile", ctypes.c_ulonglong),
                    ("ullAvailPageFile", ctypes.c_ulonglong),
                    ("ullTotalVirtual", ctypes.c_ulonglong),
                    ("ullAvailVirtual", ctypes.c_ulonglong),
                    ("sullAvailExtendedVirtual", ctypes.c_ulonglong),
                ]
            stat = MEMORYSTATUSEX()
            stat.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
            if ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat)):
                total_gb = round(stat.ullTotalPhys / (1024 ** 3), 2)
                avail_gb = round(stat.ullAvailPhys / (1024 ** 3), 2)
                return total_gb, avail_gb
        except Exception:
            pass

    elif system == "darwin":
        try:
            out = subprocess.check_output(["sysctl", "-n", "hw.memsize"]).decode().strip()
            total_gb = round(int(out) / (1024 ** 3), 2)
            avail_gb = round(total_gb * 0.7, 2)
            return total_gb, avail_gb
        except Exception:
            pass

    return total_gb, avail_gb


def detect_environment():
    """Detect if running inside Android Virtualization Framework (AVF) Debian VM, WSL, or bare metal."""
    env_info = {
        "is_android_vm": False,
        "is_wsl": False,
        "is_container": False,
        "platform_desc": f"{platform.system()} {platform.release()}"
    }

    if os.path.exists("/proc/version"):
        try:
            with open("/proc/version", "r", encoding="utf-8") as f:
                v = f.read().lower()
                if "microsoft" in v or "wsl" in v:
                    env_info["is_wsl"] = True
                if "android" in v or "crosvm" in v or "microdroid" in v or "avf" in v:
                    env_info["is_android_vm"] = True
        except Exception:
            pass

    # Check for Android environment signs in Debian VM
    if os.path.exists("/dev/vsock") or os.path.exists("/dev/kvm"):
        if platform.machine().lower() in ("aarch64", "arm64"):
            # Characteristic of Pixel / Tensor AVF VM
            env_info["is_android_vm"] = True

    if os.path.exists("/.dockerenv"):
        env_info["is_container"] = True

    return env_info


def get_compute_topology():
    """Detect CPU architecture, core counts, SIMD extensions, and GPU availability."""
    arch = platform.machine().lower()
    threads = os.cpu_count() or 4

    features = []
    gpu_desc = "None (CPU Inference)"
    has_gpu = False

    # Check Linux CPU info
    if os.path.exists("/proc/cpuinfo"):
        try:
            with open("/proc/cpuinfo", "r", encoding="utf-8") as f:
                content = f.read().lower()
                # x86 vector extensions
                if "avx512" in content:
                    features.append("AVX-512")
                elif "avx2" in content:
                    features.append("AVX2")
                # ARM extensions
                if "asimd" in content or "neon" in content:
                    features.append("ARM-NEON")
                if "dotprod" in content:
                    features.append("DotProd")
                if "i8mm" in content:
                    features.append("I8MM")
                if "sve" in content:
                    features.append("SVE")
        except Exception:
            pass

    # Check NVIDIA GPU
    try:
        res = subprocess.run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], capture_output=True, text=True, timeout=2)
        if res.returncode == 0 and res.stdout.strip():
            gpu_desc = f"NVIDIA {res.stdout.strip().splitlines()[0]}"
            has_gpu = True
    except Exception:
        pass

    # Check AMD GPU / APU via lspci
    if not has_gpu:
        try:
            res = subprocess.run(["lspci"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                for line in res.stdout.splitlines():
                    if any(k in line.lower() for k in ["vga", "3d", "display"]) and "amd" in line.lower():
                        gpu_desc = "AMD Radeon / APU"
                        has_gpu = True
                        break
        except Exception:
            pass

    return {
        "arch": arch,
        "threads": threads,
        "features": features,
        "gpu_desc": gpu_desc,
        "has_gpu": has_gpu
    }


def evaluate_tier(total_ram_gb, arch, has_gpu, is_android_vm):
    """
    Selects the optimal model tier and context configuration:
    - Tier 1 (< 8 GB RAM / Pixel Debian VM / Mobile ARM): 3B class, num_ctx 2048-4096
    - Tier 2 (8 GB - 18 GB RAM / Handheld / APU): 7B-8B class, num_ctx 4096-8192
    - Tier 3 (18 GB - 36 GB RAM / Workstation): 14B class, num_ctx 8192
    - Tier 4 (> 36 GB RAM / Enterprise): 27B-32B class, num_ctx 16384
    """
    if is_android_vm or arch in ("aarch64", "arm64") or total_ram_gb < 8.0:
        return {
            "tier_name": "Tier 1 // Mobile VM & Edge Architecture",
            "recommended_model": "llama3.2:3b",
            "fallback_model": "phi3.5:3.8b",
            "context_window": 4096 if total_ram_gb >= 6.0 else 2048,
            "est_vram_gb": 2.2,
            "throughput_expectation": "35-50 tok/s on ARM NEON / Tensor G5"
        }
    elif total_ram_gb <= 18.0:
        return {
            "tier_name": "Tier 2 // Compact & Handheld Architecture",
            "recommended_model": "qwen2.5:7b",
            "fallback_model": "llama3.1:8b",
            "context_window": 8192 if total_ram_gb >= 14.0 else 4096,
            "est_vram_gb": 5.4,
            "throughput_expectation": "20-30 tok/s on Zen4 AVX-512 / RDNA3"
        }
    elif total_ram_gb <= 36.0:
        return {
            "tier_name": "Tier 3 // High-Throughput Workstation",
            "recommended_model": "qwen2.5:14b",
            "fallback_model": "gemma2:9b",
            "context_window": 8192,
            "est_vram_gb": 9.8,
            "throughput_expectation": "12-18 tok/s"
        }
    else:
        return {
            "tier_name": "Tier 4 // Deep Compute Foundry",
            "recommended_model": "qwen2.5:32b",
            "fallback_model": "qwen2.5:14b",
            "context_window": 16384,
            "est_vram_gb": 19.5,
            "throughput_expectation": "8-14 tok/s"
        }


def check_existing_models():
    """Check both Ollama registered models and staged .gguf files."""
    registered = []
    try:
        res = subprocess.run(["ollama", "list"], capture_output=True, text=True, timeout=5)
        if res.returncode == 0:
            lines = res.stdout.strip().splitlines()
            for line in lines[1:]:
                parts = line.split()
                if parts:
                    registered.append(parts[0])
    except Exception:
        pass

    staged_ggufs = []
    if os.path.exists(MODELS_DIR):
        for root, _, files in os.walk(MODELS_DIR):
            for f in files:
                if f.lower().endswith(".gguf"):
                    staged_ggufs.append(os.path.join(root, f))

    return registered, staged_ggufs


def auto_provision(pull_if_empty=True):
    """Diagnose host and pull/tune optimal model if environment is empty."""
    total_ram, avail_ram = get_system_memory_gb()
    env = detect_environment()
    compute = get_compute_topology()
    plan = evaluate_tier(total_ram, compute["arch"], compute["has_gpu"], env["is_android_vm"])

    print("=" * 70)
    print("      VANGUARD FOUNDRY // UNIVERSAL HARDWARE ARBITER")
    print("=" * 70)
    print(f"  * Architecture:      {compute['arch']} ({compute['threads']} CPU threads)")
    print(f"  * SIMD Features:     {', '.join(compute['features']) if compute['features'] else 'Standard'}")
    print(f"  * System Memory:     {total_ram} GB Total ({avail_ram} GB Available)")
    print(f"  * Graphics Compute:  {compute['gpu_desc']}")
    if env["is_android_vm"]:
        print("  * Environment:       Debian VM on Android AVF (Pixel 10 Pro XL / Tensor G5)")
    elif env["is_wsl"]:
        print("  * Environment:       WSL2 Virtualization")
    else:
        print(f"  * Environment:       {env['platform_desc']}")
    print("-" * 70)
    print(f"  * Matched Tier:      {plan['tier_name']}")
    print(f"  * Target Model:      {plan['recommended_model']} (Fallback: {plan['fallback_model']})")
    print(f"  * Optimal Context:   {plan['context_window']} tokens")
    print(f"  * Estimated Perf:    {plan['throughput_expectation']}")
    print("=" * 70)

    registered, staged = check_existing_models()

    if registered or staged:
        print(f"\n[+] Models already detected:")
        if registered:
            print(f"    - Ollama Library: {', '.join(registered[:5])}{'...' if len(registered) > 5 else ''}")
        if staged:
            print(f"    - Staged GGUFs:   {len(staged)} file(s) found in models/")
        print("[+] Hardware profile verified. System is ready to launch.")
        return True

    if not pull_if_empty:
        print("\n[*] Zero models found. Run with --provision to automatically pull the target model.")
        return False

    target_model = plan["recommended_model"]
    print(f"\n[!] Zero models detected on this system (Cold Drop).")
    print(f"[*] Auto-pulling optimal hardware-tailored model: '{target_model}'...")

    try:
        cmd = ["ollama", "pull", target_model]
        res = subprocess.run(cmd)
        if res.returncode == 0:
            print(f"\n[+] Successfully pulled '{target_model}'.")
            print(f"[+] Vanguard Foundry is fully provisioned and ready for inference!")
            return True
        else:
            print(f"\n[!] Failed to pull '{target_model}'. Attempting fallback '{plan['fallback_model']}'...")
            res_fb = subprocess.run(["ollama", "pull", plan["fallback_model"]])
            return res_fb.returncode == 0
    except Exception as e:
        print(f"[!] Auto-pull execution failed: {e}")
        return False


if __name__ == "__main__":
    do_provision = "--provision" in sys.argv
    as_json = "--json" in sys.argv

    if as_json:
        t_ram, a_ram = get_system_memory_gb()
        e = detect_environment()
        c = get_compute_topology()
        p = evaluate_tier(t_ram, c["arch"], c["has_gpu"], e["is_android_vm"])
        regs, stgs = check_existing_models()
        data = {
            "ram_total_gb": t_ram,
            "ram_available_gb": a_ram,
            "arch": c["arch"],
            "threads": c["threads"],
            "features": c["features"],
            "gpu": c["gpu_desc"],
            "is_android_vm": e["is_android_vm"],
            "matched_tier": p["tier_name"],
            "recommended_model": p["recommended_model"],
            "context_window": p["context_window"],
            "has_models": bool(regs or stgs)
        }
        print(json.dumps(data, indent=2))
    else:
        auto_provision(pull_if_empty=do_provision)
