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
-- File: a.e-Stack.vhd
-- Date: September 2019
-- Brief: Stack memory (not synthesized) to spill and fill data from the Windowed
--		  Register File of the DLX datapath
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;


-- ######## STACK MEMORY for DLX ########
-- This entity implements a stack to be used with the Windowed Register File in order to
-- allow even more nested subroutine calls than the number of windows of the regfile.

-- To decrease the number of stalls in the pipeline when a spill/fill is needed, each
-- synchronous transfer is meant to move BUS_WIDTH registers from/to the stack to/from
-- the register file at each clock cycle. So, since byte-addressing or single register-
-- addressing are not needed, the words of the stack have the same width of the spill/
-- fill bus, so that the internal architecture is simplified.
-- With such choice, MEM_SIZE*BUS_WIDTH is the total number of registers which can be
-- held in the stack, corresponding to MEM_SIZE*BUS_WIDTH/(2*N) register windows (N is
-- the number of registers in IN,LOCAL,OUT groups). The total size of the stack memory
-- is MEM_SIZE*BUS_WIDTH*DATA_SIZE/8 (in bytes).
-- The stack has the same endianess of the register file, since the incoming data are
-- not rearranged (in this implementation, big-endian) and the stack pointer points to
-- the last full slot, filling up the stack in an increasing fashion.

entity STACK is
	generic (
		MEM_SIZE  : integer := 32;			-- in multiple of BUS_WIDTH
		DATA_SIZE : integer := Nbit_DATA;	-- in bits (multiple of 8 bits)
		BUS_WIDTH : integer := 4			-- RegFile Bus width (in registers of DATA_SIZE bits each)
		
		-- With default generics, stack size is: 32 entries * 4 registers * 32 bits / 8 bits = 512 kB
		-- and it can hold up to: 32 entries * 4 registers / 2*8 registers/window = 8 windows
	);
	port (
		Clk 		: in std_logic;
		Rst			: in std_logic;
		-- Interface to RF
		SPILL 		: in std_logic;
		FILL		: in std_logic;
		RfBus_in	: in std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0);
		RfBus_out	: out std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0)
	);
end STACK;

architecture Behavioural of STACK is

	-- Stack memory signal
	type MEM_ARRAY is array (natural range <>) of std_logic_vector(DATA_SIZE*BUS_WIDTH-1 downto 0);
	signal STACK_mem	: MEM_ARRAY(0 to MEM_SIZE - 1);

	-- Stack pointer = pointer to last full slot, increasing filling
	signal SP : integer range -1 to MEM_SIZE;

begin

	-- purpose: Manage write and the read of the stack basing on the Stack Pointer
	-- type   : sequential
	-- inputs : SP, SPILL, FILL, STACK_mem, RfBus_in
	-- outputs: SP, STACK_mem, RfBus_out
	STACK_proc: process (Clk, Rst)
	begin
	
		if (Rst = '0') then
			STACK_mem <= (others => (others => '0'));
			SP 		  <= -1;
			RfBus_out <= (others => 'Z');
		elsif (Clk = '1' and Clk'EVENT) then
			
			if (SPILL = '1') then
				-- Synchronous SPILL
				SP <= SP + 1;
				STACK_mem(SP+1) <= RfBus_in;
			elsif (FILL = '1') then
				-- Synchronous SP update for FILL
				SP <= SP - 1;
				RfBus_out <= STACK_mem(SP);
			end if;
			
		end if;
		
	end process STACK_proc;

end Behavioural;

configuration CFG_DLX_STACK of STACK is
	for Behavioural
	end for;
end CFG_DLX_STACK;