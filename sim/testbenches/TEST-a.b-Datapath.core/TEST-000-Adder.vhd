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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-000-Adder.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_signed.all;
use WORK.functions.all;

entity TB_ADDERS is 
end TB_ADDERS; 

architecture TEST of TB_ADDERS is
	
	component P4ADD is
		generic (	Nbit : integer := 32 );
			port( 	A : IN  std_logic_vector(Nbit-1 downto 0);
					B : IN  std_logic_vector(Nbit-1 downto 0);
					Cin : IN  std_logic;
					Sum : OUT  std_logic_vector(Nbit-1 downto 0);
					Cout : OUT Std_logic
			);
	end component;
	
	constant N: integer := 8; -- bits of the operands
	
	signal A_s, B_s : std_logic_vector(N-1 downto 0) := (OTHERS => '0');
	signal Ci_s : std_logic := '0';
	signal S_p4 : std_logic_vector(N-1 downto 0);
	signal Co_p4 : std_logic;
	
begin
	
	P4ADD_0: P4ADD
		generic map (Nbit => N)
		port map (A_s, B_s, Ci_s, S_p4, Co_p4);
	
	stimuli: process
		variable correctRes: std_logic_vector(N-1 downto 0);
	begin
		
		A_s <= X"80"; -- start from most negative
		
		-- cycle for operand A
		NumROW : for i in 0 to 2**(N)-1 loop
			
			B_s <= X"80"; -- start from most negative
			-- cycle for operand B
			NumCOL : for j in 0 to 2**(N)-1 loop
				wait for 1 ns;
				correctRes := A_s + B_s;
				assert (S_p4 = correctRes) report "Error" severity error;
				wait for 0.1 ns;
				B_s <= B_s + '1';
			end loop NumCOL;
			
			A_s <= A_s + '1';
		
		end loop NumROW ;

		wait;          
	end process stimuli;
	
end TEST;


architecture TEST2 of TB_ADDERS is

	component RCA_GENERIC is 
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
	end component;
	
	component P4ADD is
		generic (	Nbit : integer := 32 );
			port( 	A : IN  std_logic_vector(Nbit-1 downto 0);
					B : IN  std_logic_vector(Nbit-1 downto 0);
					Cin : IN  std_logic;
					Sum : OUT  std_logic_vector(Nbit-1 downto 0);
					Cout : OUT Std_logic
			);
	end component;
	
	component CARRYGENERATOR_GEN is
		generic(
			Nbit_i : integer := 32
		);
		port(
			A_i, B_i: in std_logic_vector(Nbit_i-1 downto 0);
			Cin: in std_logic;
			Carries: out std_logic_vector(ceilDiv(Nbit_i,4)-1 downto 0)
		);
	end component;
	
	constant N: integer := 64; -- bits of the operands
	
	signal A_s, B_s : std_logic_vector(N-1 downto 0) := (OTHERS => '0');
	signal Ci_s : std_logic := '0';
	signal S_rca, S_p4 : std_logic_vector(N-1 downto 0);
	signal Co_rca, Co_p4 : std_logic;
	signal C_array : std_logic_vector(ceilDiv(N,4) downto 0);
	
begin
	
	RCA_0: RCA_GENERIC 
	   generic map (N => N) 
	   port map (A_s, B_s, Ci_s, S_rca, Co_rca);
	   
	P4ADD_0: P4ADD
		generic map (Nbit => N)
		port map (A_s, B_s, Ci_s, S_p4, Co_p4);
		
	CARRYGEN_0: CARRYGENERATOR_GEN
		generic map (Nbit_i => N)
		port map (A_s, B_s, Ci_s, C_array(ceilDiv(N, 4) downto 1));
	
	-- Whole carry array from C_0 (= C_in) to C_N (= C_out)
	-- Only C_array(Nbit_i/4-1 downto 0) is passed to the sum generator
	C_array(0) <= Ci_s;
	 
	StimuliProc: process
	begin
		A_s <= X"FFFFFFFFFFFFFFFF";
		B_s <= X"0000000100000001";
		Ci_s <= '0';
		wait for 2 ns;
		A_s <= X"FFFFFFFFFFFFFFFF";
		B_s <= X"FFFFFFFFFFFFFFFF";
		wait for 2 ns;
		A_s <= X"00FF000000FF0000";
		B_s <= X"839BC0FF839BC0FF";
		Ci_s <= '1';
		wait;
	end process StimuliProc;
	
end TEST2;


configuration TEST_ADDER_complete of TB_ADDERS is
  for TEST
	for P4ADD_0: P4ADD
      use configuration WORK.CFG_P4ADD_STRUCTURAL;
    end for;
  end for;
end TEST_ADDER_complete;

configuration TEST_ADDER_custom of TB_ADDERS is
  for TEST2
  
    for RCA_0: RCA_GENERIC 
      use configuration WORK.CFG_RCA_GEN_BEH;
    end for;
	
	for P4ADD_0: P4ADD
      use configuration WORK.CFG_P4ADD_STRUCTURAL;
    end for;
	
	for CARRYGEN_0: CARRYGENERATOR_GEN
      use configuration WORK.CFG_CARRYGEN_STRUCTURAL;
    end for;
	
  end for;
end TEST_ADDER_custom;
