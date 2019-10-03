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
-- File: a.b-DataPath.core\c-HazardDet_Unit.vhd
-- Date: September 2019
-- Brief: Combinational Hazard Detection Unit for forwarding and stalls management
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.functions.all;

-- ######## HAZARD DETECTION UNIT for DLX ########
-- This entity implements a combinational Hazard Detection Unit, in charge of analysing and
-- comparing the instructions in the pipeline during each clock cycle, issuing STALLS when
-- necessary and managing the control signals for the FORWARDING multiplexers.
-- The output STALL signal is meant to drive a flush signal (which should be nothing else
-- than a synchronous reset) for the ID/EX storage block and, after being inverted, the enable
-- signal for the PC register and the IF/ID storage block, preventing them from updating with
-- a new instruction and propagating a bubble starting froom ID stage when a stall is needed.

-- Note that the behaviour of this Hazard Detection Unit is adapted to the presence of a
-- Windowed Register File in the datapath: this implies that two instructions in the pipeline
-- may refer to the same physical register even if addressed with different addresses (e.g.
-- r24 of the OUTPUTs and r8 of its subroutine INPUTs); to overcome this problem, the addresses
-- of the registers, stored in the IR of each state, have to be first translated into physical
-- addresses and then the comparisons to detect hazards can happen.

entity hdu_dlx is
	generic(
		IR_SIZE         : integer := Nbit_INSTR		-- Instruction Register size
	);                                  
	port(
		-- Instruction Registers of different stages
		IR_IFID           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
		IR_IDEX           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
		IR_EXMEM           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
		IR_MEMWB          		: in  std_logic_vector(IR_SIZE - 1 downto 0);
		-- Current window pointer (register file with 8 windows)
		CWP_IDEX				: in std_logic_vector(log2(RF_WIND_num)-1 downto 0);
		CWP_EXMEM               : in std_logic_vector(log2(RF_WIND_num)-1 downto 0);
		CWP_MEMWB               : in std_logic_vector(log2(RF_WIND_num)-1 downto 0);
		-- Control signals for Hazard management
		BJ_regA_MUX				: out std_logic;
		ALU_inputA_MUX  		: out std_logic_vector(1 downto 0);
		ALU_inputB_MUX  		: out std_logic_vector(1 downto 0);
		B_latchEM_MUX   		: out std_logic_vector(1 downto 0);
		WrIN_DRAM_MUX   		: out std_logic_vector(1 downto 0);
		STALL					: out std_logic
	);
end hdu_dlx;

architecture Behavioural of hdu_dlx is

	constant M : integer := RF_GLOB_num;  -- registers in GLOBALS group
	constant N : integer := RF_ILO_num;  -- registers per Windowed RegFile group (IN,LOCALS,OUT)
	constant F : integer := RF_WIND_num;	-- number of windows in RegFile

	signal opcode_IFID, opcode_IDEX, opcode_EXMEM, opcode_MEMWB : std_logic_vector(Nbit_OPCODE - 1 downto 0);
	signal rs_IFID, rs_IDEX 									: std_logic_vector(log2(M+2*N*F) - 1 downto 0);
	signal rt_IFID, rt_IDEX, rt_EXMEM, rt_MEMWB					: std_logic_vector(log2(M+2*N*F) - 1 downto 0);
	signal rd_IDEX, rd_EXMEM, rd_MEMWB							: std_logic_vector(log2(M+2*N*F) - 1 downto 0);

begin
	
	-- Opcodes from each pipeline stage to detect which instruction is where
	opcode_IFID  <= IR_IFID(IR_SIZE - 1 downto IR_SIZE - Nbit_OPCODE);
	opcode_IDEX  <= IR_IDEX(IR_SIZE - 1 downto IR_SIZE - Nbit_OPCODE);
	opcode_EXMEM <= IR_EXMEM(IR_SIZE - 1 downto IR_SIZE - Nbit_OPCODE);
	opcode_MEMWB <= IR_MEMWB(IR_SIZE - 1 downto IR_SIZE - Nbit_OPCODE);
	
	-- #### PHYSICAL ADDRESSES COMPUTATION ####
	
	-- purpose: Computation of rs and rt for instruction in IF/ID; the reference window
	--			pointer is CWP from ID/EX level
	-- type   : combinational
	-- inputs : IR_IFID, CWP_IDEX
	-- outputs: rs_IFID, rt_IFID
	process(IR_IFID, CWP_IDEX)
		variable reg_addr : integer;
	begin
		reg_addr := to_integer(unsigned(IR_IFID(IR_SIZE - Nbit_OPCODE - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr)));	-- take address field
		if (reg_addr < M) then
			rs_IFID  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_IDEX));                          	 					-- shift according to corresponding CWP
			rs_IFID  <= (others => '0');
			rs_IFID(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);               	-- wrap around physical register windows
		end if;
		
		reg_addr := to_integer(unsigned(IR_IFID(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2)));
		if (reg_addr < M) then
			rt_IFID  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_IDEX));
			rt_IFID  <= (others => '0');
			rt_IFID(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
	end process;
	
	-- purpose: Computation of rs, rt and rd for instruction in ID/EX; the reference
	--			window pointer is CWP from ID/EX level
	-- type   : combinational
	-- inputs : IR_IDEX, CWP_IDEX
	-- outputs: rs_IDEX, rt_IDEX, rd_IDEX
	process(IR_IDEX, CWP_IDEX)
		variable reg_addr : integer;
	begin
		reg_addr := to_integer(unsigned(IR_IDEX(IR_SIZE - Nbit_OPCODE - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr)));
		if (reg_addr < M) then
			rs_IDEX  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_IDEX));
			rs_IDEX  <= (others => '0');
			rs_IDEX(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
		
		reg_addr := to_integer(unsigned(IR_IDEX(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2)));
		if (reg_addr < M) then
			rt_IDEX  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_IDEX));
			rt_IDEX  <= (others => '0');
			rt_IDEX(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
		
		reg_addr := to_integer(unsigned(IR_IDEX(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2 - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*3)));
		if (reg_addr < M) then
			rd_IDEX  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_IDEX));
			rd_IDEX  <= (others => '0');
			rd_IDEX(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
	end process;
	
	-- purpose: Computation of rt and rd for instruction in EX/MEM; the reference
	--			window pointer is CWP from EX/MEM level (old_CWP1)
	-- type   : combinational
	-- inputs : IR_EXMEM, CWP_EXMEM
	-- outputs: rt_EXMEM, rd_EXMEM
	process(IR_EXMEM, CWP_EXMEM)
		variable reg_addr : integer;
	begin
		reg_addr := to_integer(unsigned(IR_EXMEM(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2)));
		if (reg_addr < M) then
			rt_EXMEM  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_EXMEM));
			rt_EXMEM  <= (others => '0');
			rt_EXMEM(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
		
		reg_addr := to_integer(unsigned(IR_EXMEM(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2 - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*3)));
		if (reg_addr < M) then
			rd_EXMEM  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_EXMEM));
			rd_EXMEM  <= (others => '0');
			rd_EXMEM(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
	end process;
	
	-- purpose: Computation of rt and rd for instruction in MEM/WB; the reference
	--			window pointer is CWP from MEM/WB level (old_CWP2)
	-- type   : combinational
	-- inputs : IR_MEMWB, CWP_MEMWB
	-- outputs: rt_MEMWB, rd_MEMWB
	process(IR_MEMWB, CWP_MEMWB)
		variable reg_addr : integer;
	begin
		reg_addr := to_integer(unsigned(IR_MEMWB(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2)));
		if (reg_addr < M) then
			rt_MEMWB  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_MEMWB));
			rt_MEMWB  <= (others => '0');
			rt_MEMWB(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
		
		reg_addr := to_integer(unsigned(IR_MEMWB(IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*2 - 1 downto IR_SIZE - Nbit_OPCODE - Nbit_GPRAddr*3)));
		if (reg_addr < M) then
			rd_MEMWB  <= std_logic_vector(to_unsigned(reg_addr, log2(M+2*N*F)));
		else
			reg_addr := reg_addr - M + 2*N*to_integer(unsigned(CWP_MEMWB));
			rd_MEMWB  <= (others => '0');
			rd_MEMWB(log2(2*N*F)-1 downto 0)  <= std_logic_vector(to_unsigned(reg_addr, log2(2*N*F)) + M);
		end if;
	end process;
	
	
	-- #### HAZARD ANALYSIS ####
	
	-- purpose: Drive forwarding for branch & jump logic
	-- type   : combinational
	-- output : BJ_regA_MUX
	BJ_regA_MUX_P : process(opcode_IFID, opcode_EXMEM, rs_IFID, rt_EXMEM, rd_EXMEM)
	begin
		BJ_regA_MUX <= '0';
		
		-- ORIGIN = R-type
		if (opcode_EXMEM = RTYPE) then
		-- DESTINATION = Branch/Jump I-type
			if (opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #6
				if (rd_EXMEM = rs_IFID) then
					BJ_regA_MUX <= '1'; -- EX/MEM.ALUOut to REG A FOR BRANCH/JUMP logic
				end if;
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_EXMEM = ITYPE_ADDI OR opcode_EXMEM = ITYPE_ADDUI OR opcode_EXMEM = ITYPE_SUBI OR
			opcode_EXMEM = ITYPE_SUBUI OR opcode_EXMEM = ITYPE_ANDI OR opcode_EXMEM = ITYPE_ORI OR
			opcode_EXMEM = ITYPE_XORI OR opcode_EXMEM = ITYPE_LHI OR opcode_EXMEM = ITYPE_SLLI OR
			opcode_EXMEM = ITYPE_SRLI OR opcode_EXMEM = ITYPE_SRAI OR opcode_EXMEM = ITYPE_SEQI OR
			opcode_EXMEM = ITYPE_SNEI OR opcode_EXMEM = ITYPE_SLTI OR opcode_EXMEM = ITYPE_SGTI OR
			opcode_EXMEM = ITYPE_SLEI OR opcode_EXMEM = ITYPE_SGEI OR opcode_EXMEM = ITYPE_SLTUI OR 
			opcode_EXMEM = ITYPE_SGTUI OR opcode_EXMEM = ITYPE_SLEUI OR opcode_EXMEM = ITYPE_SGEUI) then
		-- DESTINATION = Branch/Jump I-type
			if (opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #14
				if (rt_EXMEM = rs_IFID) then
					BJ_regA_MUX <= '1'; -- EX/MEM.ALUOut to REG A FOR BRANCH/JUMP logic
				end if;
			end if;
		end if;
		
	end process BJ_regA_MUX_P;
	
	
	-- purpose: Drive forwarding for ALU input A
	-- type   : combinational
	-- output : ALU_inputA_MUX
	ALU_inputA_MUX_P : process (opcode_IDEX, opcode_EXMEM, opcode_MEMWB, rs_IDEX, rt_EXMEM, rt_MEMWB, rd_EXMEM, rd_MEMWB)
	begin
		ALU_inputA_MUX <= "00";
		
		-- ORIGIN = R-type
		if (opcode_MEMWB = RTYPE) then
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type
			if (opcode_IDEX = RTYPE OR
				opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
				opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
				opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_SLLI OR opcode_IDEX = ITYPE_SRLI OR
				opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR opcode_IDEX = ITYPE_SNEI OR
				opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR opcode_IDEX = ITYPE_SLEI OR
				opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR opcode_IDEX = ITYPE_SGTUI OR
				opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI OR
				opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
				opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU OR
				opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
				
				-- Hazard #3
				if (rd_MEMWB = rs_IDEX) then
					ALU_inputA_MUX <= "10"; -- MEM/WB.ALUOut to ALU INPUT A
				end if; 
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_MEMWB = ITYPE_ADDI OR opcode_MEMWB = ITYPE_ADDUI OR opcode_MEMWB = ITYPE_SUBI OR
			opcode_MEMWB = ITYPE_SUBUI OR opcode_MEMWB = ITYPE_ANDI OR opcode_MEMWB = ITYPE_ORI OR
			opcode_MEMWB = ITYPE_XORI OR opcode_MEMWB = ITYPE_LHI OR opcode_MEMWB = ITYPE_SLLI OR
			opcode_MEMWB = ITYPE_SRLI OR opcode_MEMWB = ITYPE_SRAI OR opcode_MEMWB = ITYPE_SEQI OR
			opcode_MEMWB = ITYPE_SNEI OR opcode_MEMWB = ITYPE_SLTI OR opcode_MEMWB = ITYPE_SGTI OR
			opcode_MEMWB = ITYPE_SLEI OR opcode_MEMWB = ITYPE_SGEI OR opcode_MEMWB = ITYPE_SLTUI OR 
			opcode_MEMWB = ITYPE_SGTUI OR opcode_MEMWB = ITYPE_SLEUI OR opcode_MEMWB = ITYPE_SGEUI) then
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type
			if (opcode_IDEX = RTYPE OR
				opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
				opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
				opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_SLLI OR opcode_IDEX = ITYPE_SRLI OR
				opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR opcode_IDEX = ITYPE_SNEI OR
				opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR opcode_IDEX = ITYPE_SLEI OR
				opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR opcode_IDEX = ITYPE_SGTUI OR
				opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI OR
				opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
				opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU OR
				opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
				
				-- Hazard #11
				if (rt_MEMWB = rs_IDEX) then
					ALU_inputA_MUX <= "10"; -- MEM/WB.ALUOut to ALU INPUT A
				end if; 
			end if;
		end if;
		
		-- ORIGIN = Load I-type
		if (opcode_MEMWB = ITYPE_LB OR opcode_MEMWB = ITYPE_LW OR
			opcode_MEMWB = ITYPE_LBU OR opcode_MEMWB = ITYPE_LHU) then
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type
			if (opcode_IDEX = RTYPE OR
				opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
				opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
				opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_SLLI OR opcode_IDEX = ITYPE_SRLI OR
				opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR opcode_IDEX = ITYPE_SNEI OR
				opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR opcode_IDEX = ITYPE_SLEI OR
				opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR opcode_IDEX = ITYPE_SGTUI OR
				opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI OR
				opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
				opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU OR
				opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
				
				-- Hazard #19
				if (rt_MEMWB = rs_IDEX) then
					ALU_inputA_MUX <= "11"; -- MEM/WB.LMD to ALU INPUT A
				end if;
			end if;
		end if;
		
		-- ORIGIN = R-type
		if (opcode_EXMEM = RTYPE) then
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type
			if (opcode_IDEX = RTYPE OR
				opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
				opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
				opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_SLLI OR opcode_IDEX = ITYPE_SRLI OR
				opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR opcode_IDEX = ITYPE_SNEI OR
				opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR opcode_IDEX = ITYPE_SLEI OR
				opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR opcode_IDEX = ITYPE_SGTUI OR
				opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI OR
				opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
				opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU OR
				opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
				
				-- Hazard #1
				if (rd_EXMEM = rs_IDEX) then
					ALU_inputA_MUX <= "01"; -- EX/MEM.ALUOut to ALU INPUT A
				end if; 
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_EXMEM = ITYPE_ADDI OR opcode_EXMEM = ITYPE_ADDUI OR opcode_EXMEM = ITYPE_SUBI OR
			opcode_EXMEM = ITYPE_SUBUI OR opcode_EXMEM = ITYPE_ANDI OR opcode_EXMEM = ITYPE_ORI OR
			opcode_EXMEM = ITYPE_XORI OR opcode_EXMEM = ITYPE_LHI OR opcode_EXMEM = ITYPE_SLLI OR
			opcode_EXMEM = ITYPE_SRLI OR opcode_EXMEM = ITYPE_SRAI OR opcode_EXMEM = ITYPE_SEQI OR
			opcode_EXMEM = ITYPE_SNEI OR opcode_EXMEM = ITYPE_SLTI OR opcode_EXMEM = ITYPE_SGTI OR
			opcode_EXMEM = ITYPE_SLEI OR opcode_EXMEM = ITYPE_SGEI OR opcode_EXMEM = ITYPE_SLTUI OR 
			opcode_EXMEM = ITYPE_SGTUI OR opcode_EXMEM = ITYPE_SLEUI OR opcode_EXMEM = ITYPE_SGEUI) then
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type
			if (opcode_IDEX = RTYPE OR
				opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
				opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
				opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_SLLI OR opcode_IDEX = ITYPE_SRLI OR
				opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR opcode_IDEX = ITYPE_SNEI OR
				opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR opcode_IDEX = ITYPE_SLEI OR
				opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR opcode_IDEX = ITYPE_SGTUI OR
				opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI OR
				opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
				opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU OR
				opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
				
				-- Hazard #9
				if (rt_EXMEM = rs_IDEX) then
					ALU_inputA_MUX <= "01"; -- EX/MEM.ALUOut to ALU INPUT A
				end if; 
			end if;
		end if;
		
	end process ALU_inputA_MUX_P;
	
	
	-- purpose: Drive forwarding for ALU input B
	-- type   : combinational
	-- output : ALU_inputB_MUX
	ALU_inputB_MUX_P : process (opcode_IDEX, opcode_EXMEM, opcode_MEMWB, rt_IDEX, rt_EXMEM, rt_MEMWB, rd_EXMEM, rd_MEMWB)
	begin
		ALU_inputB_MUX <= "00";
		
		-- ORIGIN = R-type
		if (opcode_MEMWB = RTYPE) then
		-- DESTINATION = R-type
			if (opcode_IDEX = RTYPE) then
			
				-- Hazard #4
				if (rd_MEMWB = rt_IDEX) then
					ALU_inputB_MUX <= "10"; -- MEM/WB.ALUOut to ALU INPUT B
				end if; 
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_MEMWB = ITYPE_ADDI OR opcode_MEMWB = ITYPE_ADDUI OR opcode_MEMWB = ITYPE_SUBI OR
			opcode_MEMWB = ITYPE_SUBUI OR opcode_MEMWB = ITYPE_ANDI OR opcode_MEMWB = ITYPE_ORI OR
			opcode_MEMWB = ITYPE_XORI OR opcode_MEMWB = ITYPE_LHI OR opcode_MEMWB = ITYPE_SLLI OR
			opcode_MEMWB = ITYPE_SRLI OR opcode_MEMWB = ITYPE_SRAI OR opcode_MEMWB = ITYPE_SEQI OR
			opcode_MEMWB = ITYPE_SNEI OR opcode_MEMWB = ITYPE_SLTI OR opcode_MEMWB = ITYPE_SGTI OR
			opcode_MEMWB = ITYPE_SLEI OR opcode_MEMWB = ITYPE_SGEI OR opcode_MEMWB = ITYPE_SLTUI OR 
			opcode_MEMWB = ITYPE_SGTUI OR opcode_MEMWB = ITYPE_SLEUI OR opcode_MEMWB = ITYPE_SGEUI) then
		-- DESTINATION = R-type
			if (opcode_IDEX = RTYPE) then
			
				-- Hazard #12
				if (rt_MEMWB = rt_IDEX) then
					ALU_inputB_MUX <= "10"; -- MEM/WB.ALUOut to ALU INPUT B
				end if; 
			end if;
		end if;
		
		-- ORIGIN = Load I-type
		if (opcode_MEMWB = ITYPE_LB OR opcode_MEMWB = ITYPE_LW OR
			opcode_MEMWB = ITYPE_LBU OR opcode_MEMWB = ITYPE_LHU) then
		-- DESTINATION = R-type
			if (opcode_IDEX = RTYPE) then
				
				-- Hazard #20
				if (rt_MEMWB = rt_IDEX) then
					ALU_inputB_MUX <= "11"; -- MEM/WB.LMD to ALU INPUT B
				end if;
			end if;
		end if;
		
		-- ORIGIN = R-type
		if (opcode_EXMEM = RTYPE) then
		-- DESTINATION = R-type
			if (opcode_IDEX = RTYPE) then
			
				-- Hazard #2
				if (rd_EXMEM = rt_IDEX) then
					ALU_inputB_MUX <= "01"; -- EX/MEM.ALUOut to ALU INPUT B
				end if; 
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_EXMEM = ITYPE_ADDI OR opcode_EXMEM = ITYPE_ADDUI OR opcode_EXMEM = ITYPE_SUBI OR
			opcode_EXMEM = ITYPE_SUBUI OR opcode_EXMEM = ITYPE_ANDI OR opcode_EXMEM = ITYPE_ORI OR
			opcode_EXMEM = ITYPE_XORI OR opcode_EXMEM = ITYPE_LHI OR opcode_EXMEM = ITYPE_SLLI OR
			opcode_EXMEM = ITYPE_SRLI OR opcode_EXMEM = ITYPE_SRAI OR opcode_EXMEM = ITYPE_SEQI OR
			opcode_EXMEM = ITYPE_SNEI OR opcode_EXMEM = ITYPE_SLTI OR opcode_EXMEM = ITYPE_SGTI OR
			opcode_EXMEM = ITYPE_SLEI OR opcode_EXMEM = ITYPE_SGEI OR opcode_EXMEM = ITYPE_SLTUI OR 
			opcode_EXMEM = ITYPE_SGTUI OR opcode_EXMEM = ITYPE_SLEUI OR opcode_EXMEM = ITYPE_SGEUI) then
		-- DESTINATION = R-type
			if (opcode_IDEX = RTYPE) then
			
				-- Hazard #10
				if (rt_EXMEM = rt_IDEX) then
					ALU_inputB_MUX <= "01"; -- EX/MEM.ALUOut to ALU INPUT B
				end if; 
			end if;
		end if;
		
	end process ALU_inputB_MUX_P;
	
	
	-- purpose: Drive forwarding for latch B of EX/MEM storage block
	-- type   : combinational
	-- output : B_latchEM_MUX
	B_latchEM_MUX_P : process (opcode_IDEX, opcode_MEMWB, rt_IDEX, rt_EXMEM, rt_MEMWB, rd_MEMWB)
	begin
		B_latchEM_MUX <= "00";
		
		-- ORIGIN = R-type
		if (opcode_MEMWB = RTYPE) then
		-- DESTINATION = Store I-type
			if (opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
			
				-- Hazard #8
				if (rd_MEMWB = rt_IDEX) then
					B_latchEM_MUX <= "01"; -- MEM/WB.ALUOut to EX/MEM.B LATCH input
				end if; 
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_MEMWB = ITYPE_ADDI OR opcode_MEMWB = ITYPE_ADDUI OR opcode_MEMWB = ITYPE_SUBI OR
			opcode_MEMWB = ITYPE_SUBUI OR opcode_MEMWB = ITYPE_ANDI OR opcode_MEMWB = ITYPE_ORI OR
			opcode_MEMWB = ITYPE_XORI OR opcode_MEMWB = ITYPE_LHI OR opcode_MEMWB = ITYPE_SLLI OR
			opcode_MEMWB = ITYPE_SRLI OR opcode_MEMWB = ITYPE_SRAI OR opcode_MEMWB = ITYPE_SEQI OR
			opcode_MEMWB = ITYPE_SNEI OR opcode_MEMWB = ITYPE_SLTI OR opcode_MEMWB = ITYPE_SGTI OR
			opcode_MEMWB = ITYPE_SLEI OR opcode_MEMWB = ITYPE_SGEI OR opcode_MEMWB = ITYPE_SLTUI OR 
			opcode_MEMWB = ITYPE_SGTUI OR opcode_MEMWB = ITYPE_SLEUI OR opcode_MEMWB = ITYPE_SGEUI) then	
		-- DESTINATION = Store I-type
			if (opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
			
				-- Hazard #16
				if (rt_MEMWB = rt_IDEX) then
					B_latchEM_MUX <= "01"; -- MEM/WB.ALUOut to EX/MEM.B LATCH input
				end if; 
			end if;
		end if;
		
		-- ORIGIN = Load I-type
		if (opcode_MEMWB = ITYPE_LB OR opcode_MEMWB = ITYPE_LW OR
			opcode_MEMWB = ITYPE_LBU OR opcode_MEMWB = ITYPE_LHU) then
		-- DESTINATION = Store I-type
			if (opcode_IDEX = ITYPE_SB OR opcode_IDEX = ITYPE_SW) then
			
				-- Hazard #24
				if (rt_MEMWB = rt_IDEX) then
					B_latchEM_MUX <= "10"; -- MEM/WB.LMD to EX/MEM.B LATCH input
				end if; 
			end if;
		end if;
		
	end process B_latchEM_MUX_P;
	
	
	-- purpose: Drive forwarding for Data Memory write input
	-- type   : combinational
	-- output : WrIN_DRAM_MUX
	WrIN_DRAM_MUX_P : process (opcode_EXMEM, opcode_MEMWB, rt_EXMEM, rt_MEMWB, rd_MEMWB)
	begin
		WrIN_DRAM_MUX <= "00";
		
		-- ORIGIN = R-type
		if (opcode_MEMWB = RTYPE) then
		-- DESTINATION = Store I-type
			if (opcode_EXMEM = ITYPE_SB OR opcode_EXMEM = ITYPE_SW) then
			
				-- Hazard #7
				if (rd_MEMWB = rt_EXMEM) then
					WrIN_DRAM_MUX <= "01"; -- MEM/WB.ALUOut to WrIN OF DATA MEMORY
				end if;
			end if;
		end if;
		
		-- ORIGIN =  ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_MEMWB = ITYPE_ADDI OR opcode_MEMWB = ITYPE_ADDUI OR opcode_MEMWB = ITYPE_SUBI OR
			opcode_MEMWB = ITYPE_SUBUI OR opcode_MEMWB = ITYPE_ANDI OR opcode_MEMWB = ITYPE_ORI OR
			opcode_MEMWB = ITYPE_XORI OR opcode_MEMWB = ITYPE_LHI OR opcode_MEMWB = ITYPE_SLLI OR
			opcode_MEMWB = ITYPE_SRLI OR opcode_MEMWB = ITYPE_SRAI OR opcode_MEMWB = ITYPE_SEQI OR
			opcode_MEMWB = ITYPE_SNEI OR opcode_MEMWB = ITYPE_SLTI OR opcode_MEMWB = ITYPE_SGTI OR
			opcode_MEMWB = ITYPE_SLEI OR opcode_MEMWB = ITYPE_SGEI OR opcode_MEMWB = ITYPE_SLTUI OR 
			opcode_MEMWB = ITYPE_SGTUI OR opcode_MEMWB = ITYPE_SLEUI OR opcode_MEMWB = ITYPE_SGEUI) then
		-- DESTINATION = Store I-type
			if (opcode_EXMEM = ITYPE_SB OR opcode_EXMEM = ITYPE_SW) then
			
				-- Hazard #15
				if (rt_MEMWB = rt_EXMEM) then
					WrIN_DRAM_MUX <= "01"; -- MEM/WB.ALUOut to WrIN OF DATA MEMORY
				end if;
			end if;
		end if;
		
		-- ORIGIN = Load I-type
		if (opcode_MEMWB = ITYPE_LB OR opcode_MEMWB = ITYPE_LW OR
			opcode_MEMWB = ITYPE_LBU OR opcode_MEMWB = ITYPE_LHU) then
		-- DESTINATION = Store I-type
			if (opcode_EXMEM = ITYPE_SB OR opcode_EXMEM = ITYPE_SW) then
			
				-- Hazard #23
				if (rt_MEMWB = rt_EXMEM) then
					WrIN_DRAM_MUX <= "10"; -- MEM/WB.LMD to WrIN OF DATA MEMORY
				end if;
			end if;
		end if;
		
	end process WrIN_DRAM_MUX_P;


	-- purpose: Detect hazards for which a stall is needed
	-- type   : combinational
	-- output : STALL
	STALL_MGMT_P : process (opcode_IFID, opcode_IDEX, rs_IFID, rt_IFID, rt_IDEX, rt_EXMEM, rd_IDEX)
	begin
		STALL <= '0';
		
		-- ORIGIN = R-type in ID/EX
		if (opcode_IDEX = RTYPE) then
		-- DESTINATION = Branch/Jump I-type
			if (opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #5
				if (rd_IDEX = rs_IFID) then
					STALL <= '1';
				end if;
			end if;
		end if;
		
		-- ORIGIN = ALU I-type (including LHI - excluding NOP, load/store, branch/jump)
		if (opcode_IDEX = ITYPE_ADDI OR opcode_IDEX = ITYPE_ADDUI OR opcode_IDEX = ITYPE_SUBI OR
			opcode_IDEX = ITYPE_SUBUI OR opcode_IDEX = ITYPE_ANDI OR opcode_IDEX = ITYPE_ORI OR
			opcode_IDEX = ITYPE_XORI OR opcode_IDEX = ITYPE_LHI OR opcode_IDEX = ITYPE_SLLI OR
			opcode_IDEX = ITYPE_SRLI OR opcode_IDEX = ITYPE_SRAI OR opcode_IDEX = ITYPE_SEQI OR
			opcode_IDEX = ITYPE_SNEI OR opcode_IDEX = ITYPE_SLTI OR opcode_IDEX = ITYPE_SGTI OR
			opcode_IDEX = ITYPE_SLEI OR opcode_IDEX = ITYPE_SGEI OR opcode_IDEX = ITYPE_SLTUI OR 
			opcode_IDEX = ITYPE_SGTUI OR opcode_IDEX = ITYPE_SLEUI OR opcode_IDEX = ITYPE_SGEUI) then
		-- DESTINATION = Branch/Jump I-type	
			if (opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #13
				if (rt_IDEX = rs_IFID) then
						STALL <= '1';
				end if;
			end if;
		end if;
		
		-- ORIGIN = Load I-type in ID/EX
		if (opcode_IDEX = ITYPE_LB OR opcode_IDEX = ITYPE_LW OR
			opcode_IDEX = ITYPE_LBU OR opcode_IDEX = ITYPE_LHU) then
			
		-- DESTINATION = R-type, ALU I-type (excluding LHI, NOP), Load/Store I-type, Branch/Jump I-type
			if (opcode_IFID = RTYPE OR
				opcode_IFID = ITYPE_ADDI OR opcode_IFID = ITYPE_ADDUI OR opcode_IFID = ITYPE_SUBI OR
				opcode_IFID = ITYPE_SUBUI OR opcode_IFID = ITYPE_ANDI OR opcode_IFID = ITYPE_ORI OR
				opcode_IFID = ITYPE_XORI OR opcode_IFID = ITYPE_SLLI OR opcode_IFID = ITYPE_SRLI OR
				opcode_IFID = ITYPE_SRAI OR opcode_IFID = ITYPE_SEQI OR opcode_IFID = ITYPE_SNEI OR
				opcode_IFID = ITYPE_SLTI OR opcode_IFID = ITYPE_SGTI OR opcode_IFID = ITYPE_SLEI OR
				opcode_IFID = ITYPE_SGEI OR opcode_IFID = ITYPE_SLTUI OR opcode_IFID = ITYPE_SGTUI OR
				opcode_IFID = ITYPE_SLEUI OR opcode_IFID = ITYPE_SGEUI OR
				opcode_IFID = ITYPE_LB OR opcode_IFID = ITYPE_LW OR
				opcode_IFID = ITYPE_LBU OR opcode_IFID = ITYPE_LHU OR
				opcode_IFID = ITYPE_SB OR opcode_IFID = ITYPE_SW OR
				opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #17 & #21
				if (rt_IDEX = rs_IFID) then
					STALL <= '1';
				end if;
			end if;
		
		-- DESTINATION = R-type
			if (opcode_IFID = RTYPE) then
			
				-- Hazard #18
				if (rt_IDEX = rt_IFID) then
					STALL <= '1';
				end if;
			end if;
			
		end if;
		
		-- ORIGIN = Load I-type in EX/MEM
		if (opcode_EXMEM = ITYPE_LB OR opcode_EXMEM = ITYPE_LW OR
			opcode_EXMEM = ITYPE_LBU OR opcode_EXMEM = ITYPE_LHU) then
			
		-- DESTINATION = Branch/Jump I-type
			if (opcode_IFID = ITYPE_BEQZ OR opcode_IFID = ITYPE_BNEZ OR
				opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
				
				-- Hazard #22
				if (rt_EXMEM = rs_IFID) then
					STALL <= '1';
				end if;
			end if;
			
		end if;
		
	end process STALL_MGMT_P;

end architecture;

configuration CFG_DLX_HDU of hdu_dlx is
	for Behavioural
	end for;
end CFG_DLX_HDU;
