#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

HOST_IP="${1:-127.0.0.1}"
PORTAL_PORT="${PORTAL_PORT:-8000}"
EASY_PORT="${EASY_PORT:-8080}"
MEDIUM_PORT="${MEDIUM_PORT:-5000}"
HARD_PORT="${HARD_PORT:-2222}"
FAILED=0

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}              CTF GroupB 服務檢查              ${NC}"
echo -e "${BLUE}===============================================${NC}"

check_http() {
    local name="$1"
    local url="$2"

    if curl -fsS -o /dev/null "$url"; then
        echo -e "${GREEN}[OK]${NC} ${name}: ${url}"
    else
        echo -e "${RED}[FAIL]${NC} ${name}: ${url}"
        FAILED=1
    fi
}

check_tcp() {
    local name="$1"
    local host="$2"
    local port="$3"

    if nc -z "$host" "$port" >/dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC} ${name}: ${host}:${port}"
    else
        echo -e "${RED}[FAIL]${NC} ${name}: ${host}:${port}"
        FAILED=1
    fi
}

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}[錯誤] 找不到 curl。${NC}"
    exit 1
fi

if ! command -v nc >/dev/null 2>&1; then
    echo -e "${RED}[錯誤] 找不到 nc。${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/2] Docker Compose 狀態${NC}"
docker compose ps || FAILED=1

echo -e "\n${YELLOW}[2/2] 服務連線檢查${NC}"
check_http "Challenge portal" "http://${HOST_IP}:${PORTAL_PORT}/"
check_http "Easy metadata image" "http://${HOST_IP}:${EASY_PORT}/challenge.png"
check_http "Medium web app" "http://${HOST_IP}:${MEDIUM_PORT}"
check_tcp "Hard SSH service" "$HOST_IP" "$HARD_PORT"

if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}[完成] 三題服務檢查通過。${NC}"
else
    echo -e "\n${RED}[警告] 至少一項服務檢查失敗，請查看 docker compose logs。${NC}"
fi

exit "$FAILED"
