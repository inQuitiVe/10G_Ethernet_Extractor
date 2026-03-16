# Debug Log — 10G Ethernet Message Extractor

完整記錄從開始到結束的所有 bug 發現、根因分析、與修正過程。

---

## Bug 1 — Icarus Verilog 不支援 `break` 語句

**發現時機**：在 `msg_extractor_stress_tb.sv` 的向量載入迴圈與 `skip_line` task 中使用了 `break`。

**錯誤訊息**：
```
sim/msg_extractor_stress_tb.sv:119: sorry: break statements not supported.
```

**根因**：Icarus Verilog 的 SystemVerilog 支援不完整，不允許在 `while`/`for` 迴圈中使用 `break`。

**修正**：
- 在具名 block 中改用 `disable <block_name>` 替代 `break`
- 向量載入迴圈改以 `done` flag 控制迴圈結束條件

```systemverilog
// Before
while (...) begin
  ...
  if (done) break;
end

// After
begin : load_loop
  integer done;
  done = 0;
  while (!$feof(fd) && !done) begin
    ...
    if (r <= 0) done = 1;
  end
end
```

---

## Bug 2 — Icarus Verilog 不支援 task 內的 `return`

**發現時機**：`check_packet` task 中使用 `return` 做提早離開。

**錯誤訊息**：
```
sim/msg_extractor_stress_tb.sv:131: error: Cannot "return" from tasks.
```

**根因**：Icarus Verilog 不允許在 task 內使用 `return` 陳述式。

**修正**：將原本 `return` 之後的比對邏輯改為放在 `else` block 中，消除提早返回的需求。

```systemverilog
// Before
if (n_out < pkt_base + n_exp) begin
  $display("TIMEOUT ...");
  return;   // ← not supported
end
for (...) begin ... end

// After
if (n_out < pkt_base + n_exp) begin
  $display("TIMEOUT ...");
end else begin
  for (...) begin ... end
end
```

---

## Bug 3 — Testbench 對 AXI-S 無效 byte 位置做嚴格比對

**發現時機**：stress test 跑出大量 FAIL，例如：
```
FAIL: exp d=a185000000000000 k=c0 l=1
      got d=a185000ea07a0000 k=c0 l=1
```
keep=0xC0 表示只有高 2 個 byte 有效，DUT 在低位輸出非零但 AXI-S 規格允許 receiver 忽略 tkeep=0 的位元組。

**根因**：Testbench 直接比較 64-bit `m_tdata`，未依照 `m_tkeep` 遮罩無效位元組，判定為誤報的 FAIL。

**修正**：在 `msg_extractor_stress_tb.sv` 加入 `tkeep_mask` 函數，比對前先做遮罩：

```systemverilog
function automatic logic [63:0] tkeep_mask(input logic [7:0] k);
  integer b;
  logic [63:0] m;
  m = '0;
  for (b = 0; b < 8; b++)
    if (k[7-b]) m[63-b*8 -: 8] = 8'hFF;
  return m;
endfunction
```

比對時：
```systemverilog
mask       = tkeep_mask(exp_k[i]);
exp_masked = exp_d[i]          & mask;
got_masked = out_d[pkt_base+i] & mask;
if (got_masked === exp_masked && out_k[...] === exp_k[i] && ...)
```

---

## Bug 4 — S_HDR 接受無效 payload 長度，進入 ghost message 處理

**發現時機**：部分 packet 出現 TIMEOUT（DUT 輸出 beat 數比預期少），尤其是 packet 結尾含有 zero-padded bytes 時。

**根因**：packet 結束後，DUT 在 `S_HDR` 重新開始解析時，`wa` 中還殘留前一 message 的 payload 資料。這些資料的 low bits 恰好被解釋為 `prem`。若 `prem == 0` 或遠超規格範圍，DUT 進入 ghost `S_PAY` 並浪費時脈或輸出錯誤資料。

**影響**：last beat 含有 zero-padding 時（tkeep < 0xFF），零位元組被誤解為長度 0 的 header，導致 ghost message 佔據 FSM 狀態，後續真實 message 輸出被 delay 或丟失。

**修正（Fix 1，保留至今）**：在 `S_HDR` 解析 `prem_nx` 後，立即驗證長度範圍：

```systemverilog
// 所有 window-based 變體及 area 變體
prem_nx = hdr[5:0];
if (prem_nx < 6'd8 || prem_nx > 6'd32) begin
  state_nx = S_IDLE;   // 無效長度 → 丟棄，回到閒置
end else begin
  // 正常處理
end
```

---

## Bug 5 — Fix 2（S_PAY stuck-state escape）過度積極截斷合法 message

**發現時機**：在 Fix 1 基礎上加入「S_PAY 卡死逃脫」修正後，stress test 反而更差：
```
TIMEOUT pkt 3: expected 14 beats, got 7  ← 原本 got 13，修後變 got 7
```

**錯誤的 Fix 2 邏輯**：
```systemverilog
// 在 S_PAY 開頭加入
if (last_q && !wb_vld_q && (noff5 > 5'd8)) begin
  state_nx = S_IDLE;  // ← 太積極！
end
```

**根因分析**：`last_q` 在最後一個 input beat（beat 12）被載入 wb 時立即設為 1，此時 DUT 仍在處理中間的 message（msg2, msg3）。當非最後一個 output beat 完成後，wb 暫時為空（`wb_vld → 0`），恰好觸發三個條件同時成立：
- `last_q = 1`（最後 input beat 已收）
- `!wb_vld_q = 1`（wb 暫時空）
- `noff5 > 8`（需要 wb 繼續）

導致合法 message 的中間被誤判為「卡死」，FSM 跳回 IDLE，輸出只有 7 beats 而非 14。

**修正**：完全移除 Fix 2，改以更精確的根因修正（見 Bug 6）取代。

---

## Bug 6 — S_PAY 在 `noff5 == 8` 時將 stale `wb_q` 寫入 `wa`（根本原因）

**發現時機**：移除 Fix 2 後，仔細追蹤波形發現 TIMEOUT「got 13」（pkt 3 應有 14 beats）的根本原因。

### 問題描述

**觸發條件**：`noff5 == 8`（即 `off == 0`，當前 message 恰好在 beat 邊界結束），且 `wb_vld_q == 0`（wb 尚未載入下一 beat）。

**問題程式碼**（以 S_PAY last beat 路徑為例）：
```systemverilog
// 原始 S_PAY，noff5 >= 8 分支
if (noff5 >= 5'd8) begin
  off_nx    = noff5[2:0];
  wa_nx     = wb_q;     // ← BUG: wb_q 是 stale（已消耗的舊值）！
  wb_vld_nx = 1'b0;     // ← BUG: 蓋掉 fill block 剛設的 wb_vld_nx = 1
end
```

**always_comb 執行順序**：

```
fill block（先）: wb_nx = s_tdata; wb_vld_nx = 1'b1;
case S_PAY（後）: wa_nx = wb_q(stale); wb_vld_nx = 1'b0;  ← 最後寫優先
```

- `fill` 已將新 beat 載入 `wb_nx`
- `case` 卻把 stale 的 `wb_q` 寫進 `wa_nx`，並蓋掉 `wb_vld_nx = 1`
- posedge 後：`wa = stale_old_data`，`wb = new_beat`，`wb_vld = 0`
- S_HDR 立即用 stale `wa` 解析 header → **ghost message**

### 兩種觸發路徑

#### 路徑 A：Last beat（prem ≤ 8, noff5 = 8, wb_vld = 0）
- S_PAY 輸出最後一個 beat 後，wa 被 stale 值覆寫
- S_HDR 用 stale wa 解析出 ghost header（前一 message 的 payload bytes）
- ghost prem 若在 [8, 32] 範圍內：S_PAY 嘗試輸出 ghost message，最終卡死

**舉例**（pkt 3, msg2 → msg3 邊界）：
```
S_PAY last beat: wa=beat5, wb=beat5(stale), wb_vld=0
fill fires:      wb_nx=beat6 (msg3's first beat)
case overrides:  wa_nx=beat5(stale), wb_vld_nx=0

After posedge:  wa=beat5(stale), wb=beat6, wb_vld=0
S_HDR fires:    hdr = beat5[63:48] = msg2 payload bytes 18-19 ← WRONG!
                Should be beat6[63:48] = msg3 header
```

#### 路徑 B：Non-last beat（prem > 8, off = 0, noff5 = 8, wb_vld = 0）
- 當 S_HDR off=6 促銷後，S_PAY 從 off=0 開始
- 第一個 output beat（8 bytes from wa）觸發：noff5=0+8=8，`m_tvalid = (8≤8||0) = 1`
- 輸出 beat 正確，但 wa 被 stale 覆寫，下一個 beat 輸出錯誤資料

### 修正方案

**修正一：`m_tvalid` 強制非最後 beat 等待 `wb_vld`**

非最後 beat 輸出後必須促銷 wa ← wb，若 wb 還沒就緒就不能輸出：

```systemverilog
// 修正後
// 非最後 beat（prem > 8）永遠需要 wb 才能促銷
// 最後 beat（prem ≤ 8）只在 noff5 > 8 才需要 wb
assign m_tvalid = (state_q == S_PAY) &&
                  (wb_vld_q || (prem_q <= 6'd8 && noff5 <= 5'd8));
```

**修正二：`wa_valid_q` 旗標，防止 S_HDR 解析 stale wa**

在 stale 路徑（noff5=8, wb_vld=0）不更新 `wa_nx` 也不覆蓋 `wb_vld_nx`，改設旗標：

```systemverilog
// S_PAY last beat, noff5 = 8
if (noff5 != 5'd8 || wb_vld_q) begin
  // 正常促銷：wb 有效
  wa_nx       = wb_q;
  wb_vld_nx   = 1'b0;
  wa_valid_nx = 1'b1;
end else begin
  // stale 路徑：讓 fill 的 wb_vld = 1 保留，標記 wa 無效
  wa_valid_nx = 1'b0;
  // wa_nx 不動，wb_vld_nx 不動（fill 的 1 保留）
end
```

**修正三：S_HDR 等待 wb 就緒後才促銷**

```systemverilog
S_HDR: begin
  // off=0 且 wa 無效：新 beat 在 wb 裡，等它就緒再促銷
  if (off_q == 3'd0 && !wa_valid_q) begin
    if (wb_vld_q) begin
      wa_nx       = wb_q;       // 正確 beat 到了，促銷
      wb_vld_nx   = 1'b0;
      wa_valid_nx = 1'b1;
      prem_nx     = wb_q[53:48];  // 解析新 beat 的 header
      if (prem_nx < 6'd8 || prem_nx > 6'd32)
        state_nx = S_IDLE;
      else begin
        off_nx   = 3'd2;
        state_nx = S_PAY;
      end
    end else if (last_q) begin
      state_nx = S_IDLE;   // 最後 beat 也沒來，packet 結束
    end
    // else: 繼續等待

  end else if ((off_q <= 3'd5) || wb_vld_q) begin
    // 正常解析路徑（off 1-5 直接從 wa，off 6-7 從 wb 促銷）
    ...
  end
end
```

**附加效益**：修正後 ghost S_HDR 也被正確處理：

```
msg4 最後 beat 後: off=0, wa_valid=0, wb_vld=0, last_q=1
S_HDR: off=0 && !wa_valid && !wb_vld && last_q → state = S_IDLE ✓
```

Ghost message 不再卡死 FSM，DUT 乾淨地回到 IDLE 等待下一個 packet。

---

## 最終測試結果

所有修正套用至 5 個設計變體（baseline、power、area、throughput、timing）後：

| 測試項目 | 說明 | 結果 |
|---------|------|------|
| Fixed-vector testbench × 5 | 固定向量功能驗證，每變體 12 tests | **60 / 60 PASS** |
| stress（seed=42, 20 pkts）× 5 | 各變體隨機壓力測試 | **5 × 185 PASS** |
| stress_dense（50 pkts, pay 8-12B）| 密集短 message，header 邊界壓力 | **888 / 888 PASS** |
| stress_max（20 pkts, pay 28-32B） | 最大 payload，4-beat output | **156 / 156 PASS** |
| stress_long（200 pkts, pay 8-32B）| 耐久測試，全範圍 payload | **2565 / 2565 PASS** |

**area 變體（byte-serial）**：不受 `noff5==8` stale-wa bug 影響（架構不同），保持 Fix 1 與原有的 bptr=7 escape 邏輯即可。

---

## 修正摘要表

| # | 位置 | 問題 | 修正 |
|---|------|------|------|
| 1 | `stress_tb.sv` | `break` 不被 Icarus 支援 | 改用 `disable` + `done` flag |
| 2 | `stress_tb.sv` | task 內 `return` 不被 Icarus 支援 | 改用 `else` block |
| 3 | `stress_tb.sv` | 比對未遮罩 AXI-S 無效 bytes | 加入 `tkeep_mask` 函數 |
| 4 | 所有 RTL | S_HDR 接受超出規格的 prem | 加入 `prem ∈ [8,32]` 驗證（Fix 1） |
| 5 | 所有 window RTL | Fix 2 誤殺合法 message | 完全移除 Fix 2 |
| 6a | 所有 window RTL | Non-last beat 在 `wb_vld=0` 觸發 | 修改 `m_tvalid`：non-last 強制等待 wb |
| 6b | 所有 window RTL | Last beat stale `wa` 促銷 | 加入 `wa_valid_q` 旗標 + S_HDR 等待邏輯 |
