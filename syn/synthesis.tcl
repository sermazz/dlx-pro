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
## File: synthesis.tcl
## Date: September 2019
## Brief: TCL script for Synopsys Design Vision to synthesize the DLX circuit; the
##		  synthesis is performed with a frequency-constrained area and dynamic power
##		  minimization, exploiting the flattening of the design hierarchy to expose
##		  more possibilities of optimization
##
#########################################################################################

set projDir {..}
set srcDir "${projDir}/src"
set simDir "${projDir}/sim"

set libName "work"
# Create work library for Design Vision, if it doesn't exist
set libDir "./${libName}"
if {![file exists $libDir]} {
	file mkdir $libDir
}

# Create directories to store outputs
set netlistsDir "./netlists"
if {![file exists $netlistsDir]} {
	file mkdir $netlistsDir
}
set reportsDir "./reports"
if {![file exists $reportsDir]} {
	file mkdir $reportsDir
}

###############################################################
#                   Analysis & Elaboration                    #
###############################################################

# Analyze all vhdl source files to be synthesized (no memories)
analyze -library $libName -format vhdl "${srcDir}/000-functions.vhd"
analyze -library $libName -format vhdl "${srcDir}/001-globals.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.a-CU_HW.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/a.a.a-smallPG.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/a.a-PGnetwork_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/a.b-bigG.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/a.c-bigPG.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/a-CarryGenerator_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a.a-RCA_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a.b-mux2_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/b.a-carrysel_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.core/b-SumGenerator_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/000-Adder.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/a-RegFile_Win.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/b-BJ_Logic.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/c-HazardDet_Unit.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/000-inv_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/a-Shifter.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.core/a-nand3_generic.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.core/b-nand4_generic.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/b-Logicals.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/a-xor2_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/b-or2_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/c-and2_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.core/d-zeroDet_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/c-Comparator.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/a-boothEnc_block.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/b-boothMuxCalc.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/c-mux5_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/d.a-FA.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.core/d-CSA_gen.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.core/d-Multiplier.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.core/d-ALU.vhd"
analyze -library $libName -format vhdl "${srcDir}/a.b-DataPath.vhd"
analyze -library $libName -format vhdl "${srcDir}/a-DLX_syn.vhd"

# Elaborate the DLX architecture
elaborate DLX -architecture DLX_RTL -library ${libName} -parameters "ADDR_SIZE = 32, DATA_SIZE = 32, IR_SIZE = 32, OPC_SIZE = 6, REGADDR_SIZE = 5, STACKBUS_WIDTH = 4"

###############################################################
#                      Constraints setup                      #
###############################################################

# Unconstrained compilation
compile
report_timing > "${reportsDir}/DLX_time_uncstr.rpt"
report_area > "${reportsDir}/DLX_area_uncstr.rpt"
report_power > "${reportsDir}/DLX_power_uncstr.rpt"

set delayConstraint "1.25"

# Sequential constraint
set clockName "Clk"
create_clock -period $delayConstraint $clockName
# Clock network tolerances setup
set_clock_uncertainty 0.05 $clockName
set_clock_transition 0.05 $clockName
set_clock_latency 0.05 $clockName

# Combinational constraint
set_max_delay $delayConstraint -from [all_inputs] -to [all_outputs]

# Area & dynamic power minimization
set_max_area 0.0
set_max_dynamic_power 0.0

###############################################################
#                           Compile                           #
###############################################################

# Flatten hierarchy of all designs
ungroup -all -flatten

# Compile
compile -map_effort high

# Elaborate reports
report_timing > "${reportsDir}/DLX_time_ungroup.rpt"
report_area > "${reportsDir}/DLX_area_ungroup.rpt"
report_power > "${reportsDir}/DLX_power_ungroup.rpt"

# Save post-synthesis netlists and post-synthesis constraint file
write -hierarchy -format vhdl -output "${netlistsDir}/DLX_postsyn_ungroup.vhdl"
write -hierarchy -format verilog -output "${netlistsDir}/DLX_postsyn_ungroup.v"
write -hierarchy -format ddc -output "${netlistsDir}/DLX_postsyn_ungroup.ddc"
write_sdc "${netlistsDir}/DLX_postsyn_ungroup.sdc"

###############################################################
#                        Clean & Exit                         #
###############################################################

#exec rm -rf "${libDir}"
#exit