# Easy CTF Challenge: 我只是在看圖

這是一個適合在 Linux 主機上用 Docker 部署的 Easy / 100 pts CTF 題目。題目類型是 Image Metadata + Base64 Encoding，核心概念是公開圖片前沒有清除 metadata，導致內部備註外洩。

## 題目資訊

- 題目名稱：我只是在看圖
- 難度：Easy / 100 pts
- 題型：Image Metadata + Base64 Encoding
- Flag：`FLAG{metadata_leak}`
- 主要工具：`curl`、`exiftool`、`base64`
- 對外服務：HTTP port `8080`

## 給 Red Team 的題目描述

公司內部網站上傳了一張活動照片。Blue Team 懷疑圖片匯出流程把內部發布備註一起保留在檔案裡。

請下載圖片，檢查圖片檔案資訊，找出可疑內容並解碼取得 flag。

目標檔案：

```text
http://<Linux主機IP>:8080/challenge.png
```

## Docker 部署方式

在 Linux 主機安裝 Docker 後，進入本題目錄：

```bash
cd easy_metadata_challenge
docker compose up --build
```

Red Team 可使用瀏覽器或 `curl` 下載：

```bash
curl -O http://<Linux主機IP>:8080/challenge.png
```

若 Linux 防火牆有開啟，需允許 port `8080`。

## 純 Docker 指令

若不使用 Docker Compose：

```bash
docker build -t ctf-easy-metadata .
docker run --rm -p 8080:8080 ctf-easy-metadata
```

## 重新產生題目圖片

本題的 `challenge.png` 可由 Python 標準函式庫重新產生，不需要 Pillow：

```bash
python3 make_challenge_image.py
python3 verify_metadata.py
```

## Blue Team 設計說明

這題故意把敏感資訊放在 PNG metadata 中：

```text
ImageDescription: Public release copy - approved for external sharing
Comment: RkxBR3ttZXRhZGF0YV9sZWFrfQ==
Software: TW-Corp Internal Image Exporter 1.0
```

`Comment` 欄位是 Base64 編碼後的 flag。Red Team 需要先檢查圖片 metadata，再解碼取得：

```text
FLAG{metadata_leak}
```

## 防禦與修補方式

真實環境中，公開或上傳圖片前應清除 metadata，避免洩漏隱私或敏感資訊。

可使用：

```bash
exiftool -all= image.png
```

或：

```bash
mat2 image.png
```

## 建議截圖

- Red Team 下載 `challenge.png` 的畫面。
- `exiftool challenge.png` 顯示 metadata 的畫面。
- `base64 -d` 解碼取得 `FLAG{metadata_leak}` 的畫面。
- Blue Team 使用 `docker logs ctf-easy-metadata` 顯示 HTTP 存取紀錄。
