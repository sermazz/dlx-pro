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
-- File: a.b-DataPath.core\d-ALU.core\c-Comparator.core\d-zeroDet_gen.vhd
-- Date: August 2019
-- Brief: Generic-width zero detector based on a generic NOR gate
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.ALL;
use WORK.myTypes.all;

entity ZeroDet_generic is
	generic (
		N	: integer := Nbit_DATA
	);
	port (
		A 	: in std_logic_vector(N-1 downto 0);
		Y 	: out std_logic
	);
end ZeroDet_generic;

architecture Behavioural of ZeroDet_generic is
	
	signal reduced_or : std_logic;

begin
	
	process (A)
		variable temp_OR : std_logic;
	begin
		temp_OR := '0';
		for I in N-1 downto 0 loop
			temp_OR := temp_OR or A(I);
		end loop;
		
		reduced_or <= temp_OR;
		
	end process;
	
	Y <= not(reduced_or);
end Behavioural;

configuration CFG_ZERODET_BEH of ZeroDet_generic is
	for Behavioural
	end for;
end CFG_ZERODET_BEH;
