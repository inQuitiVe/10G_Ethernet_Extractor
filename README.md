# 10G Ethernet Message Extractor

RTL implementation of a 10G Ethernet message extractor with AXI-Stream interfaces.
Receives a raw Ethernet byte stream and extracts variable-length messages formatted as:

```
[ 2-byte big-endian payload_len ][ payload (8–32 bytes) ]
```

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Icarus Verilog](https://github.com/steveicarus/iverilog) (`iverilog`, `vvp`) | Simulation |
| Python 3 | Test vector generation & log parsing |
| GNU Make | Build automation |

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
