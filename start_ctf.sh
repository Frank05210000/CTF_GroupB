#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}              CTF GroupB 一鍵啟動              ${NC}"
echo -e "${BLUE}===============================================${NC}"

if ! command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}[錯誤] 找不到 docker。請先執行 ./install_docker.sh 或安裝 Docker。${NC}"
    exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
    echo -e "${YELLOW}[錯誤] 找不到 Docker Compose v2。請確認可使用 docker compose。${NC}"
    exit 1
fi

HOST_IP="${1:-127.0.0.1}"

echo -e "${YELLOW}[1/2] 建置並在背景啟動三題...${NC}"
docker compose up --build -d

echo -e "\n${YELLOW}[2/2] 目前容器狀態...${NC}"
docker compose ps

echo -e "\n${GREEN}[完成] CTF 服務已啟動。${NC}"
echo -e "Red Team 目標："
echo -e "  Easy   : http://${HOST_IP}:8080/challenge.png"
echo -e "  Medium : http://${HOST_IP}:5000"
echo -e "  Hard   : ${HOST_IP}:2222"
echo -e "\n可執行 ./check_ctf.sh ${HOST_IP} 檢查服務狀態。"
