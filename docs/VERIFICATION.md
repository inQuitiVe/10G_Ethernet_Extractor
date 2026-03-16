# Verification Plan — 10G Ethernet Message Extractor

## 1. DUT Overview

Five RTL variants are verified independently using a shared testbench infrastructure.

| Variant     | File                              | Architecture                                        |
|-------------|-----------------------------------|-----------------------------------------------------|
| baseline    | `rtl/msg_extractor_baseline.sv`   | Double buffer + barrel shifter, combinational output|
| power       | `rtl/msg_extractor_power.sv`      | Same + registered output + wide-bus gating          |
| area        | `rtl/msg_extractor_area.sv`       | Byte-serial accumulator (no barrel shifter)         |
| throughput  | `rtl/msg_extractor_throughput.sv` | Combinational `s_tready`, zero-bubble input         |
| timing      | `rtl/msg_extractor_timing.sv`     | Output pipeline register, halved critical path      |

All variants share the same top-level ports:

```
clk, rst_n
s_tvalid, s_tready, s_tdata[63:0], s_tkeep[7:0], s_tlast   (AXI-S slave)
m_tvalid,           m_tdata[63:0], m_tkeep[7:0], m_tlast   (AXI-S master)
```

`m_tready` is tied to 1 (no downstream backpressure).

---

## 2. Verification Strategy

Two complementary test tiers are used:

| Tier          | Testbench                        | Purpose                                                                     |
|---------------|----------------------------------|-----------------------------------------------------------------------------|
| **Functional**| `sim/msg_extractor_tb.sv`        | Deterministic, hand-crafted vectors; covers edge cases                      |
| **Stress**    | `sim/msg_extractor_stress_tb.sv` | Randomly generated packets; covers rare alignment and boundary combinations |

---

## 3. Functional Test Workload

**Testbench:** `sim/msg_extractor_tb.sv`  
**Automation:** `make <variant>` or `make all`

Twelve hand-crafted test cases are applied to every variant:

| #     | Test Name             | Input Description                              | Verification Focus                                                      |
|-------|------------------------|------------------------------------------------|-------------------------------------------------------------------------|
| 1     | Single 8B message      | 1 message, 8-byte payload, aligned to beat 0   | Basic extract and output                                                |
| 2     | Two messages 8B + 10B  | Two consecutive messages in one packet         | Multi-message, non-aligned offset carry-over                            |
| 3     | Max 32B payload        | 1 message with 32-byte payload                 | Multi-beat output; correct `tkeep` on last beat                         |
| 4     | Input gaps             | `s_tvalid` deasserted mid-packet                | Back-pressure handling; no lost beats                                   |
| 5     | Three 8B back-to-back   | Three 8-byte messages, tight packing           | Dense boundary handling; `off_q` wrap-around                            |
| 6–12  | (7 additional cases)    | Various payload lengths, offsets, and packet lengths | Corner cases: header at word boundary, header straddling two beats, single-byte remainder, etc. |

Each test records an expected beat sequence (data + `tkeep` + `tlast`) and compares it against DUT output after all beats arrive.

---

## 4. Stress Test Workload

**Testbench:** `sim/msg_extractor_stress_tb.sv`  
**Generator:** `sim/scripts/gen_test.py`  
**Automation:** `make stress_all` (full matrix) or `make stress_<scenario>`

### Scenario Definitions

| Scenario   | Packets | Msgs/pkt | Payload (B) | Purpose                                                                 |
|------------|--------:|:--------:|:-----------:|-------------------------------------------------------------------------|
| `default`  |      20 | 1–5      | 8–32        | General mixed traffic                                                   |
| `dense`    |      50 | 4–8      | 8–12        | High message density per packet; stresses `off_q` accumulation          |
| `max`      |      20 | 1–3      | 28–32       | Near-maximum payloads; stresses multi-beat output and last-beat `tkeep` |
| `long`     |     200 | 1–5      | 8–32        | High packet count; exposes rare alignment combinations                  |

Each scenario is run for all five variants (5 × 4 = **20 runs** per seed).

### Test Vector Format

Generated text file; each token on its own line:

```
R              — reset (2 cycles)
I <data> <keep> <last>  — drive one AXI-S input beat
O <data> <keep> <last>  — expect one AXI-S output beat
```

The testbench sends all `I` beats, collects all `O` beats from the DUT, then compares.

---

## 5. Pass / Fail Criteria

### 5.1 Per-Beat Comparison

An output beat **passes** if and only if all three fields match:

```
(got_data & tkeep_mask) === (exp_data & tkeep_mask)
got_tkeep              === exp_tkeep
got_tlast              === exp_tlast
```

`tkeep_mask` zeroes out byte lanes where `tkeep = 0`, matching the AXI-S specification that receivers must ignore invalid bytes.

### 5.2 Per-Packet Outcome

| Outcome   | Condition                                                         |
|-----------|-------------------------------------------------------------------|
| **PASS**  | Every expected beat matches; correct beat count                   |
| **FAIL**  | Any beat mismatch (data, tkeep, or tlast)                         |
| **TIMEOUT**| DUT produced fewer beats than expected within the timeout window |

### 5.3 Simulation-Level Pass Gate

A simulation run **passes** only when:

- `FAIL = 0`
- `TIMEOUT = 0`
- Total PASS count equals the total expected beat count for that run

### 5.4 Full Verification Pass Gate

Verification is considered **complete** when all of the following hold:

| Check              | Requirement                                      |
|--------------------|--------------------------------------------------|
| Functional tests   | 60 / 60 PASS (5 variants × 12 tests)             |
| Stress tests       | 0 FAIL, 0 TIMEOUT across all 20 scenario runs    |
| All five variants  | Each variant passes both tiers independently     |

---

## 6. Running Verification

```sh
# Full functional test for all variants + summary report
make all

# Full stress matrix (5 variants × 4 scenarios) + summary report
make stress_all
make parse

# Single variant, single scenario
make stress_v_baseline SCENARIO=dense SEED=123 N_PKTS=50

# Waveform for debug
make baseline DUMP_WAVE=1
make stress_v_area DUMP_WAVE=1 SCENARIO=max
```

---

## 7. Results

### Functional (seed-independent, fixed vectors)

All five variants pass all 12 test cases: **60 / 60 PASS**.

### Stress (seed = 42)

| Variant     | default (20 pkts) | dense (50 pkts) | max (20 pkts) | long (200 pkts) |
|-------------|:-----------------:|:---------------:|:--------------:|:---------------:|
| baseline    | 185 ✓             | 888 ✓           | 156 ✓         | 2565 ✓          |
| power       | 185 ✓             | 888 ✓           | 156 ✓         | 2565 ✓          |
| area        | 185 ✓             | 888 ✓           | 156 ✓         | 2565 ✓          |
| throughput  | 185 ✓             | 888 ✓           | 156 ✓         | 2565 ✓          |
| timing      | 185 ✓             | 888 ✓           | 156 ✓         | 2565 ✓          |

Total: **18970 / 18970 beat PASS, 0 FAIL, 0 TIMEOUT**

Numbers shown are output beats verified per run; ✓ = 0 FAIL, 0 TIMEOUT.
