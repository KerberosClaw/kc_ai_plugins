# KC AI Plugins — 一包給兩種 agent，整套工作一次裝好

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md)

這個情境你一定遇過：同事跑來說「你之前講的那個 QA skill 借我用一下」，十分鐘後你們還在線上會議裡：「先把這個資料夾複製過去，不是那個，是另一個，好，現在打開你的 MCP 設定檔……」這個 repo 存在的目的，就是讓這通電話不要再發生。

<p align="center">
  <img src="image/kc_ai_plugins_hero.png" width="460" alt="暖橘色的 Claude agent 與冷青綠色的 Codex agent 一起打開同一個 plugin pack，裡面有 MCP、QA、DOCS 與 PDF 模組">
</p>

<p align="center"><em>同一包給 Claude Code 和 Codex 共用：MCP 加上完成整套工作所需的 skills。</em></p>

這裡的每個 plugin 都是一個 **pack**：同一件工作要用到的幾個 skill，加上它們需要的 MCP，一個指令裝好。**Claude Code** 和 **Codex** 都能用。剛好 Codex 會直接讀 Claude 的 plugin 清單，所以整個 repo 只有一套檔案，沒有人需要維護兩份。（我們確認過，而且確認了兩次，都是在拋棄式的設定目錄裡測的，因為我們沒那麼勇敢。）

只想要單一 skill、不想要這些排場？單點菜單還在 [kc_ai_skills](https://github.com/KerberosClaw/kc_ai_skills) 照常營業。

## 為什麼要從 kc_ai_skills 拆出來

簡單講：我們發現一個 skill 資料夾，只是大家真正需要的東西的一半。

- **有些 skill 單獨拿到沒用。** `qa` 要透過 Playwright MCP 操作真的瀏覽器。只給 skill 資料夾、不給 MCP 設定，就像交車不交鑰匙：東西是完整的，但只能拿來看。
- **有些 skill 其實是同一件工作的三個分身。** `qa` 一邊測一邊收集成功路徑的截圖，`project-docs` 拿那些截圖寫手冊，`md2pdf` 再把手冊轉成可以寄出去的檔案。以前一個一個裝，總是有人只裝了其中兩個。
- **複製資料夾這招，連一個人用都撐不住。** 在這個 repo 之前，這些 skill 靠手動 symlink 裝，每個 agent、每台機器各接一次，換一台新機器就要回想當初到底接了哪幾個。這次改成 plugin，一口氣涵蓋了七個環境：一台筆電上的三個 Claude 帳號加 Codex、第二台機器的 Claude 和 Codex、第三台的 Claude。現在每個環境一行指令裝好，更新也走 marketplace，不用再像考古一樣挖當初的設定。
- **同事用的 agent 不一樣。** 有人用 Claude Code，有人用 Codex。一個 pack 兩邊用同樣的方式安裝，就不會有人被晾在一邊，也不用另外維護一份「Codex 特別版」。

kc_ai_skills 繼續做它本來就擅長的事：一大櫃可以單獨取用的 skill。搬過來的 skill 在那邊仍然列著，並且指向新的位置。

## Plugin 清單

| Plugin | 包含的 skill | 附帶的 MCP | 用來做什麼 |
|---|---|---|---|
| [doc-qa](plugins/doc-qa/) | `project-docs`、`qa`、`md2pdf` | Playwright | 幫既有專案補文件、從真實介面做 QA，兩者都能轉成 PDF 交出去 |
| [owl](plugins/owl/) | `brief`、`run`、`accept` | 無 | 把談妥的工作交給無人值守的 agent，測試要像正式環境，交回來的東西要驗過才算 |

### doc-qa

- **project-docs**：讀既有專案的程式碼，寫出下一個接手的人會希望早就存在的文件。維護者拿到的是技術文件（Mermaid 圖、介面、維運）；終端使用者和管理者拿到的是附實機截圖的逐步操作手冊，畢竟從來沒有人是看架構圖找到按鈕的。
- **qa**：專門對付那個經典時刻：單元測試全綠、API 測試全綠，第一個真人一碰介面就卡住。它比對已核准需求／spec 與實作，產出可追溯案例；Web 用 Playwright MCP，桌面／跨 App 流程用具備工具的 Codex computer-use。證據依 driver 分開，原生 App 沒有瀏覽器 network／console 就明列限制。沒跑過的測試，不會生出「零缺陷」這種字。
- **md2pdf**：把一份 Markdown 轉成 A4 PDF。Mermaid 圖、中文、寬表格、分頁都處理好了；這些坑我們已經一個一個踩過，你不用再踩。

三個串起來剛好：`qa` 測試時會順手幫 `project-docs` 收集截圖，兩者的產出再交給 `md2pdf`，轉成可以直接夾在信裡、不用先道歉的檔案。

`project-docs` 不是 QA 必經的前置階段：需要補建技術文件或手冊時才用，不從現況文件反推測試預期。QA 從已核准需求／spec 推案例，實跑的成功路徑素材也能在之後回補手冊。只是實作／hotfix 後維護既有文件時，使用 [align](https://github.com/KerberosClaw/kc_ai_skills/tree/main/align)。

操作手冊描述該版本可用行為與已知限制；核准需求／AC 與選用的盲測驗收腳本保留預期行為。agent 的背景執行方式不影響 UI driver：Claude Code bg session／agents 測 Web 仍用 Playwright。QA 0.5.1+ 先查適用性：查證受測產品無 UI 時記 UI QA 不適用並連回原流程 AC／整合驗證證據；有 UI 卻缺工具仍是未測。`BLOCKED` 不算通過，報告產出也不等於 QA 通過；無人值守的完成判準由 QA 報告契約維護。

**跨 Web 與桌面 UI 的 QA 建議用 Codex。** Web 仍由兩個 agent 都可用的 bundled Playwright MCP 操作；computer-use 分支僅限實際有工具且可存取目標的 Codex session。本 plugin 不安裝或內附 computer-use server；缺工具或不支援的段落標 `NOT RUN`，不能讀程式就當 UI 已實測。見 [UI driver 與證據](plugins/doc-qa/skills/qa/references/ui-driver.md)。

### owl

這個情境你可能也遇過：agent 跑了一整晚，回報全綠，結果第一個真人問了第一個真實的問題，整套就倒了。我們就遇過一次。測試機上只有五份文件。正式環境要開的功能，在測試計畫裡被列成「選做」，所以沒人開。驗收題全是寫程式的那個 agent 自己出的，等於讓學生自己出考卷，再自己改分數。owl 就是隔天早上寫出來的。

它管的是：把談妥的工作交給一個你不在場時跑的 agent（你可能在睡覺、在開會，或它根本跑在另一台機器上），而且交回來的東西你真的敢用。

- **brief**：把談妥的工作寫成工單，讓無人值守的 agent 不必半夜打電話問人也做得完。它先讀 repo 的 `owl.md`，缺什麼就一次問你一題，答完寫回去。它最在意的是「測試要像正式環境」：測試環境跟正式環境哪裡不一樣，全部列成一張表。每一列要嘛補齊，要嘛寫出補不齊的理由，改成上線後在正式環境用唯讀方式驗。「這項是選做」不算理由，我們試過了。
- **run**：夜班守則。狀態和紀錄都寫在檔案裡，agent 當機也好，撞到用量上限也好，半路換人接手也好，進度都不會掉。寫進狀態檔的新指示優先。共用資源（正式環境、瀏覽器設定檔、共用帳號）用帶心跳的鎖；別人的鎖，看起來再怎麼像死了也不准清。`owl.md` 有缺口不會讓它停下來，它會記下來留給早班。至於你要怎麼收到這些消息，owl 沒有意見：它只會在固定的六種事件發生時呼叫一個指令，指令是什麼寫在 `owl.md`。可以是團隊自己的通知服務，可以是內附的腳本（Telegram、Discord、Slack、iMessage），也可以乾脆不通知；那樣的話，所有消息都寫進紀錄檔，像貓一樣蹲在門口等你回來。
- **accept**：早班接班。它會讀結果交接，然後一個字都不輕信：拿交接的說法去跟實際環境對，用唯讀的正式環境測試帳號跑真人問法題組，把夜班記下的缺口一題一題問你，再把這次抓到的新漏洞全部加進題組，下一輪就會被測到。

真人問法題組是這裡的幕後功臣。每一題都是一般人實際的問法，加上預期的「行為」（「要用會議紀錄回答」「不能反問」），從來不寫標準答案。回答的字句每次都不一樣，行為不該跟著變。

owl 刻意不管的事：輕量的查修，就是「服務好像卡住了，去看一下」那種。這種事不需要寫工單，硬包成工單只是在演文書作業。審查的力氣也看風險：動到正式環境的工單，最多跑三輪 [review-gate](https://github.com/KerberosClaw/kc_ai_skills/tree/main/review-gate)；其他的跑一輪。review-gate 在 kc_ai_skills，要一起裝。

## 之後還會有更多 pack

doc-qa 是第一個 pack，不會是最後一個。裝一個 pack 比手動接 skill 輕鬆太多，我們完全打算繼續這樣做下去。

什麼會被包成 pack，判斷標準是：**大家總是為了同一件工作一起用的幾個 skill**，尤其是還需要 MCP、或是要給用不同 agent 的同事一起用的時候。kc_ai_skills 裡現在看起來有機會的，包括規格與需求的工作流程，以及正體中文的寫作校閱。名字和時間都不先承諾；哪天新的 pack 上架了，會出現在上面的清單裡，跑一次 marketplace 更新就拿得到。

## 安裝

### Claude Code

```text
/plugin marketplace add KerberosClaw/kc_ai_plugins
/plugin install doc-qa@kc-ai-plugins
/plugin install owl@kc-ai-plugins
```

skill 名稱會加上 plugin 當前綴：`/doc-qa:qa`、`/doc-qa:project-docs`、`/doc-qa:md2pdf`、`/owl:brief`、`/owl:run`、`/owl:accept`。直接用白話講也行（「幫這個專案跑一輪 QA」），agent 會自己找到對的那個。

### Codex

```bash
codex plugin marketplace add KerberosClaw/kc_ai_plugins
codex plugin add doc-qa@kc-ai-plugins
codex plugin add owl@kc-ai-plugins
```

### 更新

| | 指令 |
|---|---|
| Claude Code | `/plugin marketplace update kc-ai-plugins` |
| Codex | `codex plugin marketplace upgrade kc-ai-plugins` |

### owl 的兩支腳本

鎖腳本和通知腳本要放在固定的位置：放鎖的那台、跑派工的那台各放一份。plugin 更新時安裝目錄可能會變，所以複製一次，再把路徑寫進 `owl.md`：

```bash
mkdir -p ~/bin
cp plugins/owl/skills/run/scripts/owl_lock.sh plugins/owl/skills/run/scripts/owl_notify.sh ~/bin/
chmod +x ~/bin/owl_lock.sh ~/bin/owl_notify.sh
```

在這個 repo 的 clone 裡跑。plugin 更新後如果腳本有改，再複製一次。設定通知時先用 `OWL_NOTIFY_DRY_RUN=1` 測，這樣什麼都不會真的送出去。

## 系統需求

plugin 會帶來 skill 和 MCP 設定，但不會幫你裝 skill 要呼叫的工具。下面這些要先裝在機器上：

| 誰需要 | 工具 | macOS | Debian／Ubuntu／WSL |
|---|---|---|---|
| Playwright MCP | Node.js（`npx` 要用） | `brew install node` | `sudo apt install nodejs npm` |
| md2pdf | pandoc | `brew install pandoc` | `sudo apt install pandoc` |
| md2pdf | weasyprint | `brew install weasyprint` | `sudo apt install weasyprint` |
| md2pdf | mermaid-cli | `npm install -g @mermaid-js/mermaid-cli` | 同左 |
| md2pdf | 中文字型 | 內建 | `sudo apt install fonts-noto-cjk` |
| owl | bash（鎖與通知腳本用） | 內建 | 內建 |
| owl | curl、python3（內附通知腳本用，選用） | curl 內建；python3 要裝開發者工具（`xcode-select --install`） | `sudo apt install curl python3` |
| owl | review-gate skill | 從 [kc_ai_skills](https://github.com/KerberosClaw/kc_ai_skills/tree/main/review-gate) 裝 | 同左 |

Windows 的 `md2pdf` 請在 WSL 裡跑：它是 bash 腳本，原生 weasyprint 也要另外裝 GTK。桌面 QA 則需要 computer-use 工具能存取目標 UI 的 Codex session；只有 WSL 不會自動取得這項能力。

## 不裝 plugin，只拿單一 skill

每個 skill 都是 `plugins/<plugin>/skills/` 底下一個獨立的資料夾。只想要其中一個，就照老方法把整個資料夾複製到 `~/.claude/skills/` 或 `~/.codex/skills/`。這樣會少了附帶的 MCP，也不會自動更新，不過我們不會評判你。只有一個例外：owl 的 `accept` 會讀 `brief/templates/` 裡的 `owl.md` 範本，複製時要一起帶走。

## Repo 結構

```text
.claude-plugin/marketplace.json    列出所有 plugin（Claude Code 和 Codex 都讀這份）
plugins/<plugin>/
  .claude-plugin/plugin.json       plugin 名稱與版本
  .mcp.json                        plugin 會啟動的 MCP
  skills/<skill>/SKILL.md          一個 skill 一個資料夾
  skills/<skill>/agents/openai.yaml  Codex 的顯示資訊
```

pack 用「同事要完成的工作」命名，不用那種沒人會拿來搜尋的技術分類。每個 skill 只住在一個 pack 裡，所以永遠不會有「哪一份才是正本」的問題。

## 授權

MIT
