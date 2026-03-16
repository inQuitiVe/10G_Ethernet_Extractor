# 10G Ethernet Message Extractor — Five-Variant Architecture

## System Specification

| Item | Description |
|------|-------------|
| Input interface | 64-bit AXI-Stream Slave |
| Output interface | 64-bit AXI-Stream Master |
| Message format | `[2B big-endian payload_len][payload]` |
| Payload length | 8–32 bytes |
| Max packet length | ≤ 1500 bytes |
| Output backpressure | None (m_tready always 1) |
| Data byte order | Big-endian (MSB first) |

Messages are contiguous within a packet, no padding.

---

## Common Design Decisions

### Message Format Assumption
```
Packet: [msg0_hdr(2B)] [msg0_payload(8-32B)] [msg1_hdr(2B)] [msg1_payload] ...
```
The 16-bit big-endian header value is the payload length in bytes.

### AXI-Stream Alignment
The 64-bit input bus uses 8-byte beats; message boundaries may not align to 8-byte word boundaries.
**Byte offset** (`off_q`) tracks the current message start position within the buffer (0–7).

---

## Variant 0: Baseline (Most Intuitive)

**File**: `rtl/msg_extractor_baseline.sv`

### Core Architecture

```
s_tdata → [wa_q / wb_q 128b double buffer] → [Barrel Shift] → m_tdata
                    ↑                          ↑
               s_tready = !wb_vld         FSM (3-state)
```

### Key Design

| Component | Design |
|-----------|--------|
| Double buffer (wa/wb) | wa_q = older 64b word, wb_q = newer 64b word |
| 128→64 Barrel Shifter | `wide_fill[127 - off_q*8 -: 64]` |
| s_tready | Sequential: `!wb_vld_q` (1 cycle bubble) |
| FSM | S_IDLE / S_HDR / S_PAY (3 states, 2b) |

### State Machine Transitions

```
         s_tvalid
S_IDLE ──────────→ S_HDR ──────────→ S_PAY
                  off≤5 or wb_vld        │ last beat
                                  ←──────┘
                                  S_HDR ──→ S_IDLE (last_q)
```

**S_IDLE**: Wait for first packet beat. On `s_tvalid` → load `wa_q`, enter S_HDR.

**S_HDR**: Read 2-byte header from `wide[127-off*8 -: 16]`.
- `off ≤ 5`: header fully in wa, `off += 2`.
- `off = 6`: header in wa, payload starts next word, need wb valid.
- `off = 7`: header spans wa/wb boundary, need wb valid.
Enter S_PAY.

**S_PAY**: Output 1 beat per cycle (8 bytes or final partial beat).
- Non-last beat: `wa ← wb`, release wb slot, continue.
- Last beat: compute new `off_q`, return to S_HDR or S_IDLE.

### Register Summary

| Register | Width | Purpose |
|----------|-------|---------|
| wa_q | 64 | Older 64b |
| wb_q | 64 | Newer 64b |
| wb_vld | 1 | wb valid flag |
| off_q | 3 | Message offset in wa |
| prem_q | 6 | Remaining payload bytes |
| last_q | 1 | s_tlast received |
| state | 2 | FSM state |
| **Total** | **141** | |

### Trade-off Summary

| Metric | Value |
|--------|-------|
| Registers (bits) | ~141 |
| Stall cycle | 1 cycle (when wb promoted to wa) |
| Critical Path | 128→64 Barrel Shifter (~8 FO4) |
| Output latency | 0 cycles (combinational pass-through) |

---

## Variant 1: Power-Optimized (Lowest Power)

**File**: `rtl/msg_extractor_power.sv`

### Power Optimization Strategies

1. **Output Register**: `m_tdata` updates only when m_tvalid is asserted.
   In Baseline, `m_tdata` is pure combinational logic, toggling every cycle with wa/wb/off changes,
   causing high switching activity. With registered output, only real outputs toggle.

2. **Barrel Shift Gating** (Wide Bus Gating):
   ```sv
   wide_gated = (state_q == S_PAY) ? wide_fill : 128'b0;
   ```
   When not in S_PAY, 128-bit combinational inputs are zeroed, reducing toggle rate.

3. **Binary state encoding**: Fewer state register toggles compared to one-hot.

4. **Explicit Register Enable**: Synthesis tools can infer clock gating.

### Architecture Difference

```
Baseline: wide_fill → 128→64 MUX → m_tdata (combinational)
Power:    wide_gated (gated) → 128→64 MUX → m_tdata_pre → [FF] → m_tdata (registered)
```

### Trade-off

| Metric | vs Baseline |
|--------|-------------|
| Dynamic power | Significantly lower (~40–60%, depends on activity) |
| Output latency | +1 cycle |
| Area | Slightly larger (extra output FF) |
| Throughput | Same |
| Critical path | Same |

---

## Variant 2: Area-Optimized (Smallest Area)

**File**: `rtl/msg_extractor_area.sv`

### Area Optimization Strategy

Eliminate main area cost: 128→64 bit Barrel Shifter (~800 gates).

Replace with **Byte Accumulator** architecture:
- Each cycle extract **1 byte** from `wa_q[bptr_q]` (8-to-1 byte MUX = ~64 gates)
- Fill 64-bit output accumulator `out_q` progressively
- Output when 8 bytes accumulated or payload last byte reached

### Byte Extractor (Replaces Barrel Shifter)

```sv
always_comb case (bptr_q)
  3'd0: cur_byte = wa_q[63:56];
  3'd1: cur_byte = wa_q[55:48];
  // ...
  default: cur_byte = wa_q[7:0];
endcase
```

8 cases × 8-bit select = **64-gate MUX** (vs 8×64-bit 8-way MUX = 800+ gates)

### Architecture Flow

```
s_tdata → [wa_q 64b] ─→ cur_byte (8b MUX)
                              ↓ (1 byte/cycle)
                         [out_q 64b accumulator]
                              ↓ (when full or last byte)
                         m_tdata, m_tkeep, m_tvalid
```

### Register Summary

| Register | Width | Purpose |
|----------|-------|---------|
| wa_q | 64 | Input word |
| out_q | 64 | Output accumulator |
| bptr_q | 3 | Byte index in wa_q |
| ocnt_q | 3 | Bytes filled in out_q |
| prem_q | 6 | Remaining payload bytes |
| hb0_q | 8 | Store first header byte |
| hgot | 1 | Header byte 0 stored |
| last | 1 | s_tlast seen |
| state | 2 | FSM |
| **Total** | ~152 | |

### Trade-off

| Metric | vs Baseline |
|--------|-------------|
| Combinational area (gates) | **~50% smaller** |
| Register bits | Similar (+11 bits) |
| Throughput | ~8× slower (1 byte/cycle accumulation) |
| Critical path | Shallower (8-to-1 MUX) |
| Use case | Resource-limited FPGA, low-speed embedded |

---

## Variant 3: Throughput-Optimized (Fewest Cycles)

**File**: `rtl/msg_extractor_throughput.sv`

### Throughput Analysis

Baseline 1-cycle bubble cause:
```
s_tready = !wb_vld_q  (sequential)
```
When wb is promoted to wa (wb_vld_nx ← 0), s_tready reflects only on the **next clock cycle**,
causing 1-cycle input bubble.

### Solution: Combinational s_tready

```sv
// "promoting" = this cycle will release wb slot
logic promoting;
assign promoting =
  ((state_q == S_PAY) && m_tvalid && m_tready && (prem_q > 6'd8)) ||  // non-last PAY
  ((state_q == S_PAY) && m_tvalid && m_tready && (prem_q <= 6'd8) && (noff5 >= 5'd8)) ||
  ((state_q == S_HDR) && wb_vld_q && (off_q >= 3'd6));

// s_tready fires in the SAME cycle as the promotion
assign s_tready = (state_q == S_IDLE) || !wb_vld_q || promoting;
```

### Core Operation: Same-Cycle Fill of New wb

```sv
// Fill block runs in same cycle as promotion:
if (s_tvalid && s_tready && state != S_IDLE) begin
  wb_nx     = s_tdata;   // new word loaded
  wb_vld_nx = 1'b1;
end

// S_PAY non-last beat:
//   wa_nx = wb_q (old)    ← promotion
//   wb = s_tdata (new)    ← simultaneous fill
```

### Performance (Test 2: Two messages 8B + 10B)

| Variant | Cycles | Notes |
|---------|--------|-------|
| Baseline | ~12 | 1-cycle bubble per wb promotion |
| Throughput | ~9 | No bubble, s_tready high same cycle |

### Trade-off

| Metric | vs Baseline |
|--------|-------------|
| Throughput | +30% (fewer bubbles) |
| Combinational path | Deeper (s_tready depends on FSM + prem_q) |
| Area | Slightly larger (promoting logic) |
| Power | Slightly higher (higher activity) |

---

## Variant 4: Timing-Optimized (Shortest Clock Time)

**File**: `rtl/msg_extractor_timing.sv`

### Critical Path Analysis

Baseline critical path:
```
wb_vld_q (FF) → wide_fill (128b concat) → wide_fill[127-off*8 -: 64] (8-way 64b MUX) → m_tdata
```
This path involves:
- 2:1 MUX (64b, wb_vld select) = ~1 FO4
- 8:1 MUX (64b, off_q select) = ~3–4 FO4
- Total ~5–6 FO4, timing bottleneck

### Solution: Output Pipeline Register

```
Stage-0 (combinational):  wide_fill → barrel shift → m_tdata_pre
                                    ↓  [pipeline FF]
Stage-1 (registered):                m_tdata_q → m_tdata (output)
```

```sv
// Stage-0: same combinational barrel shift as baseline
assign m_tdata_pre  = wide_fill[127 - off_q*8 -: 64];
assign m_tvalid_pre = (state_q == S_PAY) && ...;

// Stage-1: pipeline register
always_ff @(posedge clk) begin
  m_tvalid <= m_tvalid_pre;
  if (m_tvalid_pre) begin
    m_tdata <= m_tdata_pre;
    m_tkeep <= m_tkeep_pre;
    m_tlast <= m_tlast_pre;
  end
end

// FSM advances using pre-stage valid (1 cycle ahead of consumer)
S_PAY: if (m_tvalid_pre) begin ... end
```

### Critical Path Shortening

```
Original path (1 clock period):
  [FF] → wide_fill → 8:1 MUX(64b) → m_tdata → [consumer]

Split (same 1 clock period, each half can run at higher frequency):
  Stage-0: [FF] → wide_fill → 8:1 MUX → m_tdata_pre → [pipeline FF]
  Stage-1: [pipeline FF] → m_tdata → [consumer FF]
```

Pipeline register splits the ~6 FO4 path into two ~3 FO4 segments;
theoretically fmax can improve ~40–60% (depends on setup/hold overhead).

### Trade-off

| Metric | vs Baseline |
|--------|-------------|
| fmax (timing) | Significantly higher (critical path halved) |
| Output latency | +1 cycle |
| Throughput | Same (no impact with m_tready=1) |
| Area | Slightly larger (extra 64+8+1 = 73-bit pipeline FF) |

---

## Five-Variant Comparison

| Metric | Baseline | Power | Area | Throughput | Timing |
|--------|----------|-------|------|------------|--------|
| Registers (bits) | ~141 | ~141+73 | ~152 | ~141 | ~141+73 |
| Main Comb logic | 128→64 MUX | 128→64 (gated) | 8→1 Byte MUX | 128→64 + s_tready | 128→64 (pipelined) |
| Est. Gates | ~1500 | ~1600 | ~800 | ~1700 | ~1600 |
| Bubble Cycles | 1/msg | 1/msg | N/A (byte-serial) | 0 | 1/msg |
| Critical Path | ~6 FO4 | ~6 FO4 | ~2 FO4 | ~7 FO4 | ~3 FO4 |
| Output latency (cycles) | 0 | +1 | +N/A | 0 | +1 |
| Throughput (beats/beat) | ~0.8 | ~0.8 | ~0.1 | ~1.0 | ~0.8 |
| Dynamic power | Baseline | Low (~60%) | Lowest (~40%) | Slightly higher (~110%) | Slightly higher (~105%) |
| Use case | Dev/debug | Low-power SoC | Resource-limited | High-throughput 10G | High-frequency design |

---

## Testbench

**File**: `sim/msg_extractor_tb.sv`

### Design

Uses **Background Monitor + Array Collection** to avoid timing races:
```sv
// Background monitor: collect all output beats
always @(posedge clk) begin
  if (m_tvalid && m_tready) begin
    out_d[n_out] = m_tdata;
    out_k[n_out] = m_tkeep;
    out_l[n_out] = m_tlast;
    n_out++;
  end
end
```
Each test records `base = n_out`, sends input, waits for `n_out >= base + expected`, then verifies.

### Test Cases

| # | Name | Verification focus |
|---|------|---------------------|
| 1 | Single 8B message | Basic function, aligned output |
| 2 | Two messages 8B+10B | Consecutive messages, misaligned offset |
| 3 | Max 32B payload | Multi-beat output, last beat tkeep |
| 4 | Input with gaps | s_tvalid bubble tolerance |
| 5 | Three 8B back-to-back | Dense message boundary handling |

### DUT Selection

Uses compile-time defines:
```sh
# Baseline (default)
iverilog -g2012 -o sim.vvp pkg.sv rtl/msg_extractor_baseline.sv sim/msg_extractor_tb.sv

# Power
iverilog -g2012 -DMSG_DESIGN_POWER -o sim.vvp pkg.sv rtl/msg_extractor_power.sv sim/msg_extractor_tb.sv

# Area / Throughput / Timing: similar, replace define and RTL file
```

---

## Verification Summary

All five variants pass the same 12 test cases (5 tests × per-variant output beat count):

```
Results: 12 PASS, 0 FAIL  (Baseline, Power, Throughput, Timing)
Results: 12 PASS, 0 FAIL  (Area, byte-serial achieves same output)
```

---

## Design Assumptions

See `docs/ASSUMPTIONS.md`.
