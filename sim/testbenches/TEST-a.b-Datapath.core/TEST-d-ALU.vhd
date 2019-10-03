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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-d-ALU.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.functions.all;

entity TB_ALU is
end TB_ALU;

architecture TEST of TB_ALU is

	component ALU is
		generic(
			DATA_SIZE		: integer := Nbit_DATA				-- Data size
		);                                  
		port(
			A		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			B		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			opcode	: in  aluOp;
			Z		: out std_logic_vector(DATA_SIZE - 1 downto 0)
		);
	end component;

	constant numBit : integer := 32;  
	
	--  input	 
	signal A_s, B_s	: std_logic_vector(numBit-1 downto 0) 	:= (OTHERS => '0');
	signal opcode_s : aluOp									:= NOP;
	
	-- output
	signal Z_s 		: std_logic_vector(numBit-1 downto 0);
	
	constant delay : time := 1 ns;
  
begin

	uut: ALU
		generic map (numBit)
		PORT MAP (A_s, B_s, opcode_s, Z_s);

	stimuli: process
	begin
		-- Logicals
		A_s <= X"10101111";
		B_s <= X"10010010";
		wait for delay;
		opcode_s <= ANDalu;
		wait for delay;
		opcode_s <= ORalu;
		wait for delay;
		opcode_s <= XORalu;
		wait for delay;
		
		-- Shifts
		A_s <= X"00000111"; 
		B_s <= X"00000001";
		opcode_s <= LSL;
		wait for delay;
		A_s <= X"00000011"; 
		B_s <= X"00000100";
		wait for delay;
		opcode_s <= RSL;
		wait for delay;
		A_s <= X"10001111"; 
		opcode_s <= RSA;
		wait for delay;
		
		-- Comparisons
		A_s <= std_logic_vector(to_unsigned(0, numBit));
		B_s <= std_logic_vector(to_unsigned(0, numBit));
		opcode_s <= LE;
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(12, numBit));
		B_s <= std_logic_vector(to_unsigned(250, numBit));
		opcode_s <= LEU;
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(100, numBit));
		B_s <= std_logic_vector(to_unsigned(100, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(-1, numBit));
		B_s <= std_logic_vector(to_signed(-65, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(-100, numBit));
		B_s <= std_logic_vector(to_signed(50, numBit));
		opcode_s <= LT;
		wait for delay;
		A_s <= std_logic_vector(to_signed(12, numBit));
		B_s <= std_logic_vector(to_signed(-7, numBit));
		wait for delay;
		opcode_s <= GT;
		wait for delay;
		
		-- Multiplier
		A_s <= X"00007F00"; 
		B_s <= X"00007F00"; 
		opcode_s <= MULT;
		wait for delay;
		A_s <= X"00008000"; 
		B_s <= X"00008002"; 
		wait for delay;
		A_s <= X"00000000"; 
		B_s <= X"0000FFFF"; 
		wait for delay;
		
		-- Add/sub
		A_s <= X"70000000"; 
		B_s <= X"70000000"; 
		opcode_s <= ADD;
		wait for delay;
		A_s <= X"80000000"; 
		B_s <= X"80000002"; 
		opcode_s <= SUB;
		wait for delay;
		
		-- Through B
		A_s <= X"70000000"; 
		B_s <= X"AABBCCDD"; 
		opcode_s <= THR_B;
		wait for delay;
		
		wait;
	end process stimuli;

end TEST;


configuration TEST_ALU of TB_ALU is
	for TEST
		for uut: ALU
			use configuration WORK.CFG_DLX_ALU;
		end for;
	end for;
end TEST_ALU;
