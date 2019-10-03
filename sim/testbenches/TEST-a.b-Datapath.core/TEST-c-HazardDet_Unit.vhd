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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-c-HazardDet_Unit.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

entity dlx_hdu_test is
end dlx_hdu_test;

architecture TEST of dlx_hdu_test is

    component hdu_dlx is
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
	end  component;

    signal IR_IFID_s, IR_IDEX_s, IR_EXMEM_s, IR_MEMWB_s : std_logic_vector(Nbit_INSTR - 1 downto 0);
	signal ALU_inputA_MUX_s, ALU_inputB_MUX_s, B_latchEM_MUX_s, WrIN_DRAM_MUX_s : std_logic_vector(1 downto 0);
	signal BJ_regA_MUX_s, STALL_s : std_logic;
	signal CWP_IDEX_s, CWP_EXMEM_s, CWP_MEMWB_s : std_logic_vector(2 downto 0) := "000";
begin

		-- instance of Hazard Detection Unit
		dut: hdu_dlx
		port map (
			-- Inputs
		    IR_IFID       	=> IR_IFID_s,
		    IR_IDEX       	=> IR_IDEX_s,
		    IR_EXMEM      	=> IR_EXMEM_s,
		    IR_MEMWB      	=> IR_MEMWB_s,
			CWP_IDEX		=> CWP_IDEX_s,
			CWP_EXMEM       => CWP_EXMEM_s,
			CWP_MEMWB       => CWP_MEMWB_s,
		    -- Outputs
		    BJ_regA_MUX		=> BJ_regA_MUX_s,
		    ALU_inputA_MUX	=> ALU_inputA_MUX_s,
		    ALU_inputB_MUX	=> ALU_inputB_MUX_s,
		    B_latchEM_MUX 	=> B_latchEM_MUX_s,
		    WrIN_DRAM_MUX 	=> WrIN_DRAM_MUX_s,
		    STALL			=> STALL_s
		);
		
        STIMULI_PROC: process
        begin
			-- LB R1, 0(R0)		; Reg[R1] <= Mem[Reg[R0]+0]
			-- ADD R3, R1, R2	; Reg[R3] <= Reg[R1] + Reg[R2]
			IR_IFID_s  <= ITYPE_LB & "00000" & "00001" & "0000000000000000";
			wait for 1 ns;
			IR_IFID_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			IR_IDEX_s  <= ITYPE_LB & "00000" & "00001" & "0000000000000000";
			wait for 1 ns;
			IR_IDEX_s  <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			IR_EXMEM_s  <= ITYPE_LB & "00000" & "00001" & "0000000000000000";
			wait for 1 ns;
			IR_IFID_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_IDEX_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			IR_EXMEM_s  <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			IR_MEMWB_s  <= ITYPE_LB & "00000" & "00001" & "0000000000000000";
			wait for 1 ns;
			IR_IDEX_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_EXMEM_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			IR_MEMWB_s  <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			wait for 1 ns;
			IR_EXMEM_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_MEMWB_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			wait for 1 ns;
			IR_MEMWB_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			wait for 3 ns;
			
			-- ADD R3, R1, R2	; Reg[R3] <= Reg[R1] + Reg[R2]
			-- SUB R5, R3, R4	; Reg[R5] <= Reg[R3] + Reg[R4]
			IR_IFID_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			wait for 1 ns;
			IR_IFID_s  <= RTYPE	   & "00011" & "00100" & "00101" & F_SUB;
			IR_IDEX_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			wait for 1 ns;
			IR_IFID_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_IDEX_s  <= RTYPE	   & "00011" & "00100" & "00101" & F_SUB;
			IR_EXMEM_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			wait for 1 ns;
			IR_IDEX_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_EXMEM_s  <= RTYPE	   & "00011" & "00100" & "00101" & F_SUB;
			IR_MEMWB_s  <= RTYPE	   & "00001" & "00010" & "00011" & F_ADD;
			wait for 1 ns;
			IR_EXMEM_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
			IR_MEMWB_s  <= RTYPE	   & "00011" & "00100" & "00101" & F_SUB;
			wait for 1 ns;
			IR_MEMWB_s  <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";			
			wait;
			
        end process;

end TEST;

configuration TEST_DLX_HDU of dlx_hdu_test is
	for TEST
		for dut: hdu_dlx
			use configuration WORK.CFG_DLX_HDU;
		end for;
	end for;
end TEST_DLX_HDU;
