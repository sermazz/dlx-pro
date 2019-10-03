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
-- File: a.b-DataPath.core\d-ALU.core\c-Comparator.core\a-xor2_gen.vhd
-- Date: August 2019
-- Brief: 2-inputs XOR gate with generic width
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.ALL;
use WORK.myTypes.all;

entity XOR2_generic is
	generic (
		N	: integer := Nbit_DATA
	);
	port (
		A 	: in std_logic_vector(N-1 downto 0);
		B 	: in std_logic_vector(N-1 downto 0);
		Y 	: out std_logic_vector(N-1 downto 0)
	);
end XOR2_generic;

architecture Behavioural of XOR2_generic is
begin
	Y <= A xor B;
end Behavioural;

configuration CFG_XOR2_BEH of XOR2_generic is
	for Behavioural
	end for;
end CFG_XOR2_BEH;
