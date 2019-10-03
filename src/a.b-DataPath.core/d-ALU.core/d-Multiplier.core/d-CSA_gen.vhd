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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.core\d-CSA_gen.vhd
-- Date: August 2019
-- Brief: Carry-Save Adder with generic inputs width
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity CSA_generic is 
	generic (
		N : integer := 16
	);
	port (	
		A	: in	std_logic_vector(N-1 downto 0);
		B	: in	std_logic_vector(N-1 downto 0);
		C	: in	std_logic_vector(N-1 downto 0);
		S	: out	std_logic_vector(N-1 downto 0);
		Co	: out	std_logic_vector(N-1 downto 0)
	);
end CSA_generic; 

architecture Structural of CSA_generic is

	component FA is
		port (	
			A	: in	std_logic;
			B	: in	std_logic;
			Ci	: in	std_logic;
			S	: out	std_logic;
			Co	: out	std_logic
		);
	end component; 

begin
  
	ADDERS_GEN: for i in 0 to N-1 generate
		FA_i : FA port map (
			A(i), B(i), C(i), S(i), Co(i)
		); 
	end generate;

end Structural;

configuration CFG_CSA_STR of CSA_generic is
	for Structural 
		for ADDERS_GEN
			for all : FA
				use configuration WORK.CFG_FA_BEH;
			end for;
		end for;
	end for;
end CFG_CSA_STR;


