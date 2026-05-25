# Medium CTF Challenge: 你以為你登進去了

這是一個可放在 Linux 主機上的 Medium / 200 pts Web CTF 題目。正式交付方式以 Docker 為主，Python venv 作為備用。題目主線是 IDOR / Broken Access Control，SQL Injection 保留為備用解法。

## 題目資訊

- 題目名稱：你以為你登進去了
- 難度：Medium / 200 pts
- 題型：Web vulnerability
- 主漏洞：IDOR / Broken Access Control
- 備用漏洞：SQL Injection in login
- Flag：`FLAG{IDOR_profile_leak}`
- Port：`5000`
- Red Team 起始帳號：`employee / pass1234`

## 給 Red Team 的題目描述

這是一個 TW-Corp 內部員工系統。你有一組普通員工帳號，但聽說系統裡有管理者才能看到的機密資料，裡面藏著 flag。

請登入系統並取得 flag。

目標網站：

```text
http://<Linux主機IP>:5000
```

起始帳號：

```text
employee / pass1234
```

## Docker 主部署方式

Docker 是此題正式交付與 Linux 上機部署的建議方式。

進入題目資料夾：

```bash
cd medium_web_challenge
```

建立 image：

```bash
docker build -t medium-web-idor .
```

啟動容器：

```bash
docker run --rm -p 5000:5000 medium-web-idor
```

Red Team 可用瀏覽器開啟：

```text
http://<Linux主機IP>:5000
```

若 Linux 防火牆有開啟，需允許 port 5000。

## Python venv 備用部署方式

如果部署環境不能使用 Docker，可改用 Python venv。

```bash
cd medium_web_challenge
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python app.py
```

## 快速測試

開啟：

```text
http://localhost:5000/login
```

使用：

```text
employee / pass1234
```

登入後把網址從：

```text
/profile?id=3
```

改成：

```text
/profile?id=1
```

應可看到 admin profile 中的 Base64 attachment：

```text
RkxBR3tJRE9SX3Byb2ZpbGVfbGVha30=
```

## Blue Team 設計說明

這題故意留下兩個 Web 漏洞：

1. IDOR / Broken Access Control：`/profile?id=<id>` 只檢查是否登入，沒有檢查目前 session 是否有權限讀取指定 id。
2. SQL Injection：登入功能故意使用字串拼接 SQL，讓 SQLi 成為備用登入路徑。

資料庫中有兩個使用者：

- `id=1`：admin，管理者 profile 內含 Base64 flag。
- `id=3`：employee，提供給 Red Team 的普通帳號。

主線解法是登入 employee 後，將 `/profile?id=3` 改成 `/profile?id=1`，讀取 admin profile。

## Detection & Logging

Flask app 會在 container log 或 terminal 印出簡單 request log：

```text
REQUEST remote=... method=GET path=/profile profile_id=1 session_user=employee
```

Docker 部署時可用：

```bash
docker ps
docker logs <container-id>
```

Blue Team 可以截圖說明：

- 同一個 `employee` session 存取了不屬於自己的 `profile_id=1`。
- 登入表單中出現 SQL 特殊字元，例如 `' OR '1'='1' --`。

## 防禦與修補方式

真實環境中應移除這些漏洞：

- `/profile?id=...` 必須檢查 `session["user_id"] == requested_id`，或使用 RBAC 驗證 admin 權限。
- SQL 查詢必須使用 parameterized query。
- 密碼不應明文儲存，應使用 bcrypt / Argon2 等安全 hash。
- 監控同一 session 短時間存取多個 profile id 的異常行為。
- 登入錯誤訊息不要回傳 SQL error 細節。

## 建議截圖

- Red Team 登入 employee 的畫面。
- `/profile?id=3` 的普通員工 profile。
- 改成 `/profile?id=1` 後看到 admin profile 與 Base64 字串。
- Base64 decode 出 `FLAG{IDOR_profile_leak}` 的畫面。
- Blue Team `docker logs <container-id>` request log。
