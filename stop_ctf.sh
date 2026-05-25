#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}              CTF GroupB 一鍵停止              ${NC}"
echo -e "${BLUE}===============================================${NC}"

echo -e "${YELLOW}正在停止三題容器...${NC}"
docker compose down

echo -e "\n${GREEN}[完成] CTF 服務已停止。${NC}"
