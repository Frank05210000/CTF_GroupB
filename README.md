# CTF Public Release

這個資料夾是公開發題包。內容只提供部署與題目資訊，不包含解題手冊、`SOLUTION.md`、報告草稿或內部審查文件。

## 部署方式

若 release 內包含三題 release 目錄與總 `docker-compose.yml`，可在此目錄執行：

```bash
./start_ctf.sh
```

檢查服務狀態：

```bash
./check_ctf.sh
```

停止服務：

```bash
./stop_ctf.sh
```

也可以直接使用 Docker Compose：

```bash
docker compose up --build
```

停止服務：

```bash
docker compose down
```

查看 log：

```bash
docker compose logs
```

## 題目目標

| 難度 | 題目 | 目標 |
|---|---|---|
| Easy | 我只是在看圖 | `http://127.0.0.1:8080/challenge.png` |
| Medium | 你以為你登進去了 | `http://127.0.0.1:5000` |
| Hard | 進來只是開始 | `127.0.0.1:2222` |

如果部署在 Linux lab 主機，請把 `127.0.0.1` 換成該主機 IP。

## Public Release 規則

公開發題包應保留：

- `README.md`
- `CHALLENGE.md`
- Docker 部署檔
- 題目執行必要檔案

公開發題包不應包含：

- `SOLUTION.md`
- `SOLUTION_GUIDE.md`
- 報告草稿
- 開發用虛擬環境
- 內部 handoff 或研究筆記
