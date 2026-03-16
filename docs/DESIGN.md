# Design Notes — 10G Ethernet Message Extractor

## Specification

| Item               | Value                                         |
|--------------------|-----------------------------------------------|
| Input / Output     | 64-bit AXI-Stream (Slave / Master)            |
| Message format     | `[2B big-endian payload_len][payload 8–32 B]` |
| Max packet length  | ≤ 1500 B, messages packed contiguously        |
| Output backpressure| None (`m_tready` always 1)                    |
| Byte order         | Big-endian                                    |

---

## Common Architecture

All window-based variants share:

- **Double buffer (`wa_q` / `wb_q`)** — `wa` is the active word, `wb` holds the prefetched word.
- **128→64 Barrel Shifter** — `wide_fill[127 - off_q*8 -: 64]` extracts 8 output bytes from any byte offset.
- **Byte offset (`off_q`, 3 b)** — tracks where the current message starts within `wa`.
- **3-state FSM** — `S_IDLE → S_HDR → S_PAY`, returns to `S_HDR` between messages in the same packet.

**`s_tready`** is `!wb_vld_q` (Baseline / Power / Timing) or combinational (Throughput).

---

## Variant 0 — Baseline

**File:** `rtl/msg_extractor_baseline.sv`

Reference implementation. Combinational output, sequential `s_tready`.

| Register    | Bits | Role                                  |
|-------------|------|---------------------------------------|
| `wa_q`      | 64   | Active word                           |
| `wb_q`      | 64   | Prefetch word                         |
| `wb_vld_q`  | 1    | `wb` valid flag                       |
| `wa_valid_q`| 1    | `wa` valid flag (ghost-message guard) |
| `off_q`     | 3    | Byte offset within `wa`               |
| `prem_q`    | 6    | Remaining payload bytes               |
| `last_q`    | 1    | `s_tlast` received                    |
| `state_q`   | 2    | FSM state                             |

- **Input bubble:** 1 cycle per `wb→wa` promotion (`s_tready` updates next cycle).
- **Output latency:** 0 cycles (combinational path).

---

## Variant 1 — Power-Optimized

**File:** `rtl/msg_extractor_power.sv`

Three changes over Baseline to reduce dynamic power:

1. **Registered output** — `m_tdata` updates only when `m_tvalid` is asserted; stops constant toggling from the combinational path.
2. **Wide-bus gating** — `wide_gated = (state == S_PAY) ? wide_fill : 128'b0`; kills switching in the barrel shifter when idle.
3. **Binary FSM encoding** — fewer state-register transitions.

Trade-off: +1 cycle output latency, slightly larger area.

---

## Variant 2 — Area-Optimized

**File:** `rtl/msg_extractor_area.sv`

Replaces the 128→64 barrel shifter (~800 gates) with a **byte-serial accumulator**:

- Extract 1 byte/cycle from `wa_q` using an 8→1 byte MUX (~64 gates).
- Accumulate into `out_q`; emit when 8 bytes fill or payload ends.

Extra registers vs Baseline: `out_q` (64), `bptr_q` (3), `ocnt_q` (3), `hb0_q` (8), `hgot` (1).

Trade-off: ~50% less combinational area, ~8× lower throughput (byte-serial).

---

## Variant 3 — Throughput-Optimized

**File:** `rtl/msg_extractor_throughput.sv`

Eliminates the 1-cycle input bubble by making `s_tready` combinational:

```sv
logic promoting;
assign promoting =
  ((state_q == S_PAY) && m_tvalid && m_tready && (prem_q > 6'd8)) ||
  ((state_q == S_PAY) && m_tvalid && m_tready && (prem_q <= 6'd8) && (noff5 >= 5'd8)) ||
  ((state_q == S_HDR) && wb_vld_q && (off_q >= 3'd6));

assign s_tready = (state_q == S_IDLE) || !wb_vld_q || promoting;
```

`wb` is filled in the same cycle it is promoted to `wa`, so the input stream never stalls.

Trade-off: deeper `s_tready` combinational path; ~30% throughput gain.

---

## Variant 4 — Timing-Optimized

**File:** `rtl/msg_extractor_timing.sv`

Inserts a pipeline register on the output path to cut the critical path ~in half:

```
Stage 0 (combinational):  wide_fill → 8:1 MUX(64b) → m_tdata_pre → [FF]
Stage 1 (registered):     m_tdata_pre → m_tdata (output)
```

The FSM advances using `m_tvalid_pre` (one cycle ahead) so throughput is unchanged.

Trade-off: +1 cycle output latency, 73-bit extra pipeline FF; estimated fmax improvement ~40–60%.

---

## Variant Comparison

| Metric         | Baseline    | Power       | Area        | Throughput    | Timing        |
|----------------|-------------|-------------|-------------|---------------|---------------|
| Est. gates     | ~1500       | ~1600       | ~800        | ~1700         | ~1600         |
| Critical path  | ~6 FO4      | ~6 FO4      | ~2 FO4      | ~7 FO4        | ~3 FO4        |
| Input bubble   | 1/promotion | 1/promotion | N/A         | 0             | 1/promotion   |
| Output latency | 0 cyc       | +1 cyc      | serial      | 0 cyc         | +1 cyc        |
| Dynamic power  | ref         | ~60%        | ~40%        | ~110%         | ~105%         |
| Best for       | Dev / debug | Low-power   | Area-limited| Max throughput| High-frequency|

---

## Testbench Overview

**Functional:** `sim/msg_extractor_tb.sv` — 12 fixed test cases covering single/multi-message, max payload, input gaps, and back-to-back boundaries.

**Stress:** `sim/msg_extractor_stress_tb.sv` — file-driven, reads random packets from `sim/pattern/`, verifies every output beat with `tkeep` masking.

See `docs/DEBUG.md` for all bugs found during verification.  
See `docs/ASSUMPTIONS.md` for design assumptions.
