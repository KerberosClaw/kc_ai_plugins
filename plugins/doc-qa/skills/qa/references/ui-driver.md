# UI 操作與證據來源

階段 0 選擇，階段 3 開始前再核對。測試案例與預期結果仍由需求／spec 推導，工具不改變測試意圖。

## 選擇操作方式

| 目標 | 操作方式 | 執行端 |
|---|---|---|
| Web UI | 優先 Playwright MCP | Claude Code 或 Codex，只要實際有可用工具 |
| 原生桌面 App、系統對話框、Web 外的跨 App 流程 | Computer-use／CUA | 本 skill 此分支僅支援 Codex，且該 session 必須有可操作目標的 computer-use 工具 |
| Web 與桌面混合 | 每段分別標示 Playwright 或 Codex computer-use | 建議 Codex；不能用 Web 的測試結果代替桌面段落 |

**建議由 Codex 執行需要涵蓋多種 UI 的 QA**，以便同一輪使用兩種操作方式。這不是保證每個 Codex session 都有 computer-use；開跑前必須看實際工具與目標可存取性。Claude 的 Web QA 仍沿用 Playwright，不推測它支援此 computer-use 分支。

Computer-use 是執行端能力，不是此 plugin 額外啟動的 MCP server；不要在 `.mcp.json` 裡加一個假想的 computer-use server，也不在 QA 中自行安裝、開權限或改系統設定。沒有工具或目標不受支援時，該段標 `NOT RUN` 並回報缺什麼，不以程式碼閱讀或 API 測試充當 UI 實跑。

CLI／背景服務的命令測試仍是其他驗證層；不能因為用 computer-use 看了終端畫面，就把它改稱已完成使用者介面 QA。

## 在階段 0 記錄

記錄 runner（Codex／Claude）、執行主機與作業系統、目標 App 身分／版本或 URL、已授權環境與角色、各段 driver、可用證據通道與限制。需求／原始碼／執行目標的三方版本仍要對齊。

沿用使用者或 dispatch 已確定的範圍與授權，不重問相同問題。權限不足或缺帳號就記錄缺口；無人值守不等於可以跨到其他 App、帳號或正式環境。

## Playwright：Web 證據

先確認工具文件與當前可用方法。使用可存取的無障礙樹／DOM、network、console 與截圖；具體規則沿用 run-discipline。若操作包含原生檔案選擇器或其他桌面段落，另外記錄該段的 driver 與證據，不默認 Playwright 已測過。

## Codex computer-use：桌面證據

- 使用該 session 實際提供的 computer-use／CUA 工具（例如 `mcp__cua_repl`），先讀其使用說明，依允許的入口選擇已授權目標 App／視窗，再使用文件中存在的 API。不要從別次 session 猜方法名，也不要用 shell 腳本或另一套 GUI automation 偷換操作管道。
- 每步以新讀取的 UI 狀態／截圖定位，操作後重新觀察結果；不可沿用失效元素或憑記憶盲點座標。只操作本次目標與必要系統對話框，不巡覽無關 App。
- 可讀無障礙樹、控制項文字與狀態時優先使用，並保留必要片段。工具只有影像時，標明「視覺證據」及限制，用操作前後截圖支持可直接觀察的 UI 結論，不假裝已取得 DOM／AX tree。
- 涉及儲存、建立、送出等狀態變更，需額外讀回實際結果，例如重新打開目標紀錄、檢查輸出檔，或讀已授權且確認無副作用的 log／狀態。單一成功畫面不能證明資料已保存、外部已送達或背景工作完成。
- 原生 App 未必有瀏覽器 network／console。能讀取既有診斷／log 就附上；沒有則在證據邊界記「未取得」或「不適用」及原因。若該訊號是某條預期結果的必要依據而拿不到，保留證據缺口，不以畫面推成 PASS；`UNCLEAR` 仍專指使用者看不懂的正確阻擋，不拿來包裝工具缺失。
- 依目標明確的可觀察條件等待。若工具沒有 wait API，可有界地重讀狀態；沿用測試既有逾時，不無限輪詢、不憑固定睡眠宣稱完成。
- 截圖沿用 `defect`／`manual` 分類，保存為報告能相對引用的檔案。若工具無法匯出／保存，只能回傳暫時畫面，先記錄證據通道限制，不宣稱已交付截圖檔。

正式環境唯讀、可拋棄資料寫入授權、不可逆操作及每次寫入留紀錄的規則，兩種 driver 完全相同。
