# Custom DLX-pro microprocessor architecture
The aim of this project has been to develop from scratch a DLX microprocessor architecture, limited to its integer part, with custom functionalities. The stages of the project encompassed the RTL design of the architecture, its simulation by means of custom asm benchmarks, the synthesis of a netlists exploiting the Nangate Open Cell Library and, finally, its physical design.

The main features of the developed DLX include:
* **Extended instruction set** including almost the whole default integer ISA of the DLX and a custom integer *mult*;
* **extended datapath** to perform all instructions: integer multiplier, jump register logic,
multiple format alignments for data memory;
* **architectural optimizations**: latency-optimized adder, latency-optimized multiplier,
structural logic unit, structural general-purpose comparator, power-optimized ALU;
* **windowed register file** with a stack for spill and fill operations;
* **data hazards detection unit** with forwarding logic management and stalls issuing;
* **control hazard management logic** with branch history table and anticipated target
address computation.

For an extensive description of the DLX architecture and its functioning, refer to the report in the `docs` folder.

## Files organization
    .
    ├── docs ........................ Documentation of the project
    ├── libs ........................ Libraries which might not be included in ModelSim by default
    │   ├── NangateOpenCellLibrary
    │   └── vital2000
    ├── phy ......................... Physical design directory
    │   ├── outputs ................. Output of physical design: post-routing netlist, delay annotation
    │   └── reports ................. Timing and parasitics reports, power analysis, ...
    ├── script ...................... Custom assembler scripts for asm programs
    │   └── assembler.bin
    ├── sim ......................... Simulation directory, containing sim and post-syn sim scripts
    │   ├── outputs ................. Output of simulations: switching activity annotations files
    │   └── testbenches ............. All testbenches of the whole DLX and its individual modules
    ├── src ......................... VHDL source files of the custom DLX
    ├── syn ......................... Synthesis directory, containing synthesis and optimization scripts
    │   ├── netlists ................ Output netlists of the various synthesis processes
    │   └── reports ................. Timing, power and area reports of the various synthesized netlists
    └── test ........................ Asm programs used for simulation purposes
