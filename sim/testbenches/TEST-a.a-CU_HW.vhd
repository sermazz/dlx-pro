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
-- File: testbenches\TEST-a.a-CU_HW.vhd
-- Date: September 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

entity dlx_cu_test is
end dlx_cu_test;

architecture TEST of dlx_cu_test is

    component dlx_cu is
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
	end component;

    signal Clock: std_logic := '0';
    signal Reset: std_logic;
	
	signal stall_i, misprediction_i: std_logic := '0';

    signal IR_i : std_logic_vector(Nbit_INSTR - 1 downto 0);
	
	signal MUXImmTA_SEL_i, NPC_LATCH_IFID_EN_i, TA_LATCH_IFID_EN_i, PC_LATCH_IFID_EN_i,
		   RF_RD1EN_i, RF_RD2EN_i, RegA_LATCH_IDEX_EN_i, RegB_LATCH_IDEX_EN_i, RegIMM_LATCH_IDEX_EN_i, LPC_LATCH_IDEX_EN_i, RF_CALL_i, RF_RET_i,
		   MUXB_SEL_i, ALUOUT_LATCH_EXMEM_EN_i, RegB_LATCH_EXMEM_EN_i, LPC_LATCH_EXMEM_EN_i,
		   DRAM_WE_i, DRAM_RE_i, DRAMOP_SEL_i, MUXLPC_SEL_i, LMD_LATCH_MEMWB_EN_i, ALUOUT_LATCH_MEMWB_EN_i, LPC_LATCH_MEMWB_EN_i,
		   RF_WE_i : std_logic;
		   
	signal MUXImm_SEL_i, MUXLMD_SEL_i, MUXWrAddr_SEL_i, MUXWB_SEL_i : std_logic_vector(1 downto 0);
		   
	signal ALU_OPCODE_i : aluOp;

begin

		-- instance of Control unit
		dut: dlx_cu
		port map (
			-- INPUTS
			Clk             	  => Clock,	
			Rst                   => Reset,
			IR_IN                 => IR_i,
			stall			      => stall_i,
			misprediction		  => misprediction_i,
			--OUTPUTS               	
			MUXImmTA_SEL		  => MUXImmTA_SEL_i,
			NPC_LATCH_IFID_EN     => NPC_LATCH_IFID_EN_i, 
			TA_LATCH_IFID_EN      => TA_LATCH_IFID_EN_i,
			PC_LATCH_IFID_EN	  => PC_LATCH_IFID_EN_i,
			
			MUXImm_SEL            => MUXImm_SEL_i,      
			RF_RD1EN			  => RF_RD1EN_i,
			RF_RD2EN			  => RF_RD2EN_i,
			RegA_LATCH_IDEX_EN    => RegA_LATCH_IDEX_EN_i,   
			RegB_LATCH_IDEX_EN    => RegB_LATCH_IDEX_EN_i,   
			RegIMM_LATCH_IDEX_EN  => RegIMM_LATCH_IDEX_EN_i, 
			LPC_LATCH_IDEX_EN     => LPC_LATCH_IDEX_EN_i, 
			RF_CALL               => RF_CALL_i,              
			RF_RET                => RF_RET_i,               
			
			MUXB_SEL              => MUXB_SEL_i,            
			ALUOUT_LATCH_EXMEM_EN => ALUOUT_LATCH_EXMEM_EN_i,
			RegB_LATCH_EXMEM_EN   => RegB_LATCH_EXMEM_EN_i,  
			LPC_LATCH_EXMEM_EN    => LPC_LATCH_EXMEM_EN_i,
			ALU_OPCODE            => ALU_OPCODE_i,           
			
			DRAM_WE               => DRAM_WE_i,
			DRAM_RE				  => DRAM_RE_i,
			DRAMOP_SEL            => DRAMOP_SEL_i,           
			MUXLPC_SEL            => MUXLPC_SEL_i,           
			MUXLMD_SEL            => MUXLMD_SEL_i,           
			LMD_LATCH_MEMWB_EN    => LMD_LATCH_MEMWB_EN_i,   
			ALUOUT_LATCH_MEMWB_EN => ALUOUT_LATCH_MEMWB_EN_i,
			LPC_LATCH_MEMWB_EN    => LPC_LATCH_MEMWB_EN_i,   
			
			RF_WE                 => RF_WE_i,                
			MUXWrAddr_SEL         => MUXWrAddr_SEL_i,       
			MUXWB_SEL             => MUXWB_SEL_i
		);

        Clock <= not Clock after 1 ns;
		Reset <= '0', '1' after 0.5 ns;
		
        STIMULI_PROC: process
        begin
			
			-- Test #1 - STALL
			
			IR_i <= ITYPE_LW & "00000" & "00001" & X"00FF";			-- lw r1,255(r0)
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= RTYPE & "00001" & "00010" & "00100" & F_XOR; 	-- xor r4, r1, r2
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= ITYPE_LHI & "00000" & "01000" & X"FFFF"; 		-- lhi r8, #65535
			wait until (Clock = '1' AND Clock'EVENT);
			-- Now XOR instruction (RTYPE instr following a LOAD) is in ID
			-- and the hazard detection unit detects that a stall is needed
			wait for 0.2 ns;
			stall_i <= '1';
			
			wait for 0.5 ns;
			IR_i <= ITYPE_NOP & "00" & X"000000";					-- nop
			wait until (Clock = '1' AND Clock'EVENT);
			wait for 0.2 ns;
			stall_i <= '0';
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait for 3 ns;
			
			-- Test #2 - MISPREDICTION
			
			IR_i <= ITYPE_BEQZ & "00001" & '0' & X"00012";			-- beqz r1, #12
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= RTYPE & "00010" & "00011" & "00100" & F_OR; 	-- or r4, r2, r3
			wait until (Clock = '1' AND Clock'EVENT);
			-- Now BEQZ instruction is in its ID stage and Branch logic actually
			-- performs the comparison R1==0 and detects a misprediction
			wait for 0.2 ns;
			misprediction_i <= '1';
			
			wait for 0.5 ns;
			IR_i <= ITYPE_LHI & "00000" & "01000" & X"FFFF"; 		-- lhi r8, #65535
			wait until (Clock = '1' AND Clock'EVENT);
			wait for 0.2 ns;
			misprediction_i <= '0';
			
			wait for 0.5 ns;
			IR_i <= ITYPE_NOP & "00" & X"000000";					-- nop
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait until (Clock = '1' AND Clock'EVENT);
			wait for 3 ns;
			
			-- Test #3 - JUMPs & RML
			
			IR_i <= X"0800000C"; -- j 16
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= X"00430820"; -- add r1,r2,r3
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= X"20410005"; -- addi r1,r2,#5
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= X"1040fff0"; -- beqz 32
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= ITYPE_NOP & "00" & X"000000";
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= JTYPE_JAL & "00" & X"000000";
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= ITYPE_JALR & "00" & X"000000";
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= ITYPE_JR & "11111" & '0' & X"00000";
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait for 0.5 ns;
			IR_i <= ITYPE_JR & "01011" & '0' & X"00000";
			wait until (Clock = '1' AND Clock'EVENT);
			
			wait;
        end process;

end TEST;

configuration TEST_DLX_HWCU of dlx_cu_test is
	for TEST
		for dut: dlx_cu
			use configuration WORK.CFG_DLX_HWCU;
		end for;
	end for;
end TEST_DLX_HWCU;
