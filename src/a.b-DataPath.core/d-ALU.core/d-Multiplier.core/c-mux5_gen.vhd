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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.core\c-mux5_gen.vhd
-- Date: August 2019
-- Brief: 5-inputs generic multiplexer
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;

entity mux5_generic is
	generic(
		N : natural := 16
	);
	port(
		A, B, C, D, E: IN std_logic_vector (N-1 downto 0);
		SEL: IN std_logic_vector(2 downto 0);
		Z : OUT std_logic_vector(N-1 downto 0)
	);
end mux5_generic;

architecture Behavioural of mux5_generic is
begin

	with SEL select
		Z <= 	A when "000",
				B when "001",
				C when "010",
				D when "011",
				E when others;
			
end Behavioural;

configuration CFG_MUX5_GENERIC_BEH of mux5_generic is
	for Behavioural
	end for;
end CFG_MUX5_GENERIC_BEH;