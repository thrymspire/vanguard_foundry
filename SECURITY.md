# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Security Architecture

**Vanguard Foundry** is designed from the ground up for air-gapped local computing:
* **Local In-Memory Inference**: Model weights are loaded locally into host RAM via Ollama daemon (`http://localhost:11434`).
* **No Cloud Transmissions**: Prompts, watermarks, chat dialogues, and generated HTML artifacts stay entirely on your local machine.
* **Isolated HTTP Bridge**: The Vanguard Bridge binds exclusively to IPv4 loopback (`127.0.0.1:11435`) and does not listen on external network interfaces.

## Reporting a Vulnerability

If you discover a security vulnerability within Vanguard Foundry, please submit an issue or contact `thrymspire@hotmail.com`. Reports will be acknowledged within 48 hours with coordinated remediation.
