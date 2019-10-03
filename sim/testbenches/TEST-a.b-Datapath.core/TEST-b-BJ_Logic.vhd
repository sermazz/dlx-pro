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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-b-BJ_Logic.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

entity dlx_bjlogic_test is
end dlx_bjlogic_test;

architecture TEST of dlx_bjlogic_test is

    component bj_logic is
		generic(
			MEM_SIZE		: integer := 64;								-- Size (in words of 2 bits) for prediction memory
			OPC_SIZE        : integer := Nbit_OPCODE;						-- Opcode size
			ADDR_SIZE		: integer := Nbit_DATA;							-- Addresses size
			DATA_SIZE		: integer := Nbit_DATA							-- Data size
		);                                  
		port(
			Clk				: in std_logic;									-- Clock for prediction memory
			Rst				: in std_logic;									-- Reset (active-low, asynchronous) for prediction memory
			STALL			: in std_logic;
			opcode_IRAM		: in  std_logic_vector(OPC_SIZE - 1 downto 0);	-- Opcode from IRAM Dout
			opcode_IFID		: in  std_logic_vector(OPC_SIZE - 1 downto 0);	-- Opcode from instruction in IF/ID storage
			-- Addresses
			bAddr_PC		: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Address of the instruction coming from PC register
			bAddr_IFID		: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Address of instruction stored in IF/ID storage block
			NPC				: in std_logic_vector(ADDR_SIZE - 1 downto 0);	-- Next Program Counter from IF stage (PC+4)
			TA				: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Target Address computed in IF stage
			-- Register A for zero comparison
			REG_A			: in std_logic_vector(DATA_SIZE - 1 downto 0);
			-- Signals for Branch & Jump management
			take_bj			: out std_logic;	-- Prediction outcome: 0 for normal PC increment, 1 to branch/jump
			flush_IFID		: out std_logic;	-- Can be raised during ID; signals to abort previously fetched instr
			muxPC_SEL		: out std_logic;
			correct_PC		: out std_logic_vector(ADDR_SIZE - 1 downto 0)
		);
	end component;

    signal Clock: std_logic := '0';
    signal Reset: std_logic := '0';
	
	signal nextPC: unsigned(Nbit_DATA - 1 downto 0);
	signal nextFetch_opcode: std_logic_vector(Nbit_OPCODE - 1 downto 0);
	
	-- Inputs
	signal Dout_opcode_s, IR_IFID_opcode_s: std_logic_vector(Nbit_OPCODE - 1 downto 0) := (OTHERS => '0');
	signal PC_reg_s, PC_IFID_s: std_logic_vector(Nbit_DATA - 1 downto 0) := (OTHERS => '0');
	signal NPC_IFID_s: std_logic_vector(Nbit_DATA - 1 downto 0) := X"CCCCCCCC";	-- Fixed for simplicity
	signal TA_IFID_s: std_logic_vector(Nbit_DATA - 1 downto 0) := X"FFFFFFFF"; 	-- Fixed for simplicity
	signal RegA_s: std_logic_vector(Nbit_DATA - 1 downto 0) := X"00000000";
	-- Outputs
	signal STALL_s, take_bj_s, flush_IFID_s, muxPC_SEL_s: std_logic;
	signal correct_PC_s : std_logic_vector(Nbit_DATA - 1 downto 0);
	
begin

		dut: bj_logic
		port map (
			-- Inputs
			Clk			=> Clock,
			Rst			=> Reset,
			STALL 		=> stall_s,
			opcode_IRAM	=> Dout_opcode_s,
			opcode_IFID	=> IR_IFID_opcode_s,
			bAddr_PC	=> PC_reg_s,
			bAddr_IFID	=> PC_IFID_s,
			NPC			=> NPC_IFID_s,
			TA			=> TA_IFID_s,
			REG_A	    => RegA_s,
		    -- Outputs	
			take_bj	    => take_bj_s,
			flush_IFID	=> flush_IFID_s,
			muxPC_SEL	=> muxPC_SEL_s,
			correct_PC	=> correct_PC_s
		);

        Clock <= not Clock after 1 ns;
		Reset <= '0', '1' after 0.5 ns;
		
		PIPE_PROC: process (Clock, Reset)
		begin
			if (Reset = '0') then
				PC_reg_s         <= (OTHERS => '0');
				PC_IFID_s        <= (OTHERS => '0');
				Dout_opcode_s	 <= (OTHERS => '0');
				IR_IFID_opcode_s <= (OTHERS => '0');
			elsif (Clock = '1' and Clock'EVENT) then
				PC_reg_s <= std_logic_vector(nextPC);
				PC_IFID_s <= PC_reg_s;
				Dout_opcode_s <= nextFetch_opcode;
				IR_IFID_opcode_s <= Dout_opcode_s;
			end if;
		end process;
		
        STIMULI_PROC: process
        begin
			
			nextPC <= to_unsigned(0, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(4, Nbit_DATA);
			nextFetch_opcode <= ITYPE_ADDI;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(8, Nbit_DATA);
			nextFetch_opcode <= JTYPE_JAL;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(12, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(32, Nbit_DATA);
			nextFetch_opcode <= ITYPE_ORI;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(36, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(40, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(64, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(76, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			RegA_s <= X"AA00BB0F";
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(72, Nbit_DATA);
			nextFetch_opcode <= ITYPE_BEQZ;
			wait until Clock = '1' and Clock'EVENT;
			
			wait for 0.5 ns;
			nextPC <= to_unsigned(68, Nbit_DATA);
			nextFetch_opcode <= RTYPE;
			wait until Clock = '1' and Clock'EVENT;
			
			wait;
        end process;

end TEST;

configuration TEST_DLX_BJLOGIC of dlx_bjlogic_test is
	for TEST
		for dut: bj_logic
			use configuration WORK.CFG_DLX_BJLOGIC;
		end for;
	end for;
end TEST_DLX_BJLOGIC;
