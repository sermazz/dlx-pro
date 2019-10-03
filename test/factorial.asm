; FACTORIAL Test - DURATION: 123ns @ Clk = 1ns
; This test encompasses the computation of the factorial of the number stored from the
; "main" routine in r24; the max value for such input, with the given architecture, is
; 8 since the multiplier of the designed integer datapath only handles 16 bits input
; so that the multiplication 1x2x3x4x5x6x7x8 = 0x9D80 results negative on 16 bits and
; the further multiplication by 9, being signed, would give a wrong result.
; The following asm program is based on recursive calls of the same subroutine, so that
; the register management logic gets tested, along with the hazard detection unit which
; has to deal with references to same physical registers but addressed with different
; virtual addresses

; The unique branch (bnez) always gets correctly predicted as Not Taken; only in the
; last subroutine called the prediction is wrong because the input r8 becomes equal to
; 0, so that the prediction changes to "weak Not Taken" and the SUBI fetched is flushed,
; but then the branch is never traversed anymore since the program concludes

; In the initial phase there are many stalls due to the subsequent subroutine calls,
; which need to spill data to stack when the nested recursive calls take more than 8
; windows; in the last phase stalls are mainly due to fills needed to recover the data
; of the spilled registers.

;SUBROUTINE 0
		jal main

;SUBROUTINE 2,3,4,5,6,7,8(0),9(1),10(2)
fact:
		slei r16, r8, #0	;if r8 (INPUT var) <= 0, set r16 (LOCAL var)	- forward r8 from MEM/WB.ALUout to ALUIn_A
		bnez r16, put_one	;base of recursion								- STALL because r16 is not ready + forward from EX/MEM.ALUOut to B&JLogic
		subi r24, r8, #1	;set r24 (OUTPUT var) = r8-1
		jal fact			;recurr on fact subroutine with new input in r24, which will be r8 of callee
		mult r8, r8, r24	;multiply input of this routine call with the value returned by called subroutine
		jr r23				;return the result of multiplication to caller
		nop

put_one:
		addi r8, r0, #1		;base of recursion, return 1 if input r8 is 0
		jr r23				;return
		nop


;SUBROUTINE 1
main:
		addi r24, r0, #8	;load input in R4 (OUTPUT var)
		jal fact			;call fact routine with input r24 = 8, which will be input of fact in r8

end:
		j end				;result should be 40.320 = 0x00009D80 store @ RegFile[40] = R24 of subroutine 1 (main)
