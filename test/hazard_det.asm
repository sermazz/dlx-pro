; HAZARDS Test - DURATION: 43ns @ Clk = 1ns
; Test of all data hazards managed by the Hazard Detection Unit with stalls and forwarding

		;OUTPUT = I-Type ALU instructions
		addi r1, r0, #50
		subi r2, r1, #10	; hazard #9 for r1									- r1 from EX/MEM.ALUOut to ALU_InA
		add r3, r1, r2		; hazard #11 for r1 + hazard #10 for r2				- r1 from MEM/WB.ALUOut to ALU_InA + r2 from EX/MEM.ALUOut to ALU_InB
		sub r4, r1, r2		; hazard #12 for r2 + RF struct hazard for r1		- r1 from RF_DataIn to RF_RdOut1   + r2 from MEM/WB.ALUOut to ALU_InB
		and	r5, r1, r2		; RF struct hazard for r2							- r2 from RF_DataIn to RF_RdOut2
		
		addi r1, r0, #1
		beqz r1, end		; hazard #13 for r1 = generates STALL + hazard #14	- beqz stalls during ID + r1 from EX/MEM.ALUOut to B&J Logic
		
		ori r2, r0, #65535
		sw 0(r0), r2		; hazard #15 for r2 								- r2 from MEM/WB.ALUOut to DRAM_DataIn
		sb 0(r0), r2		; hazard #16 for r2 								- r2 from MEM/WB.ALUOut to EX/MEM.B
		
		subi r1, r0, #1		; test wheter hazards #9 & #10 have priority wrt	
		addi r1, r0, #4369	; hazards #11 & #12: add r2,r1,r1 must use the
		add r2, r1, r1		; newest value of r1, which is addi r1,r0,#65535	- r1 from EX/MEM.ALUOut to ALU_InA and ALU_InB
		
		;OUTPUT = R-Type instructions
		addi r1, r0, #50
		subi r2, r0, #10
		add r3, r1, r2		; hazard #11 for r1 + hazard #10 for r2				- r1 from MEM/WB.ALUOut to ALU_InA + r2 from EX/MEM.ALUOut to ALU_InB
		addi r4, r3, #1		; hazard #1 for r3									- r3 from EX/MEM.ALUOut to ALU_InA
		sub r5, r1, r3		; hazard #4 for r3                                  - r3 from MEM/WB.ALUOut to ALU_InB
		and r3, r1, r5		; hazard #2 for r5                                  - r5 from EX/MEM.ALUOut to ALU_InA
		lw r4, 0(r5)		; hazard #3 for r5		                            - r5 from MEM/WB.ALUOut to ALU_InA
		
		add r1, r0, #1
		beqz r1, end		; hazard #5 for r1 = generates STALL + hazard #6	- beqz stalls during ID + r1 from EX/MEM.ALUOut to B&J Logic
		
		or r2, r0, r1		; there isn't hazard #4 for r1 (which is MEM/WB.ALUOut to ALU_InB) because beqz stalled
		sw 0(r0), r2		; hazard #7 for r2									- r2 from MEM/WB.ALUOut to DRAM_DataIn
		sb 0(r0), r2		; hazard #8 for r2                                  - r2 from MEM/WB.ALUOut to EX/MEM.B
		
		;OUTPUT = I-Type Load instructions
		lw r5, 0(r0)
		addi r6, r5, #10	; hazard #17 for r5 = generate STALL + hazard #19	- addi stalls in ID + r5 from MEM/WB.LMD to ALUIn_A
		lb r5, 0(r0)
		xor r6, r1, r5		; hazard #18 for r5 = generate STALL + hazard #20	- xor stalls in ID + r5 from MEM/WB.LMD to ALUIn_B
		
		lhu r5, 0(r0)
		beqz r5, end		; hazard #21 for r5 = generate STALL + hazard #22 = generate another stall 		- r5 from RF_DataIn to RF_RdOut1
		
		lbu r5, 0(r0)
		sw 20(r0), r5		; hazard #23 for r5									- r5 from MEM/WB.LMD to DRAM_DataIn
		sb 25(r0), r5		; hazard #24 for r5                                 - r5 from MEM/WB.LMD to EX/MEM.B
		
end:
		j end
		