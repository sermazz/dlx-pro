#########################################################################################
##
##					DLX ARCHITECTURE - Custom Implementation (PRO version)
##								Politecnico di Torino
##						  Microelectronic Systems, A.Y. 2018/19
##							  Prof. Mariagrazia Graziano
##
## Author: Sergio Mazzola
## Contact: s.mazzola@outlook.com
## 
## File: post_syn_simulation.tcl
## Date: September 2019
## Brief: TCL script for ModelSim to compile and simulate the post-synthesis DLX netlist;
##		  the design is synthetized with NangateOpenCellLibrary technology library, thus
##		  the VHDL (Vital standard) libraries are compiled before the VHDL post-synthesis
##		  netlist. During simulation, switching activity information is collected and
##		  annotated in SAIF and VCD formats for post-synthesis power optimization and
##		  power analysis of physical design
##
#########################################################################################

set projDir {..}
set libsDir "${projDir}/libs"
set srcDir "${projDir}/src"
set synDir "${projDir}/syn"

# Create nangate ModelSim library
if {![file exists "./nangateopencelllibrary"]} {
	vlib nangateopencelllibrary
	vmap nangateopencelllibrary nangateopencelllibrary
}

set outputsDir "./outputs"
if {![file exists $outputsDir]} {
	file mkdir $outputsDir
}

###############################################################
#                     Design compilation                      #
###############################################################

# Compile source files for technology library
vcom -reportprogress 300 -work NangateOpenCellLibrary "${libsDir}/NangateOpenCellLibrary/Vital/NangateOpenCellLibrary_tables.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${libsDir}/NangateOpenCellLibrary/Vital/NangateOpenCellLibrary_components.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${libsDir}/NangateOpenCellLibrary/Vital/NangateOpenCellLibrary_attribute.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${libsDir}/NangateOpenCellLibrary/Vital/NangateOpenCellLibrary.vhd"
# Compile post-synthesis DLX netlist
vcom -reportprogress 300 -work NangateOpenCellLibrary "${synDir}/netlists/DLX_postsyn_ungroup.vhdl"

# Compile other dependencies for simulation wrapper (non-synthesized memories)
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/000-functions.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/001-globals.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/a.c-IRAM.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/a.d-DRAM.vhd"
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/a.e-Stack.vhd"
# Compile post-synthesis wrapper
vcom -reportprogress 300 -work NangateOpenCellLibrary "${srcDir}/a-DLX_postsyn_sim.vhd"

# Compile testbench
vcom -reportprogress 300 -work NangateOpenCellLibrary "./testbenches/TEST-a-DLX_sim.vhd"

###############################################################
#                      Simulation setup                       #
###############################################################

# Start simulation
vsim -t 100ps -novopt NangateOpenCellLibrary.test_dlx

onerror {resume}

# Define symbolic radix for instruction types to improve readability of opcodes waveforms
radix define ISA {
    "6'b000000" "RTYPE",
    "6'b000010" "JTYPE_J",
    "6'b000011" "JTYPE_JAL",
    "6'b000100" "ITYPE_BEQZ",
    "6'b000101" "ITYPE_BNEZ",
    "6'b001000" "ITYPE_ADDI",
    "6'b001001" "ITYPE_ADDUI",
    "6'b001010" "ITYPE_SUBI",
    "6'b001011" "ITYPE_SUBUI",
    "6'b001100" "ITYPE_ANDI",
    "6'b001101" "ITYPE_ORI",
    "6'b001110" "ITYPE_XORI",
    "6'b001111" "ITYPE_LHI",
    "6'b010010" "ITYPE_JR",
    "6'b010011" "ITYPE_JALR",
    "6'b010100" "ITYPE_SLLI",
    "6'b010101" "ITYPE_NOP",
    "6'b010110" "ITYPE_SRLI",
    "6'b010111" "ITYPE_SRAI",
    "6'b011000" "ITYPE_SEQI",
    "6'b011001" "ITYPE_SNEI",
    "6'b011010" "ITYPE_SLTI",
    "6'b011011" "ITYPE_SGTI",
    "6'b011100" "ITYPE_SLEI",
    "6'b011101" "ITYPE_SGEI",
    "6'b100000" "ITYPE_LB",
    "6'b100011" "ITYPE_LW",
    "6'b100100" "ITYPE_LBU",
    "6'b100101" "ITYPE_LHU",
    "6'b101000" "ITYPE_SB",
    "6'b101011" "ITYPE_SW",
    "6'b111010" "ITYPE_SLTUI",
    "6'b111011" "ITYPE_SGTUI",
    "6'b111100" "ITYPE_SLEUI",
    "6'b111101" "ITYPE_SGEUI",
    -default hexadecimal
}

# Install signal for the opcode of the fetched instruction
quietly virtual signal -install /tb_dlx/dlx_uut { /tb_dlx/dlx_uut/IR_fetched(31 downto 26)} opcode_fetched

###############################################################
#                          Simulation                         #
###############################################################

# Setup waveforms and dividers

quietly WaveActivateNextPane {} 0

add wave -noupdate -format Logic /tb_dlx/dlx_uut/clk
add wave -noupdate -format Logic /tb_dlx/dlx_uut/rst
add wave -noupdate -divider {Post-syn DLX}
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/pc_fetch
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/ir_fetched
add wave -noupdate -format Logic /tb_dlx/dlx_uut/dram_we
add wave -noupdate -format Logic /tb_dlx/dlx_uut/dram_re
add wave -noupdate -format Logic /tb_dlx/dlx_uut/dramop_sel
add wave -noupdate -format Literal -radix unsigned /tb_dlx/dlx_uut/dataaddr
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/dataout
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/datain_w
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/datain_hw
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/datain_b
add wave -noupdate -format Logic /tb_dlx/dlx_uut/spill
add wave -noupdate -format Logic /tb_dlx/dlx_uut/fill
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/rf2stack_bus
add wave -noupdate -format Literal -radix hexadecimal /tb_dlx/dlx_uut/stack2rf_bus

add wave -noupdate -divider Memories
add wave -noupdate -color Turquoise -format Literal -radix hexadecimal /tb_dlx/dlx_uut/dlx_iram/iram_mem
add wave -noupdate -color Orange -format Literal /tb_dlx/dlx_uut/dlx_dram/dram_mem
add wave -noupdate -color {Forest Green} -format Literal /tb_dlx/dlx_uut/dlx_stack/stack_mem

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 357
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {10500 ps}

# Annotate switching activity of all primary-inputs and internal nets
# It is annotated both in SAIF format (for back-annotated power analysis in Synopsys)
# and in VCD format (for more precise power analysis in Innovus, after physical design)
power add -in /tb_dlx/DLX_uut/DLX/*
power add -internal /tb_dlx/DLX_uut/DLX/*
vcd  file "${outputsDir}/dlx_swa.vcd"
vcd add /tb_dlx/DLX_uut/DLX/*

# Run simulation
run 245 ns

# Report switching activity to file
power report -all -bsaif "${outputsDir}/dlx_swa.saif"
power report -all -file "${outputsDir}/dlx_swa.txt"
