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
-- File: a.b-DataPath.core\000-Adder.core\a.a.a-smallPG.vhd
-- Date: August 2019
-- Brief: Propagate and generate terms computer
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity smallPG is
	PORT (
		A, B : IN STD_LOGIC;
		p, g : OUT STD_LOGIC
	);
end smallPG;

architecture BEHAVIOURAL of smallPG is
begin
	p <= A XOR B;
	g <= A AND B;
end BEHAVIOURAL;

configuration CFG_smallPG_BEHAVIOURAL of smallPG is
	for BEHAVIOURAL
	end for;
end configuration CFG_smallPG_BEHAVIOURAL;