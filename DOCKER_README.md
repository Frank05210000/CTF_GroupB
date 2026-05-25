# Ubuntu Docker 安裝與設定指南

本指南詳細說明如何在 Ubuntu 系統上安裝與設定 Docker 和 Docker Compose，以便順利部署本專案的 CTF 題目環境。

---

## 快速安裝步驟

### 步驟 1：更新系統套件並安裝前置依賴
在安裝 Docker 之前，先更新現有的套件清單，並安裝一些允許 `apt` 透過 HTTPS 使用儲存庫的必要套件：

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
```

### 步驟 2：新增 Docker 官方的 GPG 金鑰
為確保下載套件的安全性與完整性，我們需要將 Docker 的 GPG 金鑰加入系統中：

```bash
# 建立存放金鑰的目錄
sudo install -m 0755 -d /etc/apt/keyrings

# 下載並轉換金鑰格式
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 設定金鑰權限為所有使用者可讀
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 步驟 3：設定 Docker 穩定版儲存庫（Repository）
將 Docker 儲存庫寫入系統的 APT 來源清單中：

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 步驟 4：安裝 Docker Engine、CLI 與 Docker Compose
更新套件索引，並安裝 Docker Engine、命令列工具（CLI）以及最新的 Docker Compose 插件：

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 步驟 5：驗證安裝是否成功
執行官方提供的測試映像檔（Hello World）來確認 Docker 服務是否正常運作：

```bash
sudo docker run hello-world
```
> [!NOTE]
> 如果看到 `Hello from Docker!` 等引導訊息，代表安裝成功！

---

## 進階設定（強烈建議）

### 免 `sudo` 執行 Docker 指令
預設情況下，只有 `root` 使用者或擁有 `sudo` 權限的使用者才能執行 Docker 指令。如果您希望目前的使用者可以直接執行 `docker` 而不需輸入 `sudo`，請進行以下設定：

1. **建立 `docker` 使用者群組**：
   ```bash
   sudo groupadd docker
   ```
   *(通常安裝完後系統已自動建立此群組)*

2. **將目前的使用者加入該群組**：
   ```bash
   sudo usermod -aG docker $USER
   ```

3. **使群組設定立即生效**（或登出系統再重新登入）：
   ```bash
   newgrp docker
   ```

4. **測試是否可以免 `sudo` 執行**：
   ```bash
   docker run hello-world
   ```

---

## 常用 Docker 指令快速參考

| 功能 | 指令 | 說明 |
|---|---|---|
| **啟動服務** | `sudo systemctl start docker` | 啟動 Docker 後台服務 |
| **開機自啟** | `sudo systemctl enable docker` | 設定 Docker 隨系統開機自動啟動 |
| **檢查狀態** | `sudo systemctl status docker` | 查看 Docker 服務目前的運作狀態 |
| **查看版本** | `docker version` 或 `docker compose version` | 查看已安裝的 Docker / Compose 版本 |
| **啟動專案** | `docker compose up -d` | 在背景啟動並運行目前的 `docker-compose.yml` 專案 |
| **停止專案** | `docker compose down` | 停止並移除執行中的專案容器與網路 |
| **查看日誌** | `docker compose logs -f` | 即時查看執行中容器的 Log 輸出 |
