# KC AI Plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[English](README.md)

給 **Claude Code** 和 **Codex** 用的工作流程 plugin。每個 plugin 把同一件工作會用到的幾個 skill 和它們需要的 MCP 包在一起，同事裝一次就拿到做那件事的全套工具。

同一個 repo 兩邊都能用：Codex 直接讀 Claude 的 plugin 清單，所以只有一套檔案，不必兩邊同步。

只想要單一 skill？請到 [kc_ai_skills](https://github.com/KerberosClaw/kc_ai_skills)。

## Plugin 清單

| Plugin | 包含的 skill | 附帶的 MCP | 用來做什麼 |
|---|---|---|---|
| [doc-qa](plugins/doc-qa/) | `project-docs`、`qa`、`md2pdf` | Playwright | 幫既有專案補文件、從真實介面做 QA，兩者都能轉成 PDF 交出去 |

### doc-qa

- **project-docs**：盤點既有專案的程式碼，補齊下一個人需要的文件。給維護者的是技術文件（Mermaid 圖、介面、維運），給終端使用者和管理者的是附實機截圖的逐步操作手冊。
- **qa**：專治「單元測試和 API 測試都綠，真人一操作就卡住」。把需求文件和前後端程式碼擺在一起比對，挖出沒有人寫下來的規矩，轉成可追溯的測試案例，用 Playwright 實際跑過，再寫一份結論不超出證據的報告。
- **md2pdf**：把一份 Markdown 轉成 A4 PDF，處理 Mermaid 圖、中文、寬表格和分頁。

三個可以串起來用：`qa` 跑的時候會順手收集成功路徑的截圖，給 `project-docs` 寫手冊；兩者的產出再用 `md2pdf` 轉成可以直接寄出去的檔案。

## 安裝

### Claude Code

```text
/plugin marketplace add KerberosClaw/kc_ai_plugins
/plugin install doc-qa@kc-ai-plugins
```

skill 名稱會加上 plugin 前綴：`/doc-qa:qa`、`/doc-qa:project-docs`、`/doc-qa:md2pdf`。直接用白話講（「幫這個專案跑一輪 QA」）也可以。

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

plugin 只帶 skill 和 MCP 設定，下面這些工具要先裝在機器上：

| 誰需要 | 工具 | macOS | Debian／Ubuntu／WSL |
|---|---|---|---|
| Playwright MCP | Node.js（`npx` 要用） | `brew install node` | `sudo apt install nodejs npm` |
| md2pdf | pandoc | `brew install pandoc` | `sudo apt install pandoc` |
| md2pdf | weasyprint | `brew install weasyprint` | `sudo apt install weasyprint` |
| md2pdf | mermaid-cli | `npm install -g @mermaid-js/mermaid-cli` | 同左 |
| md2pdf | 中文字型 | 內建 | `sudo apt install fonts-noto-cjk` |

Windows 請在 WSL 裡跑 agent。`md2pdf` 用的是 bash 腳本，而且 weasyprint 在原生 Windows 上還要另外裝 GTK。

## 不裝 plugin，只拿單一 skill

每個 skill 都是 `plugins/<plugin>/skills/` 底下一個獨立的資料夾。只想要其中一個，就把整個資料夾複製到 `~/.claude/skills/` 或 `~/.codex/skills/`。代價是少了附帶的 MCP，也不會自動更新。

## Repo 結構

```text
.claude-plugin/marketplace.json    列出所有 plugin（Claude Code 和 Codex 都讀這份）
plugins/<plugin>/
  .claude-plugin/plugin.json       plugin 名稱與版本
  .mcp.json                        plugin 會啟動的 MCP
  skills/<skill>/SKILL.md          一個 skill 一個資料夾
  skills/<skill>/agents/openai.yaml  Codex 的顯示資訊
```

plugin 用「同事要完成的工作」命名，不用技術分類命名。每個 skill 只放在一個 plugin 裡。

## 授權

MIT
