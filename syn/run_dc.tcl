# =============================================================================
# run_dc.tcl — Design Compiler synthesis for 10G Ethernet Message Extractor
#
# Invocation (called by Makefile):
#   dc_shell -f syn/run_dc.tcl \
#            -x "set top_module msg_extractor_area; \
#                set filelist_path syn/filelists/filelist_area; \
#                set syn_effort high"
#
# Supported variants: area  power  throughput  timing
# =============================================================================
if { ![info exists top_module] }    { set top_module    msg_extractor_area }
if { ![info exists rtlPath] }       { set rtlPath       [file normalize [file join [pwd] ..]] }
if { ![info exists filelist_path] } { set filelist_path "syn/filelists/filelist_area" }
if { ![info exists syn_effort] }    { set syn_effort    high }
if { ![info exists clock_period] }  { set clock_period  2.0  }
if { ![info exists syn_focus] }     { set syn_focus     default }

# Derive a filesystem-safe tag:  2.0 → 2p0ns,  1.8 → 1p8ns,  1.0 → 1p0ns
set period_tag "[regsub -all {\.} $clock_period p]ns"

set filelist_full [file join $rtlPath $filelist_path]

# Read RTL file list (skip blank lines and comment lines)
set rtl_files {}
if { [file exists $filelist_full] } {
    set f [open $filelist_full r]
    while { [gets $f line] >= 0 } {
        set line [string trim $line]
        if { $line == "" || [string match "//*" $line] } { continue }
        if { [string match "./*" $line] } { set line [string range $line 2 end] }
        lappend rtl_files $line
    }
    close $f
} else {
    echo "ERROR: filelist not found: $filelist_full"
    exit 1
}

# Target library — TSMC 65 nm GP (worst-case)
set target_library /home/linux/ieng6/ECE260B_WI26_A00/public/PDKdata/db/tcbn65gpluswc.db
set link_library   $target_library
set symbol_library {}
set wire_load_mode enclosed
set timing_use_enhanced_capacitance_modeling true

set search_path [concat $rtlPath $search_path]
set link_library [concat * $link_library]

set synthetic_library {}
set link_path [concat $link_library $synthetic_library]
set dont_use_cells 1
set dont_use_cell_list ""

remove_design -all
if {![file exists work]}               { exec mkdir -p work }
if {![file exists log/$period_tag]}    { exec mkdir -p log/$period_tag }
if {![file exists gate/$period_tag]}   { exec mkdir -p gate/$period_tag }
set_svf work/default.svf

sh date
sh hostname
sh uptime

set compile_effort                   "high"
set compile_no_new_cells_at_top_level false
set hdlin_enable_vpp                  true
set hdlin_auto_save_templates         false

define_design_lib WORK -path work/.template
set verilogout_single_bit false

# Analyze RTL — SystemVerilog source files
foreach vfile $rtl_files {
    set fullpath [file join $rtlPath $vfile]
    analyze -format sverilog -lib WORK $fullpath
}

elaborate $top_module -lib WORK -update
current_design $top_module

if { $syn_focus == "power" } {
    set_cost_priority -power
    set_dynamic_optimization true
    set_leakage_optimization false
    set compile_clock_gating_through_hierarchy true
    set_optimize_registers true
    set_app_var power_opto true
} else {
    set_optimize_registers true
    set_cost_priority -delay
}

link

# Apply timing constraints inline (parameterised by clock_period)
# For aggressive timing (<= 0.5 ns): reduce I/O budget to maximize internal path margin
if { $clock_period <= 0.5 } {
    set io_delay 0.1
} else {
    set io_delay 0.2
}
create_clock -name clk -period $clock_period [get_ports clk]
set_input_delay  -clock [get_clocks clk] -max $io_delay \
    [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -clock [get_clocks clk] -max $io_delay [all_outputs]
propagate_constraints

current_design $top_module

# Always set DRC cost; power mode keeps -power as primary via earlier set_cost_priority -power
set_cost_priority {max_transition max_fanout max_delay max_capacitance}
set_fix_multiple_port_nets -all -buffer_constants
set_fix_hold [all_clocks]

# Critical-path optimizations when clock_period <= 0.5 ns
# (Avoid set_max_fanout — can force buffers that add delay on critical path)

set_driving_cell -lib_cell BUFFD8 -pin Z [all_inputs]
foreach_in_collection p [all_outputs] {
    set_load 0.050 $p
}

set compile_effort                      "high"
set_app_var ungroup_keep_original_design true
set_register_merging [get_designs $top_module] false
set compile_seqmap_propagate_constants       false
set compile_seqmap_propagate_high_effort     false

foreach_in_collection design [get_designs "*"] {
    current_design $design
    set_fix_multiple_port_nets -all
}
current_design $top_module

# Compile
echo "========================================================"
echo " Variant      : $top_module"
echo " Clock period : $clock_period ns  ($period_tag)"
echo " Syn focus    : $syn_focus"
echo " Synthesis    : $syn_effort"
echo "========================================================"

if { $syn_focus == "power" } {
    # Power-first: same compile as default (retime+exact_map) but with -power cost priority
    compile_ultra -retime -gate_clock -exact_map
} elseif { $syn_effort == "low" } {
    compile -map_effort low
} elseif { $syn_effort == "medium" } {
    compile -map_effort medium
} elseif { $clock_period <= 0.5 } {
    # Critical-path-first: timing_high_effort_script for aggressive timing closure
    compile_ultra -retime -gate_clock -exact_map -timing_high_effort_script
} else {
    compile_ultra -retime -gate_clock -exact_map
}

current_design $top_module
change_names -rules verilog -hierarchy

write -format verilog -hier -output \
    [format "gate/%s/%s.out.v" $period_tag $top_module]

# Write reports
redirect [format "log/%s/%s_area.rep"   $period_tag $top_module] { report_area }
redirect -append [format "log/%s/%s_area.rep" $period_tag $top_module] \
    { report_reference }
redirect [format "log/%s/%s_power.rep"  $period_tag $top_module] \
    { report_power }
redirect [format "log/%s/%s_timing.rep" $period_tag $top_module] \
    { report_timing -path full -max_paths 100 -nets -transition_time \
                    -capacitance -significant_digits 3 -nosplit }

# Quick summary to stdout
set inFile [open log/${period_tag}/${top_module}_area.rep]
while { [gets $inFile line] >= 0 } {
    if { [regexp {Total cell area:} $line] } { set AREA [lindex $line 3] }
}
close $inFile
set inFile [open log/${period_tag}/${top_module}_power.rep]
while { [gets $inFile line] >= 0 } {
    if { [regexp {Total Dynamic Power} $line] } { set PWR  [lindex $line 4] }
    if { [regexp {Cell Leakage Power}  $line] } { set LEAK [lindex $line 4] }
}
close $inFile

echo "========================================================"
echo " Results for $top_module  @ $clock_period ns"
if { [info exists AREA] } { echo "   Total cell area   : $AREA um2" }
if { [info exists PWR]  } { echo "   Total dyn. power  : $PWR"      }
if { [info exists LEAK] } { echo "   Cell leakage pwr  : $LEAK"     }
echo "========================================================"

set unmapped [get_designs -filter "is_unmapped == true" $top_module]
if { [sizeof_collection $unmapped] != 0 } {
    echo "****************************************************"
    echo "* ERROR: Compile finished with unmapped logic.     *"
    echo "****************************************************"
}

sh date
sh uptime

# Move DC runtime artifacts into work/
foreach f {command.log filenames.log} {
    if { [file exists $f] } { file rename -force $f work/$f }
}
foreach d [glob -nocomplain alib-*] {
    if { [file exists work/$d] } { file delete -force work/$d }
    file rename -force $d work/$d
}

echo "run_dc.tcl completed successfully — $top_module @ $clock_period ns"
exit
