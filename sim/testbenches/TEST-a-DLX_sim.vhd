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
-- File: testbenches\TEST-a-DLX_sim.vhd
-- Date: September 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

entity tb_dlx is
end tb_dlx;

architecture TEST of tb_dlx is

    component DLX is
		generic (
			ADDR_SIZE 		: integer := Nbit_DATA;		-- Width of Address Bus
			DATA_SIZE 		: integer := Nbit_DATA;		-- Width of Data Bus
			IR_SIZE			: integer := Nbit_INSTR;	-- Size of Instruction Register
			OPC_SIZE		: integer := Nbit_OPCODE;	-- Size of Opcode field of IR
			REGADDR_SIZE	: integer := Nbit_GPRAddr;	-- Size of Register fields of IR
			IRAM_size 		: integer := 128; 			-- in words (of IR_SIZE bits = instructions)
			DRAM_size 		: integer := 128; 			-- in words (of DATA_SIZE bits)
			STACKBUS_WIDTH	: integer := 4;
			STACK_size		: integer := 32				-- in words (of DATA_SIZE*STACKBUS_WIDTH bits)
		);
		port (
			Clk 			: in std_logic;
			Rst 			: in std_logic				-- Asynchronous, active-low
		);
	end component;

    signal Clock: std_logic := '1';
    signal Reset: std_logic := '1';
	
begin

	DLX_uut: DLX
    Generic Map (
		ADDR_SIZE 	 	=> Nbit_DATA,
		DATA_SIZE 	 	=> Nbit_DATA,
		IR_SIZE		 	=> Nbit_INSTR,
		OPC_SIZE	 	=> Nbit_OPCODE,
		REGADDR_SIZE 	=> Nbit_GPRAddr,
		IRAM_size 		=> 256, 			
		DRAM_size 		=> 128, 			
		STACKBUS_WIDTH	=> 4,
		STACK_size		=> 32				
		
		
	)
	Port Map (
		Clk 		 => Clock,
		Rst			 => Reset
	);
	
    Clock <= not(Clock) after 0.5 ns;
	Reset <= '0', '1' after 0.8 ns;
       

end TEST;

configuration TEST_DLX of tb_dlx  is
	for TEST
	end for;
end TEST_DLX;
