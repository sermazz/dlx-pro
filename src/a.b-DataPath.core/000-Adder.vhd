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
-- File: a.b-DataPath.core\000-Adder.vhd
-- Date: August 2019
-- Brief: Wrapper for Pentium 4 Sparse Tree Adder
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.functions.all;

-- ######## PENTIUM 4 ADDER ########
-- Sparse tree adder based on the one of the Pentium 4 microprocessor; it is composed by
-- a sparse tree carry generator and a sum generator made up of carry select adders.

entity P4ADD is
	generic (
		Nbit : integer := 32
	);
	port(
		A 	: in  std_logic_vector(Nbit-1 downto 0);
		B 	: in  std_logic_vector(Nbit-1 downto 0);
		Cin : in  std_logic;
		Sum : out std_logic_vector(Nbit-1 downto 0);
		Cout: out Std_logic
	);
end P4ADD;

architecture STRUCTURAL of P4ADD is

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
	 
	component SUMGENERATOR_GEN is
		generic(
			Nbit : integer := 32 ;	-- Number of bits of operands
			Nbb : integer := 4 		-- Number of bits per carry-sel block
		);
		port(
			A, B: in std_logic_vector(Nbit-1 downto 0);
			Ci: in std_logic_vector(ceilDiv(Nbit,Nbb)-1 downto 0);
			S: out std_logic_vector(Nbit-1 downto 0)
		);
	end component;

	signal sparseCarries, carryArray: std_logic_vector(ceilDiv(Nbit,4)-1 downto 0);
	
begin

	P4_CarryGen : CARRYGENERATOR_GEN
		generic map (Nbit_i => Nbit)
		port map (A_i => A, B_i => B, Cin => Cin, Carries => sparseCarries);

	P4_SumGen : SUMGENERATOR_GEN	
		generic map(Nbit => Nbit, Nbb => 4)
		port map (A => A, B => B, Ci => carryArray, S => Sum);
	
	carryArray 	<= sparseCarries(ceilDiv(Nbit,4) - 2 downto 0) & Cin;
	Cout 		<= sparseCarries(ceilDiv(Nbit,4) - 1);

end STRUCTURAL;

configuration CFG_P4ADD_STRUCTURAL of P4ADD is
	for STRUCTURAL
	
		for P4_CarryGen : CARRYGENERATOR_GEN
			use configuration WORK.CFG_CARRYGEN_STRUCTURAL;
		end for;
		
		for P4_SumGen : SUMGENERATOR_GEN
			use configuration WORK.CFG_SUMGEN_STRUCTURAL;
		end for;
		
	end for;
end configuration CFG_P4ADD_STRUCTURAL;
