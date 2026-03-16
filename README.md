# 10G Ethernet Message Extractor

RTL implementation of a 10G Ethernet message extractor with AXI-Stream interfaces.
Receives a raw Ethernet byte stream and extracts variable-length messages formatted as:

```
[ 2-byte big-endian payload_len ][ payload (8–32 bytes) ]
```

---

## Performance at a Glance

Measured cycle efficiency across five design variants and four stress scenarios (seed = 42).  
`eff = input beats / active cycles` — higher is better; `exp` = total input beats (ideal lower bound).

| Scenario          | exp beats | baseline  | power     | area       | throughput | timing    |
|-------------------|----------:|:---------:|:---------:|:----------:|:----------:|:---------:|
| default (20 pkts) |       182 | 376 (48%) | 398 (46%) | 1420 (13%) | 276 (66%)  | 398 (46%) |
| dense  (50 pkts)  |       777 | 1717 (45%)| 1771 (44%)| 6138 (13%) | 1472 (53%) | 1771 (44%)|
| max    (20 pkts)  |       163 | 328 (50%) | 350 (47%) | 1274 (13%) | 224 (73%)  | 350 (47%) |
| long  (200 pkts)  |      2493 | 5161 (48%)| 5407 (46%)|19572 (13%) | 3731 (67%) | 5407 (46%)|

All 5 variants × 4 scenarios = **20 stress runs**: 18970 / 18970 beat PASS, 0 FAIL, 0 TIMEOUT.

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


Run `make stress_all && make parse` to reproduce.

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Icarus Verilog](https://github.com/steveicarus/iverilog) (`iverilog`, `vvp`) | Simulation |
| Python 3 | Test vector generation & log parsing |
| GNU Make | Build automation |

> **⚠️ Icarus Verilog version requirement**  
> This project uses SystemVerilog syntax (`logic`, `always_ff`, `always_comb`, `typedef enum`, `import pkg::*`).  
> **Icarus Verilog 11.0 or newer** is required. Version 10.x (e.g. 10.2 on CentOS 7) does not support these constructs and will report syntax errors.  
> If your system has an older iverilog, either install iverilog 11+ from source, or use ModelSim (`module load modelsim-se-2021.3` on systems with module support).

---

## Repository Layout

```
10G_Ethernet_Extractor/
├── rtl/
│   ├── msg_extractor_baseline.sv      # Window-based baseline
│   ├── msg_extractor_power.sv         # Power-minimized
│   ├── msg_extractor_area.sv          # Area-minimized (byte-serial)
│   ├── msg_extractor_throughput.sv    # Throughput-optimized
│   ├── msg_extractor_timing.sv        # Timing-optimized
│   └── submodules/                    # Shared RTL components
│       ├── barrel_shift_64.sv
│       ├── axis_out_pipe.sv
│       ├── byte_mux8.sv
│       ├── tkeep_enc.sv
│       └── win_comb.sv
├── sim/
│   ├── pkg_msg_extractor.sv           # Shared type definitions
│   ├── msg_extractor_tb.sv            # Functional testbench (fixed vectors)
│   ├── msg_extractor_stress_tb.sv     # Stress testbench (file-driven)
│   ├── scripts/
│   │   ├── gen_test.py                # Random test vector generator
│   │   ├── run_stress.py              # Cross-platform tee helper
│   │   └── parse_stress.py            # Log parser & summary printer
│   ├── compiled/                      # (generated) Simulation binaries
│   ├── pattern/                       # (generated) Test vector files
│   ├── waveform/                      # (generated) VCD waveform dumps
│   └── logs/                          # (generated) Simulation logs
├── docs/
│   ├── DESIGN.md                      # Architecture & design decisions
│   ├── VERIFICATION.md                # Verification plan & results
│   ├── ASSUMPTIONS.md                 # Protocol & design assumptions
│   └── DEBUG.md                       # Bug history & root-cause analysis
├── Makefile
└── USER_DEFINE_VARS                   # User configuration (edit this)
```

---

## Quick Start

```bash
# 1. Run functional tests for all variants + summary
make all

# 2. Run full stress test matrix (5 variants × 4 scenarios) + summary
make stress_all

# 3. View combined summary of all logs
make parse
```

---

## Configuration

Edit **`USER_DEFINE_VARS`** to change behaviour without touching the Makefile.

```makefile
VARIANTS  = baseline power area throughput timing   # variants for make all / make stress_all
DUMP_WAVE = 0                                        # 1 = generate VCD waveforms

PYTHON    = python     # interpreter (change to python3 if needed)

SEED     = 42    # random seed for stress vector generation
N_PKTS   = 20    # packets per stress run
MSGS_MIN = 1     # messages per packet (min)
MSGS_MAX = 5     # messages per packet (max)
PAY_MIN  = 8     # payload length in bytes (min, valid: 8–32)
PAY_MAX  = 32    # payload length in bytes (max, valid: 8–32)
```

Any parameter can also be overridden on the command line:
```bash
make stress_all SEED=123 DUMP_WAVE=1
```

---

## Make Targets

### Functional Tests

| Command               | Description                                 |
|-----------------------|---------------------------------------------|
| `make all`            | Compile & run all `VARIANTS`, print summary |
| `make <variant>`      | Run one variant (e.g. `make baseline`)      |
| `make wave_<variant>` | Run one variant and write VCD               |
| `make wave_all`       | Run all variants and write VCDs             |

Output logs: `sim/logs/<variant>_func.log`  
Output waveforms: `sim/waveform/<variant>_func.vcd`

### Stress Tests

Stress tests use randomly generated AXI-Stream packet sequences.
Each run writes a log to `sim/logs/` and a vector file to `sim/pattern/`.

#### Pre-defined scenarios

| Scenario   | Packets | Messages/pkt | Payload  | Purpose                                       |
|------------|--------:|:------------:|:--------:|-----------------------------------------------|
| `default`  |      20 | 1–5          | 8–32 B   | General mixed traffic                         |
| `dense`    |      50 | 5–15         | 8–12 B   | High message density; boundary-crossing stress|
| `max`      |      20 | 1–3          | 28–32 B  | Near-maximum payload; multi-beat output       |
| `long`     |     200 | 1–8          | 8–32 B   | High packet count; rare alignment combinations|

#### Commands

| Command                  | Description                                           |
|--------------------------|-------------------------------------------------------|
| `make stress_default`    | `default` scenario on `VARIANT` (default: `baseline`) |
| `make stress_dense`      | `dense` scenario on `VARIANT`                         |
| `make stress_max`       | `max` scenario on `VARIANT`                            |
| `make stress_long`      | `long` scenario on `VARIANT`                           |
| `make stress_v_<variant>`| All 4 scenarios on one variant                        |
| `make stress_all`       | All 4 scenarios × all `VARIANTS` (20 runs)             |

Output logs: `sim/logs/<variant>_<scenario>_seed<N>.log`  
Output patterns: `sim/pattern/<variant>_<scenario>_seed<N>.txt`

#### Primitive target (full parameter control)

```bash
make stress VARIANT=area SCENARIO=custom SEED=99 N_PKTS=100 MSGS_MIN=3 MSGS_MAX=10
```

Add `DUMP_WAVE=1` to any stress command to generate a VCD.

### Reporting

| Command                  | Description                              |
|--------------------------|------------------------------------------|
| `make parse`             | Print summary of all logs in `sim/logs/` |
| `make parse LOGDIR=path/`| Parse logs from a custom directory       |

`parse_stress.py` prints two summary tables — functional and stress:

```
================================================================
  Functional Test Summary  (5 variant(s))
================================================================
+-------------+--------+--------+----------+
|   variant   |  pass  |  fail  |  status  |
+-------------+--------+--------+----------+
| baseline    |     12 |      0 |   PASS   |
...

================================================================
  Stress Test Summary  (20 run(s))
================================================================
+-------------+-----------+------+-----+------+------+---------+----------+
|   variant   |  scenario | seed | pkt | pass | fail | timeout |  status  |
+-------------+-----------+------+-----+------+------+---------+----------+
| baseline    | default   |  42  |  20 |  185 |    0 |       0 |   PASS   |
...
```

### Housekeeping

| Command          | Description                                |
|------------------|--------------------------------------------|
| `make clean`     | Remove `compiled/`, `waveform/`, `pattern/`, `logs/` |
| `make clean_logs`| Remove `sim/logs/` only                    |

---

## Design Variants

| Variant      | File                         | Optimisation goal                               |
|--------------|------------------------------|-------------------------------------------------|
| `baseline`   | `msg_extractor_baseline.sv`  | Reference implementation                        |
| `power`      | `msg_extractor_power.sv`     | Clock-gate inactive datapath, registered output |
| `area`       | `msg_extractor_area.sv`      | Byte-serial processing, no barrel shifter       |
| `throughput` | `msg_extractor_throughput.sv`| Zero input-bubble, combinational `s_tready`     |
| `timing`     | `msg_extractor_timing.sv`    | Pipeline register halves critical path          |

All variants share the same AXI-Stream interface and message format.
Selected at compile time via preprocessor defines (`-DMSG_DESIGN_POWER`, etc.).

---

## Common Workflows

### Run everything from scratch

```bash
make clean
make all          # functional: 5 variants, prints summary
make stress_all   # stress: 20 runs, prints summary
make parse        # view combined func + stress summary
```

### Focus on one variant

```bash
make area                                # functional test
make stress_v_area                       # stress: all 4 scenarios
make stress_dense VARIANT=area           # stress: dense scenario only
```

### Change the random seed

```bash
make stress_all SEED=123
# or set in USER_DEFINE_VARS:  SEED = 123
```

### Debug with waveform

```bash
make wave_baseline                             # functional + VCD
make stress VARIANT=baseline DUMP_WAVE=1       # stress + VCD
# Open sim/waveform/baseline_func.vcd or baseline_stress.vcd in GTKWave
```

### Subset of variants

In `USER_DEFINE_VARS`:
```makefile
VARIANTS = baseline area
```
Then `make all` and `make stress_all` both run only those two.

---

## Output File Naming

All outputs follow `<variant>_<type>[_<detail>].<ext>`.

| File                        | Location         | Name                              |
|-----------------------------|------------------|-----------------------------------|
| Functional binary           | `sim/compiled/`  | `<variant>_func.vvp`              |
| Functional binary (wave)    | `sim/compiled/`  | `<variant>_func_wave.vvp`         |
| Stress binary               | `sim/compiled/`  | `<variant>_stress.vvp`            |
| Stress binary (wave)        | `sim/compiled/`  | `<variant>_stress_wave.vvp`       |
| Test vector                 | `sim/pattern/`   | `<variant>_<scenario>_seed<N>.txt`|
| Functional log              | `sim/logs/`      | `<variant>_func.log`              |
| Stress log                  | `sim/logs/`      | `<variant>_<scenario>_seed<N>.log`|
| Functional VCD              | `sim/waveform/`  | `<variant>_func.vcd`              |
| Stress VCD                  | `sim/waveform/`  | `<variant>_stress.vcd`            |

---

## Further Reading

- [`docs/DESIGN.md`](docs/DESIGN.md) — Architecture, FSM, and datapath details
- [`docs/VERIFICATION.md`](docs/VERIFICATION.md) — Verification plan, workload, and results
- [`docs/ASSUMPTIONS.md`](docs/ASSUMPTIONS.md) — Protocol and design assumptions
- [`docs/DEBUG.md`](docs/DEBUG.md) — Bug history and root-cause analysis
