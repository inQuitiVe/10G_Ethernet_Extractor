# =============================================================================
# Makefile  —  10G Ethernet Message Extractor
#
# ── Functional tests (fixed vectors) ─────────────────────────────────────────
#   make [all]              run all VARIANTS + print functional summary
#                           DUMP_WAVE=1 → also writes VCD to sim/waveform/
#   make <variant>          run one variant  (log → sim/logs/<variant>_func.log)
#   make wave_<variant>     always-wave run for one variant
#   make wave_all           always-wave run for all variants
#
# ── Stress tests (random vectors, via sim/scripts/gen_test.py) ───────────────
#   Primitive (full parameter control):
#     make stress           generate + run one variant  (VARIANT=baseline SEED=42)
#                           → log: sim/logs/<variant>_custom_seed<N>.log
#     make stress DUMP_WAVE=1
#                           → + VCD: sim/waveform/stress_<variant>.vcd
#
#   Single-scenario targets (run on VARIANT, default = baseline):
#     make stress_default   20 pkts,  msgs 1-5,   payload  8-32 B
#     make stress_dense     50 pkts,  msgs 5-15,  payload  8-12 B  (boundary crossing)
#     make stress_max       20 pkts,  msgs 1-3,   payload 28-32 B  (max payload)
#     make stress_long      200 pkts, msgs 1-8,   payload  8-32 B  (endurance)
#                           → logs: sim/logs/<variant>_<scenario>_seed<N>.log
#
#   Per-variant targets (run all 4 scenarios on one variant):
#     make stress_v_<variant>   e.g. stress_v_baseline, stress_v_area ...
#
#   Full matrix (all 5 variants × all 4 scenarios = 20 runs):
#     make stress_all       clears sim/logs/, runs 20 cases, then prints summary
#
#   Parse existing logs (without re-running):
#     make parse            print summary table from sim/logs/
#     make parse LOGDIR=path/to/logs
#
#   Key overrides: VARIANT=  SEED=  DUMP_WAVE=  (N_PKTS / MSGS_* / PAY_* for primitive)
#
# ── File layout ───────────────────────────────────────────────────────────────
#   sim/scripts/   Python utilities (gen_test.py, run_stress.py, parse_stress.py)
#   sim/pattern/   Generated test vector files  (vectors.txt)
#   sim/compiled/  Simulation binaries (.vvp)
#   sim/waveform/  VCD waveform dumps  (.vcd)
#   sim/logs/      Simulation logs     (.log)  functional: <v>_func.log
#                                              stress:     <v>_<scenario>_seed<N>.log
#
# ── Housekeeping ──────────────────────────────────────────────────────────────
#   make clean              remove compiled/, waveform/, pattern/, logs/
#   make clean_logs         remove sim/logs/ only
#
# Edit USER_DEFINE_VARS for VARIANTS and DUMP_WAVE only.
# =============================================================================

-include USER_DEFINE_VARS

VARIANTS  ?= baseline power area throughput timing
DUMP_WAVE ?= 0

# ── User-facing tool paths (override in USER_DEFINE_VARS if needed) ───────────
PYTHON    ?= python
SCRIPTS    = sim/scripts
LOGDIR    ?= sim/logs

# ── Build internals (do not edit) ──────────────────────────────────────────────
SIM         = iverilog
SIM_FLAGS   = -g2012
RUNNER      = vvp
COMPILED    = sim/compiled
WAVE        = sim/waveform
RTL_DIR     = rtl
TB_DIR      = sim
SUB_DIR     = $(RTL_DIR)/submodules

PKG = $(TB_DIR)/pkg_msg_extractor.sv
TB  = $(TB_DIR)/msg_extractor_tb.sv

SUBMODS = \
    $(SUB_DIR)/barrel_shift_64.sv \
    $(SUB_DIR)/axis_out_pipe.sv   \
    $(SUB_DIR)/byte_mux8.sv       \
    $(SUB_DIR)/tkeep_enc.sv       \
    $(SUB_DIR)/win_comb.sv

DEFINE_baseline   =
DEFINE_power      = -DMSG_DESIGN_POWER
DEFINE_area       = -DMSG_DESIGN_AREA
DEFINE_throughput = -DMSG_DESIGN_THROUGHPUT
DEFINE_timing     = -DMSG_DESIGN_TIMING

IVFLAGS = $(SIM_FLAGS)

ifeq ($(OS),Windows_NT)
  MKDIR = mkdir
  RM    = rmdir /s /q
  SLASH = $(subst /,\,$1)
else
  MKDIR = mkdir -p
  RM    = rm -rf
  SLASH = $1
endif

# =============================================================================
.PHONY: all wave_all clean $(VARIANTS) $(addprefix wave_,$(VARIANTS))

# all: compile+run all VARIANTS (respects DUMP_WAVE), then print functional summary
all:
	$(MAKE) $(VARIANTS)
	$(PYTHON) $(SCRIPTS)/parse_stress.py $(LOGDIR)

wave_all: $(addprefix wave_,$(VARIANTS))

$(COMPILED):
	-$(MKDIR) "$(call SLASH,$(COMPILED))"

$(WAVE):
	-$(MKDIR) "$(call SLASH,$(WAVE))"

$(LOGDIR):
	-$(MKDIR) "$(call SLASH,$(LOGDIR))"

# ── Per-variant rules ────────────────────────────────────────────────────────
define VARIANT_RULES

$(COMPILED)/$(1)_func.vvp: $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(TB) | $(COMPILED)
	@echo [compile] $(1)
	$(SIM) $(IVFLAGS) $(DEFINE_$(1)) -o $$@ $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(TB)

$(COMPILED)/$(1)_func_wave.vvp: $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(TB) | $(COMPILED) $(WAVE)
	@echo [compile+wave] $(1)
	$(SIM) $(IVFLAGS) $(DEFINE_$(1)) -DDUMP_VCD -o $$@ $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(TB)

$(1): $(if $(filter 1,$(DUMP_WAVE)),$(COMPILED)/$(1)_func_wave.vvp,$(COMPILED)/$(1)_func.vvp) | $(LOGDIR)
	@echo ============================================================
	@echo   Variant : $(1)
	@echo ============================================================
	$(PYTHON) $(SCRIPTS)/run_stress.py \
	    --logfile "$(LOGDIR)/$(1)_func.log" \
	    --meta "variant=$(1) type=func" \
	    -- $(RUNNER) $(if $(filter 1,$(DUMP_WAVE)),$(COMPILED)/$(1)_func_wave.vvp,$(COMPILED)/$(1)_func.vvp)

wave_$(1): $(COMPILED)/$(1)_func_wave.vvp | $(WAVE) $(LOGDIR)
	@echo ============================================================
	@echo   Variant (wave) : $(1)
	@echo ============================================================
	$(PYTHON) $(SCRIPTS)/run_stress.py \
	    --logfile "$(LOGDIR)/$(1)_func.log" \
	    --meta "variant=$(1) type=func" \
	    -- $(RUNNER) $(COMPILED)/$(1)_func_wave.vvp
	@echo   Waveform -> $(WAVE)/$(1)_func.vcd

endef

$(foreach v,$(VARIANTS),$(eval $(call VARIANT_RULES,$(v))))

clean:
	-$(RM) "$(call SLASH,$(COMPILED))"
	-$(RM) "$(call SLASH,$(WAVE))"
	-$(RM) "$(call SLASH,$(GENDIR))"
	-$(RM) "$(call SLASH,$(LOGDIR))"
	@echo Cleaned.

# =============================================================================
# Stress test infrastructure
# =============================================================================
STRESS_TB  = $(TB_DIR)/msg_extractor_stress_tb.sv
GENDIR     = sim/pattern
VFILE      = $(GENDIR)/$(VARIANT)_$(SCENARIO)_seed$(SEED).txt

# Stress parameters (override on command line)
SEED      ?= 42
N_PKTS    ?= 20
MSGS_MIN  ?= 1
MSGS_MAX  ?= 5
PAY_MIN   ?= 8
PAY_MAX   ?= 32
VARIANT   ?= baseline
SCENARIO  ?= custom

$(GENDIR):
	-$(MKDIR) "$(call SLASH,$(GENDIR))"

.PHONY: gen stress stress_dense stress_max stress_long stress_all_variants stress_sweep \
        $(addprefix stress_v_,$(VARIANTS)) parse clean_logs

gen: | $(GENDIR)
	$(PYTHON) $(SCRIPTS)/gen_test.py \
	    --seed $(SEED) --n-pkts $(N_PKTS) \
	    --msgs-min $(MSGS_MIN) --msgs-max $(MSGS_MAX) \
	    --pay-min $(PAY_MIN) --pay-max $(PAY_MAX) \
	    --output $(VFILE)

# ── Stress compile rules per variant (normal + waveform) ────────────────────
define STRESS_RULES

$(COMPILED)/$(1)_stress.vvp: $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(STRESS_TB) | $(COMPILED)
	@echo [compile-stress] $(1)
	$(SIM) $(IVFLAGS) $(DEFINE_$(1)) \
	    -o $$@ $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(STRESS_TB)

$(COMPILED)/$(1)_stress_wave.vvp: $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(STRESS_TB) | $(COMPILED) $(WAVE)
	@echo [compile-stress+wave] $(1)
	$(SIM) $(IVFLAGS) $(DEFINE_$(1)) -DDUMP_VCD \
	    -o $$@ $(PKG) $(SUBMODS) $(RTL_DIR)/msg_extractor_$(1).sv $(STRESS_TB)

endef

$(foreach v,$(VARIANTS),$(eval $(call STRESS_RULES,$(v))))

# SVVP: select normal or wave binary depending on DUMP_WAVE
SVVP = $(if $(filter 1,$(DUMP_WAVE)),\
           $(COMPILED)/$(VARIANT)_stress_wave.vvp,\
           $(COMPILED)/$(VARIANT)_stress.vvp)

# LOGFILE: one log per (variant, scenario, seed) combination
LOGFILE = $(LOGDIR)/$(VARIANT)_$(SCENARIO)_seed$(SEED).log

# META: metadata string written as first line of log (parsed by parse_stress.py)
META = variant=$(VARIANT) scenario=$(SCENARIO) seed=$(SEED) n_pkts=$(N_PKTS) msgs=$(MSGS_MIN)-$(MSGS_MAX) pay=$(PAY_MIN)-$(PAY_MAX)

# stress: generate vectors, run simulation, tee stdout to log (cross-platform via Python)
stress: gen $(SVVP) | $(LOGDIR)
	@echo ================================================================
	@echo   Stress: variant=$(VARIANT)  scenario=$(SCENARIO)  seed=$(SEED)  n_pkts=$(N_PKTS)
	@echo   msgs=$(MSGS_MIN)-$(MSGS_MAX)  pay=$(PAY_MIN)-$(PAY_MAX) B
	@echo ================================================================
	$(PYTHON) $(SCRIPTS)/run_stress.py \
	    --logfile "$(LOGFILE)" \
	    --meta "$(META)" \
	    -- $(RUNNER) $(SVVP) +vectors=$(VFILE)

# ── Scenario definitions ──────────────────────────────────────────────────────
# Each scenario sets a named group of parameters; VARIANT and SEED are inherited.
STRESS_PARAMS_default = N_PKTS=20  MSGS_MIN=1 MSGS_MAX=5  PAY_MIN=8  PAY_MAX=32
STRESS_PARAMS_dense   = N_PKTS=50  MSGS_MIN=5 MSGS_MAX=15 PAY_MIN=8  PAY_MAX=12
STRESS_PARAMS_max     = N_PKTS=20  MSGS_MIN=1 MSGS_MAX=3  PAY_MIN=28 PAY_MAX=32
STRESS_PARAMS_long    = N_PKTS=200 MSGS_MIN=1 MSGS_MAX=8  PAY_MIN=8  PAY_MAX=32

STRESS_SCENARIOS := default dense max long

.PHONY: stress stress_default stress_dense stress_max stress_long \
        $(addprefix stress_v_,$(VARIANTS)) stress_all gen

# ── Single-scenario targets (honour VARIANT override) ─────────────────────────
stress_default:
	$(MAKE) stress $(STRESS_PARAMS_default) SEED=$(SEED) VARIANT=$(VARIANT) SCENARIO=default

stress_dense:
	$(MAKE) stress $(STRESS_PARAMS_dense) SEED=$(SEED) VARIANT=$(VARIANT) SCENARIO=dense

stress_max:
	$(MAKE) stress $(STRESS_PARAMS_max) SEED=$(SEED) VARIANT=$(VARIANT) SCENARIO=max

stress_long:
	$(MAKE) stress $(STRESS_PARAMS_long) SEED=$(SEED) VARIANT=$(VARIANT) SCENARIO=long

# ── Per-variant target: all 4 scenarios on one variant ────────────────────────
define STRESS_VARIANT_RULES
stress_v_$(1):
	$(MAKE) stress_default VARIANT=$(1) SEED=$(SEED)
	$(MAKE) stress_dense   VARIANT=$(1) SEED=$(SEED)
	$(MAKE) stress_max     VARIANT=$(1) SEED=$(SEED)
	$(MAKE) stress_long    VARIANT=$(1) SEED=$(SEED)
endef

$(foreach v,$(VARIANTS),$(eval $(call STRESS_VARIANT_RULES,$(v))))

# ── Full matrix: all 5 variants × all 4 scenarios = 20 runs ──────────────────
# Removes only stress logs (*_*_seed*.log) so func logs are preserved.
stress_all:
	$(PYTHON) -c "import glob,os; [os.remove(f) for f in glob.glob('$(LOGDIR)/*_*_seed*.log')]"
	$(MAKE) $(addprefix stress_v_,$(VARIANTS))
	$(PYTHON) $(SCRIPTS)/parse_stress.py $(LOGDIR)

# ── Parse existing logs without re-running ────────────────────────────────────
clean_logs:
	-$(RM) "$(call SLASH,$(LOGDIR))"
	@echo Logs cleaned.

parse:
	$(PYTHON) $(SCRIPTS)/parse_stress.py $(LOGDIR)
