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
## File: simulation.tcl
## Date: September 2019
## Brief: TCL script for ModelSim to compile and simulate the whole DLX design; the
##		  script encompasses the use of IRAM and DRAM entities, which respectively uses
##		  "test.asm.mem" containing the firmware to be loaded in the DLX, and "data.mem"
##		  which contains the initialization values for the data memory. Both files should
##		  exist in the ModelSim directory
##
#########################################################################################

set projDir {C:/Users/sergi/OneDrive - Politecnico di Torino/Documents/Università/Computer Engineering - PoliTo/Corsi/Microelectronic Systems/Laboratorio/DLX (Git)/dlx_project}
set srcDir "${projDir}/src"
set simDir "${projDir}/sim"

###############################################################
#                     Design compilation                      #
###############################################################

# Globals
vcom -reportprogress 300 -work work "${srcDir}/000-functions.vhd"
vcom -reportprogress 300 -work work "${srcDir}/001-globals.vhd"
# Control Unit
vcom -reportprogress 300 -work work "${srcDir}/a.a-CU_HW.vhd"
# Datapath/Adder
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/a.a.a-smallPG.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/a.a-PGnetwork_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/a.b-bigG.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/a.c-bigPG.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/a-CarryGenerator_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a.a-RCA_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a.b-mux2_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a-carrysel_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.core/b-SumGenerator_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/000-Adder.vhd"
# Datapath modules
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/a-RegFile_Win.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/b-BJ_Logic.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/c-HazardDet_Unit.vhd"
# Datapath/ALU
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/000-inv_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/a-Shifter.vhd"
# Datapath/ALU/Logicals
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.core/a-nand3_generic.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.core/b-nand4_generic.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.vhd"
# Datapath/ALU/Comparator
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/a-xor2_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/b-or2_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/c-and2_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/d-zeroDet_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.vhd"
# Datapath/ALU/Multiplier
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/a-boothEnc_block.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/b-boothMuxCalc.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/c-mux5_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/d.a-FA.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/d-CSA_gen.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.core/d-ALU.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.b-DataPath.vhd"
# Memories
vcom -reportprogress 300 -work work "${srcDir}/a.c-IRAM.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.d-DRAM.vhd"
vcom -reportprogress 300 -work work "${srcDir}/a.e-Stack.vhd"
# DLX Wrapper and Testbench
vcom -reportprogress 300 -work work "${srcDir}/a-DLX_sim.vhd"
vcom -reportprogress 300 -work work "${simDir}/testbenches/TEST-a-DLX_sim.vhd"

###############################################################
#                      Simulation setup                       #
###############################################################

# Start simulation
vsim -t 100ps work.test_dlx

onerror {resume}

# Define symbolic radix for instruction types, to improve readability of opcodes waveforms
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

# Install groups of signals of interests
# Control word stages
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_ControlUnit { /tb_dlx/DLX_uut/DLX_ControlUnit/cw1(29 downto 26)} cw1_IF
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_ControlUnit { /tb_dlx/DLX_uut/DLX_ControlUnit/cw2(25 downto 18)} cw2_ID
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_ControlUnit { /tb_dlx/DLX_uut/DLX_ControlUnit/cw3(17 downto 14)} cw3_EX
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_ControlUnit { /tb_dlx/DLX_uut/DLX_ControlUnit/cw4(13 downto 5)} cw4_MEM
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_ControlUnit {/tb_dlx/DLX_uut/DLX_ControlUnit/cw5  } cw5_WB
# Opcode stages
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/IR_fetched(31 downto 26)} opcode_fetched
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath { /tb_dlx/DLX_uut/DLX_Datapath/IR_IFID(31 downto 26)} opcode_IFID
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath { /tb_dlx/DLX_uut/DLX_Datapath/IR_IDEX(31 downto 26)} opcode_IDEX
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath { /tb_dlx/DLX_uut/DLX_Datapath/IR_EXMEM(31 downto 26)} opcode_EXMEM
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath { /tb_dlx/DLX_uut/DLX_Datapath/IR_MEMWB(31 downto 26)} opcode_MEMWB
# 16-bits immediate from IF/ID
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath { /tb_dlx/DLX_uut/DLX_Datapath/IR_IFID(15 downto 0)} Imm16
# Register File Windows
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(0 to 7)} GLOBALS
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(8 to 31)} WIND_0
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(24 to 47)} WIND_1
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(40 to 63)} WIND_2
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(56 to 79)} WIND_3
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(72 to 95)} WIND_4
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(88 to 111)} WIND_5
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(104 to 127)} WIND_6
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile { (context /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile )( phy_regfile(120 to 135) & phy_regfile(8 to 15) )} WIND_7
# RegFile-Stack bus
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/rf2stack_bus(127 downto 96)} RFtoSTACK_bus_3
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/rf2stack_bus(95 downto 64)} RFtoSTACK_bus_2
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/rf2stack_bus(63 downto 32)} RFtoSTACK_bus_1
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/rf2stack_bus(31 downto 0)} RFtoSTACK_bus_0
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/stack2rf_bus(127 downto 96)} STACKtoRF_bus_3
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/stack2rf_bus(95 downto 64)} STACKtoRF_bus_2
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/stack2rf_bus(63 downto 32)} STACKtoRF_bus_1
quietly virtual signal -install /tb_dlx/DLX_uut { /tb_dlx/DLX_uut/stack2rf_bus(31 downto 0)} STACKtoRF_bus_0
# Branch prediction memory address
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic { /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/bAddr_IFID(6 downto 2)} pred_index_IFID
quietly virtual signal -install /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic { /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/bAddr_PC(6 downto 2)} pred_index_IRAM

###############################################################
#                          Simulation                         #
###############################################################

# Setup waveforms, dividers and groups

quietly WaveActivateNextPane {} 0

add wave -noupdate -height 24 /tb_dlx/Clock
add wave -noupdate /tb_dlx/Reset

add wave -noupdate -divider Control
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/cw1
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/cw2
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/cw3
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/cw4
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/cw5
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/ALUop1
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/ALUop2
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/ALUop3
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/RMLcw1
add wave -noupdate -group {Control Unit} -group {CW Stages} /tb_dlx/DLX_uut/DLX_ControlUnit/RMLcw2
add wave -noupdate -group {Control Unit} -divider IF
add wave -noupdate -group {Control Unit} -color Firebrick -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/MUXImmTA_SEL
add wave -noupdate -group {Control Unit} -color Firebrick -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/NPC_LATCH_IFID_EN
add wave -noupdate -group {Control Unit} -color Firebrick -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/TA_LATCH_IFID_EN
add wave -noupdate -group {Control Unit} -color Firebrick -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/PC_LATCH_IFID_EN
add wave -noupdate -group {Control Unit} -divider ID
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_ControlUnit/MUXImm_SEL
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RF_RD1EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RF_RD2EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RegA_LATCH_IDEX_EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RegB_LATCH_IDEX_EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RegIMM_LATCH_IDEX_EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/LPC_LATCH_IDEX_EN
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RF_CALL
add wave -noupdate -group {Control Unit} -color {Green Yellow} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RF_RET
add wave -noupdate -group {Control Unit} -divider EX
add wave -noupdate -group {Control Unit} -color Orange -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/MUXB_SEL
add wave -noupdate -group {Control Unit} -color Orange -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/ALUOUT_LATCH_EXMEM_EN
add wave -noupdate -group {Control Unit} -color Orange -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RegB_LATCH_EXMEM_EN
add wave -noupdate -group {Control Unit} -color Orange -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/LPC_LATCH_EXMEM_EN
add wave -noupdate -group {Control Unit} -color Orange -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/ALU_OPCODE
add wave -noupdate -group {Control Unit} -divider MEM
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/DRAM_WE
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/DRAM_RE
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/DRAMOP_SEL
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/MUXLPC_SEL
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_ControlUnit/MUXLMD_SEL
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/LMD_LATCH_MEMWB_EN
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/ALUOUT_LATCH_MEMWB_EN
add wave -noupdate -group {Control Unit} -color {Medium Aquamarine} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/LPC_LATCH_MEMWB_EN
add wave -noupdate -group {Control Unit} -divider WB
add wave -noupdate -group {Control Unit} -color {Dark Green} -radix binary /tb_dlx/DLX_uut/DLX_ControlUnit/RF_WE
add wave -noupdate -group {Control Unit} -color {Dark Green} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_ControlUnit/MUXWrAddr_SEL
add wave -noupdate -group {Control Unit} -color {Dark Green} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_ControlUnit/MUXWB_SEL
add wave -noupdate -group {HDU Mux} -color {Orange Red} /tb_dlx/DLX_uut/DLX_Datapath/HDU_stall
add wave -noupdate -group {HDU Mux} /tb_dlx/DLX_uut/DLX_Datapath/HDU_BJRegA_SEL
add wave -noupdate -group {HDU Mux} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_Datapath/HDU_ALUInA_SEL
add wave -noupdate -group {HDU Mux} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_Datapath/HDU_ALUInB_SEL
add wave -noupdate -group {HDU Mux} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_Datapath/HDU_Blatch_SEL
add wave -noupdate -group {HDU Mux} -radix binary -radixshowbase 0 /tb_dlx/DLX_uut/DLX_Datapath/HDU_DRAMIn_SEL
add wave -noupdate -expand -group {Branch&Jump Logic} -color {Orange Red} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/flush_IFID
add wave -noupdate -expand -group {Branch&Jump Logic} -color Tan -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_index_IRAM
add wave -noupdate -expand -group {Branch&Jump Logic} -color Tan -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_index_IFID
add wave -noupdate -expand -group {Branch&Jump Logic} -color Khaki -subitemconfig {/tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(0) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(1) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(2) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(3) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(4) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(5) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(6) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(7) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(8) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(9) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(10) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(11) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(12) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(13) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(14) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(15) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(16) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(17) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(18) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(19) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(20) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(21) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(22) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(23) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(24) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(25) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(26) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(27) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(28) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(29) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(30) {-color Khaki} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem(31) {-color Khaki}} /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/pred_mem
add wave -noupdate -color {Orange Red} /tb_dlx/DLX_uut/DLX_Datapath/STALL

add wave -noupdate -divider IF
add wave -noupdate -color Gold /tb_dlx/DLX_uut/IR_fetched
add wave -noupdate -radix ISA /tb_dlx/DLX_uut/opcode_fetched
add wave -noupdate -color Sienna /tb_dlx/DLX_uut/PC_fetch
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/MUX_ImmTA
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/next_NPC_IFID
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/next_TA_IFID
add wave -noupdate -color Firebrick /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/take_bj
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/MUX_PC
add wave -noupdate -color Turquoise /tb_dlx/DLX_uut/DLX_IRAM/IRAM_mem

add wave -noupdate -divider ID
add wave -noupdate -radix ISA /tb_dlx/DLX_uut/DLX_Datapath/opcode_IFID
add wave -noupdate -color Gold /tb_dlx/DLX_uut/DLX_Datapath/IR_IFID
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/MUX_HDU_BJRegA
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/BJ_correctPC
add wave -noupdate -color Firebrick /tb_dlx/DLX_uut/DLX_Datapath/BrancJump_logic/muxPC_SEL
add wave -noupdate -radix binary /tb_dlx/DLX_uut/DLX_Datapath/Imm16
add wave -noupdate -radix binary /tb_dlx/DLX_uut/DLX_Datapath/MUX_Imm
add wave -noupdate -color Orchid -radix ufixed -childformat {{/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(4) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(3) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(2) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(1) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(0) -radix ufixed}} -subitemconfig {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(4) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(3) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(2) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(1) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr(0) {-color Orchid -height 15 -radix ufixed}} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd1_Addr
add wave -noupdate -color Orchid -radix ufixed -childformat {{/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(4) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(3) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(2) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(1) -radix ufixed} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(0) -radix ufixed}} -subitemconfig {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(4) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(3) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(2) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(1) {-color Orchid -height 15 -radix ufixed} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr(0) {-color Orchid -height 15 -radix ufixed}} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Rd2_Addr
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Out1
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Out2
add wave -noupdate -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/GLOBALS
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_0
add wave -noupdate -group {RF Windows} -color Orange -childformat {{/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(24) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(25) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(26) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(27) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(28) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(29) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(30) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(31) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(32) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(33) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(34) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(35) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(36) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(37) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(38) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(39) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(40) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(41) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(42) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(43) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(44) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(45) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(46) -radix hexadecimal} {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1(47) -radix hexadecimal}} -subitemconfig {/tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(24) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(25) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(26) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(27) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(28) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(29) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(30) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(31) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(32) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(33) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(34) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(35) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(36) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(37) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(38) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(39) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(40) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(41) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(42) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(43) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(44) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(45) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(46) {-color Orange -radix hexadecimal} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/phy_regfile(47) {-color Orange -radix hexadecimal}} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_1
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_2
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_3
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_4
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_5
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_6
add wave -noupdate -group {RF Windows} -color Orange /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/WIND_7
add wave -noupdate -group {RF Pointers} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/CALL
add wave -noupdate -group {RF Pointers} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/RET
add wave -noupdate -group {RF Pointers} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/RF_state
add wave -noupdate -group {RF Pointers} -color {Medium Sea Green} -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/CWP
add wave -noupdate -group {RF Pointers} -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/old_CWP1
add wave -noupdate -group {RF Pointers} -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/old_CWP2
add wave -noupdate -group {RF Pointers} -color {Cornflower Blue} -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/SWP
add wave -noupdate -group {RF-Stack Interface} -color Turquoise /tb_dlx/DLX_uut/DLX_Stack/STACK_mem
add wave -noupdate -group {RF-Stack Interface} -color {Forest Green} /tb_dlx/DLX_uut/RFtoSTACK_bus_3
add wave -noupdate -group {RF-Stack Interface} -color {Forest Green} /tb_dlx/DLX_uut/RFtoSTACK_bus_2
add wave -noupdate -group {RF-Stack Interface} -color {Forest Green} /tb_dlx/DLX_uut/RFtoSTACK_bus_1
add wave -noupdate -group {RF-Stack Interface} -color {Forest Green} /tb_dlx/DLX_uut/RFtoSTACK_bus_0
add wave -noupdate -group {RF-Stack Interface} -color {Medium Blue} /tb_dlx/DLX_uut/STACKtoRF_bus_3
add wave -noupdate -group {RF-Stack Interface} -color {Medium Blue} /tb_dlx/DLX_uut/STACKtoRF_bus_2
add wave -noupdate -group {RF-Stack Interface} -color {Medium Blue} /tb_dlx/DLX_uut/STACKtoRF_bus_1
add wave -noupdate -group {RF-Stack Interface} -color {Medium Blue} /tb_dlx/DLX_uut/STACKtoRF_bus_0
add wave -noupdate -group {RF-Stack Interface} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/SPILL
add wave -noupdate -group {RF-Stack Interface} /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/FILL

add wave -noupdate -divider EX
add wave -noupdate -radix ISA /tb_dlx/DLX_uut/DLX_Datapath/opcode_IDEX
add wave -noupdate -color Gold /tb_dlx/DLX_uut/DLX_Datapath/IR_IDEX
add wave -noupdate -radix sfixed /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/A
add wave -noupdate -radix sfixed -childformat {{/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(31) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(30) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(29) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(28) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(27) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(26) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(25) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(24) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(23) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(22) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(21) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(20) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(19) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(18) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(17) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(16) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(15) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(14) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(13) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(12) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(11) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(10) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(9) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(8) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(7) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(6) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(5) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(4) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(3) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(2) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(1) -radix sfixed} {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(0) -radix sfixed}} -subitemconfig {/tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(31) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(30) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(29) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(28) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(27) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(26) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(25) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(24) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(23) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(22) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(21) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(20) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(19) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(18) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(17) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(16) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(15) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(14) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(13) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(12) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(11) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(10) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(9) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(8) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(7) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(6) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(5) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(4) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(3) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(2) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(1) {-height 15 -radix sfixed} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B(0) {-height 15 -radix sfixed}} /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/B
add wave -noupdate -color Firebrick /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/opcode
add wave -noupdate -radix sfixed /tb_dlx/DLX_uut/DLX_Datapath/ArithLogUnit/Z

add wave -noupdate -divider MEM
add wave -noupdate -radix ISA /tb_dlx/DLX_uut/DLX_Datapath/opcode_EXMEM
add wave -noupdate -color Gold /tb_dlx/DLX_uut/DLX_Datapath/IR_EXMEM
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/ALUOut_EXMEM
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/LPC_EXMEM
add wave -noupdate -color Orchid -radix ufixed /tb_dlx/DLX_uut/DLX_DRAM/Addr
add wave -noupdate /tb_dlx/DLX_uut/DLX_DRAM/Din
add wave -noupdate -color Turquoise /tb_dlx/DLX_uut/DLX_DRAM/DRAM_mem
add wave -noupdate -expand -group {DRAM Output} /tb_dlx/DLX_uut/DLX_DRAM/Dout_b
add wave -noupdate -expand -group {DRAM Output} /tb_dlx/DLX_uut/DLX_DRAM/Dout_hw
add wave -noupdate -expand -group {DRAM Output} /tb_dlx/DLX_uut/DLX_DRAM/Dout_w
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/MUX_LMD

add wave -noupdate -divider WB
add wave -noupdate -radix ISA /tb_dlx/DLX_uut/DLX_Datapath/opcode_MEMWB
add wave -noupdate -color Gold /tb_dlx/DLX_uut/DLX_Datapath/IR_MEMWB
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/ALUOut_MEMWB
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/LMD_MEMWB
add wave -noupdate -color Orchid -radix ufixed /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/Wr_Addr
add wave -noupdate /tb_dlx/DLX_uut/DLX_Datapath/RegisterFile/DataIn

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48600 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 372
configure wave -valuecolwidth 233
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
configure wave -timelineunits ns
update
WaveRestoreZoom {80700 ps} {101700 ps}

# Run simulation
run 215 ns
