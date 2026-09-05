import os
import sys
import json
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler

# Paths
SRC_DIR = os.path.dirname(os.path.abspath(__file__))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)
BASE_DIR = os.path.dirname(SRC_DIR)
ARTIFACTS_DIR = os.path.join(BASE_DIR, "artifacts")
MODELS_DIR = os.path.join(BASE_DIR, "models")
GLOBAL_ALIEN_DIR = r"C:\Users\Thrym\Desktop\Alien Artifacts"

os.makedirs(ARTIFACTS_DIR, exist_ok=True)
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(GLOBAL_ALIEN_DIR, exist_ok=True)

PORT = 11435

class VanguardBridgeHandler(BaseHTTPRequestHandler):
    def _set_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, *")

    def do_OPTIONS(self):
        self.send_response(204)
        self._set_cors()
        self.end_headers()

    def do_GET(self):
        if self.path == "/ping":
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "online",
                "artifacts_dir": ARTIFACTS_DIR,
                "models_dir": MODELS_DIR,
                "global_artifacts_dir": GLOBAL_ALIEN_DIR
            }).encode("utf-8"))

        elif self.path == "/scan_models":
            # Dynamically run model registrar
            try:
                import register_model
                models = register_model.scan_and_register_models()
                self.send_response(200)
                self._set_cors()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "ok",
                    "registered_models": models
                }).encode("utf-8"))
            except Exception as e:
                self.send_response(500)
                self._set_cors()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "error": str(e)}).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/save":
            try:
                content_length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(content_length).decode("utf-8")
                data = json.loads(body)

                filename = data.get("filename", "artifact.html")
                filename = os.path.basename(filename)
                if not filename.endswith(".html"):
                    filename += ".html"

                content = data.get("content", "")

                # 1. Save to local project artifacts directory
                local_path = os.path.join(ARTIFACTS_DIR, filename)
                with open(local_path, "w", encoding="utf-8") as f:
                    f.write(content)

                # 2. Mirror to global Alien Artifacts folder if it exists
                global_path = os.path.join(GLOBAL_ALIEN_DIR, filename)
                try:
                    with open(global_path, "w", encoding="utf-8") as gf:
                        gf.write(content)
                except Exception as ge:
                    print(f"[WARN] Global mirror error: {ge}")

                self.send_response(200)
                self._set_cors()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({
                    "status": "ok",
                    "filename": filename,
                    "local_path": local_path,
                    "global_path": global_path
                }).encode("utf-8"))
                print(f"[VANGUARD BRIDGE] Saved artifact: {filename}")
            except Exception as e:
                self.send_response(500)
                self._set_cors()
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"status": "error", "error": str(e)}).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

def run():
    server = HTTPServer(("127.0.0.1", PORT), VanguardBridgeHandler)
    print(f"[VANGUARD BRIDGE] Running on http://127.0.0.1:{PORT}")
    print(f"[VANGUARD BRIDGE] Local Artifacts: {ARTIFACTS_DIR}")
    print(f"[VANGUARD BRIDGE] Global Mirror:   {GLOBAL_ALIEN_DIR}")
    server.serve_forever()

if __name__ == "__main__":
    run()
