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
-- File: a.b-DataPath.core\000-Adder.core\b.a.a-RCA_gen.vhd
-- Date: August 2019
-- Brief: Generic Ripple Carry Adder
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity RCA_GENERIC is 
	generic(
		N : integer := 8
	);
	port(
		A:	In	std_logic_vector(N-1 downto 0);
		B:	In	std_logic_vector(N-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(N-1 downto 0);
		Co:	Out	std_logic
	);
end RCA_GENERIC;

architecture Behavioural of RCA_GENERIC is
	signal TEMP_S : std_logic_vector(N downto 0);
begin
  
  TEMP_S <= ('0' & A) + ('0' & B) + Ci; -- a+b returns carry on MSB(6th bit)
  S <= TEMP_S(N-1 downto 0);
  Co <= TEMP_S(N);
  
end Behavioural;

configuration CFG_RCA_GEN_BEH of RCA_GENERIC is
  for Behavioural 
  end for;
end CFG_RCA_GEN_BEH;


