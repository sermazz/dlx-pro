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
-- File: a.b-DataPath.core\d-ALU.core\b-Logicals.vhd
-- Date: August 2019
-- Brief: Logic unit made up of a NAND gates tree, based on the OpenSPARC T2 one
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use WORK.myTypes.all;

-- ######## LOGIC UNIT ########
-- Logic unit for the computation of AND, OR, XOR of the two input operands; the
-- structure consists of a NAND gates tree, like the logic unit of the OpenSPARC T2
-- architecture, and has 4 control signals encoding the operation to perform

entity LU is
	generic (
		N	: integer := Nbit_DATA
	);
	port (
		A 	: in  std_logic_vector(N-1 downto 0);
		B 	: in  std_logic_vector(N-1 downto 0);
		SEL	: in std_logic_vector(3 downto 0);
		Y 	: out std_logic_vector(N-1 downto 0)
	);
end LU;

architecture Structural of LU is
	
	component INV_GENERIC is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	component NAND3_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			B 	: in std_logic_vector(N-1 downto 0);
			C	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	component NAND4_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			B 	: in std_logic_vector(N-1 downto 0);
			C 	: in std_logic_vector(N-1 downto 0);
			D 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	signal not_A, not_B : std_logic_vector(N-1 downto 0);
	
	type data_array is array(natural range <>) of std_logic_vector(N-1 downto 0);
	signal S 			: data_array(0 to 3);
	signal NAND_out		: data_array(0 to 3);
	
begin
	
	-- Extension of selection signals to match data width
	SelExtGen: for i in 0 to 3 generate
		S(i) <= (others => SEL(i));
	end generate SelExtGen;
	
	-- Inverters
	INV_0: INV_GENERIC
		generic map (N)
		port map (
			A => A, 
			Y => not_A
		);
		
	INV_1: INV_GENERIC
		generic map (N)
		port map (
			A => B, 
			Y => not_B
		);
	
	-- First NAND level
	NAND_0: NAND3_generic
		generic map (N)
		port map (
			A => not_A,
			B => not_B,
			C => S(0),
			Y => NAND_out(0)
		);
		
	NAND_1: NAND3_generic
		generic map (N)
		port map (
			A => not_A,
			B => B,
			C => S(1),
			Y => NAND_out(1)
		);
		
	NAND_2: NAND3_generic
		generic map (N)
		port map (
			A => A,
			B => not_B,
			C => S(2),
			Y => NAND_out(2)
		);
	
	NAND_3: NAND3_generic
		generic map (N)
		port map (
			A => A,
			B => B,
			C => S(3),
			Y => NAND_out(3)
		);
	
	-- Final NAND
	NAND_4: NAND4_generic
		generic map (N)
		port map (
			A => NAND_out(0),
			B => NAND_out(1),
			C => NAND_out(2),
			D => NAND_out(3),
			Y => Y
		);
		
end Structural;

configuration CFG_LU_STR of LU is
	for Structural
		
		for all : INV_GENERIC
			use configuration work.CFG_INV_BEH;
		end for;
		
		for all : NAND3_GENERIC
			use configuration work.CFG_NAND3_BEH;
		end for;
		
		for all : NAND4_GENERIC
			use configuration work.CFG_NAND4_BEH;
		end for;
	end for;
end CFG_LU_STR;
