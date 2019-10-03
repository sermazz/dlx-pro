--#######################################################################################
--
--					DLX ARCHITECTURE - Custom Implementation (PRO version)
--								Politecnico di Torino
--						  Microelectronic Systems, A.Y. 2018/19
--							  Prof. Mariagrazia Graziano
--
-- Author: Sergio Mazzola
-- Contact: s.mazzola@outlook.com
-- 
-- File: a.a-CU_HW.vhd
-- Date: September 2019
-- Brief: Hardwired Control Unit to manage the custom DLX datapath
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

-- ######## HARDWIRED CONTROL UNIT for DLX ########
-- This entity implements an hardwired control unit to manage the datapath of a custom DLX
-- processor. The main component of the CU is its ROM, composed of MEM_SIZE words of CW_SIZE
-- bits: each bit is a control signal for a component of the datapath. The control words are
-- extracted in a combinational way from the ROM and the first stage of the pipeline, the IF
-- is fed with the first signals, the the remaining ones are pipelined to correctly manage
-- the following stages; in a similar way, the operation code for the ALU and the signals
-- for RML (RegisterFile Management Logic for windowing) are generated; such signals are
-- similarly pipelined according to the datapath pipeline stages.
-- Note that a STALL and a MISPREDICTION input signals are present: when a stall (flush of
-- ID/EX and recirculating of IF/ID registers) or a misprediction (flush of IF/ID registers)
-- happen in the datapath pipeline, control signals have indeed to follow the same path.

entity dlx_cu is
	generic(
		MEM_SIZE 		: integer := 62;			-- Microcode Memory size
		CW_SIZE         : integer := 30;			-- Control Word size
		IR_SIZE         : integer := Nbit_INSTR		-- Instruction Register size
		
		-- Opcode and func field sizes are not generic but taken directly from the package
		-- myTypes in order to make IR_opcode and IR_func signals locally static for case/when
	);                                  
	port(
		Clk             		: in std_logic; 					-- Clock
		Rst             		: in std_logic; 					-- Reset (active-low) 
		stall					: in std_logic;
		misprediction			: in std_logic;
		-- Instruction Register
		IR_IN           		: in std_logic_vector(IR_SIZE - 1 downto 0);
		
		-- **INSTRUCTION FETCH** control signals
		MUXImmTA_SEL			: out std_logic;					-- Imm to sum to PC for Target Address (branch/jump)
		-- IF/ID latches
		NPC_LATCH_IFID_EN   	: out std_logic;					-- Next Program Counter (PC+4) Register Latch Enable
		TA_LATCH_IFID_EN   		: out std_logic;					-- Target Address Register Latch Enable
		PC_LATCH_IFID_EN   		: out std_logic;					-- Program Counter (PC) Register Latch Enable
		
		-- **INSTRUCTION DECODE** control signals
		MUXImm_SEL				: out std_logic_vector(1 downto 0);	-- Mux for extended immediate selection
		RF_RD1EN				: out std_logic;					-- RegFile Read port 1 Enable
		RF_RD2EN				: out std_logic;					-- RegFile Read port 2 Enable
		-- ID/EX latches
		RegA_LATCH_IDEX_EN   	: out std_logic; 					-- Register A Latch Enable
		RegB_LATCH_IDEX_EN   	: out std_logic; 					-- Register B Latch Enable
		RegIMM_LATCH_IDEX_EN 	: out std_logic; 					-- Immediate Register Latch Enable
		LPC_LATCH_IDEX_EN 		: out std_logic;					-- Link Address Register Latch Enable
		-- RegisterFile Management Logic
		RF_CALL					: out std_logic;					-- Signals a Subroutine Call to the Register File
		RF_RET					: out std_logic;					-- Signals a Subroutine Return to the Register File
		
		-- **EXECUTION** control signals
		MUXB_SEL        		: out std_logic; 					-- ALU input B Mux Sel
		-- EX/MEM latches
		ALUOUT_LATCH_EXMEM_EN	: out std_logic; 					-- ALU Output Register Enable
		RegB_LATCH_EXMEM_EN   	: out std_logic;					-- Register B Latch Enable
		LPC_LATCH_EXMEM_EN 		: out std_logic;					-- Link Address Register Latch Enable
		-- ALU Opcode				
		ALU_OPCODE      		: out aluOp;    					-- Implicit coding (defined in myTypes)
		
		-- **MEMORY** control signals		
		DRAM_WE         		: out std_logic; 					-- Data RAM Write Enable
		DRAM_RE					: out std_logic;					-- Data RAM Read Enable
		DRAMOP_SEL				: out std_logic; 					-- Data RAM operation selection (on word or on byte)
		MUXLPC_SEL				: out std_logic; 					-- Mux for Link Address selection (PC+4 for JAL, PC+8 for JALR)
		MUXLMD_SEL				: out std_logic_vector(1 downto 0); -- Mux for selection of extension mode for Data RAM output
		-- MEM/WB latches
		LMD_LATCH_MEMWB_EN    	: out std_logic; 					-- Load Memory Data Register Latch Enable
		ALUOUT_LATCH_MEMWB_EN	: out std_logic;					-- ALU Output Register Enable
		LPC_LATCH_MEMWB_EN		: out std_logic;					-- Link Address Register Latch Enable
		
		-- **WRITE BACK** control signals				
		RF_WE           		: out std_logic;					-- Register File Write Enable
		MUXWrAddr_SEL			: out std_logic_vector(1 downto 0);	-- Mux for selection of RF Write Address
		MUXWB_SEL      			: out std_logic_vector(1 downto 0) 	-- Write Back MUX Sel
	);
end dlx_cu;

architecture dlx_cu_hw of dlx_cu is

	type mem_array is array (natural range <>) of std_logic_vector(CW_SIZE-1 downto 0);
	
	-- Instructions opcode encodings correspond to addresses of the following memory,
	-- which contains the whole control words to drive the datapath for each instruction
	-- NB: All addresses not corresponding to instructions opcode of the ISA are NOP
	
	signal cw_mem : mem_array(0 to MEM_SIZE-1);
	-- Constant used to set the memory, since initial value is not supported in synthesis
	constant CW_MEM_INIT : mem_array(0 to MEM_SIZE-1) := (	
									"000000111100010000000001010001", 	-- 0x00 - R-type
									"000000000000000000000000000000", 	-- 0x01
									"100000000000000000000000000000", 	-- 0x02 - J
									"110000000001000100000000111010", 	-- 0x03 - JAL
									"011100100000000000000000000000", 	-- 0x04 - BEQZ
									"011100100000000000000000000000", 	-- 0x05 - BNEZ
									"000000000000000000000000000000", 	-- 0x06
									"000000000000000000000000000000", 	-- 0x07
									"000001101010110000000001010101", 	-- 0x08 - ADDI
									"000000101010110000000001010101",	-- 0x09 - ADDUI	(pro)         	
									"000001101010110000000001010101", 	-- 0x0A - SUBI
									"000000101010110000000001010101", 	-- 0x0B - SUBUI	(pro) 	
									"000000101010110000000001010101", 	-- 0x0C - ANDI
									"000000101010110000000001010101", 	-- 0x0D - ORI
									"000000101010110000000001010101", 	-- 0x0E - XORI
									"000010000010110000000001010101", 	-- 0x0F - LHI 	(pro)	  
									"000000000000000000000000000000", 	-- 0x10
									"000000000000000000000000000000", 	-- 0x11
									"000000100000000000000000000000", 	-- 0x12 - JR 	(pro)	  
									"010000100001000100010000111010", 	-- 0x13 - JALR 	(pro)	  
									"000000101010110000000001010101", 	-- 0x14 - SLLI
									"000000000000000000000000000000", 	-- 0x15 - NOP
									"000000101010110000000001010101", 	-- 0x16 - SRLI
									"000000101010110000000001010101", 	-- 0x17 - SRAI 	(pro)	  
									"000001101010110000000001010101", 	-- 0x18 - SEQI 	(pro)	  
									"000001101010110000000001010101", 	-- 0x19 - SNEI	
									"000001101010110000000001010101", 	-- 0x1A - SLTI 	(pro)	  
									"000001101010110000000001010101", 	-- 0x1B - SGTI 	(pro)	  
									"000001101010110000000001010101", 	-- 0x1C - SLEI
									"000001101010110000000001010101", 	-- 0x1D - SGEI
									"000000000000000000000000000000", 	-- 0x1E
									"000000000000000000000000000000", 	-- 0x1F
									"000001101010110001001110010100", 	-- 0x20 - LB 	(pro)	  
									"000000000000000000000000000000", 	-- 0x21
									"000000000000000000000000000000", 	-- 0x22
									"000001101010110001000010010100", 	-- 0x23 - LW
									"000001101010110001001010010100", 	-- 0x24 - LBU 	(pro)	  
									"000001101010110001000110010100", 	-- 0x25 - LHU 	(pro)	  
									"000000000000000000000000000000", 	-- 0x26
									"000000000000000000000000000000", 	-- 0x27
									"000001111110111010100000000000", 	-- 0x28 - SB 	(pro)	  
									"000000000000000000000000000000", 	-- 0x29
									"000000000000000000000000000000", 	-- 0x2A
									"000001111110111010000000000000", 	-- 0x2B - SW
									"000000000000000000000000000000", 	-- 0x2C
									"000000000000000000000000000000", 	-- 0x2D
									"000000000000000000000000000000", 	-- 0x2E
									"000000000000000000000000000000", 	-- 0x2F
									"000000000000000000000000000000", 	-- 0x30
									"000000000000000000000000000000", 	-- 0x31
									"000000000000000000000000000000", 	-- 0x32
									"000000000000000000000000000000", 	-- 0x33
									"000000000000000000000000000000", 	-- 0x34
									"000000000000000000000000000000", 	-- 0x35
									"000000000000000000000000000000", 	-- 0x36
									"000000000000000000000000000000", 	-- 0x37
									"000000000000000000000000000000", 	-- 0x38
									"000000000000000000000000000000", 	-- 0x39
									"000000101010110000000001010101",  	-- 0x3A - SLTUI	(pro) 	
									"000000101010110000000001010101",  	-- 0x3B - SGTUI	(pro) 	
									"000000101010110000000001010101", 	-- 0x3C - SLEUI	(my addition)
									"000000101010110000000001010101"	-- 0x3D - SGEUI	(pro)
								);

	signal IR_opcode 	: std_logic_vector(Nbit_OPCODE - 1 downto 0);	-- OpCode field of IR
	signal IR_func   	: std_logic_vector(Nbit_FUNC - 1 downto 0); 	-- Func field of IR when Rtype
	signal IR_rega		: std_logic_vector(Nbit_GPRAddr - 1 downto 0);	-- Address of register A

	-- Shifted control words to match each stage of the	pipeline
	signal cw1 : std_logic_vector(CW_SIZE - 1 downto 0); 		-- stage #1 - feeds IF (PC level)
	signal cw2 : std_logic_vector(CW_SIZE - 1 - 4 downto 0); 	-- stage #2 - feeds ID (IF/ID level)
	signal cw3 : std_logic_vector(CW_SIZE - 1 - 12 downto 0); 	-- stage #3 - feeds EX (ID/EX level)
	signal cw4 : std_logic_vector(CW_SIZE - 1 - 16 downto 0); 	-- stage #4 - feeds MEM (EX/MEM level)
	signal cw5 : std_logic_vector(CW_SIZE - 1 - 25 downto 0); 	-- stage #5 - feeds WB (MEM/WB level)

	-- Propagation of ALU Opcode until EX stage
	signal ALUop1, ALUop2, ALUop3  : aluOp;
	
	-- Propagation of RML signls until ID stage
	signal RMLcw1, RMLcw2 : std_logic_vector(1 downto 0);

begin
	cw_mem <= CW_MEM_INIT;
	
	-- Take opcode and func fields of the input IR
	IR_opcode 	<= IR_IN(IR_SIZE - 1 downto IR_SIZE - Nbit_OPCODE);
	IR_func		<= IR_IN(Nbit_FUNC - 1 downto 0);
	IR_rega 	<= IR_IN(IR_SIZE - Nbit_OPCODE - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr);


	-- Update cw1 in a combinational way (as soon as input opcode changes)
	cw1 <= cw_mem(to_integer(unsigned(IR_opcode)));


	-- purpose: Generation of ALU OpCode
	-- type   : combinational
	-- inputs : IR_opcode, IR_func
	-- outputs: ALUop1
	NEXT_ALUOP : process(IR_opcode, IR_func)
	begin

		case IR_opcode is
		
			when RTYPE =>	-- case of R type requires analysis of FUNC field
							case IR_func is
								when F_SLL	=> ALUop1 <= LSL; 	
								when F_SRL	=> ALUop1 <= RSL; 	
								when F_SRA	=> ALUop1 <= RSA;	
								when F_ADD	=> ALUop1 <= ADD;
								when F_ADDU	=> ALUop1 <= ADD;
								when F_SUB	=> ALUop1 <= SUB;
								when F_SUBU	=> ALUop1 <= SUB;
								when F_AND	=> ALUop1 <= ANDalu;
								when F_OR	=> ALUop1 <= ORalu;
								when F_XOR	=> ALUop1 <= XORalu;
								when F_SEQ	=> ALUop1 <= EQ;		
								when F_SNE	=> ALUop1 <= NE;		
								when F_SLT	=> ALUop1 <= LT;		
								when F_SGT	=> ALUop1 <= GT;    
								when F_SLE	=> ALUop1 <= LE;		
								when F_SGE	=> ALUop1 <= GE;		
								when F_SLTU	=> ALUop1 <= LTU;	
								when F_SGTU	=> ALUop1 <= GTU;
								when F_SLEU => ALUop1 <= LEU;
								when F_SGEU	=> ALUop1 <= GEU;	
								when F_MULT	=> ALUop1 <= MULT;
								when others => ALUop1 <= NOP;
							end case;

			when JTYPE_J 	=> ALUop1 <= NOP;
			when JTYPE_JAL  => ALUop1 <= NOP;
			when ITYPE_BEQZ => ALUop1 <= NOP;
			when ITYPE_BNEZ => ALUop1 <= NOP;
			when ITYPE_ADDI => ALUop1 <= ADD;
			when ITYPE_ADDUI=> ALUop1 <= ADD;
			when ITYPE_SUBI => ALUop1 <= SUB;
			when ITYPE_SUBUI=> ALUop1 <= SUB;
			when ITYPE_ANDI => ALUop1 <= ANDalu;
			when ITYPE_ORI 	=> ALUop1 <= ORalu;
			when ITYPE_XORI => ALUop1 <= XORalu;
			when ITYPE_LHI 	=> ALUop1 <= THR_B;
			when ITYPE_JR 	=> ALUop1 <= NOP;
			when ITYPE_JALR	=> ALUop1 <= NOP;
			when ITYPE_SLLI => ALUop1 <= LSL;
			when ITYPE_NOP 	=> ALUop1 <= NOP;
			when ITYPE_SRLI => ALUop1 <= RSL;
			when ITYPE_SRAI	=> ALUop1 <= RSA;
			when ITYPE_SEQI	=> ALUop1 <= EQ;
			when ITYPE_SNEI => ALUop1 <= NE;
			when ITYPE_SLTI	=> ALUop1 <= LT;
			when ITYPE_SGTI	=> ALUop1 <= GT;
			when ITYPE_SLEI => ALUop1 <= LE;
			when ITYPE_SGEI => ALUop1 <= GE;
			when ITYPE_LB	=> ALUop1 <= ADD;
			when ITYPE_LW 	=> ALUop1 <= ADD;
			when ITYPE_LBU	=> ALUop1 <= ADD;
			when ITYPE_LHU	=> ALUop1 <= ADD;
			when ITYPE_SB	=> ALUop1 <= ADD;
			when ITYPE_SW 	=> ALUop1 <= ADD;
			when ITYPE_SLTUI=> ALUop1 <= LTU;
			when ITYPE_SGTUI=> ALUop1 <= GTU;
			when ITYPE_SLEUI=> ALUop1 <= LEU;
			when ITYPE_SGEUI=> ALUop1 <= GEU;
			when others 	=> ALUop1 <= NOP;
			
		end case;
	end process NEXT_ALUOP;
	
	
	-- purpose: Generation of new signals for Register Management Logic
	-- type   : combinational
	-- inputs : IR_opcode, IR_rega
	-- outputs: RMLcw1
	NEXT_RML : process(IR_IN, IR_opcode, IR_rega)
	begin
		-- CALL control signal management logic
		if (IR_opcode = JTYPE_JAL OR IR_opcode = ITYPE_JALR) then
			-- CALL is 1 if the instruction is a Jump&Link (either J-Type or JR-Type)
			RMLcw1(1) <= '1';
		else
			RMLcw1(1) <= '0';
		end if;
		
		-- RETURN control signal management logic
		if (IR_opcode = ITYPE_JR AND IR_rega = "10111") then
			-- RETURN is 1 if a Jump Register instructions jumps to R23 (return address)
			
			-- NB: Link Register is R23, the last register of LOCALS group of the routine,
			-- and not R31, which belongs to OUT group and thus to IN group of callee,
			-- so that its direct child subroutine does not have access to return address
			-- and cannot corrupt it, preventing the caller from returing to its parent
			RMLcw1(0) <= '1';
		else
			RMLcw1(0) <= '0';
		end if;
	end process NEXT_RML;
	
	
	-- purpose: Pipeline generated control signals
	-- type   : sequential
	-- inputs : stall, misprediction
	-- outputs: pipelined control words
	CW_PIPE : process(Clk, Rst)
	begin                               
		if (Rst = '0') then               		-- asynchronous reset (active-low)
			cw2		<= (others => '0');
			cw3		<= (others => '0');
			cw4		<= (others => '0');
			cw5		<= (others => '0');
			ALUop2 	<= NOP;
			ALUop3 	<= NOP;
			RMLcw2 	<= (others => '0');
		elsif (Clk = '1' AND Clk'EVENT) then  	-- rising clock edge
		
			if (stall = '1') then	-- (priority given to STALL rather than to MISPREDICTION)
				-- Recirculate control signals of IF stage (IF/ID level)
				
				-- since cw1, ALUop1, RMLcw1 are combinationally updated basing on IR_out of IRAM
				-- the stall of such signals is automatically achieved by the datapath stalling
				-- the current instruction in the IF stage: since PC to address the IRAM stays
				-- the same when the IF stage stalls, also IR_out remains the same, and so do cw1,
				-- ALUop1 and RMLcw1
				
				-- Flush control signals going to EX stage (ID/EX level)
				cw3	<= (others => '0');
				ALUop3 	<= NOP;
			else
				
				if (misprediction = '1') then
					-- Flush control signals going to ID (IF/ID level)
					cw2	<= (others => '0');
					ALUop2 	<= NOP;
					RMLcw2 	<= (others => '0');
				else
					cw2 <= cw1(CW_SIZE - 1 - 4 downto 0);
					ALUop2 <= ALUop1;
					RMLcw2 	<= RMLcw1;
				end if;
				
				-- If there are no stalls, assign cw3, ALUop3 independently from misprediction
				cw3 <= cw2(CW_SIZE - 1 - 12 downto 0);
				ALUop3 <= ALUop2;
				
			end if;
			
			-- Asign cw4, cw5 in any case
			cw4 <= cw3(CW_SIZE - 1 - 16 downto 0);
			cw5 <= cw4(CW_SIZE - 1 - 25 downto 0);
			
		end if;
	end process CW_PIPE;
	
	
	
	-- stage #1 control signals
	MUXImmTA_SEL		<= cw1(CW_SIZE - 1);   
	NPC_LATCH_IFID_EN   <= cw1(CW_SIZE - 2);
	TA_LATCH_IFID_EN  	<= cw1(CW_SIZE - 3);
	PC_LATCH_IFID_EN	<= cw1(CW_SIZE - 4);
	
	-- stage #2 control signals
	MUXImm_SEL				<= cw2(CW_SIZE - 5 downto CW_SIZE - 6);
	RF_RD1EN				<= cw2(CW_SIZE - 7);
	RF_RD2EN                <= cw2(CW_SIZE - 8);
	RegA_LATCH_IDEX_EN		<= cw2(CW_SIZE - 9);
	RegB_LATCH_IDEX_EN		<= cw2(CW_SIZE - 10);
	RegIMM_LATCH_IDEX_EN	<= cw2(CW_SIZE - 11);
	LPC_LATCH_IDEX_EN		<= cw2(CW_SIZE - 12);
	
	RF_CALL					<= RMLcw2(1);
	RF_RET					<= RMLcw2(0);
 
	-- stage #3 control signals
	MUXB_SEL        		<= cw3(CW_SIZE - 13);
	ALUOUT_LATCH_EXMEM_EN	<= cw3(CW_SIZE - 14);
	RegB_LATCH_EXMEM_EN   	<= cw3(CW_SIZE - 15);
	LPC_LATCH_EXMEM_EN 		<= cw3(CW_SIZE - 16);
	
	ALU_OPCODE      		<= ALUop3;
	
	-- stage #4 control signals
	DRAM_WE         		<= cw4(CW_SIZE - 17);
	DRAM_RE					<= cw4(CW_SIZE - 18);
	DRAMOP_SEL				<= cw4(CW_SIZE - 19);
	MUXLPC_SEL				<= cw4(CW_SIZE - 20);
	MUXLMD_SEL              <= cw4(CW_SIZE - 21 downto CW_SIZE - 22);
	LMD_LATCH_MEMWB_EN    	<= cw4(CW_SIZE - 23);
	ALUOUT_LATCH_MEMWB_EN	<= cw4(CW_SIZE - 24);
	LPC_LATCH_MEMWB_EN		<= cw4(CW_SIZE - 25);
	
	-- stage #5 control signals
	RF_WE           		<= cw5(CW_SIZE - 26);
	MUXWrAddr_SEL			<= cw5(CW_SIZE - 27 downto CW_SIZE - 28);
	MUXWB_SEL      			<= cw5(CW_SIZE - 29 downto CW_SIZE - 30);	
	
end dlx_cu_hw;

configuration CFG_DLX_HWCU of dlx_cu is
	for dlx_cu_hw
	end for;
end CFG_DLX_HWCU;