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
## File: post_syn_backannotation.tcl
## Date: September 2019
## Brief: TCL script for Synopsys Design Vision to back annotate power information
## 		  collected with post-synthesis simulation and better optimize the design from
##		  the point of view of the dynamic power
##
#########################################################################################

set projDir {..}
set simDir "${projDir}/sim"

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
#                         Read design                         #
###############################################################

# Read netlist and constraints
read_file -format ddc {./netlists/DLX_postsyn_ungroup.ddc}
read_sdc {./netlists/DLX_postsyn_ungroup.sdc}
# Read power back annotated file from ModelSim
read_saif -input ${simDir}/outputs/dlx_swa.saif -instance tb_dlx/dlx_uut/dlx

# Reports after back-annotation (only power should be different)
report_area > "${reportsDir}/DLX_area_backann.rpt"

###############################################################
#                           Compile                           #
###############################################################

# Specify wire model (useful for physical design)
set_wire_load_model -name 5K_hvratio_1_4

# Compile
compile -map_effort high

# Elaborate new reports
report_timing > "${reportsDir}/DLX_time_backann_opt.rpt"
report_area > "${reportsDir}/DLX_area_backann_opt.rpt"
report_power > "${reportsDir}/DLX_power_backann_opt.rpt"

# Save post-synthesis netlists optimized after back-annotation and constraint file (for physical design)
write -hierarchy -format vhdl -output "${netlistsDir}/DLX_backann_opt.vhdl"
write -hierarchy -format verilog -output "${netlistsDir}/DLX_backann_opt.v"
write -hierarchy -format ddc -output "${netlistsDir}/DLX_backann_opt.ddc"
write_sdc "${netlistsDir}/DLX_backann_opt.sdc"

###############################################################
#                        Clean & Exit                         #
###############################################################

#exit
