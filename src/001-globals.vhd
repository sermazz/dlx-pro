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
-- File: 001-globals.vhd
-- Date: August 2019
-- Brief: Global constants definitions for the DLX project
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.functions.all;

package myTypes is

    -- Generic architecture sizes
	constant Nbit_INSTR		: integer := 32;	-- ISA encoding size
	constant Nbit_DATA		: integer := 32;	-- Width of data bus
	constant Nbit_OPCODE	: integer := 6;		-- OPCODE field size
	constant Nbit_FUNC  	: integer := 11;	-- FUNC field size for R-Type
	constant Nbit_GPRAddr	: integer := 5;		-- Number of bits to address all GPRs
	
	-- Windowed Register File dimensions
	constant RF_GLOB_num    : integer := 8;		-- Number of registers in GLOBALS group
	constant RF_ILO_num     : integer := 8;		-- Number of register for each IN, LOCALS, OUT group
	constant RF_WIND_num	: integer := 8;		-- Number of windows in the register file

	-- R-Type instruction - OPCODE field
	constant RTYPE   	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "000000"; 	-- 0x00
	-- J-Type instruction - OPCODE field
	constant JTYPE_J 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "000010";	-- 0x02
	constant JTYPE_JAL 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "000011";	-- 0x03
	-- I-Type instruction - OPCODE field
	constant ITYPE_BEQZ : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "000100";	-- 0x04
	constant ITYPE_BNEZ : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "000101";	-- 0x05
	constant ITYPE_ADDI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001000"; 	-- 0x08
	constant ITYPE_ADDUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001001"; 	-- 0x09 (pro)
	constant ITYPE_SUBI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001010"; 	-- 0x0A
	constant ITYPE_SUBUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001011"; 	-- 0x0B (pro)
	constant ITYPE_ANDI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001100"; 	-- 0x0C
	constant ITYPE_ORI 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001101"; 	-- 0x0D
	constant ITYPE_XORI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001110"; 	-- 0x0E
	constant ITYPE_LHI 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "001111"; 	-- 0x0F (pro)
	constant ITYPE_JR 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010010"; 	-- 0x12 (pro)
	constant ITYPE_JALR	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010011"; 	-- 0x13 (pro)
	constant ITYPE_SLLI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010100"; 	-- 0x14
	constant ITYPE_NOP 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010101"; 	-- 0x15
	constant ITYPE_SRLI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010110"; 	-- 0x16
	constant ITYPE_SRAI	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "010111"; 	-- 0x17 (pro)
	constant ITYPE_SEQI	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011000"; 	-- 0x18 (pro)
	constant ITYPE_SNEI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011001"; 	-- 0x19
	constant ITYPE_SLTI	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011010"; 	-- 0x1A (pro)
	constant ITYPE_SGTI	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011011"; 	-- 0x1B (pro)
	constant ITYPE_SLEI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011100"; 	-- 0x1C
	constant ITYPE_SGEI : std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "011101"; 	-- 0x1D
	constant ITYPE_LB	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "100000"; 	-- 0x20 (pro)
	constant ITYPE_LW 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "100011"; 	-- 0x23
	constant ITYPE_LBU	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "100100"; 	-- 0x24 (pro)
	constant ITYPE_LHU	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "100101"; 	-- 0x25 (pro)
	constant ITYPE_SB	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "101000"; 	-- 0x28 (pro)
	constant ITYPE_SW 	: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "101011"; 	-- 0x2B
	constant ITYPE_SLTUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "111010"; 	-- 0x3A (pro)
	constant ITYPE_SGTUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "111011"; 	-- 0x3B (pro)
	constant ITYPE_SLEUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "111100"; 	-- 0x3C (my addition)
	constant ITYPE_SGEUI: std_logic_vector(Nbit_OPCODE - 1 downto 0) :=  "111101"; 	-- 0x3D (pro)

	-- R-Type instruction - FUNC field
	constant F_SLL		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000000100";	-- 0x04
	constant F_SRL		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000000110";	-- 0x06
	constant F_SRA		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000000111";	-- 0x07 (pro)
	constant F_ADD		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100000";	-- 0x20
	constant F_ADDU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100001";	-- 0x21
	constant F_SUB		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100010";	-- 0x22
	constant F_SUBU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100011";	-- 0x23
	constant F_AND		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100100";	-- 0x24
	constant F_OR		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100101";	-- 0x25
	constant F_XOR		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000100110";	-- 0x26
	constant F_SEQ		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101000";	-- 0x28 (pro)
	constant F_SNE		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101001";	-- 0x29
	constant F_SLT		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101010";	-- 0x2A (pro)
	constant F_SGT		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101011";	-- 0x2B (pro)
	constant F_SLE		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101100";	-- 0x2C
	constant F_SGE		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000101101";	-- 0x2D
	constant F_SLTU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000111010";	-- 0x3A (pro)
	constant F_SGTU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000111011";	-- 0x3B (pro)
	constant F_SLEU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000111100";	-- 0x3C (my addition)
	constant F_SGEU		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00000111101";	-- 0x3D (pro)
	constant F_MULT		: std_logic_vector(Nbit_FUNC - 1 downto 0) :=  "00001000000";	-- 0x40

	-- Implicit encoding for ALU OpCode
	type aluOp is (
		NOP,
		LSL, 	-- left shift logical
		RSL, 	-- right shift logical
		RSA,	-- right shift arithmetical
		ADD,	-- integer addition
		SUB,	-- integer subtraction
		ANDalu,	-- bitwise and
		ORalu,	-- bitwise or
		XORalu,	-- bitwise xor
		EQ,		-- check if A==B		
		NE,		-- check if A!=B
		LT,		-- check if A<B 		
		GT,     -- check if A>B			
		LE,		-- check if A<=B
		GE,		-- check if A>=B
		LTU,	-- check if A<B (unsigned)
		GTU,    -- check if A>B (unsigned)
		LEU,	-- check if A<=B(unsigned) 
		GEU,	-- check if A>=B (unsigned)
		MULT,	-- integer multiplication
		THR_B	-- let B through
	);

end myTypes;

