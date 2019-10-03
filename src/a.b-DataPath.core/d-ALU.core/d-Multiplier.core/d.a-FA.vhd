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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.core\d.a-FA.vhd
-- Date: August 2019
-- Brief: Full Adder
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all; 

entity FA is
	port (	
		A	: in	std_logic;
		B	: in	std_logic;
		Ci	: in	std_logic;
		S	: out	std_logic;
		Co	: out	std_logic
	);
end FA; 

architecture Behavioural of FA is
begin

	S <= A xor B xor Ci;
	Co <= (A and B) or (B and Ci) or (A and Ci);
  
end Behavioural;

configuration CFG_FA_BEH of FA is	
	for Behavioural
	end for;
end CFG_FA_BEH;
