# 通知契約

> **English summary:** owl decides *when* to notify and *what* the event is; how the message travels is up to each repo. A repo's `owl.md` names a notify command (your own command, the bundled `owl_notify.sh`, or none). owl calls it as `<command> <event> <message> [result-path]` with `OWL_TASK` and `OWL_WORKDIR` in the environment. Every notification is also appended to `notify.log` in the work directory, so "no channel" still leaves a trail. A configured channel must pass a test before the run starts; a failed send mid-run is retried once, logged, and never stops the work.

## owl 管什麼、不管什麼

- **owl 管**：在對的時機呼叫通知，事件名稱固定，訊息一行。
- **owl 不管**：訊息怎麼送、送到哪、用什麼憑證。這些寫在各 repo 的 `owl.md`「通知」欄。

## 事件

| 事件 | 燈號 | 什麼時候發 |
|---|---|---|
| `started` | 🟢 | 開跑前檢查全過，正式開工 |
| `progress` | 🟢 | 每個里程碑；超過 90 分鐘沒通知時補一則 |
| `attention` | 🟡 | 出了狀況但已自行處理或繞過，工作繼續；例：等鎖超過 30 分鐘 |
| `needs_you` | 🔴 | 需要人：缺決定、疑似殘留的鎖、某一塊停在那裡等人 |
| `completed` | 🟢 | 收尾完成，結果交接已交出 |
| `failed` | 🔴 | 整輪停止 |

燈號只是建議的呈現方式，通知指令可以自己決定怎麼顯示。

## 呼叫方式

```bash
<通知指令> <事件> "<一行訊息>" [<結果檔路徑>]
```

- **事件**：上表六個之一。
- **訊息**：一行文字，換行會被換成空白。不放密碼、token 這類機敏資料。
- **結果檔路徑**：可省略。收尾時給結果交接的路徑，其他時候可以給一張截圖或證據檔。路徑在執行通知的那台機器上；指令可以附檔、轉成連結，或忽略。
- **環境變數**：owl 呼叫時會帶 `OWL_TASK`（派工名稱）與 `OWL_WORKDIR`（工作目錄）。
- **離開碼**：0 代表**已送達**。只有排進佇列、還沒確認送達，要回非 0，否則開跑前的測試會誤判成測通。

例：

```bash
OWL_TASK=nightly-release OWL_WORKDIR=~/work/nightly-release \
  ~/bin/owl_notify.sh progress "K3 done: migration verified on staging; K4 next"

OWL_TASK=nightly-release OWL_WORKDIR=~/work/nightly-release \
  ~/bin/owl_notify.sh completed "release done; search feature shipped switched off" ~/work/nightly-release/result.md
```

## 三種送法（寫在 owl.md）

| 寫法 | 意思 |
|---|---|
| **自己的指令** | 任何吃得到上面參數的指令都行：團隊既有的通知服務包裝、Slack 或 email 腳本。參數格式不同就寫一支小包裝轉一下 |
| **內附的 `owl_notify.sh`** | 支援 Telegram、Discord、Slack、iMessage；管道用 `OWL_NOTIFY_CHANNEL` 指定，憑證只從環境變數或 `OWL_NOTIFY_CONFIG` 指向的設定檔讀 |
| **不通知** | 寫「無」。只寫工作目錄的 `notify.log` 與結果交接，人回來時自己看 |

內附腳本與鎖腳本一樣，建議複製到執行主機的固定位置（例如 `~/bin/`），owl.md 寫那個路徑。plugin 更新時安裝目錄可能會變，不要在 owl.md 寫 plugin 的安裝路徑。

## 紀錄檔

不管用哪一種送法，每次通知都追加一行到 `<工作目錄>/notify.log`：時間、事件、訊息、結果（`sent`、`failed`、`retry-sent`、`not-configured`）。結果交接引用這個檔。

## 測試與失敗

- **開跑前**：有設定通知指令，就送一則 `progress`，訊息開頭寫「測試：」。離開碼不是 0，不准開工，因為接下來等於盲跑。設定成「無」就不送、不擋，在 `notify.log` 記一行 `not-configured`。
- **執行中送失敗**：等 30 秒重試一次。還是失敗就寫進 `notify.log` 與 `run_log.md`，**工作照做**，不因通知失敗中斷。下一個事件照常再試。
- **連續失敗**：把失敗的事件與時間寫進結果交接，讓人知道哪幾則沒收到。
