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
-- File: a.b-DataPath.core\d-ALU.core\000-inv_gen.vhd
-- Date: August 2019
-- Brief: NOT gate with generic width
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.ALL;
use WORK.myTypes.all;

entity INV_generic is
	generic (
		N	: integer := Nbit_DATA
	);
	port (
		A 	: in std_logic_vector(N-1 downto 0);
		Y 	: out std_logic_vector(N-1 downto 0)
	);
end INV_generic;

architecture Behavioural of INV_generic is
begin
	Y <= not(A);
end Behavioural;

configuration CFG_INV_BEH of INV_generic is
	for Behavioural
	end for;
end CFG_INV_BEH;
