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
-- File: a.b-DataPath.core\d-ALU.core\b-Logicals.core\b-nand4_generic.vhd
-- Date: August 2019
-- Brief: 4-inputs NAND gate with generic width
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.ALL;
use WORK.myTypes.all;

entity NAND4_generic is
	generic (
		N	: integer := Nbit_DATA
	);
	port (
		A 	: in std_logic_vector(N-1 downto 0);
		B 	: in std_logic_vector(N-1 downto 0);
		C 	: in std_logic_vector(N-1 downto 0);
		D 	: in std_logic_vector(N-1 downto 0);
		Y 	: out std_logic_vector(N-1 downto 0)
	);
end NAND4_generic;

architecture Behavioural of NAND4_generic is
begin
	Y <= not(A and B and C and D);
end Behavioural;

configuration CFG_NAND4_BEH of NAND4_generic is
	for Behavioural
	end for;
end CFG_NAND4_BEH;
