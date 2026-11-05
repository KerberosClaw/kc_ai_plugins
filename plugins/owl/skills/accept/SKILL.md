---
name: accept
description: "Use when an owl dispatch has reported back (typically the morning after): reads the result handoff, checks its claims against the live environments read-only, runs the real-user question set, walks the user through the owl.md gaps the run recorded and writes the answers back, and adds every newly found failure to the question set. NOT for writing a dispatch (owl:brief) or executing one (owl:run)."
version: 0.1.0
status: mvp
triggers:
  - "/owl:accept"
  - "驗收"
  - "看結果交接"
  - "早上驗收"
  - "接班"
---

# accept — 接班：確認交回來的東西真的能用

> **English summary:** accept is the morning-after check. It does not trust the result handoff on its word: it compares the claims with the live environments (read-only), runs the real-user question set, and keeps "implemented", "verified" and "unverified" apart. The gaps the run recorded in `owl.md` are resolved with the user one question at a time and written back, and every failure found becomes a new question in the set, so the next dispatch is tested against it.

> 本 skill 依賴 owl:brief 的 [owl.md 範本](../brief/templates/owl.md)（寫回 owl.md 時照它的欄位）。只複製 accept 資料夾單獨使用時，要把 brief 的 `templates/owl.md` 一併帶上。

## 步驟

1. **讀結果交接。** 先看一頁摘要，再逐項看結果與證據位置。有工作目錄的話，一併讀 `state.md` 的「## 自行決策」與「## owl.md 缺口」。
2. **對實際環境核對，不只信交接。** 唯讀查版本或提交、功能開關與健康檢查，再確認交接說「已建立」的資料或卡片真的存在。對不上的列出來，以實際環境為準。
3. **跑真人問法題組。** 用 owl.md 登記的正式環境測試帳號跑，只做唯讀操作；或請使用者用自己的帳號問，你逐題對照「預期行為」判定。不是問答系統的產品，跑的是真人操作題組（操作＋預期行為），規則相同。每題先看「前提」（帳號、資料）成不成立，不成立判「未驗證」，不判沒過。run 已經跑過的題，抽幾題重跑確認。
4. **問掉 owl.md 的缺口。** 把 run 記下的缺口一題一題問使用者，每題附建議答案，答完當場寫回 owl.md。能從 repo 或環境查到的自己查，不問。
5. **新漏洞進題組。** 這次抓到的每個漏洞，把觸發它的那題用「問題＋預期行為」（或「操作＋預期行為」）加進題組，寫上前提，註明來源與日期。需要後續修正的，照專案的追蹤方式開工作項目。
6. **回報。** 先講能不能直接用，再列三類：
   - 已實作而且驗過；
   - 已實作但未驗證（原因）；
   - 沒做或沒上線（原因與退路）。

## 判準

- 未驗證不算通過。交接寫「應該沒問題」的，當成未驗證。
- 報告寫出來、通知送出去，都不代表交付成功。
- 執行的 agent 自己說通過不算數，要有證據或實際環境的結果。
- 關著上線的功能要不要打開由人決定。accept 提供依據：交接寫的原因、題組的結果、打開的步驟。

## 不做的事

- 不在正式環境上修東西。發現問題就回報，修正走新的工單（owl:brief）或使用者在場的對話。
- 不清別人的鎖，不改正式設定。打開功能開關要使用者明確同意，而且照 owl.md 的鎖規則。
