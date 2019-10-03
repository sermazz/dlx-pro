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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-d-ALU.core\TEST-c-Comparator.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;

entity TB_COMP is
end TB_COMP;

architecture TEST of TB_COMP is

	component comparator is
		generic(
			DATA_SIZE		: integer := Nbit_DATA			-- Data size
		);                                  
		port(
			Sum			: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			Cout		: in  std_logic;
			use_borrow	: in std_logic;		-- '1' when borrow is used for comparisons instead of carry
			EQ			: out std_logic;	-- for signed
			NE			: out std_logic;	-- for signed
			LT			: out std_logic;	-- for signed/unsigned
			GT			: out std_logic;	-- for signed/unsigned
			LE			: out std_logic;	-- for signed/unsigned
			GE			: out std_logic		-- for signed/unsigned
		);
	end component;
	
	component P4ADD is
		generic (
			Nbit : integer := 32
		);
		port(
			A : IN  std_logic_vector(Nbit-1 downto 0);
			B : IN  std_logic_vector(Nbit-1 downto 0);
			Cin : IN  std_logic;
			Sum : OUT  std_logic_vector(Nbit-1 downto 0);
			Cout : OUT Std_logic
		);
	end component;

	constant numBit : integer := 8;  
	
	--  input	 
	signal A_s, B_s	: std_logic_vector(numBit-1 downto 0) 		:= (OTHERS => '0');
	signal notB_s	: std_logic_vector(numBit-1 downto 0);
	signal use_borrow_s : std_logic;
	
	signal Sum_s 	: std_logic_vector(numBit-1 downto 0);
	signal Cout_s	: std_logic;
	
	-- output
	signal EQ_s, NE_s, LT_s, GT_s, LE_s, GE_s : std_logic;
	
	constant delay : time := 1 ns;
  
begin

	notB_s <= not(B_s);

	adder : P4ADD
		generic map (numBit)
		port map (A_s, notB_s, '1', Sum_s, Cout_s);

	uut: comparator
		generic map (numBit)
		port map (
			Sum		=> Sum_s,
		    Cout	=> Cout_s,
		    use_borrow	=> use_borrow_s,
		    EQ		=> EQ_s,
		    NE		=> NE_s,
		    LT		=> LT_s,
		    GT		=> GT_s,
		    LE		=> LE_s,
		    GE		=> GE_s
		);

	stimuli: process
	begin
		-- Generic inputs test
		A_s <= std_logic_vector(to_unsigned(5, numBit));
		B_s <= std_logic_vector(to_unsigned(2, numBit));
		use_borrow_s <= '0';
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(0, numBit));
		B_s <= std_logic_vector(to_unsigned(0, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(12, numBit));
		B_s <= std_logic_vector(to_unsigned(250, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(100, numBit));
		B_s <= std_logic_vector(to_unsigned(100, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(-1, numBit));
		B_s <= std_logic_vector(to_signed(-65, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(35, numBit));
		B_s <= std_logic_vector(to_signed(4, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(-100, numBit));
		B_s <= std_logic_vector(to_signed(50, numBit));
		use_borrow_s <= '1';	-- because different sign
		wait for delay;
		A_s <= std_logic_vector(to_signed(12, numBit));
		B_s <= std_logic_vector(to_signed(-7, numBit));
		use_borrow_s <= '1';	-- because different sign
		wait for delay;
		A_s <= std_logic_vector(to_signed(-50, numBit));
		B_s <= std_logic_vector(to_signed(-50, numBit));
		wait for delay*3;
		
		-- Boundary cases test
		A_s <= std_logic_vector(to_signed(-2**(numBit-1), numBit));
		B_s <= std_logic_vector(to_signed(-2**(numBit-1), numBit));
		wait for delay;
		A_s <= std_logic_vector(to_signed(-2**(numBit-1), numBit));
		B_s <= std_logic_vector(to_signed(2**(numBit-1)-1, numBit));
		use_borrow_s <= '1';	-- because different sign
		wait for delay;
		A_s <= std_logic_vector(to_signed(2**(numBit-1)-1, numBit));
		B_s <= std_logic_vector(to_signed(-2**(numBit-1), numBit));
		use_borrow_s <= '1';	-- because different sign
		wait for delay;
		A_s <= std_logic_vector(to_signed(2**(numBit-1)-1, numBit));
		B_s <= std_logic_vector(to_signed(2**(numBit-1)-1, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(2**(numBit)-1, numBit));
		B_s <= std_logic_vector(to_unsigned(0, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(0, numBit));
		B_s <= std_logic_vector(to_unsigned(2**(numBit)-1, numBit));
		wait for delay;
		A_s <= std_logic_vector(to_unsigned(2**(numBit)-1, numBit));
		B_s <= std_logic_vector(to_unsigned(2**(numBit)-1, numBit));
		wait for delay;
		wait;
	end process stimuli;

end TEST;


configuration TEST_COMP of TB_COMP is
	for TEST
		for adder : P4ADD
			use configuration WORK.CFG_P4ADD_STRUCTURAL;
		end for;
		
		for uut: comparator
			use configuration WORK.CFG_COMP_STR;
		end for;
	end for;
end TEST_COMP;
