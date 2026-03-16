# Debug Log — 10G Ethernet Message Extractor

Complete record of every bug found, root-cause analysis, and fix applied.

---

## Bug 1 — Icarus Verilog: `break` not supported

**Where found:** Vector loading loop and `skip_line` task in `msg_extractor_stress_tb.sv`.

**Error message:**
```
sim/msg_extractor_stress_tb.sv:119: sorry: break statements not supported.
```

**Root cause:** Icarus Verilog has incomplete SystemVerilog support and does not allow `break` inside `while`/`for` loops.

**Fix:**
- Replaced `break` with `disable <block_name>` inside named blocks
- Replaced loop-exit `break` with a `done` flag controlling the `while` condition

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

## Bug 2 — Icarus Verilog: `return` from task not supported

**Where found:** Early-exit `return` inside the `check_packet` task.

**Error message:**
```
sim/msg_extractor_stress_tb.sv:131: error: Cannot "return" from tasks.
```

**Root cause:** Icarus Verilog does not allow `return` statements inside tasks.

**Fix:** Moved the comparison logic into an `else` block, eliminating the need for early return.

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

## Bug 3 — Testbench comparing invalid AXI-S byte lanes strictly

**Where found:** Stress test producing large numbers of false FAILs, e.g.:
```
FAIL: exp d=a185000000000000 k=c0 l=1
      got d=a185000ea07a0000 k=c0 l=1
```
`tkeep=0xC0` means only the top 2 bytes are valid. The DUT outputs non-zero values in the invalid lanes, which is permitted by the AXI-S specification — receivers must ignore bytes where `tkeep=0`.

**Root cause:** The testbench compared the full 64-bit `m_tdata` without masking out bytes where `m_tkeep=0`, causing false FAILs.

**Fix:** Added a `tkeep_mask` function to `msg_extractor_stress_tb.sv`; both expected and actual data are masked before comparison.

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

Comparison:
```systemverilog
mask       = tkeep_mask(exp_k[i]);
exp_masked = exp_d[i]          & mask;
got_masked = out_d[pkt_base+i] & mask;
if (got_masked === exp_masked && out_k[...] === exp_k[i] && ...)
```

---

## Bug 4 — S_HDR accepts out-of-range payload length, enters ghost message

**Where found:** Some packets produced TIMEOUT (DUT output fewer beats than expected), particularly when the last beat contained zero-padded bytes.

**Root cause:** After a packet ends, `wa` still holds leftover payload data from the previous message. Its low bits are misinterpreted as `prem`. If `prem` is 0 or outside the valid range, the FSM enters a ghost `S_PAY` that wastes cycles or outputs garbage.

**Impact:** When the last beat has `tkeep < 0xFF`, the zero-padding bytes are decoded as a zero-length header, causing the FSM to stall or emit spurious output beats before the next real message can proceed.

**Fix (Fix 1 — retained throughout):** Validate `prem_nx` immediately after parsing in `S_HDR`:

```systemverilog
// Applied to all window-based and area variants
prem_nx = hdr[5:0];
if (prem_nx < 6'd8 || prem_nx > 6'd32) begin
  state_nx = S_IDLE;   // invalid length → discard, return to idle
end else begin
  // normal processing
end
```

---

## Bug 5 — Fix 2 (S_PAY stuck-state escape) prematurely terminates valid messages

**Where found:** After applying Fix 1, an additional "stuck-state escape" was added to `S_PAY`. The stress test results got worse:
```
TIMEOUT pkt 3: expected 14 beats, got 7   (previously got 13)
```

**Incorrect Fix 2 logic:**
```systemverilog
// Added at the top of S_PAY
if (last_q && !wb_vld_q && (noff5 > 5'd8)) begin
  state_nx = S_IDLE;  // ← too aggressive
end
```

**Root cause:** `last_q` is set to 1 as soon as the final input beat (beat 12) is loaded into `wb`, even though the DUT is still processing intermediate messages (msg2, msg3). After each non-final output beat completes, `wb` temporarily goes empty (`wb_vld → 0`), causing all three conditions to fire simultaneously:
- `last_q = 1` (last input beat received)
- `!wb_vld_q = 1` (wb momentarily empty)
- `noff5 > 8` (wb needed to continue)

This falsely detected a "stuck" FSM in the middle of a valid message, jumping back to IDLE with only 7 output beats instead of 14.

**Fix:** Removed Fix 2 entirely. The true root cause (Bug 6) was identified and fixed more precisely.

---

## Bug 6 — S_PAY writes stale `wb_q` into `wa` when `noff5 == 8`

**Where found:** After removing Fix 2, waveform tracing of the TIMEOUT "got 13" case (pkt 3, expected 14 beats) revealed the underlying root cause.

### Description

**Trigger condition:** `noff5 == 8` (i.e., `off == 0`, current message ends exactly on a beat boundary) and `wb_vld_q == 0` (the next beat has not yet been loaded into `wb`).

**Buggy code** (S_PAY last-beat path):
```systemverilog
// Original S_PAY, noff5 >= 8 branch
if (noff5 >= 5'd8) begin
  off_nx    = noff5[2:0];
  wa_nx     = wb_q;     // ← BUG: wb_q is stale (already consumed)
  wb_vld_nx = 1'b0;     // ← BUG: overwrites wb_vld_nx = 1 set by fill block
end
```

**`always_comb` last-write-wins ordering:**
```
fill block (first):  wb_nx = s_tdata;   wb_vld_nx = 1'b1;
case S_PAY (later):  wa_nx = wb_q(stale); wb_vld_nx = 1'b0;  ← wins
```

- `fill` has already written the new beat into `wb_nx`
- `case` overwrites `wa_nx` with stale `wb_q` and clobbers `wb_vld_nx` back to 0
- After posedge: `wa = stale_old_data`, `wb = new_beat`, `wb_vld = 0`
- `S_HDR` immediately parses `wa` → **ghost message**

### Two trigger paths

#### Path A: Last beat (prem ≤ 8, noff5 = 8, wb_vld = 0)

- After `S_PAY` outputs the final beat, `wa` is overwritten with the stale value
- `S_HDR` parses the stale `wa` as a ghost header (previous message's payload bytes)
- If ghost `prem` falls within [8, 32]: FSM enters a ghost `S_PAY` and stalls

**Example** (pkt 3, msg2 → msg3 boundary):
```
S_PAY last beat: wa=beat5, wb=beat5(stale), wb_vld=0
fill fires:      wb_nx=beat6 (msg3's first beat)
case overrides:  wa_nx=beat5(stale), wb_vld_nx=0

After posedge:  wa=beat5(stale), wb=beat6, wb_vld=0
S_HDR fires:    hdr = beat5[63:48] = msg2 payload bytes 18-19  ← WRONG
                Should be beat6[63:48] = msg3 header
```

#### Path B: Non-last beat (prem > 8, off = 0, noff5 = 8, wb_vld = 0)

- After `S_HDR` promotes at `off=6`, `S_PAY` starts from `off=0`
- The first output beat (8 bytes from `wa`) triggers: `noff5 = 0+8 = 8`, `m_tvalid` asserts
- That beat is correct, but `wa` is then overwritten with stale data, corrupting subsequent beats

### Fix

**Fix 1: Force non-last beats to wait for `wb_vld`**

A non-last beat requires `wa ← wb` promotion; if `wb` is not yet valid, output must stall:

```systemverilog
// Non-last beats (prem > 8) always need wb for promotion
// Last beat (prem ≤ 8) only needs wb when noff5 > 8
assign m_tvalid = (state_q == S_PAY) &&
                  (wb_vld_q || (prem_q <= 6'd8 && noff5 <= 5'd8));
```

**Fix 2: `wa_valid_q` flag prevents `S_HDR` from parsing a stale `wa`**

On the stale path (`noff5 = 8`, `wb_vld = 0`), do not update `wa_nx` or clobber `wb_vld_nx`; instead set a validity flag:

```systemverilog
// S_PAY last beat, noff5 = 8
if (noff5 != 5'd8 || wb_vld_q) begin
  // normal promotion: wb is valid
  wa_nx       = wb_q;
  wb_vld_nx   = 1'b0;
  wa_valid_nx = 1'b1;
end else begin
  // stale path: preserve fill's wb_vld = 1, mark wa as invalid
  wa_valid_nx = 1'b0;
  // wa_nx unchanged, wb_vld_nx unchanged (fill's 1 is preserved)
end
```

**Fix 3: `S_HDR` waits for `wb` before promoting when `wa` is invalid**

```systemverilog
S_HDR: begin
  // off=0 and wa invalid: the next beat is in wb, wait for it
  if (off_q == 3'd0 && !wa_valid_q) begin
    if (wb_vld_q) begin
      wa_nx       = wb_q;         // correct beat arrived, promote
      wb_vld_nx   = 1'b0;
      wa_valid_nx = 1'b1;
      prem_nx     = wb_q[53:48];  // parse header from fresh wa
      if (prem_nx < 6'd8 || prem_nx > 6'd32)
        state_nx = S_IDLE;
      else begin
        off_nx   = 3'd2;
        state_nx = S_PAY;
      end
    end else if (last_q) begin
      state_nx = S_IDLE;   // no more beats coming, end of packet
    end
    // else: keep waiting

  end else if ((off_q <= 3'd5) || wb_vld_q) begin
    // normal parse path (off 1–5 directly from wa, off 6–7 promote from wb)
    ...
  end
end
```

**Side benefit:** Ghost `S_HDR` at end-of-packet is also handled cleanly:
```
After msg4's last beat: off=0, wa_valid=0, wb_vld=0, last_q=1
S_HDR: off=0 && !wa_valid && !wb_vld && last_q → state = S_IDLE  ✓
```

The FSM no longer stalls on ghost messages; it returns cleanly to IDLE.

---

## Bug 7 — Icarus Verilog: chained range select not supported

**Where found:** Recompiling window-based variants after the `wa_valid_q` fix produced a new error.

**Error message:**
```
rtl/msg_extractor_baseline.sv:116: error: All but the final index in a chain
of indices must be a single value, not a range.
```

**Root cause:** Icarus Verilog does not support chained range selects (`[63:48][5:0]`), which is valid SystemVerilog but not yet implemented in Icarus.

**Buggy code:**
```systemverilog
prem_nx = wb_q[63:48][5:0];   // chain: first select 16 bits, then lower 6 bits
```

**Fix:** Compute the equivalent bit range directly:
```systemverilog
prem_nx = wb_q[53:48];        // equivalent to wb_q[63:48][5:0]
```

Applied to all four window-based variants (baseline, power, throughput, timing).

---

## Final Test Results

All fixes applied to all five design variants (baseline, power, area, throughput, timing).

### Functional Test (fixed vectors)

Each variant runs independently: 5 × 12 tests = **60 / 60 PASS**.

### Stress Test — Full Matrix (5 variants × 4 scenarios = 20 runs, seed = 42)

| variant     | default<br>20 pkts | dense<br>50 pkts | max<br>20 pkts | long<br>200 pkts |
|-------------|:------------------:|:----------------:|:--------------:|:----------------:|
| baseline    | 185 ✓              | 888 ✓            | 156 ✓          | 2565 ✓           |
| power       | 185 ✓              | 888 ✓            | 156 ✓          | 2565 ✓           |
| area        | 185 ✓              | 888 ✓            | 156 ✓          | 2565 ✓           |
| throughput  | 185 ✓              | 888 ✓            | 156 ✓          | 2565 ✓           |
| timing      | 185 ✓              | 888 ✓            | 156 ✓          | 2565 ✓           |

Total: **18970 / 18970 beat PASS, 0 FAIL, 0 TIMEOUT**

> **area variant (byte-serial):** Not affected by the `noff5 == 8` stale-wa bug (different architecture).
> Fix 1 and the original `bptr=7` escape logic are sufficient; `wa_valid_q` is not needed.

---

## Fix Summary

| #   | File                          | Issue                                  | Fix                                              |
|-----|-------------------------------|----------------------------------------|--------------------------------------------------|
| 1   | `sim/msg_extractor_stress_tb.sv` | `break` not supported by Icarus        | Replace with `disable` + `done` flag             |
| 2   | `sim/msg_extractor_stress_tb.sv` | `return` from task not supported       | Replace with `else` block                        |
| 3   | `sim/msg_extractor_stress_tb.sv` | Comparing invalid AXI-S byte lanes     | Add `tkeep_mask` function                        |
| 4   | All RTL                       | `S_HDR` accepts out-of-range `prem`   | Add `prem ∈ [8, 32]` guard (Fix 1)               |
| 5   | All window RTL                | Fix 2 kills valid messages             | Remove Fix 2 entirely                            |
| 6a  | All window RTL                | Non-last beat fires when `wb_vld = 0`  | Restrict `m_tvalid`: non-last waits for `wb`    |
| 6b  | All window RTL                | Last beat promotes stale `wa`          | Add `wa_valid_q` flag + `S_HDR` wait logic       |
| 7   | All window RTL                | Icarus rejects chained range select    | `wb_q[63:48][5:0]` → `wb_q[53:48]`               |
