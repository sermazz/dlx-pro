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
-- File: testbenches\TEST-a.c-IRAM.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

entity dlx_IRAM_test is
end dlx_IRAM_test;

architecture TEST of dlx_IRAM_test is

    component IRAM is
		generic (
			RAM_SIZE	: integer := 48;								-- IRAM size (in words)
			I_SIZE		: integer := Nbit_DATA							-- IRAM word size (in bits)
		);
		port (
			Rst 		: in  std_logic;								-- Reset (active-low)
			Addr		: in  std_logic_vector(I_SIZE - 1 downto 0);
			Dout		: out std_logic_vector(I_SIZE - 1 downto 0)
		);
	end component;
		
    signal Reset: std_logic	:= '1';
	signal Addr_s, Dout_s : std_logic_vector(Nbit_DATA - 1 downto 0) := (OTHERS => '0');

begin

		-- instance of Instruction memory
		dut: IRAM 	
			generic map (
				RAM_SIZE=> 256,
				I_SIZE 	=> Nbit_DATA
			)
			port map (
				Rst  	=> Reset,
				Addr 	=> Addr_s,
				Dout 	=> Dout_s
			);
			
		Reset <= '0', '1' after 0.5 ns;
		
        STIMULI_PROC: process
        begin
		
			Addr_s <= (OTHERS => '0');
			
			for i in 0 to 255 loop
				wait for 0.5 ns;
				Addr_s <= std_logic_vector(unsigned(Addr_s) + to_unsigned(1, Nbit_DATA));
			end loop;
			
			wait;
        end process;

end TEST;

configuration TEST_DLX_IRAM of dlx_IRAM_test is
	for TEST
		for dut: IRAM
			use configuration WORK.CFG_DLX_IRAM;
		end for;
	end for;
end TEST_DLX_IRAM;