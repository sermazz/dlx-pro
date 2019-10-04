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
