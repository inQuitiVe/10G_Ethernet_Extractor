# =============================================================================
# Makefile — Synthesis for 10G Ethernet Message Extractor (Design Compiler)
#
# Usage:
#   make all                  all 4 variants @ default PERIOD
#   make <variant>            one variant  e.g.  make area
#   make all PERIOD=1.8       all 4 variants @ 1.8 ns
#   make timing PERIOD=1.0    timing variant @ 1.0 ns
#   make parse PERIOD=1.8     parse reports for a given period
#   make clean                remove gate/ log/ work/ artifacts
#
# Overrides:
#   PERIOD=<ns>              clock period  (default: 2.0)
#   SYN_EFFORT=low|medium|high            (default: high)
#   DC=dc_shell                           (override if not on PATH)
# =============================================================================

VARIANTS    := area power throughput timing
PERIOD      ?= 2.0
SYN_EFFORT  ?= high
DC          ?= dc_shell
PROJECT_ROOT := $(shell cd .. && pwd)
TCL          := $(shell pwd)/run_dc.tcl

# Filesystem-safe tag:  2.0 → 2p0ns,  1.8 → 1p8ns,  1.0 → 1p0ns
PERIOD_TAG  := $(shell echo $(PERIOD) | sed 's/\\./_/g; s/\\./_/g' | awk '{gsub(/\./,"p"); print $$0"ns"}')

.PHONY: all $(VARIANTS) parse clean

all: $(VARIANTS)
	@bash parse_reports.sh log/$(PERIOD_TAG)

define SYN_RULE
$(1):
	@echo "============================================================"
	@echo "  Variant: $(1)   Period: $(PERIOD) ns"
	@echo "============================================================"
	$(DC) -f $(TCL) \
	      -x "set top_module msg_extractor_$(1); \
	          set rtlPath {$(PROJECT_ROOT)}; \
	          set filelist_path {syn/filelists/filelist_$(1)}; \
	          set syn_effort $(SYN_EFFORT); \
	          set clock_period $(PERIOD)"
endef

$(foreach v,$(VARIANTS),$(eval $(call SYN_RULE,$(v))))

parse:
	@bash parse_reports.sh log/$(PERIOD_TAG)

clean:
	rm -rf gate log work
	@echo "Cleaned gate/ log/ work/"
