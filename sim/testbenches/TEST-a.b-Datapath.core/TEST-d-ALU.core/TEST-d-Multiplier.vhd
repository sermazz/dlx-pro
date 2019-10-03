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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-d-ALU.core\TEST-d-Multiplier.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use work.myTypes.all;

entity TB_MULT is
end TB_MULT;

architecture TEST of TB_MULT is

	component BOOTHMUL is
		generic (
			Nbit: natural := Nbit_DATA/2	-- Should be even (extension for odd still to do)
		);
		port (
			A 		: in  std_logic_vector(Nbit-1 downto 0);
			B 		: in  std_logic_vector(Nbit-1 downto 0);
			Sum_out : out std_logic_vector(2*Nbit-1 downto 0); -- Sum array output
			Car_out : out std_logic_vector(2*Nbit-1 downto 0)  -- Carry array output
		);
	end component;

  constant numBit : integer := 8;  

  --  input	 
  signal A_s : std_logic_vector(numBit-1 downto 0);
  signal B_s : std_logic_vector(numBit-1 downto 0);

  -- output
  signal Sum_s : std_logic_vector(2*numBit-1 downto 0);
  signal Car_s : std_logic_vector(2*numBit-1 downto 0);
  signal Y_s   : std_logic_vector(2*numBit-1 downto 0);
  
begin

   uut: BOOTHMUL
		generic map (numBit)
		PORT MAP (A_s, B_s, Sum_s, Car_s);


  stimuli: process
	variable correctRes: std_logic_vector(2*numBit-1 downto 0);
  begin
	
	A_s <= X"80"; -- start from most negative
	
    -- cycle for operand A
    NumROW : for i in 0 to 2**(numBit)-1 loop
		
		B_s <= X"80"; -- start from most negative
        -- cycle for operand B
    	NumCOL : for j in 0 to 2**(numBit)-1 loop
			wait for 0.5 ns;
			Y_s <= Sum_s + Car_s;
			correctRes := A_s * B_s;
			wait for 0.5 ns;
			assert (Y_s = correctRes) report "Error" severity error;
			wait for 0.1 ns;
			B_s <= B_s + '1';
		end loop NumCOL;
		
		A_s <= A_s + '1';
	
    end loop NumROW ;

    wait;          
  end process stimuli;

end TEST;


architecture TEST2 of TB_MULT is

	component BOOTHMUL is
		generic (
			Nbit: natural := Nbit_DATA/2	-- Should be even (extension for odd still to do)
		);
		port (
			A 		: in  std_logic_vector(Nbit-1 downto 0);
			B 		: in  std_logic_vector(Nbit-1 downto 0);
			Sum_out : out std_logic_vector(2*Nbit-1 downto 0); -- Sum array output
			Car_out : out std_logic_vector(2*Nbit-1 downto 0)  -- Carry array output
		);
	end component;

  constant numBit : integer := 16;  

  --  input	 
  signal A_s : std_logic_vector(numBit-1 downto 0) := (OTHERS => '0');
  signal B_s : std_logic_vector(numBit-1 downto 0) := (OTHERS => '0');

  -- output
  signal Sum_s : std_logic_vector(2*numBit-1 downto 0);
  signal Car_s : std_logic_vector(2*numBit-1 downto 0);

  constant delay : time := 1 ns;
  
begin

   uut: BOOTHMUL
		generic map (numBit)
		PORT MAP (A_s, B_s, Sum_s, Car_s);

  stimuli: process
  begin
	A_s <= X"8000"; 
	B_s <= X"8002"; 
	wait for delay;
	A_s <= X"7000"; 
	B_s <= X"7000"; 
	wait for delay;
	A_s <= X"FF80"; 
	B_s <= X"FF82"; 
	wait for delay;
	-- Smallest operands (biggest result)
	A_s <= X"8000"; 
	B_s <= X"8000"; 
	wait for delay;
	-- Biggest operands
	A_s <= X"7FFF"; 
	B_s <= X"7FFF"; 
	wait for delay;
	-- Opposite operands (most negative result)
	A_s <= X"8000"; 
	B_s <= X"7FFF"; 
	wait for delay;
	-- Neutral multiplication
	A_s <= X"0061"; -- +97
	B_s <= X"0001"; -- 1
	wait for delay;
	-- Only sign change
	A_s <= X"0061"; -- +97
	B_s <= X"FFFF"; -- -1
	wait for delay;
	-- Only sign change
	A_s <= X"FFFF"; -- -1
	B_s <= X"FF9F"; -- -97
	wait for delay;
	-- Zero multiplication
	A_s <= X"0061"; -- +97
	B_s <= X"0000"; -- 0
	wait for delay;
	-- Zero multiplication
	A_s <= X"0000"; -- 0
	B_s <= X"0061"; -- +97
	wait;
  end process stimuli;

end TEST2;


configuration TEST_MULT_complete of TB_MULT is
	for TEST
		for uut: BOOTHMUL
			use configuration WORK.CFG_BOOTHMUL_STR;
		end for;
	end for;
end TEST_MULT_complete;

configuration TEST_MULT_custom of TB_MULT is
	for TEST2
		for uut: BOOTHMUL
			use configuration WORK.CFG_BOOTHMUL_STR;
		end for;
	end for;
end TEST_MULT_custom;
