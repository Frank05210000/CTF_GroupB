# Hard CTF Challenge: 進來只是開始

這是一個 Hard / 300 pts 的 Network + Linux privilege escalation CTF 題目。Red Team 需要先透過 SSH 弱密碼取得低權限 shell，再利用錯誤設定的 SUID vim 提權讀取 root flag。

安全提醒：此題只能部署在隔離 Docker / VM lab 環境。弱密碼與 SUID vim 都是故意設計的危險設定，不應出現在真實主機。

## 題目資訊

- 題目名稱：進來只是開始
- 難度：Hard / 300 pts
- 題型：Network vulnerability + Privilege Escalation
- 主漏洞：Weak SSH credentials
- 提權漏洞：SUID vim
- Flag：`FLAG{suid_vim_rooted}`
- Docker port mapping：`2222:22`
- Red Team 起始資訊：只知道目標 IP 與 SSH port

## Docker 部署方式

完整部署教學請看 `DEPLOY.md`。此處保留最短啟動流程。

進入題目資料夾：

```bash
cd CTF團體報告/hard_ssh_suid_challenge
```

建議使用 Docker Compose：

```bash
docker compose up --build
```

停止服務：

```bash
docker compose down
```

也可以使用純 Docker：

建立 image：

```bash
docker build -t hard-ssh-suid .
```

啟動容器：

```bash
docker run --rm --name hard-ssh-suid -p 2222:22 hard-ssh-suid
```

不要使用 `--privileged`。此題只需要在容器內取得 root，不需要任何宿主機特權。

Red Team 目標：

```text
127.0.0.1:2222
```

如果部署在 Linux lab 主機，請把 `127.0.0.1` 換成該主機 IP。

## Blue Team 設計說明

這題故意留下兩個弱點：

1. SSH 弱密碼：低權限帳號為 `user / password123`，可被常見字典猜中。
2. SUID vim：`/usr/bin/vim` 被設定為 root SUID，低權限使用者可以透過 vim 的 Python3 command 執行 root shell。

容器設定：

- 只開放 SSH。
- 禁止 root 直接 SSH 登入。
- `/root/flag.txt` 權限為 `600`，只有 root 可讀。
- `/home/user/hint.txt` 提示尋找異常權限。
- `sshd` 使用前景模式 `sshd -D -e`，登入失敗與成功紀錄可由 `docker logs` 取得。

## Detection & Logging

Blue Team 可用以下方式取得 SSH server log：

```bash
docker ps
docker logs <container-id>
```

可截圖的證據：

- Hydra 造成的多次 SSH 登入失敗。
- `user` 成功登入 SSH。
- `ls -l /usr/bin/vim` 顯示 SUID bit，例如 `-rwsr-xr-x`。
- `ls -l /root/flag.txt` 顯示只有 root 可讀。

## 防禦與修補方式

真實環境中應移除這些錯誤設定：

```bash
chmod u-s /usr/bin/vim
passwd user
```

SSH 加固建議：

```text
PasswordAuthentication no
PermitRootLogin no
AllowUsers deploy
```

長期防禦：

- 使用 SSH key，不使用密碼登入。
- 啟用 fail2ban 或等效機制限制暴力嘗試。
- 定期清查 SUID / SGID 程式：

```bash
find / -perm -4000 -type f -ls
```

- 監控短時間大量 SSH login failure。
- 監控低權限使用者產生 root shell 的事件。

## 建議截圖

Red Team：

- `nmap -sV -p 2222 127.0.0.1` 顯示 SSH 開放。
- `hydra -s 2222 -l user -P <wordlist> ssh://127.0.0.1` 找到 `password123`。
- SSH 登入成功。
- `find / -perm -4000 -type f 2>/dev/null` 顯示 `/usr/bin/vim`。
- Vim payload 後 `whoami` 顯示 `root`。
- `cat /root/flag.txt` 顯示 flag。

Blue Team：

- `docker logs <container-id>` 中的登入失敗與成功紀錄。
- `ls -l /usr/bin/vim` 的 SUID 權限。
- `chmod u-s /usr/bin/vim` 修補前後對照。
