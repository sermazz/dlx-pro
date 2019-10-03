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
-- File: a.b-DataPath.core\d-ALU.core\a-Shifter.vhd
-- Date: August 2019
-- Brief: Generic shifter
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.myTypes.all;
use work.functions.all;

entity shifter is
	generic(
		N		: integer := Nbit_DATA		-- Data size
	);                                  
	port(
		A		: in  std_logic_vector(N - 1 downto 0);
		B		: in  std_logic_vector(log2(N) - 1 downto 0);
		SEL		: in  std_logic_vector(1 downto 0);
		Y		: out std_logic_vector(N - 1 downto 0)
	);
end shifter;

architecture Behavioural of shifter is
begin

	with SEL select
		Y <= to_StdLogicVector((to_bitvector(A)) sll (conv_integer(B))) when "00",	-- LSL
			 to_StdLogicVector((to_bitvector(A)) srl (conv_integer(B))) when "01",	-- RSL
			 to_StdLogicVector((to_bitvector(A)) sra (conv_integer(B))) when others; -- RSA + others

end Behavioural;

configuration CFG_SHIFTER_BEH of shifter is
	for Behavioural
	end for;
end CFG_SHIFTER_BEH;