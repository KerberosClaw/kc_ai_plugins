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

### doc-qa

- **project-docs**：讀既有專案的程式碼，寫出下一個接手的人會希望早就存在的文件。維護者拿到的是技術文件（Mermaid 圖、介面、維運）；終端使用者和管理者拿到的是附實機截圖的逐步操作手冊，畢竟從來沒有人是看架構圖找到按鈕的。
- **qa**：專門對付那個經典時刻：單元測試全綠、API 測試全綠，第一個真人一碰介面就卡住。它把需求文件跟前後端程式碼擺在一起比對，挖出沒有人寫下來的規矩，轉成可追溯的測試案例，用 Playwright 實際跑過，最後寫一份結論絕不超出證據的報告。沒跑過的測試，不會生出「零缺陷」這種字。
- **md2pdf**：把一份 Markdown 轉成 A4 PDF。Mermaid 圖、中文、寬表格、分頁都處理好了；這些坑我們已經一個一個踩過，你不用再踩。

三個串起來剛好：`qa` 測試時會順手幫 `project-docs` 收集截圖，兩者的產出再交給 `md2pdf`，轉成可以直接夾在信裡、不用先道歉的檔案。

## 之後還會有更多 pack

doc-qa 是第一個 pack，不會是最後一個。裝一個 pack 比手動接 skill 輕鬆太多，我們完全打算繼續這樣做下去。

什麼會被包成 pack，判斷標準是：**大家總是為了同一件工作一起用的幾個 skill**，尤其是還需要 MCP、或是要給用不同 agent 的同事一起用的時候。kc_ai_skills 裡現在看起來有機會的，包括規格與需求的工作流程，以及正體中文的寫作校閱。名字和時間都不先承諾；哪天新的 pack 上架了，會出現在上面的清單裡，跑一次 marketplace 更新就拿得到。

## 安裝

### Claude Code

```text
/plugin marketplace add KerberosClaw/kc_ai_plugins
/plugin install doc-qa@kc-ai-plugins
```

skill 名稱會加上 plugin 當前綴：`/doc-qa:qa`、`/doc-qa:project-docs`、`/doc-qa:md2pdf`。直接用白話講也行（「幫這個專案跑一輪 QA」），agent 會自己找到對的那個。

### Codex

```bash
codex plugin marketplace add KerberosClaw/kc_ai_plugins
codex plugin add doc-qa@kc-ai-plugins
```

### 更新

| | 指令 |
|---|---|
| Claude Code | `/plugin marketplace update kc-ai-plugins` |
| Codex | `codex plugin marketplace upgrade kc-ai-plugins` |

## 系統需求

plugin 會帶來 skill 和 MCP 設定，但不會幫你裝 skill 要呼叫的工具。下面這些要先裝在機器上：

| 誰需要 | 工具 | macOS | Debian／Ubuntu／WSL |
|---|---|---|---|
| Playwright MCP | Node.js（`npx` 要用） | `brew install node` | `sudo apt install nodejs npm` |
| md2pdf | pandoc | `brew install pandoc` | `sudo apt install pandoc` |
| md2pdf | weasyprint | `brew install weasyprint` | `sudo apt install weasyprint` |
| md2pdf | mermaid-cli | `npm install -g @mermaid-js/mermaid-cli` | 同左 |
| md2pdf | 中文字型 | 內建 | `sudo apt install fonts-noto-cjk` |

Windows 請在 WSL 裡跑 agent。`md2pdf` 是 bash 腳本，而且 weasyprint 在原生 Windows 上還要另外裝 GTK。我們試過讓這件事無所謂，結果它很有所謂。

## 不裝 plugin，只拿單一 skill

每個 skill 都是 `plugins/<plugin>/skills/` 底下一個獨立的資料夾。只想要其中一個，就照老方法把整個資料夾複製到 `~/.claude/skills/` 或 `~/.codex/skills/`。這樣會少了附帶的 MCP，也不會自動更新，不過我們不會評判你。

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
