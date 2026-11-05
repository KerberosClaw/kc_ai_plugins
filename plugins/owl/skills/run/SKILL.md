---
name: run
description: "Use when executing an owl dispatch unattended, or resuming one after a crash, a usage limit or an account switch: keeps the state file and step log, honours instructions added mid-run, takes and heartbeats locks on shared resources, sends milestone notifications with confirmed delivery, verifies on production with the read-only test account after release, and never stops to ask about gaps in owl.md — it records them and follows the dispatch's fallback. NOT for writing the dispatch (owl:brief) or for acceptance (owl:accept)."
version: 0.1.0
status: mvp
triggers:
  - "/owl:run"
  - "照工單做"
  - "開工"
  - "接續派工"
  - "續跑"
---

# run — 人不在的時候，照工單做完

> **English summary:** run is the discipline for the agent executing a dispatch while nobody is watching. Everything important lives in files (state, log, evidence), so a crash, a usage limit or another agent picking up the work loses nothing. Mid-run instructions in the state file win. Shared resources are locked with heartbeats, and nobody clears someone else's lock. Gaps in `owl.md` never stop the run: they are recorded and the dispatch's fallback applies. After release, the read-only production test account runs the real-user question set; a failing feature gets its switch turned off.

## 開工前

1. **讀完整份工單**，再讀 repo 根目錄的 `owl.md`。工單與 owl.md 衝突時以工單為準，並記進 `run_log.md`。
2. **跑工單第 6 節的開跑前檢查**，每一項都是指令加期望值。不過就照工單寫的處理，不自己放寬。
3. **通知測通**：送一則測試通知，回執是「已送達」才算，排隊中不算。送不出去不准開工，否則就是盲跑。
4. **查鎖**：工單要用到的鎖先看一次狀態。殘留的鎖照鎖協定處理，不清。
5. 建好工作目錄的檔案（下一節），把工單的「禁止」抄進 `state.md`。

## 工作目錄

工作目錄不進 repo；要留存的東西寫進結果交接。

| 檔案 | 用途 |
|---|---|
| `state.md` | 最上面依序是「## 禁止」「## 人的指示」「## 自行決策」「## owl.md 缺口」「## 進度」。接續時第一個讀它，而且讀全文 |
| `run_log.md` | 每一步的時間、指令與結果。時間一律取系統時間，不估；不寫密碼 |
| `evidence/` | 驗證的原始輸出、截圖，結果交接引用這裡 |
| `DONE` | 全部做完（含結果交接已交出、鎖已放）才建立 |

## 人中途改指示

- 以 `state.md`「## 人的指示」的**最新一條**為準，即使它推翻工單某一條。照做時在 `run_log.md` 記下照的是哪一條。
- 被推翻的「禁止」項目一起劃掉並註明，免得前後矛盾。
- 每次接續、對話壓縮之後、每個關鍵步驟（部署、寫正式資料）之前，都重讀 `state.md` 全文。只讀「進度」段會漏掉新指示。
- 指示怎麼送進來（例如寫檔再叫醒執行程式）照 owl.md 的「執行方式」。

## 鎖

owl.md 有登記鎖的資源，照 [鎖協定](references/lock.md) 用 [owl_lock.sh](scripts/owl_lock.sh) 或 owl.md 指定的指令：

- 動手前取鎖，拿不到每 5 分鐘再試，期間先做不碰該資源的項目。
- 持鎖期間每 10 分鐘心跳一次，長指令前後也跑一次。一段做完就放，不要整晚抱著。
- **別人的鎖一律不准清**，心跳沒更新不等於對方沒在動。疑似殘留就通知人，繼續等。
- 離時段結束不到 30 分鐘，不再開始新的鎖內動作。

## 卡住時

- **先自己排除。** 外部呼叫都設逾時，逾時就退避重試；連續失敗就換做法或跳過那一項，記錄原因，其他工作繼續。
- **不可逆的操作不盲目重試。** 部署、資料庫、環境檔、正式資料寫入逾時或結果不明，先查實際狀態（版本、容器啟動時間、檔案內容、資料筆數），確認沒發生才重做一次。
- **三種停法**，都只停受影響的部分，獨立的工作照做：
  - 缺必要的資訊或決定：記下來，照工單的退路做，通知時寫「需要你：…」；
  - 已到重試上限、連兩輪沒有實質進展：停止這一項，回報試過什麼；
  - 下一步超出授權：不做，回報。
- **整輪停止**只用在工單第 7 節列的情況，例如會傷到正式服務、回退也失敗、憑證外洩疑慮。

## owl.md 不夠時

執行中人不在，不能停下來問。遇到 owl.md 沒寫、這次又需要的事：

1. 記進 `state.md` 的「## owl.md 缺口」：缺什麼、在哪一步發現、你怎麼處理。
2. 照工單的退路做。常見的退路：測試環境補不齊的驗證改到上線後在正式環境驗；沒有測試帳號就記「未驗證」；那一塊關著上線。
3. 寫進結果交接。owl:accept 會拿這份清單去問人，補回 owl.md。

## 等待與進度

- **短查，不要長輪詢。** 每次只等一小段（數十秒到數分鐘），看一眼就記錄。把十分鐘的輪詢塞進一個指令，會撞到執行上限被砍，期間也看不到任何進度。
- **驗內容，不只看結束碼。** 背景工作會靜默失敗：可能卡死；可能結束碼是 0，輸出卻是空的；也可能 shell 的萬用字元沒對到檔案，整段直接中止。確認輸出非空、筆數合理。
- **通知**：照工單第 7 節的時機發，每則確認送達。超過 90 分鐘沒通知就補一則進度。通知方式照 owl.md；沒有現成的通知服務時，可用 [grill 附的 notify.sh](https://github.com/KerberosClaw/kc_ai_skills/tree/main/grill/references)。

## 可以被別人接手

- 每個里程碑把產出提交並推送；只存在工作目錄或對話裡的進度，換人接手時等於不存在。
- 會停服務或跑很久的步驟寫成獨立腳本：背景執行、任何結束路徑都恢復服務、每步落紀錄，可以從失敗的步驟續跑。
- 接續時先讀 `state.md` 全文，再讀 `run_log.md` 最後 40 行，核對變更、標籤、各主機的狀態、鎖是不是自己的；外部操作結果不明就先查。

## 上線後驗證

工單第 3.3 節有寫的話，上線後一定要做：

1. 用 owl.md 登記的正式環境專用測試帳號，跑題組裡跟這次改動相關的題。
2. 只做唯讀操作，不建資料、不改設定。
3. 每題對照「預期行為」，記進 `evidence/`。
4. 沒過：照工單關掉該塊的功能開關，再驗一次確認關掉後回到原本的行為，寫進結果交接。不要在正式環境上邊修邊試。

## 收尾

1. 關掉連線、放掉所有鎖、清掉暫存的大檔。
2. 照 [結果交接範本](templates/result.md) 寫結果交接，交到工單指定的位置。
3. 發收尾通知。
4. 最後才建立 `DONE`。

分清楚「做完」和「驗過」：報告產出、通知送出都不代表交付成功。未驗證的項目寫「未驗證」，不寫「應該沒問題」。
