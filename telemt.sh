#!/bin/bash

# Telemt Installation Script
# Interactive installer for the Rust-based Telemt project (telemt/telemt)
# Replaces older MTProxy scripts with a modern implementation.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}Telemt Installer (Rust Edition)${NC}"
echo -e "${CYAN}1${NC} - English"
echo -e "${CYAN}2${NC} - Русский"
read -p "Select language / Выберите язык [1/2]: " LANG_CHOICE
[[ "$LANG_CHOICE" == "2" ]] && LANG_SEL="ru" || LANG_SEL="en"

mkdir -p /etc/telemt
echo "$LANG_SEL" > /etc/telemt/lang

set_messages() {
if [[ "$1" == "ru" ]]; then
    MSG_TITLE="Установка Telemt (Rust Proxy)"
    MSG_ROOT="Этот установщик должен быть запущен от root (используйте sudo)."
    MSG_UNINSTALL_TITLE="🗑️  Удаление Telemt"
    MSG_UNINSTALL_WARN="ВНИМАНИЕ: Это полностью удалит сервис и конфигурации Telemt!"
    MSG_UNINSTALL_CONFIRM="Вы уверены? (введите 'YES' для подтверждения): "
    MSG_UNINSTALL_CANCEL="Удаление отменено."
    MSG_DEPS="Установка зависимостей (curl, xxd, jq, tar)..."
    MSG_NO_APT="Установите curl, xxd, jq и tar вручную."
    MSG_DOWNLOADING="Загрузка бинарника Telemt (Rust)..."
    MSG_PORT_PROMPT="Введите порт прокси (по умолчанию"
    MSG_MODE_TITLE="⚡ Режим работы (Direct vs Relay):"
    MSG_MODE_DIRECT="Прямое подключение к ЦОДам Telegram. Не поддерживает спонсорский канал, но очень стабильно и спасает от банов."
    MSG_MODE_RELAY="Через старые прокси-посредники. Менее стабильно, но ПОДДЕРЖИВАЕТ спонсорский канал (Ad Tag)."
    MSG_MODE_PROMPT="Выберите режим (1 - Direct, 2 - Relay) [по умолчанию 1]: "
    MSG_TAG_PROMPT="Введите ваш Ad Tag от @MTProxybot (оставьте пустым для пропуска): "
    MSG_LOG_TITLE="📝 Настройка логирования (Log Level):"
    MSG_LOG_PROMPT="Выберите уровень (1 - Normal, 2 - Silent, 3 - Debug) [по умолчанию 1]: "
    MSG_DOMAIN_PROMPT="Введите публичный домен или IP для ссылок (пусто - авто IP): "
    MSG_PROXY_PROTO_PROMPT="Вы планируете прятать прокси за Nginx/HAProxy? (Включить PROXY Protocol) [y/N]: "
    MSG_USERNAME_PROMPT="Введите имя для первого пользователя (по умолчанию 'default_user'): "
    MSG_TLS_PROMPT="Введите TLS-домен для глубокой маскировки Fake-TLS (по умолчанию"
    MSG_SVC_CREATE="Создание systemd сервиса..."
    MSG_UTIL_CREATE="Создание утилиты управления telemt-ctl..."
    MSG_COMPLETE="🎉 Установка завершена!"
    MSG_QUICK="📋 Быстрые команды:"
else
    MSG_TITLE="Telemt Installation (Rust Proxy)"
    MSG_ROOT="This installer must be run as root (use sudo)."
    MSG_UNINSTALL_TITLE="🗑️  Telemt Uninstallation"
    MSG_UNINSTALL_WARN="WARNING: This will completely remove Telemt service and configs!"
    MSG_UNINSTALL_CONFIRM="Are you sure? (type 'YES' to confirm): "
    MSG_UNINSTALL_CANCEL="Uninstallation cancelled."
    MSG_DEPS="Installing dependencies (curl, xxd, jq, tar)..."
    MSG_NO_APT="Install curl, xxd, jq, and tar manually."
    MSG_DOWNLOADING="Downloading Telemt binary (Rust)..."
    MSG_PORT_PROMPT="Enter proxy port (default"
    MSG_MODE_TITLE="⚡ Operation Mode (Direct vs Relay):"
    MSG_MODE_DIRECT="Direct-to-DC. Best stability, no Middle-End proxies. DOES NOT support sponsored ad tag."
    MSG_MODE_RELAY="Middle-End Relay. Slower and easily blocked, but REQUIRES it for sponsored ad tag."
    MSG_MODE_PROMPT="Choose mode (1- Direct, 2 - Relay) [default: 1]: "
    MSG_TAG_PROMPT="Enter your Ad Tag from @MTProxybot (leave empty to skip): "
    MSG_LOG_TITLE="📝 Log Level Configuration:"
    MSG_LOG_PROMPT="Choose level (1 - Normal, 2 - Silent, 3 - Debug) [default: 1]: "
    MSG_DOMAIN_PROMPT="Enter public domain or IP for connection links (empty for auto IP): "
    MSG_PROXY_PROTO_PROMPT="Will you hide proxy behind Nginx/HAProxy? (Enable PROXY Protocol) [y/N]: "
    MSG_USERNAME_PROMPT="Enter username for the primary user (default 'default_user'): "
    MSG_TLS_PROMPT="Enter TLS Domain for deep Fake-TLS TCP Splicing (default"
    MSG_SVC_CREATE="Creating systemd service..."
    MSG_UTIL_CREATE="Creating management utility telemt-ctl..."
    MSG_COMPLETE="🎉 Installation Complete!"
    MSG_QUICK="📋 Quick Commands:"
fi
}
set_messages "$LANG_SEL"

echo -e "\n${BLUE}$MSG_TITLE${NC}\n"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}$MSG_ROOT${NC}"
    exit 1
fi

if [[ "$1" == "uninstall" ]]; then
    echo -e "${YELLOW}$MSG_UNINSTALL_TITLE${NC}\n"
    echo -e "${RED}$MSG_UNINSTALL_WARN${NC}"
    read -p "$MSG_UNINSTALL_CONFIRM" CONFIRM
    if [[ "$CONFIRM" != "YES" ]]; then
        echo -e "${GREEN}$MSG_UNINSTALL_CANCEL${NC}"
        exit 0
    fi
    systemctl stop telemt 2>/dev/null
    systemctl disable telemt 2>/dev/null
    rm -f /etc/systemd/system/telemt.service
    systemctl daemon-reload
    rm -rf /etc/telemt
    rm -f /usr/local/bin/telemt
    rm -f /usr/local/bin/telemt-ctl
    rm -f /usr/local/bin/telemt-updater
    rm -f /etc/cron.d/telemt-updater
    userdel telemt 2>/dev/null || true
    echo -e "\n${GREEN}Telemt Uninstalled!${NC}"
    exit 0
fi

# Ask questions
read -p "$MSG_PORT_PROMPT: 443): " USER_PORT
PORT=${USER_PORT:-443}

echo -e "\n${YELLOW}$MSG_MODE_TITLE${NC}"
echo -e "1. ${GREEN}Direct Mode${NC} - $MSG_MODE_DIRECT"
echo -e "2. ${YELLOW}Relay Mode${NC}  - $MSG_MODE_RELAY"
read -p "$MSG_MODE_PROMPT" USER_MODE

USE_DIRECT="true"
AD_TAG=""
if [[ "$USER_MODE" == "2" ]]; then
    USE_DIRECT="false"
    read -p "$MSG_TAG_PROMPT" USER_TAG
    AD_TAG=$(echo "$USER_TAG" | tr -d '[:space:]')
fi

TLS_DOMAINS=("petrovich.ru" "www.cloudflare.com" "www.apple.com" "www.microsoft.com")
RANDOM_DOMAIN=${TLS_DOMAINS[$RANDOM % ${#TLS_DOMAINS[@]}]}
read -p "$MSG_TLS_PROMPT: $RANDOM_DOMAIN): " USER_TLS
TLS_DOMAIN=${USER_TLS:-$RANDOM_DOMAIN}

echo -e "\n${YELLOW}$MSG_LOG_TITLE${NC}"
read -p "$MSG_LOG_PROMPT" USER_LOG_MODE
case "$USER_LOG_MODE" in
    2) LOG_LEVEL="silent" ;;
    3) LOG_LEVEL="debug" ;;
    *) LOG_LEVEL="normal" ;;
esac

echo -e "\n${YELLOW}🌐 Public Address (Domain/IP)${NC}"
read -p "$MSG_DOMAIN_PROMPT" USER_CUSTOM_DOMAIN
USER_CUSTOM_DOMAIN=$(echo "$USER_CUSTOM_DOMAIN" | tr -d '[:space:]')

echo -e "\n${YELLOW}🛡️  Web-Server Integration${NC}"
read -p "$MSG_PROXY_PROTO_PROMPT" USER_PROXY_PROTO
if [[ "$USER_PROXY_PROTO" =~ ^[Yy]$ ]]; then
    USE_PROXY_PROTO="true"
    LISTEN_IP="127.0.0.1"
else
    USE_PROXY_PROTO="false"
    LISTEN_IP="0.0.0.0"
fi

echo -e "\n${YELLOW}👤 User Settings${NC}"
read -p "$MSG_USERNAME_PROMPT" USER_NAME_INPUT
USER_NAME_INPUT=$(echo "$USER_NAME_INPUT" | tr -d '[:space:]')
PROXY_USERNAME=${USER_NAME_INPUT:-default_user}

echo -e "\n${YELLOW}$MSG_DEPS${NC}"
if command -v apt >/dev/null 2>&1; then
    apt update -qq
    apt install -y curl xxd jq tar gzip
fi

CONFIG_DIR="/etc/telemt"
BIN_FILE="/usr/local/bin/telemt"

mkdir -p "$CONFIG_DIR"
if [[ -n "$USER_CUSTOM_DOMAIN" ]]; then
    echo "$USER_CUSTOM_DOMAIN" > "$CONFIG_DIR/custom_domain"
else
    rm -f "$CONFIG_DIR/custom_domain"
fi
systemctl stop telemt 2>/dev/null

echo -e "\n${YELLOW}$MSG_DOWNLOADING${NC}"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64) ARCH_STR="x86_64" ;;
    aarch64|arm64) ARCH_STR="aarch64" ;;
    *) echo -e "${RED}Unsupported arch: $ARCH${NC}"; exit 1 ;;
esac

if ldd --version 2>&1 | grep -qi musl || grep -qE '^ID="?alpine"?' /etc/os-release; then
    LIBC_STR="musl"
else
    LIBC_STR="gnu"
fi

TAR_NAME="telemt-${ARCH_STR}-linux-${LIBC_STR}.tar.gz"
LATEST_URL=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/telemt/telemt/releases/latest/download/$TAR_NAME")

if ! curl -fsSL -o "/tmp/$TAR_NAME" "$LATEST_URL"; then
    echo -e "${RED}Download Failed: $LATEST_URL${NC}"
    exit 1
fi

tar -xf "/tmp/$TAR_NAME" -C /tmp/
mv "/tmp/telemt" "$BIN_FILE"
chmod +x "$BIN_FILE"
echo "$LATEST_URL" > "$CONFIG_DIR/installed_url"
rm -f "/tmp/$TAR_NAME"

USER_SECRET=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')

TELE_PROXY_MODE="false"
[[ "$USE_DIRECT" == "false" ]] && TELE_PROXY_MODE="true"

cat > "$CONFIG_DIR/telemt.toml" << EOL
[general]
log_level = "$LOG_LEVEL"
use_middle_proxy = $TELE_PROXY_MODE
EOL

if [[ -n "$AD_TAG" ]]; then
    echo "ad_tag = \"$AD_TAG\"" >> "$CONFIG_DIR/telemt.toml"
fi

cat >> "$CONFIG_DIR/telemt.toml" << EOL

[general.modes]
classic = false
secure = false
tls = true

[server]
port = $PORT
proxy_protocol = $USE_PROXY_PROTO
metrics_listen = "127.0.0.1:9090"

[server.api]
enabled = true
listen = "127.0.0.1:9091"
whitelist = ["127.0.0.1/32"]

[[server.listeners]]
ip = "$LISTEN_IP"

[censorship]
tls_domain = "$TLS_DOMAIN"
mask = true
tls_emulation = true

[access.users]
$PROXY_USERNAME = "$USER_SECRET"
EOL

if ! id "telemt" >/dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin telemt
fi
chown -R telemt:telemt "$CONFIG_DIR"
chmod 640 "$CONFIG_DIR/telemt.toml"

echo -e "${YELLOW}$MSG_SVC_CREATE${NC}"
cat > /etc/systemd/system/telemt.service << 'EOF'
[Unit]
Description=Telemt Proxy Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=telemt
Group=telemt
ExecStart=/usr/local/bin/telemt /etc/telemt/telemt.toml
ExecReload=/bin/kill -SIGHUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/etc/telemt

[Install]
WantedBy=multi-user.target
EOF

cat > /usr/local/bin/telemt-updater << 'UPDATER_EOF'
#!/bin/bash
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64) ARCH_STR="x86_64" ;;
    aarch64|arm64) ARCH_STR="aarch64" ;;
    *) exit 1 ;;
esac
ldd --version 2>&1 | grep -qi musl && LIBC_STR="musl" || LIBC_STR="gnu"
TAR_NAME="telemt-${ARCH_STR}-linux-${LIBC_STR}.tar.gz"

LATEST_URL=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/telemt/telemt/releases/latest/download/$TAR_NAME")
if [[ -z "$LATEST_URL" ]]; then exit 1; fi

CURRENT_URL=""
[[ -f "/etc/telemt/installed_url" ]] && CURRENT_URL=$(cat "/etc/telemt/installed_url")

if [[ "$LATEST_URL" != "$CURRENT_URL" ]]; then
    if curl -fsSL -o "/tmp/$TAR_NAME" "$LATEST_URL"; then
        tar -xf "/tmp/$TAR_NAME" -C /tmp/
        systemctl stop telemt
        mv "/tmp/telemt" "/usr/local/bin/telemt"
        chmod +x "/usr/local/bin/telemt"
        systemctl start telemt
        rm -f "/tmp/$TAR_NAME"
        echo "$LATEST_URL" > "/etc/telemt/installed_url"
    fi
fi
UPDATER_EOF
chmod +x /usr/local/bin/telemt-updater

cat > /etc/cron.d/telemt-updater << 'CRON_EOF'
30 4 */3 * * root /usr/local/bin/telemt-updater
CRON_EOF
chmod 644 /etc/cron.d/telemt-updater

echo -e "${YELLOW}$MSG_UTIL_CREATE${NC}"
cat > /usr/local/bin/telemt-ctl << 'CTLEOF'
#!/bin/bash
LANG_SEL="en"
[[ -f "/etc/telemt/lang" ]] && LANG_SEL=$(cat /etc/telemt/lang)

show_help() {
    echo -e "\033[0;34m=== Telemt Control Utility ===\033[0m"
    echo -e "  \033[0;32mstatus\033[0m  - Show service status and connection links"
    echo -e "  \033[0;32mstart\033[0m   - Start service"
    echo -e "  \033[0;32mstop\033[0m    - Stop service"
    echo -e "  \033[0;32mrestart\033[0m - Restart service"
    echo -e "  \033[0;32mreload\033[0m  - Reload config (telemt.toml) without downtime"
    echo -e "  \033[0;32muser-add\033[0m- Add a new user (telemt-ctl user-add <name>)"
    echo -e "  \033[0;32muser-del\033[0m- Delete a user (telemt-ctl user-del <name>)"
    echo -e "  \033[0;32musers\033[0m   - List all active users"
    echo -e "  \033[0;32mlinks\033[0m   - Fetch active links natively from API"
    echo -e "  \033[0;32mstats\033[0m   - Local prometheus metrics payload"
    echo -e "  \033[0;32mupdate\033[0m  - Trigger binary update manually"
    echo -e "  \033[0;32mlogs\033[0m    - Monitor logs via systemd"
}

case "${1:-status}" in
    "start")   systemctl start telemt; echo "Started" ;;
    "stop")    systemctl stop telemt; echo "Stopped" ;;
    "restart") systemctl restart telemt; echo "Restarted" ;;
    "reload")  systemctl reload telemt; echo "Reloaded" ;;
    "user-add")
        if [[ -z "$2" ]]; then echo "Usage: telemt-ctl user-add <username>"; exit 1; fi
        NEW_USER="$2"
        if grep -q "^$NEW_USER =" /etc/telemt/telemt.toml; then
            echo -e "\033[0;31mUser $NEW_USER already exists!\033[0m"; exit 1
        fi
        NEW_SECRET=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
        sed -i "/^\[access.users\]/a $NEW_USER = \"$NEW_SECRET\"" /etc/telemt/telemt.toml
        systemctl reload telemt
        echo -e "\033[0;32m✅ User $NEW_USER added!\033[0m"
        $0 links
        ;;
    "user-del")
        if [[ -z "$2" ]]; then echo "Usage: telemt-ctl user-del <username>"; exit 1; fi
        DEL_USER="$2"
        if ! grep -q "^$DEL_USER =" /etc/telemt/telemt.toml; then
            echo -e "\033[0;31mUser $DEL_USER not found!\033[0m"; exit 1
        fi
        sed -i "/^$DEL_USER ="/d /etc/telemt/telemt.toml
        systemctl reload telemt
        echo -e "\033[0;32m🗑️  User $DEL_USER deleted!\033[0m"
        $0 links
        ;;
    "users")
        echo -e "\033[0;34m=== Active Users ===\033[0m"
        curl -s http://127.0.0.1:9091/v1/users | jq -r '.data[] | "👤 \(.username)"' 2>/dev/null || echo "API not responding"
        ;;
    "update")  echo "Checking updates..."; /usr/local/bin/telemt-updater; echo "Done." ;;
    "logs")    journalctl -u telemt -f ;;
    "links")
        echo -e "\033[1;33m🔗 Connection Links via REST API:\033[0m"
        if [[ -f "/etc/telemt/custom_domain" ]]; then
            CONNECT_HOST=$(cat /etc/telemt/custom_domain)
        else
            CONNECT_HOST=$(curl -s --max-time 3 http://ifconfig.me 2>/dev/null || curl -s --max-time 3 http://ipinfo.io/ip 2>/dev/null || echo "YOUR_SERVER_IP")
        fi
        curl -s http://127.0.0.1:9091/v1/users | jq -r '.data[] | "User: \(.username)\n\(.links.tls[0] // "NO TLS LINK FOR THIS USER")\n"' 2>/dev/null | sed -E "s/server=[a-zA-Z0-9\.-]+/server=$CONNECT_HOST/g" || echo "API is not responding. Is telemt running?"
        ;;
    "stats")
        curl -s http://127.0.0.1:9090/metrics 2>/dev/null || echo "Metrics API not ready."
        ;;
    "status")
        systemctl is-active --quiet telemt && echo -e "\033[0;32m✅ Service: Running\033[0m" || echo -e "\033[0;31m❌ Service: Stopped\033[0m"
        echo ""
        $0 links
        ;;
    *)
        show_help
        ;;
esac
CTLEOF
chmod +x /usr/local/bin/telemt-ctl

systemctl daemon-reload
systemctl enable telemt
systemctl start telemt
sleep 2

echo -e "\n${YELLOW}$MSG_COMPLETE${NC}"
echo -e "${CYAN}$MSG_QUICK${NC}"
echo -e "${GREEN}telemt-ctl status${NC}"
echo -e "${GREEN}telemt-ctl links${NC}"
echo -e "${GREEN}telemt-ctl update${NC}"

/usr/local/bin/telemt-ctl status
