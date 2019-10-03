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
-- File: a.b-DataPath.core\000-Adder.core\b.a-carrysel_gen.vhd
-- Date: August 2019
-- Brief: Generic Carry Select adder exploiting 2 generic RCAs
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all; 

entity CARRYSEL_GEN is
	generic(
		N: integer := 4
	);
	port(
		A, B: in std_logic_vector(N-1 downto 0);
		Ci: in std_logic;
		S: out std_logic_vector(N-1 downto 0)
	);
end CARRYSEL_GEN;
				
architecture STRUCTURAL of CARRYSEL_GEN is

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

	component mux2_generic is
		generic(
			N :		integer := 32
		);
		port( 
			A: 		in std_logic_vector(N-1 downto 0);
			B: 		in std_logic_vector(N-1 downto 0);
			SEL:	in std_logic;
			Y:		out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	signal S_0, S_1: std_logic_vector(N-1 downto 0);
	
begin

	RCA_0: RCA_GENERIC 
		generic map (N => N)
		port map (A, B, '0', S_0);
						
	RCA_1: RCA_GENERIC	
		generic map (N => N)
		port map (A, B, '1', S_1);
						
	MUX_sum: mux2_generic 
		generic map (N => N)
		port map (S_0, S_1, Ci, S);

end STRUCTURAL;

configuration CFG_CARRYSEL_GEN_STRUCTURAL of CARRYSEL_GEN is
	for STRUCTURAL
		for all : RCA_GENERIC
			use configuration WORK.CFG_RCA_GEN_BEH;
		end for;
		for MUX_sum: mux2_generic
			use configuration WORK.CFG_MUX2_GENERIC_BEH;
		end for;
	end for;
end configuration CFG_CARRYSEL_GEN_STRUCTURAL;
