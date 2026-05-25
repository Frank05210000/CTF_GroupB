# CTF 三題部署教學

這份文件給部署者使用，說明如何用 Docker 一次啟動 Easy、Medium、Hard 三題。三題會分別跑在獨立 container / service，但由同一個 `docker-compose.yml` 管理。

安全提醒：Hard 題包含 SSH 弱密碼與 SUID vim，只能部署在隔離 lab Docker / VM 環境。不要部署到真實主機、共用主機或公開網路。

## 1. 前置需求

部署主機需要安裝：

- Docker
- Docker Compose v2，也就是可使用 `docker compose` 指令

確認 Docker 可用：

```bash
docker --version
docker compose version
```

如果看到 Docker daemon 連線錯誤，請先啟動 Docker Desktop 或 Linux 上的 Docker service。

## 2. 目錄結構

從專案根目錄進入 `CTF團體報告/`：

```bash
cd CTF團體報告
```

主要部署檔案：

```text
docker-compose.yml
easy_metadata_challenge/
medium_web_challenge/
hard_ssh_suid_challenge/
```

總 `docker-compose.yml` 會建立三個 service：

| Service | 題目 | 對外 port | 用途 |
|---|---|---:|---|
| `easy` | 我只是在看圖 | `8080` | 圖片 metadata 題 |
| `medium` | 你以為你登進去了 | `5000` | Flask Web / IDOR 題 |
| `hard` | 進來只是開始 | `2222` | SSH / SUID 提權題 |

## 3. 一次部署三題

在專案根目錄執行一鍵啟動腳本：

```bash
./start_ctf.sh
```

如果部署在 Linux lab 主機，也可以把主機 IP 傳給腳本，輸出的 Red Team 目標會直接顯示該 IP：

```bash
./start_ctf.sh <Linux主機IP>
```

檢查三題服務是否在線：

```bash
./check_ctf.sh
```

停止三題服務：

```bash
./stop_ctf.sh
```

也可以直接使用 Docker Compose：

```bash
docker compose up --build
```

這會 build 並啟動三個 container。

如果要放到背景執行：

```bash
docker compose up --build -d
```

部署完成後，本機測試目標如下：

| 難度 | Red Team 目標 |
|---|---|
| Easy | `http://127.0.0.1:8080/challenge.png` |
| Medium | `http://127.0.0.1:5000` |
| Hard | `127.0.0.1:2222` |

如果部署在 Linux lab 主機，請把 `127.0.0.1` 換成該主機 IP。

## 4. 停止與重建

停止三題：

```bash
docker compose down
```

重新 build 並啟動：

```bash
docker compose up --build
```

只重新 build，不啟動：

```bash
docker compose build
```

查看目前 container 狀態：

```bash
docker compose ps
```

## 5. Logs 與單題管理

查看全部 log：

```bash
docker compose logs
```

持續追蹤全部 log：

```bash
docker compose logs -f
```

只看某一題：

```bash
docker compose logs easy
docker compose logs medium
docker compose logs hard
```

只啟動某一題：

```bash
docker compose up --build easy
docker compose up --build medium
docker compose up --build hard
```

只停止某一題：

```bash
docker compose stop easy
docker compose stop medium
docker compose stop hard
```

只重啟某一題：

```bash
docker compose restart easy
docker compose restart medium
docker compose restart hard
```

## 6. 部署後驗證

### Easy

確認圖片服務可連線：

```bash
curl -I http://127.0.0.1:8080/challenge.png
```

預期看到 HTTP `200`。

### Medium

確認 Web app 可連線：

```bash
curl -I http://127.0.0.1:5000
```

也可以用瀏覽器開啟：

```text
http://127.0.0.1:5000
```

### Hard

確認 SSH port 開放：

```bash
nmap -sV -p 2222 127.0.0.1
```

預期看到 `2222/tcp open ssh`。

## 7. 常見問題

### Docker daemon 沒有啟動

可能錯誤：

```text
Cannot connect to the Docker daemon
```

處理方式：

- macOS / Windows：啟動 Docker Desktop。
- Linux：啟動 Docker service。

### Port 被占用

如果 `8080`、`5000` 或 `2222` 已被其他程式使用，Docker 會顯示 port already allocated。

可在 `docker-compose.yml` 修改左側 host port，例如：

```yaml
ports:
  - "2223:22"
```

修改後 Red Team 目標也要改成新 port。

### Hard 題 SSH host key 警告

重建容器後，SSH 可能顯示 host key changed。

處理方式：

```bash
ssh-keygen -R '[127.0.0.1]:2222'
```

如果你把 Hard 題 port 改成 `2223`，指令也要改成：

```bash
ssh-keygen -R '[127.0.0.1]:2223'
```

### Hard 題不要使用 privileged mode

Hard 題只需要在 container 內取得 root，不需要宿主機權限。不要加上 `--privileged`，也不要把 SSH port 暴露到公開網路。
