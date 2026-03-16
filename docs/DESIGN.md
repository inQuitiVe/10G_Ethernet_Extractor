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

| Metric             | Baseline    | Power       | Area        | Throughput    | Timing        |
|--------------------|-------------|-------------|-------------|---------------|---------------|
| Est. gates         | ~1500       | ~1600       | ~800        | ~1700         | ~1600         |
| Critical path      | ~6 FO4      | ~6 FO4      | ~2 FO4      | ~7 FO4        | ~3 FO4        |
| Input bubble       | 1/promotion | 1/promotion | N/A         | 0             | 1/promotion   |
| Output latency     | 0 cyc       | +1 cyc      | serial      | 0 cyc         | +1 cyc        |
| Dynamic power      | ref         | ~60%        | ~40%        | ~110%         | ~105%         |
| Best for           | Dev / debug | Low-power   | Area-limited| Max throughput| High-frequency|

### Measured Cycle Efficiency (seed = 42)

`eff = input beats / active cycles × 100%`  
Active cycles = first input beat → last output beat, summed over all packets.

| Scenario         | exp beats | baseline  | power     | area      | throughput | timing    |
|------------------|----------:|:---------:|:---------:|:---------:|:----------:|:---------:|
| default (20 pkt) |       182 | 376 (48%) | 398 (46%) | 1420 (13%)| 276 (66%)  | 398 (46%) |
| dense  (50 pkt)  |       777 | 1717 (45%)| 1771 (44%)| 6138 (13%)| 1472 (53%) | 1771 (44%)|
| max    (20 pkt)  |       163 | 328 (50%) | 350 (47%) | 1274 (13%)| 224 (73%)  | 350 (47%) |
| long  (200 pkt)  |      2493 | 5161 (48%)| 5407 (46%)|19572 (13%)| 3731 (67%) | 5407 (46%)|

Key observations:
- **throughput** achieves 53–73% efficiency by eliminating input bubbles (combinational `s_tready`).
- **baseline / power / timing** settle around 45–50%: one stall cycle per `wb→wa` promotion.
- **area** runs at ~13%: byte-serial processing takes ~8× more cycles than input beats.
- **power** and **timing** share identical cycle counts (both add only a registered output stage).

### PPA & Energy — Synthesis Results (Synopsys DC, TSMC 65 nm)

Workload: **max** scenario (20 pkts, 163 exp beats). Cycles: area 1274, power/timing 350, throughput 224.  
Energy = Dynamic Power × cycles × clock period. ⚠️ 0.5 ns: all variants have timing violations.

#### 1.8 ns target (555 MHz) — timing **MET**

| Variant        | Area (um²)       | Dyn. Power (uW)  | Energy (nJ)      | Cycles |
|----------------|:----------------:|:----------------:|:----------------:|:------:|
| **area**       | **1938**         | **265**          | 608              | 1274   |
| power          | 3265             | **301**          | **189**          | 350    |
| throughput     | 2670             | 345              | **139**          | 224    |
| timing         | 3078             | 346              | 218              | 350    |

#### 0.5 ns target (2 GHz) — timing VIOLATED

| Variant        | Area (um²)       | Dyn. Power (uW)  | Energy (nJ)      | Worst Slack (ns) |
|----------------|:----------------:|:----------------:|:----------------:|:----------------:|
| **area**       | **3040**         | **1250**         | **797**          | −0.132           |
| power          | 5235             | 2219             | 388              | −0.126           |
| throughput     | 4559             | 1562             | **175**          | −0.229           |
| timing         | 4720             | 1657             | 290              | **−0.104**       |

**Key observations:**

- **area** achieves the smallest die footprint at 1.8 ns (**1938 um²**, 41% less than the next smallest).
- **power** delivers the lowest absolute dynamic power at 1.8 ns (**301 uW**). Although its instantaneous power is only marginally higher than `area` (301 vs 265 uW, +14%), the window-based architecture completes the workload in just 350 cycles versus 1274 for `area`, yielding **3.2× lower energy (189 nJ vs 608 nJ)**. 
- **throughput** wins on energy-per-job at both frequencies (**139 nJ @ 1.8 ns, 175 nJ @ 0.5 ns**) because its combinational `s_tready` eliminates input bubbles, cutting cycles to 224 — fewest of all window variants.
- **timing** has the least-violated slack at 0.5 ns (**−0.104 ns**), confirming the output-pipeline register successfully halves the critical path depth compared to baseline.

---

## Testbench Overview

**Functional:** `sim/msg_extractor_tb.sv` — 12 fixed test cases covering single/multi-message, max payload, input gaps, and back-to-back boundaries.

**Stress:** `sim/msg_extractor_stress_tb.sv` — file-driven, reads random packets from `sim/pattern/`, verifies every output beat with `tkeep` masking.

See `docs/DEBUG.md` for all bugs found during verification.  
See `docs/ASSUMPTIONS.md` for design assumptions.
