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
-- File: a.b-DataPath.core\000-Adder.core\a.c-bigPG.vhd
-- Date: August 2019
-- Brief: Generic PG carry operator 
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bigPG is
	-- ik subscript stands for i:k
	-- kj subscript actually stands for k-1:j
	port( 
		G_ik, P_ik, G_kj, P_kj: IN STD_LOGIC;
		G, P: OUT STD_LOGIC
	);
end bigPG;

architecture BEHAVIOURAL of bigPG is

	component bigG is
		-- ik subscript stands for i:k
		-- kj subscript actually stands for k-1:j
		PORT(  
			G_ik, P_ik, G_kj: IN STD_LOGIC;
			G: OUT STD_LOGIC
		);
	end component;
	
begin

	myBigG : bigG port map(G_ik, P_ik, G_kj, G);
		
	P <= P_ik and P_kj;

end BEHAVIOURAL;

configuration CFG_bigPG_BEHAVIOURAL of bigPG is
	for BEHAVIOURAL
	end for;
end configuration CFG_bigPG_BEHAVIOURAL;

