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
-- File: a.b-DataPath.core\000-Adder.core\a.b-bigG.vhd
-- Date: August 2019
-- Brief: Generic G carry operator
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bigG is
	-- ik subscript stands for i:k
	-- kj subscript actually stands for k-1:j
	PORT(  
		G_ik, P_ik, G_kj: IN STD_LOGIC;
		G: OUT STD_LOGIC
	);
end bigG;

architecture BEHAVIOURAL of bigG is

begin

	G <= G_ik or (P_ik and G_kj);
	
end BEHAVIOURAL;

configuration CFG_bigG_BEHAVIOURAL of bigG is
	for BEHAVIOURAL
	end for;
end configuration CFG_bigG_BEHAVIOURAL;
