#!/bin/bash

# 終端機顏色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 無顏色

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}     Ubuntu Docker & Docker Compose 一鍵安裝腳本    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 檢查是否為 Ubuntu 系統
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo -e "${RED}[錯誤] 本腳本僅支援 Ubuntu 系統。目前系統為: $NAME${NC}"
        exit 1
    fi
else
    echo -e "${RED}[錯誤] 無法判別作業系統類型，本腳本僅支援 Ubuntu。${NC}"
    exit 1
fi

# 確保是以 sudo 權限執行腳本
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[提示] 此腳本需要管理員權限，將使用 sudo 執行安裝...${NC}"
    sudo_cmd="sudo"
else
    sudo_cmd=""
fi

echo -e "\n${YELLOW}[1/5] 更新系統套件並安裝前置依賴...${NC}"
$sudo_cmd apt-get update -y
$sudo_cmd apt-get install -y ca-certificates curl gnupg

echo -e "\n${YELLOW}[2/5] 新增 Docker 官方 GPG 金鑰...${NC}"
$sudo_cmd install -m 0755 -d /etc/apt/keyrings
$sudo_cmd curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$sudo_cmd chmod a+r /etc/apt/keyrings/docker.asc

echo -e "\n${YELLOW}[3/5] 設定 Docker 穩定版儲存庫 (Repository)...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  $sudo_cmd tee /etc/apt/sources.list.d/docker.list > /dev/null

echo -e "\n${YELLOW}[4/5] 安裝 Docker Engine 與 Docker Compose...${NC}"
$sudo_cmd apt-get update -y
$sudo_cmd apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\n${YELLOW}[5/5] 啟動 Docker 服務並設定開機自啟...${NC}"
$sudo_cmd systemctl start docker
$sudo_cmd systemctl enable docker

echo -e "\n${GREEN}[成功] Docker 與 Docker Compose 安裝完成！${NC}"
echo -e "目前安裝版本："
docker --version
docker compose version

# 詢問是否設定免 sudo 執行 docker 指令
echo -e "\n${BLUE}===============================================${NC}"
echo -e "${YELLOW}是否設定免 sudo 執行 docker 指令？(y/n)${NC}"
read -p "請選擇: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # 獲取實際的使用者帳號（避免直接抓到 sudo 下的 root）
    REAL_USER=${SUDO_USER:-$USER}
    echo -e "${YELLOW}正在將使用者 '$REAL_USER' 加入 docker 群組...${NC}"
    
    $sudo_cmd groupadd docker 2>/dev/null || true
    $sudo_cmd usermod -aG docker $REAL_USER
    
    echo -e "${GREEN}[完成] 已將 '$REAL_USER' 加入 docker 群組。${NC}"
    echo -e "${YELLOW}請注意：您必須登出系統再重新登入，或者在終端機輸入 'newgrp docker' 才能使免 sudo 生效。${NC}"
fi

echo -e "\n${GREEN}安裝完成！祝您使用愉快。${NC}"
