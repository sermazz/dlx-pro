; VECTOR SUM Test - DURATION: 464ns @ Clk = 1ns
; The following asm code focuses on the test of a for loop to traverse a vector in memory;
; the prediction of the BHT is tested here, along with the correction when a misprediction
; happens. Also, several loads and stores are performed to test the communication with the
; data memory. Many data hazards have been induced to test forwarding and stalls. Within
; the loop, the elements of the vector are elaborated exploting several modules of the ALU,
; (adder, shifter, mult) so that also arithmetic-logic functionalities gets tested.

		addi r1, r0, #50	;number of elements N					
		add r2, r0, r0		;initialize mem address                 
		add r3, r0, r0		;initialize temp sum                   
		addi r5, r0, #5

loop:
		lw r4, 0(r2)		;load array element in r4 from Mem[r2]  - forwarding of r2 from MEM/WB.ALUOut to ALUIn_A (at first iteration: OUT <= IN for RegFile)
		slli r4, r4, #2		;R4 <= R4 * 4 (2 bits left shift)		- STALL for RAW of r4 + forwarding of r4 from MEM/WB.LMD to ALUIn_A
		mult r4, r5, r4		;R4 <= R4 * 5							- forwarding of r4 from EX/MEM.ALUOut to ALUIn_B
		add r3, r3, r4		;temp sum = temp sum + new element      
		sw 0(r2), r0		;clear array element in memory (just to test stores)
		subi r1, r1, #1		;N = N-1                           
		addi r2, r2, #4		;update memory index to address following vector element
		bnez r1, loop		;1st and 2nd loop: mispredicted as NotTaken - FLUSH of sw + fetch of a BUBBLE + PC correction to lw
					;3rd to 49th loop: correctly predicted as Taken
					;50th loop: mispredicted as Taken - FLUSH of lw + fetch of a BUBBLE + PC correction to sw

		200(r0), r3		;write final result in memory (it should be 24500 = 0x00005FB4 written @ DRAM[200])

end:
		j end