###################################################################

# Created by write_sdc on Fri Sep 13 18:19:35 2019

###################################################################
set sdc_version 1.9

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current mA
set_max_dynamic_power 0
set_max_area 0
create_clock [get_ports Clk]  -period 1.25  -waveform {0 0.625}
set_clock_latency 0.05  [get_clocks Clk]
set_clock_uncertainty 0.05  [get_clocks Clk]
set_clock_transition -max -rise 0.05 [get_clocks Clk]
set_clock_transition -max -fall 0.05 [get_clocks Clk]
set_clock_transition -min -rise 0.05 [get_clocks Clk]
set_clock_transition -min -fall 0.05 [get_clocks Clk]
set_max_delay 1.25  -from [list [get_ports Clk] [get_ports Rst] [get_ports {IR_in[31]}]           \
[get_ports {IR_in[30]}] [get_ports {IR_in[29]}] [get_ports {IR_in[28]}]        \
[get_ports {IR_in[27]}] [get_ports {IR_in[26]}] [get_ports {IR_in[25]}]        \
[get_ports {IR_in[24]}] [get_ports {IR_in[23]}] [get_ports {IR_in[22]}]        \
[get_ports {IR_in[21]}] [get_ports {IR_in[20]}] [get_ports {IR_in[19]}]        \
[get_ports {IR_in[18]}] [get_ports {IR_in[17]}] [get_ports {IR_in[16]}]        \
[get_ports {IR_in[15]}] [get_ports {IR_in[14]}] [get_ports {IR_in[13]}]        \
[get_ports {IR_in[12]}] [get_ports {IR_in[11]}] [get_ports {IR_in[10]}]        \
[get_ports {IR_in[9]}] [get_ports {IR_in[8]}] [get_ports {IR_in[7]}]           \
[get_ports {IR_in[6]}] [get_ports {IR_in[5]}] [get_ports {IR_in[4]}]           \
[get_ports {IR_in[3]}] [get_ports {IR_in[2]}] [get_ports {IR_in[1]}]           \
[get_ports {IR_in[0]}] [get_ports {DataIn_w[31]}] [get_ports {DataIn_w[30]}]   \
[get_ports {DataIn_w[29]}] [get_ports {DataIn_w[28]}] [get_ports               \
{DataIn_w[27]}] [get_ports {DataIn_w[26]}] [get_ports {DataIn_w[25]}]          \
[get_ports {DataIn_w[24]}] [get_ports {DataIn_w[23]}] [get_ports               \
{DataIn_w[22]}] [get_ports {DataIn_w[21]}] [get_ports {DataIn_w[20]}]          \
[get_ports {DataIn_w[19]}] [get_ports {DataIn_w[18]}] [get_ports               \
{DataIn_w[17]}] [get_ports {DataIn_w[16]}] [get_ports {DataIn_w[15]}]          \
[get_ports {DataIn_w[14]}] [get_ports {DataIn_w[13]}] [get_ports               \
{DataIn_w[12]}] [get_ports {DataIn_w[11]}] [get_ports {DataIn_w[10]}]          \
[get_ports {DataIn_w[9]}] [get_ports {DataIn_w[8]}] [get_ports {DataIn_w[7]}]  \
[get_ports {DataIn_w[6]}] [get_ports {DataIn_w[5]}] [get_ports {DataIn_w[4]}]  \
[get_ports {DataIn_w[3]}] [get_ports {DataIn_w[2]}] [get_ports {DataIn_w[1]}]  \
[get_ports {DataIn_w[0]}] [get_ports {DataIn_hw[15]}] [get_ports               \
{DataIn_hw[14]}] [get_ports {DataIn_hw[13]}] [get_ports {DataIn_hw[12]}]       \
[get_ports {DataIn_hw[11]}] [get_ports {DataIn_hw[10]}] [get_ports             \
{DataIn_hw[9]}] [get_ports {DataIn_hw[8]}] [get_ports {DataIn_hw[7]}]          \
[get_ports {DataIn_hw[6]}] [get_ports {DataIn_hw[5]}] [get_ports               \
{DataIn_hw[4]}] [get_ports {DataIn_hw[3]}] [get_ports {DataIn_hw[2]}]          \
[get_ports {DataIn_hw[1]}] [get_ports {DataIn_hw[0]}] [get_ports               \
{DataIn_b[7]}] [get_ports {DataIn_b[6]}] [get_ports {DataIn_b[5]}] [get_ports  \
{DataIn_b[4]}] [get_ports {DataIn_b[3]}] [get_ports {DataIn_b[2]}] [get_ports  \
{DataIn_b[1]}] [get_ports {DataIn_b[0]}] [get_ports {stackBus_In[127]}]        \
[get_ports {stackBus_In[126]}] [get_ports {stackBus_In[125]}] [get_ports       \
{stackBus_In[124]}] [get_ports {stackBus_In[123]}] [get_ports                  \
{stackBus_In[122]}] [get_ports {stackBus_In[121]}] [get_ports                  \
{stackBus_In[120]}] [get_ports {stackBus_In[119]}] [get_ports                  \
{stackBus_In[118]}] [get_ports {stackBus_In[117]}] [get_ports                  \
{stackBus_In[116]}] [get_ports {stackBus_In[115]}] [get_ports                  \
{stackBus_In[114]}] [get_ports {stackBus_In[113]}] [get_ports                  \
{stackBus_In[112]}] [get_ports {stackBus_In[111]}] [get_ports                  \
{stackBus_In[110]}] [get_ports {stackBus_In[109]}] [get_ports                  \
{stackBus_In[108]}] [get_ports {stackBus_In[107]}] [get_ports                  \
{stackBus_In[106]}] [get_ports {stackBus_In[105]}] [get_ports                  \
{stackBus_In[104]}] [get_ports {stackBus_In[103]}] [get_ports                  \
{stackBus_In[102]}] [get_ports {stackBus_In[101]}] [get_ports                  \
{stackBus_In[100]}] [get_ports {stackBus_In[99]}] [get_ports                   \
{stackBus_In[98]}] [get_ports {stackBus_In[97]}] [get_ports {stackBus_In[96]}] \
[get_ports {stackBus_In[95]}] [get_ports {stackBus_In[94]}] [get_ports         \
{stackBus_In[93]}] [get_ports {stackBus_In[92]}] [get_ports {stackBus_In[91]}] \
[get_ports {stackBus_In[90]}] [get_ports {stackBus_In[89]}] [get_ports         \
{stackBus_In[88]}] [get_ports {stackBus_In[87]}] [get_ports {stackBus_In[86]}] \
[get_ports {stackBus_In[85]}] [get_ports {stackBus_In[84]}] [get_ports         \
{stackBus_In[83]}] [get_ports {stackBus_In[82]}] [get_ports {stackBus_In[81]}] \
[get_ports {stackBus_In[80]}] [get_ports {stackBus_In[79]}] [get_ports         \
{stackBus_In[78]}] [get_ports {stackBus_In[77]}] [get_ports {stackBus_In[76]}] \
[get_ports {stackBus_In[75]}] [get_ports {stackBus_In[74]}] [get_ports         \
{stackBus_In[73]}] [get_ports {stackBus_In[72]}] [get_ports {stackBus_In[71]}] \
[get_ports {stackBus_In[70]}] [get_ports {stackBus_In[69]}] [get_ports         \
{stackBus_In[68]}] [get_ports {stackBus_In[67]}] [get_ports {stackBus_In[66]}] \
[get_ports {stackBus_In[65]}] [get_ports {stackBus_In[64]}] [get_ports         \
{stackBus_In[63]}] [get_ports {stackBus_In[62]}] [get_ports {stackBus_In[61]}] \
[get_ports {stackBus_In[60]}] [get_ports {stackBus_In[59]}] [get_ports         \
{stackBus_In[58]}] [get_ports {stackBus_In[57]}] [get_ports {stackBus_In[56]}] \
[get_ports {stackBus_In[55]}] [get_ports {stackBus_In[54]}] [get_ports         \
{stackBus_In[53]}] [get_ports {stackBus_In[52]}] [get_ports {stackBus_In[51]}] \
[get_ports {stackBus_In[50]}] [get_ports {stackBus_In[49]}] [get_ports         \
{stackBus_In[48]}] [get_ports {stackBus_In[47]}] [get_ports {stackBus_In[46]}] \
[get_ports {stackBus_In[45]}] [get_ports {stackBus_In[44]}] [get_ports         \
{stackBus_In[43]}] [get_ports {stackBus_In[42]}] [get_ports {stackBus_In[41]}] \
[get_ports {stackBus_In[40]}] [get_ports {stackBus_In[39]}] [get_ports         \
{stackBus_In[38]}] [get_ports {stackBus_In[37]}] [get_ports {stackBus_In[36]}] \
[get_ports {stackBus_In[35]}] [get_ports {stackBus_In[34]}] [get_ports         \
{stackBus_In[33]}] [get_ports {stackBus_In[32]}] [get_ports {stackBus_In[31]}] \
[get_ports {stackBus_In[30]}] [get_ports {stackBus_In[29]}] [get_ports         \
{stackBus_In[28]}] [get_ports {stackBus_In[27]}] [get_ports {stackBus_In[26]}] \
[get_ports {stackBus_In[25]}] [get_ports {stackBus_In[24]}] [get_ports         \
{stackBus_In[23]}] [get_ports {stackBus_In[22]}] [get_ports {stackBus_In[21]}] \
[get_ports {stackBus_In[20]}] [get_ports {stackBus_In[19]}] [get_ports         \
{stackBus_In[18]}] [get_ports {stackBus_In[17]}] [get_ports {stackBus_In[16]}] \
[get_ports {stackBus_In[15]}] [get_ports {stackBus_In[14]}] [get_ports         \
{stackBus_In[13]}] [get_ports {stackBus_In[12]}] [get_ports {stackBus_In[11]}] \
[get_ports {stackBus_In[10]}] [get_ports {stackBus_In[9]}] [get_ports          \
{stackBus_In[8]}] [get_ports {stackBus_In[7]}] [get_ports {stackBus_In[6]}]    \
[get_ports {stackBus_In[5]}] [get_ports {stackBus_In[4]}] [get_ports           \
{stackBus_In[3]}] [get_ports {stackBus_In[2]}] [get_ports {stackBus_In[1]}]    \
[get_ports {stackBus_In[0]}]]  -to [list [get_ports {PC_out[31]}] [get_ports {PC_out[30]}] [get_ports        \
{PC_out[29]}] [get_ports {PC_out[28]}] [get_ports {PC_out[27]}] [get_ports     \
{PC_out[26]}] [get_ports {PC_out[25]}] [get_ports {PC_out[24]}] [get_ports     \
{PC_out[23]}] [get_ports {PC_out[22]}] [get_ports {PC_out[21]}] [get_ports     \
{PC_out[20]}] [get_ports {PC_out[19]}] [get_ports {PC_out[18]}] [get_ports     \
{PC_out[17]}] [get_ports {PC_out[16]}] [get_ports {PC_out[15]}] [get_ports     \
{PC_out[14]}] [get_ports {PC_out[13]}] [get_ports {PC_out[12]}] [get_ports     \
{PC_out[11]}] [get_ports {PC_out[10]}] [get_ports {PC_out[9]}] [get_ports      \
{PC_out[8]}] [get_ports {PC_out[7]}] [get_ports {PC_out[6]}] [get_ports        \
{PC_out[5]}] [get_ports {PC_out[4]}] [get_ports {PC_out[3]}] [get_ports        \
{PC_out[2]}] [get_ports {PC_out[1]}] [get_ports {PC_out[0]}] [get_ports        \
{DataAddr[31]}] [get_ports {DataAddr[30]}] [get_ports {DataAddr[29]}]          \
[get_ports {DataAddr[28]}] [get_ports {DataAddr[27]}] [get_ports               \
{DataAddr[26]}] [get_ports {DataAddr[25]}] [get_ports {DataAddr[24]}]          \
[get_ports {DataAddr[23]}] [get_ports {DataAddr[22]}] [get_ports               \
{DataAddr[21]}] [get_ports {DataAddr[20]}] [get_ports {DataAddr[19]}]          \
[get_ports {DataAddr[18]}] [get_ports {DataAddr[17]}] [get_ports               \
{DataAddr[16]}] [get_ports {DataAddr[15]}] [get_ports {DataAddr[14]}]          \
[get_ports {DataAddr[13]}] [get_ports {DataAddr[12]}] [get_ports               \
{DataAddr[11]}] [get_ports {DataAddr[10]}] [get_ports {DataAddr[9]}]           \
[get_ports {DataAddr[8]}] [get_ports {DataAddr[7]}] [get_ports {DataAddr[6]}]  \
[get_ports {DataAddr[5]}] [get_ports {DataAddr[4]}] [get_ports {DataAddr[3]}]  \
[get_ports {DataAddr[2]}] [get_ports {DataAddr[1]}] [get_ports {DataAddr[0]}]  \
[get_ports {DataOut[31]}] [get_ports {DataOut[30]}] [get_ports {DataOut[29]}]  \
[get_ports {DataOut[28]}] [get_ports {DataOut[27]}] [get_ports {DataOut[26]}]  \
[get_ports {DataOut[25]}] [get_ports {DataOut[24]}] [get_ports {DataOut[23]}]  \
[get_ports {DataOut[22]}] [get_ports {DataOut[21]}] [get_ports {DataOut[20]}]  \
[get_ports {DataOut[19]}] [get_ports {DataOut[18]}] [get_ports {DataOut[17]}]  \
[get_ports {DataOut[16]}] [get_ports {DataOut[15]}] [get_ports {DataOut[14]}]  \
[get_ports {DataOut[13]}] [get_ports {DataOut[12]}] [get_ports {DataOut[11]}]  \
[get_ports {DataOut[10]}] [get_ports {DataOut[9]}] [get_ports {DataOut[8]}]    \
[get_ports {DataOut[7]}] [get_ports {DataOut[6]}] [get_ports {DataOut[5]}]     \
[get_ports {DataOut[4]}] [get_ports {DataOut[3]}] [get_ports {DataOut[2]}]     \
[get_ports {DataOut[1]}] [get_ports {DataOut[0]}] [get_ports DRAM_WE]          \
[get_ports DRAM_RE] [get_ports DRAMOP_SEL] [get_ports SPILL] [get_ports FILL]  \
[get_ports {stackBus_Out[127]}] [get_ports {stackBus_Out[126]}] [get_ports     \
{stackBus_Out[125]}] [get_ports {stackBus_Out[124]}] [get_ports                \
{stackBus_Out[123]}] [get_ports {stackBus_Out[122]}] [get_ports                \
{stackBus_Out[121]}] [get_ports {stackBus_Out[120]}] [get_ports                \
{stackBus_Out[119]}] [get_ports {stackBus_Out[118]}] [get_ports                \
{stackBus_Out[117]}] [get_ports {stackBus_Out[116]}] [get_ports                \
{stackBus_Out[115]}] [get_ports {stackBus_Out[114]}] [get_ports                \
{stackBus_Out[113]}] [get_ports {stackBus_Out[112]}] [get_ports                \
{stackBus_Out[111]}] [get_ports {stackBus_Out[110]}] [get_ports                \
{stackBus_Out[109]}] [get_ports {stackBus_Out[108]}] [get_ports                \
{stackBus_Out[107]}] [get_ports {stackBus_Out[106]}] [get_ports                \
{stackBus_Out[105]}] [get_ports {stackBus_Out[104]}] [get_ports                \
{stackBus_Out[103]}] [get_ports {stackBus_Out[102]}] [get_ports                \
{stackBus_Out[101]}] [get_ports {stackBus_Out[100]}] [get_ports                \
{stackBus_Out[99]}] [get_ports {stackBus_Out[98]}] [get_ports                  \
{stackBus_Out[97]}] [get_ports {stackBus_Out[96]}] [get_ports                  \
{stackBus_Out[95]}] [get_ports {stackBus_Out[94]}] [get_ports                  \
{stackBus_Out[93]}] [get_ports {stackBus_Out[92]}] [get_ports                  \
{stackBus_Out[91]}] [get_ports {stackBus_Out[90]}] [get_ports                  \
{stackBus_Out[89]}] [get_ports {stackBus_Out[88]}] [get_ports                  \
{stackBus_Out[87]}] [get_ports {stackBus_Out[86]}] [get_ports                  \
{stackBus_Out[85]}] [get_ports {stackBus_Out[84]}] [get_ports                  \
{stackBus_Out[83]}] [get_ports {stackBus_Out[82]}] [get_ports                  \
{stackBus_Out[81]}] [get_ports {stackBus_Out[80]}] [get_ports                  \
{stackBus_Out[79]}] [get_ports {stackBus_Out[78]}] [get_ports                  \
{stackBus_Out[77]}] [get_ports {stackBus_Out[76]}] [get_ports                  \
{stackBus_Out[75]}] [get_ports {stackBus_Out[74]}] [get_ports                  \
{stackBus_Out[73]}] [get_ports {stackBus_Out[72]}] [get_ports                  \
{stackBus_Out[71]}] [get_ports {stackBus_Out[70]}] [get_ports                  \
{stackBus_Out[69]}] [get_ports {stackBus_Out[68]}] [get_ports                  \
{stackBus_Out[67]}] [get_ports {stackBus_Out[66]}] [get_ports                  \
{stackBus_Out[65]}] [get_ports {stackBus_Out[64]}] [get_ports                  \
{stackBus_Out[63]}] [get_ports {stackBus_Out[62]}] [get_ports                  \
{stackBus_Out[61]}] [get_ports {stackBus_Out[60]}] [get_ports                  \
{stackBus_Out[59]}] [get_ports {stackBus_Out[58]}] [get_ports                  \
{stackBus_Out[57]}] [get_ports {stackBus_Out[56]}] [get_ports                  \
{stackBus_Out[55]}] [get_ports {stackBus_Out[54]}] [get_ports                  \
{stackBus_Out[53]}] [get_ports {stackBus_Out[52]}] [get_ports                  \
{stackBus_Out[51]}] [get_ports {stackBus_Out[50]}] [get_ports                  \
{stackBus_Out[49]}] [get_ports {stackBus_Out[48]}] [get_ports                  \
{stackBus_Out[47]}] [get_ports {stackBus_Out[46]}] [get_ports                  \
{stackBus_Out[45]}] [get_ports {stackBus_Out[44]}] [get_ports                  \
{stackBus_Out[43]}] [get_ports {stackBus_Out[42]}] [get_ports                  \
{stackBus_Out[41]}] [get_ports {stackBus_Out[40]}] [get_ports                  \
{stackBus_Out[39]}] [get_ports {stackBus_Out[38]}] [get_ports                  \
{stackBus_Out[37]}] [get_ports {stackBus_Out[36]}] [get_ports                  \
{stackBus_Out[35]}] [get_ports {stackBus_Out[34]}] [get_ports                  \
{stackBus_Out[33]}] [get_ports {stackBus_Out[32]}] [get_ports                  \
{stackBus_Out[31]}] [get_ports {stackBus_Out[30]}] [get_ports                  \
{stackBus_Out[29]}] [get_ports {stackBus_Out[28]}] [get_ports                  \
{stackBus_Out[27]}] [get_ports {stackBus_Out[26]}] [get_ports                  \
{stackBus_Out[25]}] [get_ports {stackBus_Out[24]}] [get_ports                  \
{stackBus_Out[23]}] [get_ports {stackBus_Out[22]}] [get_ports                  \
{stackBus_Out[21]}] [get_ports {stackBus_Out[20]}] [get_ports                  \
{stackBus_Out[19]}] [get_ports {stackBus_Out[18]}] [get_ports                  \
{stackBus_Out[17]}] [get_ports {stackBus_Out[16]}] [get_ports                  \
{stackBus_Out[15]}] [get_ports {stackBus_Out[14]}] [get_ports                  \
{stackBus_Out[13]}] [get_ports {stackBus_Out[12]}] [get_ports                  \
{stackBus_Out[11]}] [get_ports {stackBus_Out[10]}] [get_ports                  \
{stackBus_Out[9]}] [get_ports {stackBus_Out[8]}] [get_ports {stackBus_Out[7]}] \
[get_ports {stackBus_Out[6]}] [get_ports {stackBus_Out[5]}] [get_ports         \
{stackBus_Out[4]}] [get_ports {stackBus_Out[3]}] [get_ports {stackBus_Out[2]}] \
[get_ports {stackBus_Out[1]}] [get_ports {stackBus_Out[0]}]]
