; VECTOR MIN & MAX Test - DURATION: 245ns @ Clk = 1ns
; This test focuses on the behaviour of the Branch&Jump logic, testing the functioning
; of the prediction logic and branches/jumps anticipation, highlighting control hazards
; and their solutions. Also jumps register (jr, jalr), with their delay slot, and jumps
; (j, jal) are tested

		addi r1, r0, main
		jalr r1
		nop					;delay slot

main:
		addi r1, r0, #20	;number of elements N					
		add r2, r0, r0		;initialize mem address	to 0

		beqz r1, end		;end program if vector is empty             
		lw r10, 0(r2)		;initialize temp max
		lw r11, 0(r2)		;initialize temp min
		subui r1, r1, #1	;adjust index
		beqz r1, end		;if vector had only 1 element			- STALL because r1 is not ready + forward from EX/MEM.ALUOut
		addui r2, r2, #4	;adjust mem address

loop:
		lw r5, 0(r2)		;load array element from Mem[r2]		- forward r2 from EX/MEM.ALUOut to ALUIn_A only at first iteration
		;check if r5 is a temp max
		sgt r8, r5, r10											   ;- STALL + forward r5 from MEM/WB.LMD to ALUIn_A
		beqz r8, no_max		;a FLUSH due to mispred of this branch might happen at the same cc of a STALL: this doesn't create any problem because STALL has priority (enable)
			addi r10, r5, #0
			j no_min
no_max:
		;check if r5 is a temp min
		slt r8, r5, r11
		beqz r8, no_min
			addi r11, r5, #0
no_min:
		subi r1, r1, #1		;N = N-1                           
		addi r2, r2, #4		;update mem address
		bnez r1, loop

		sw 4(r2), r10 		;should be 0x733AA000 stored @ DRAM[84]
		sw 8(r2), r11		;should be 0xFF0F1F3F stored @ DRAM[88]
 
end:	
		addi r4, r0, end
		jr r4
		nop					;delay slot