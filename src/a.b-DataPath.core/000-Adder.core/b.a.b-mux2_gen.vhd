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
-- File: a.b-DataPath.core\000-Adder.core\b.a.b-mux2_gen.vhd
-- Date: August 2019
-- Brief: 2-inputs generic multiplexer
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.ALL;
use WORK.myTypes.all;

entity mux2_generic is
	generic(
		N :		integer := Nbit_DATA
	);
	port( 
		A: 		in std_logic_vector(N-1 downto 0);
		B: 		in std_logic_vector(N-1 downto 0);
		SEL:	in std_logic;
		Y:		out std_logic_vector(N-1 downto 0)
	);
end entity;

architecture Behavioural of mux2_generic is
begin

	with SEL select
		Y <= 	A when '0',
				B when others;
	
end Behavioural;

configuration CFG_MUX2_GENERIC_BEH of mux2_generic is
	for Behavioural
	end for;
end CFG_MUX2_GENERIC_BEH;
