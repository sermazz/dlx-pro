; ISA Test - DURATION: 84ns @ Clk = 1ns
; Test of all instructions of the Instruction Set (but branches & jumps, tested within
; other programs), to verify the correctness of the output of each submodule

		;initialize data
		addui r1, r0, #65535
		addi r2, r0, #10000
		addi r3, r0, #-15000	;5 LSBs are "01000"
		addi r4, r0, #-1		;all ones

;R-Type
		add r5,r1,r2
		addu r5,r1,r2
		sub r5,r1,r3
		subu r5,r1,r2
		mult r5,r2,r3
		and r6,r4,r1
		or r6,r4,r1
		xor r6,r4,r1
		sgt r7,r2,r1
		sgt r7,r3,r1
		sge r7,r2,r1
		sge r7,r1,r1
		slt r7,r3,r2
		slt r7,r2,r3
		sle r7,r3,r4
		sle r7,r4,r3
		sle r7,r2,r2
		seq r7,r1,r2
		seq r7,r1,r1
		sne r7,r1,r1
		sne r7,r1,r2
		sgtu r7,r4,r2
		sgtu r7,r2,r4
		sgeu r7,r1,r3
		sgeu r7,r3,r1
		sltu r7,r3,r1
		sltu r7,r1,r3
		sleu r7,r1,r3
		sleu r7,r3,r1
		sll r8,r3,r3
		srl r8,r3,r3
		sra r8,r3,r3
		
;I-Type (no branches/jumps)
		addi r5,r0,#24
		addi r5,r2,#-4
		addui r5,r2,#4
		subi r5,r0,#1
		subi r5,r2,#-1
		subui r5,r2,#3
		andi r6,r4,#65535	;Imm16 = 16 bits all 1
		ori r6,r1,#43690	;Imm16 = 16 bits alternated 1 and 0
		xori r6,r1,#43690
		sgti r7,r1,#200
		sgti r7,r1,#70000
		sgei r7,r1,#65535
		sgei r7,r1,#220
		slti r7,r1,#80000
		slti r7,r1,#5
		slei r7,r1,#50
		slei r7,r1,#65535
		seqi r7,r1,#65535
		seqi r7,r1,#65534
		snei r7,r1,#65535
		snei r7,r1,#8
		sgtui r7,r1,#3
		sgtui r7,r1,#70000
		sgeui r7,r1,#4
		sgeui r7,r1,#70000
		sltui r7,r1,#1
		sltui r7,r1,#70000
		sleui r7,r1,#1
		sleui r7,r1,#65535
		slli r8,r4,#4
		srli r8,r4,#5
		srai r8,r2,#3
		srai r8,r3,#3
		
		;initialize
		addi r10, r0, #20
		
;I-Type Load/stores
		sw 12(r0),r3	;absolute addressing
		sw 0(r10),r3	;register deferred addressing
		sw 8(r10),r3	;displacement addressing
		sw -4(r10),r3	;displacement addressing
		sw 20(r10),r3	;test automatic address word alignment
		sw 21(r10),r3 
		sw 22(r10),r3 
		sw 23(r10),r3 
		sw 24(r10),r3 
		sw 25(r10),r3 
		sb 40(r10),r2
		sb 41(r10),r3
		sb 43(r10),r4
		lw r20,20(r10)
		lw r21,23(r10)	;test automatic address word alignment
		lb r20,20(r10)
		lb r21,23(r10)
		lbu r20,20(r0)
		lbu r21,23(r1)
		lhu r20,20(r0)
		lhu r21,23(r1)	;test automatic address half word alignment
		lhi r20,#65535
		
end:	
		j end