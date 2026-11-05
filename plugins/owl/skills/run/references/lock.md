# 鎖協定

> **English summary:** One lock per shared resource that breaks when two agents touch it at once (a production environment, a browser profile, a shared account). The lock is a directory on one fixed host; whoever acts on the resource takes it there, heartbeats while holding it, and releases it as soon as the stretch of work is done. Stale locks are reported, never cleared by an agent.

## 鎖什麼

**同時操作會出事的共用資源，一個資源一把鎖。** 例如：

- 一個正式環境：部署、重啟、改正式設定、寫正式資料。
- 一個瀏覽器設定檔或一個帳號：兩個 agent 同時操作就會互相干擾。
- 一個多人共用的測試環境：兩條線同時重建會互相蓋掉。

唯讀檢查（健康端點、查詢、看紀錄）不用取鎖。

鎖放在**固定的一台機器**上，誰要動那個資源，就到那台機器取鎖（遠端就用 SSH 執行同一個指令）。每個專案在 owl.md 的「鎖」寫明：鎖住哪個資源、指令是什麼、哪些動作要取。

## 怎麼用

```bash
owl_lock.sh -n <鎖名> acquire <派工名稱> "<步驟>"   # 0 拿到；1 別人持有（印出持有者）
owl_lock.sh -n <鎖名> heartbeat <派工名稱>           # 持鎖期間每 10 分鐘一次
owl_lock.sh -n <鎖名> release <派工名稱>             # 做完就放
owl_lock.sh -n <鎖名> status                         # 0 沒人；1 有人、心跳正常；3 疑似殘留
```

- **派工名稱**：同一條派工整段都用同一個，只能用英數與 `. _ -`。被重開的派工用同一個名稱再取一次，腳本認得是自己的就沿用。
- **持鎖單位**：一段連續的動作，例如「部署、驗證」。中間要做很久、又不碰這個資源的事，先放鎖，之後再取。
- 鎖的目錄預設在 `~/.owl/locks/<鎖名>.lock.d`，可以用環境變數 `OWL_LOCK_ROOT` 改。每次取、放、強制清除都追加到同目錄的 `<鎖名>.log`。

## 拿不到怎麼辦

- 每 5 分鐘再試一次，期間先做不碰這個資源的項目。
- 等超過 30 分鐘：發一則注意通知，寫明在等誰、等哪一步。
- `status` 回 3（心跳超過 30 分鐘沒更新）：發需要人的通知，附 `status` 的輸出，**繼續等，不准自己清**。只通知一次，狀態有變才再發。
- 有時段限制的工作：離時段結束不到 30 分鐘，不再開始新的鎖內動作，照工單寫進結果交接。

## 殘留的鎖

- agent 一律不准清別人的鎖。心跳沒在更新，不等於對方沒在動。
- 只有人確認過才能清：`owl_lock.sh -n <鎖名> force-release "<原因>"`。腳本只接受從終端機互動執行，會留紀錄。

## 人在電腦前直接動手時

人親自操作不必取鎖。但 agent 要替人動那個資源之前，先跑一次 `status`：有人持鎖，就告訴人是誰、哪一步、心跳多久前，由人決定，不擋他。
