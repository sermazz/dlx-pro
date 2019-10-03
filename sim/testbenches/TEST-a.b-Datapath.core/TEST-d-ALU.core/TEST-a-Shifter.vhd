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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-d-ALU.core\TEST-a-Shifter.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

entity TB_SHIFT is
end TB_SHIFT;

architecture TEST of TB_SHIFT is

	component shifter is
		generic(
			N		: integer := Nbit_DATA		-- Data size
		);                                  
		port(
			A		: in  std_logic_vector(N - 1 downto 0);
			B		: in  std_logic_vector(log2(N) - 1 downto 0);
			SEL		: in  std_logic_vector(1 downto 0);
			Y		: out std_logic_vector(N - 1 downto 0)
		);
	end component;

	constant numBit : integer := Nbit_DATA;  
	
	--  input	 
	signal A_s 		: std_logic_vector(numBit-1 downto 0) 		:= (OTHERS => '0');
	signal B_s 		: std_logic_vector(log2(numBit)-1 downto 0) := (OTHERS => '0');
	signal SEL_s	: std_logic := "00";
	
	-- output
	signal Y_s 		: std_logic_vector(numBit-1 downto 0);
	
	constant delay : time := 1 ns;
  
begin

	uut: shifter
		generic map (numBit)
		PORT MAP (A_s, B_s, SEL_s, Y_s);

	stimuli: process
	begin
		A_s <= X"ABCD000F"; 
		B_s <= "00001";
		wait for delay;
		SEL_s <= "00";
		wait for delay;
		A_s <= X"ABCD000F"; 
		B_s <= "00100";
		wait for delay;
		SEL_s <= "01";
		wait for delay;
		SEL_s <= "10";
		wait for delay;
		A_s <= X"7BCD000F"; 
		wait;
	end process stimuli;

end TEST;


configuration TEST_SHIFT of TB_SHIFT is
	for TEST
		for uut: shifter
			use configuration WORK.CFG_SHIFTER_BEH;
		end for;
	end for;
end TEST_SHIFT;
