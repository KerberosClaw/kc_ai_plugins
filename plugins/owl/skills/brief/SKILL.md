---
name: brief
description: "Use when agreed work is about to be handed to an unattended agent (an overnight run, a background session, another machine): reads the repo's owl.md and fills its gaps with the user one question at a time, makes every difference between the test environment and production explicit, puts a real-user question set into acceptance, writes the dispatch from the template, and sizes review-gate rounds by risk. NOT for requirements that are still undecided (use grill first), routine troubleshooting that needs no written dispatch, or running the dispatch (owl:run)."
version: 0.1.0
status: mvp
triggers:
  - "/owl:brief"
  - "寫派工單"
  - "寫工單"
  - "派工"
  - "交給背景跑"
  - "今晚跑"
---

# brief — 把談妥的工作寫成交得出去的工單

> **English summary:** brief turns agreed work into a dispatch an unattended agent can finish without asking anyone. It reads the repo's `owl.md` first and fills missing facts with the user, one question at a time. Its core rule is test fidelity: every way the test environment differs from production is listed, closed where possible, and otherwise verified after release with a dedicated read-only production test account and a question set written the way real users ask. Review rounds scale with risk.

## 什麼時候用

| 用 | 不用 |
|---|---|
| 需求已經談定，要交給人不在旁邊的 agent 做完（夜間、背景、另一台機器） | 範圍或取捨還沒定：先用 grill 談清楚 |
| 步驟多、會跑好幾個小時，中途可能撞到用量上限或換帳號 | 幾個指令就做完的事：直接在對話裡做 |
| 要動正式環境，或結果要交給明天的自己或別人驗收 | 維運查修這類不寫工單的輕量工作：例如通知說服務卡住，轉一句話給維運 agent 處理。這類工作照各 repo 現有的規則和默契走，不套 owl |

## 第一步：讀 owl.md

`owl.md` 放在產品 repo 的根目錄，記這個專案的環境、測試資料、真人問法題組、鎖與通知。它是 owl 三支 skill 共用的事實來源，範本在 [templates/owl.md](templates/owl.md)。

工單常常放在另一個 repo（例如專門放派工單的 repo），執行的 agent 開工時所在的目錄也不一定是產品 repo。所以寫工單時，第 0 節要填「本工單用到的 owl.md」：一個產品 repo 一列，寫主機、絕對路徑（或 `git show <提交>:owl.md`）與提交。run 照這一列去讀，找不到就算開跑前檢查失敗。

- **還沒有 owl.md**：照範本帶使用者建一份。能從 repo 查到的（compose 檔、部署文件、AGENTS.md）自己查，查不到的才問。
- **owl.md 不夠用**：這次工單需要、但 owl.md 沒寫的事，一次問一題，每題附建議答案，答完當場寫回 owl.md，再繼續寫工單。
- **不放帳密**：密碼、token、webhook 只寫環境變數或設定檔的名字。
- **多人協作的 repo**：在 AGENTS.md 加一句白話，例如「派工環境說明在 `owl.md`，有裝 owl plugin 才需要讀」。不要用 `@owl.md` 這類自動引入，沒用 owl 的同事不必每次多讀一份。

## 步驟

1. **確認需求已定。** 列出已定案的決定；還有取捨沒定，回 grill，不在工單裡替使用者決定。
2. **先寫技術規格。** 判斷執行的 agent 會不會遇到要自己做設計決定的地方。有的話，先讀程式，把改哪裡、各版本或各部署形態的行為、資料與遷移、回退步驟寫成規格，放在產品 repo，讓團隊看得到。工單只寫「照規格做」，加上驗收與授權。不要把設計留給半夜的 agent，再用「做錯就回退」兜底。
3. **做環境差異表**（下一節，本 skill 的核心）。
4. **寫驗收。** 每一項都是可以執行的檢查加期望值，例如「健康檢查端點回 ok、版本是 1.4.0」，不要寫「確認環境正常」。真人問法（或真人操作）題組一定列進去。
5. **寫授權、鎖、停止條件、通知、恢復與收尾。** 照 [工單範本](templates/dispatch.md) 逐節填，用不到的節整節刪。
6. **送審。** 呼叫 review-gate，輪數見後面「審查輪數」。
7. **交出。** 附上開工方式。怎麼開工、怎麼中途改指示，照 owl.md 的「執行方式」寫。

## 測試要像正式環境

測試機全過、正式環境一問就出事，原因通常不是程式寫錯，而是測試環境跟正式環境不一樣，沒有人把差異寫下來。常見的三種：

- **資料太少。** 測試環境只有幾份文件，做不出正式環境才會出現的情況，例如一題撈出很多群分數相近的結果。依賴這種情況的分支，在測試環境永遠走不到。
- **設定不同。** 正式環境要開的功能，在測試環境被列成「選做」，結果沒開。兩個新功能第一次一起執行，就是使用者在正式環境問的那一題。
- **題目太乾淨。** 驗收題由寫程式的 agent 自己出，全是標準問法；一般人的說法（「那場會議講了什麼」這種帶指代的句子）一題都沒測到。

所以每張工單都要有**環境差異表**，逐項對照：

| 項目 | 測試環境 | 正式環境 | 處理 |
|---|---|---|---|
| 設定與功能開關 | | | 補齊／上線後驗 |
| 外部服務與模型 | | | |
| 資料量與資料樣態 | | | |
| 帳號、角色與權限 | | | |
| 流量與並行 | | | |
| 版本與相依套件 | | | |

處理只有兩種：

1. **補齊。** 正式環境要開的東西，測試環境一定先開，不准列成選做。資料不夠，就照 owl.md 的「測試資料」補到能觸發正式環境會出現的分支。機敏資料不複製到測試環境，改用去識別化或合成資料。
2. **補不齊，就上線後在正式環境驗。** 工單寫明：上線後用 owl.md 登記的**正式環境專用測試帳號**，把真人問法題組跑一遍。跑題組只做唯讀操作，例如問問題、查詢，不建資料、不改設定。沒過就把那一塊的功能開關關掉，寫進結果交接。為了能這樣退，規格要讓新功能各自帶開關。
   - 關開關會改正式設定，不是唯讀。工單第 3.3 節要寫出關閉指令（含讓它生效的步驟）與要取的鎖，第 2 節的「准許」要把這個動作列進去，否則 run 不能關。
   - 上線後驗證排在離時段結束至少 30 分鐘前開始，留時間給關開關與再驗一次。
   - 還沒有測試帳號時，工單照寫，上線後驗證記「未驗證」；帳號要不要開、什麼時候開，由人決定。

「補不齊」要寫出理由，例如「正式資料不能離開正式環境」。「時間不夠」「這項是選做」都不算理由。

### 真人問法題組

- **位置**寫在 owl.md，放在 repo 裡讓團隊看得到，改功能的人也拿得到。
- **格式**是「問題＋預期行為」，不寫標準答案。預期行為像是「要用會議內容回答」「要出現網路查找段」「不能反問」「要回查無」。回答的字句每次都會變，行為才驗得出對錯。
- **不是問答系統的產品**（後台、模擬工具、排程服務）改用「真人操作題組」：每題「操作＋預期行為」，例如「用一般使用者登入，上傳一份超過上限的檔案 → 要擋下並說明上限」。位置、來源、前提欄的規則都一樣。
- **每題寫前提**：要用哪個帳號、要先有哪些資料。例如「需要是那場會議的成員」。前提不成立時判「未驗證」，不判沒過，免得權限不足的題目把正常的功能關掉。
- **題目來源**有三種，不能只由寫程式的 agent 自己出：
  - 使用者實際在正式環境問過、出過問題的題；
  - 從正式環境的使用紀錄抽樣，去掉人名與機敏內容；
  - owl:accept 每抓到一個漏洞，就把觸發它的那題加進來。
- 工單的驗收引用題組裡跟這次改動相關的題，不必每次全跑；但跟改動相關的題一題都不能漏。

## 審查輪數

| 工單類型 | review-gate 輪數 |
|---|---|
| 會動正式環境：部署、寫正式資料、改正式設定 | 最多 3 輪 |
| 只動測試環境或私人專案、做壞了可以整個重來 | 1 輪 |

- **要不要加一輪**：看修法，不看嚴重度。複核者的處置都寫明了具體改法，就照著修完直接交，不再送一輪確認改對沒有。只有修法要另外判斷、會牽動其他段落，或修的時候發現新的 P1、P2，才加一輪。動正式環境的工單照樣以 3 輪為上限，其他工單加輪後總數也不超過 3 輪。
- 到上限還有重要問題，就回報阻塞與選項，不靠上限宣稱通過。
- 沒有 review-gate 或缺少獨立的審查 agent 時，如實回報能力缺口，不把自己審自己當成已審查。

## 工單一定要有的內容

[工單範本](templates/dispatch.md) 有完整的節。最常漏的是這幾項：

- **決定與授權寫死。** 哪些合併、哪些主機、哪些時段准動正式環境。執行的 agent 本機若有一般性規則會擋住這次授權的動作，工單要明寫「本次授權蓋過本機的一般規則」。但 owl.md 的「授權底線」不在此列，工單蓋不過它，順序見 owl:run 的「衝突時聽誰的」。
- **owl.md 在哪。** 第 0 節列出本工單用到的每一份 owl.md：主機、絕對路徑或提交。
- **停止條件分兩級。** 整輪停（會傷到正式服務、回退也失敗、憑證外洩疑慮），以及只停那一項、其他繼續。也寫出依賴：哪一項沒過，後面哪些不做。
- **退路。** 每一塊沒做完或驗不過時，明天的人怎麼用舊版撐過去；功能開關關著上線也算退路。
- **不可逆的操作不盲目重試。** 部署、資料庫、環境檔、資料寫入逾時或結果不明，先查實際狀態再決定。
- **鎖。** owl.md 有登記鎖的資源，工單寫明哪幾步要取鎖。規則照 owl:run 的 [鎖協定](../run/references/lock.md)。
- **通知。** 工單只寫哪些時機發哪個事件，送法交給 owl.md 的通知指令，契約見 owl:run 的 [通知契約](../run/references/notify.md)。工單裡不寫任何特定的通知服務或憑證。
- **結果交接的格式。** 照 [結果交接範本](../run/templates/result.md)。

## 不做的事

- 不替使用者做產品決定；需求有缺口就回 grill。
- 不執行工單：執行是 owl:run，驗收是 owl:accept。
- 不把帳密、token 或 webhook 寫進工單、owl.md 或任何 repo。
- 不擴大授權：工單只能寫使用者已經授權的事。
