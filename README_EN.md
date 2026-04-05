# Telemt Installer

**Language:** [Русский](README.md) | English

An automated interactive setup script for **Telemt** — a blazing-fast, Rust-based MTProto proxy engine (Tokio). The installer seamlessly deploys a highly available proxy environment with advanced DPI evasion capabilities (Fake-TLS, TCP-Splicing) and provides an easy-to-use management utility utilizing the proxy's native REST API. Underlying engine structure: [telemt/telemt](https://github.com/telemt/telemt).

## Core Features

### ⚡ Smart Automation
- **Cross-Platform Binary Resolution:** The script automatically evaluates the host CPU architecture (`x86_64` / `aarch64`) and the system C library (`gnu` / `musl`), dynamically downloading the exact matching pre-compiled `.tar.gz` from GitHub releases. No slow server-side code compilation.
- **Interactive Setup:** Bilingual installer flow supporting both English and Russian.
- **System Security:** Generates a secure `systemd` daemon running under a restricted user profile with raised file-descriptor bounds (`LimitNOFILE=1048576`).

### 🔀 Operation Modes
The installer prompts you to select your preferred traffic routing topology:
1. **Direct Mode** — Establishes raw connections directly to Telegram Data Centers bypassing middle-ends. Yields maximum speed and DPI stability. *(Note: Unsuppported by sponsored ad channels).*
2. **Relay Mode** — Routes traffic through standard Telegram proxy Middle-Ends. The installer will natively prompt you to provide your **Ad Tag** to display a specified sponsored channel to connected clients.

### 📊 Management Interface (`telemt-ctl`)

The setup logic generates `telemt-ctl`, a reliable multi-purpose CLI tool. Rather than parsing raw log text, it natively queries the proxy's active internal REST API (Port `9091`) directly for live serialization.

| Command | Description |
|---------|-------------|
| `telemt-ctl status` | Views systemd service health and summarizes active proxy URLs. |
| `telemt-ctl links` | Fetches active URI schemes dynamically from the proxy's live memory. |
| `telemt-ctl reload` | Excecutes `config.toml` changes smoothly without terminating active user TCP connections. |
| `telemt-ctl restart`| Performs a hard systemctl service restart cycle. |
| `telemt-ctl stats` | Exposes performance metrics via internal Prometheus endpoints. |
| `telemt-ctl update` | Forces a manual binary check via GitHub APIs to pull newer updates. |

## Deployment

To deploy the proxies to your server instance (requires root privileges), execute:

```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/telemt-installer/refs/heads/main/telemt.sh)
```

## Maintenance

- **Auto-Updater Mechanism:** A background cron job securely queries GitHub APIs every 3 days to transparently apply downstream updates without manual intervention.
- **Uninstallation:** To securely wipe the proxy, related binaries, crons and configurations completely:
```bash
bash <(wget -q -O - https://raw.githubusercontent.com/EikeiDev/telemt-installer/refs/heads/main/telemt.sh) uninstall
```

## System Requirements
- **OS:** Any major Linux distribution (Ubuntu, Debian, CentOS, Rocky Linux, Alpine).
- **Architecture:** `x86_64` (Intel/AMD) or `aarch64` (Oracle Ampere / ARM).
- **Privileges:** root
- **Dependencies:** Safely prepared automatically by the baseline (`curl`, `xxd`, `jq`, `tar`).
