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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-d-ALU.core\TEST-b-Logicals.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

entity TB_LOGICALS is
end TB_LOGICALS;

architecture TEST of TB_LOGICALS is

	component LU is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in  std_logic_vector(N-1 downto 0);
			B 	: in  std_logic_vector(N-1 downto 0);
			SEL	: in std_logic_vector(3 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	constant numBit : integer := 8;  
	
	--  input	 
	signal A_s, B_s	: std_logic_vector(numBit-1 downto 0) 	:= (OTHERS => '0');
	signal SEL_s 	: std_logic								:= "0000";
	
	-- output
	signal Y_s 		: std_logic_vector(numBit-1 downto 0);
	
	constant delay : time := 1 ns;
  
begin

	uut: LU
		generic map (numBit)
		PORT MAP (A_s, B_s, SEL_s, Y_s);

	stimuli: process
	begin
		A_s <= "10101111";
		B_s <= "10010010";
		wait for delay;
		SEL_s <= "1000";	-- bitwise AND
		wait for delay;
		SEL_s <= "1110";	-- bitwise OR
		wait for delay;
		SEL_s <= "0110";	-- bitwise XOR
		wait;
	end process stimuli;

end TEST;


configuration TEST_LOGICALS of TB_LOGICALS is
	for TEST
		for uut: LU
			use configuration WORK.CFG_LU_STR;
		end for;
	end for;
end TEST_LOGICALS;
