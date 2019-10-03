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
-- File: a.b-DataPath.core\000-Adder.core\a-CarryGenerator_gen.vhd
-- Date: August 2019
-- Brief: Carry generator sparse tree, basis of the Pentium 4 adder
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.functions.all;


entity CARRYGENERATOR_GEN is
	generic(
		Nbit_i : integer := 32
	);
	port(
		A_i, B_i: in std_logic_vector(Nbit_i-1 downto 0);
		Cin: in std_logic;
		Carries: out std_logic_vector(ceilDiv(Nbit_i,4)-1 downto 0)
	);
end CARRYGENERATOR_GEN;


architecture STRUCTURAL of CARRYGENERATOR_GEN is
	
	-- Signals declaration
	
	-- Extend the number of bits to a multiple of 4 to keep the internal structure simple,
	-- with a fixed step of 4 among output carries of the bit number-generic sparse tree
	-- This is needed because dealing with the same structure with a number of bits not
	-- multiple of 4 might leave some wires floating: better to set them to 0 with a padding
	constant Nbit : integer := makeDivisible(Nbit_i, 4);
	signal A, B : std_logic_vector(Nbit-1 downto 0);
	
	-- Declaration of wires matrix for P and G signals (not all of its elements are used)
	constant NRow : integer := log2(Nbit)+2;
	type WiresMatrix is array(0 to NRow-1) of std_logic_vector(Nbit-1 downto 0);
	signal PSig, GSig : WiresMatrix;
	
	-- Components declaration
	component PGNETWORK_GEN is
		generic(
			Nbit : integer := 32
		);
		port(
			A, B: in std_logic_vector(Nbit-1 downto 0);
			Cin: in std_logic;
			P, G: out std_logic_vector(Nbit-1 downto 0)
		);
	end component;
	
	component bigG is
		-- ik subscript stands for i:k
		-- kj subscript actually stands for k-1:j
		PORT(  
			G_ik, P_ik, G_kj: IN STD_LOGIC;
			G: OUT STD_LOGIC
		);
	end component;
	
	component bigPG is
		-- ik subscript stands for i:k
		-- kj subscript actually stands for k-1:j
		port( 
			G_ik, P_ik, G_kj, P_kj: IN STD_LOGIC;
			G, P: OUT STD_LOGIC
		);
	end component;
	
begin
	
	-- Add padding to A and B input operands to manage number of bits not multiple of 4
	-- (notice that if padding is not necessary range is negative and nothing happens)
	A <=(Nbit-1 downto Nbit_i => '0') & A_i;
	B <=(Nbit-1 downto Nbit_i => '0') & B_i;

	-- Instantiate the PG network, whose outputs are written on the first row of the
	-- matrix of wires, filling the whole row
	PGNetwork_0: PGNETWORK_GEN 
		generic map (
			Nbit=>Nbit
		)
		port map(	
			A=>A, B=>B, Cin=>Cin, 
			P=>PSig(0), G=>GSig(0)
		);
	
	-- The sparse tree is based upon a reversed binary tree, whose structure is then complemented
	-- by additional branches to reach the desired number of steps among the output carries (in
	-- our case, the step is 4); here, the reversed binary tree is generated first
	BinaryTreeGen: for level in 1 to NRow-1 generate
		BinLevelGen: for i in 0 to Nbit-1 generate
		
			Bin_Gen_0: if ((i+1) = 2**level) generate
				blockG_bin: bigG port map 	(	G_ik => GSig(level-1)(i),
												P_ik => PSig(level-1)(i),
												G_kj => GSig(level-1)(i-2**(level-1)),
												G => GSig(level)(i)
											);
			end generate Bin_Gen_0;
			
			Bin_Gen_i: if ((i+1) > 2**level) AND (((i+1) mod 2**level) = 0) generate
				blockPG_bin: bigPG port map (	G_ik => GSig(level-1)(i),
												P_ik => PSig(level-1)(i),
												G_kj => GSig(level-1)(i-2**(level-1)),
												P_kj => PSig(level-1)(i-2**(level-1)),
												G => GSig(level)(i),
												P => PSig(level)(i)
											);
			end generate Bin_Gen_i;
			
			-- If signal on wire i of a level is needed on next level, propagate it
			Connection_Gen: if (level > 2) and (((i+1) mod 4) = 0) and ((i mod 2**level) < 2**(level-1)) generate
				GSig(level)(i) <= GSig(level-1)(i);
				PSig(level)(i) <= PSig(level-1)(i);
			end generate Connection_Gen;
			
		end generate BinLevelGen;
	end generate BinaryTreeGen;
	
	-- The binary tree is then complemented by a pattern of additional branches and leaves
	ComplementBranches: for level in 4 to NRow-1 generate
		ComLevelGen: for i in 0 to Nbit-1 generate
			
			Com_Gen_0: if ((i+1) < 2**level) AND NOT(((i+1) mod 2**level) = 0) AND (((i/(2**(level-1))) mod 2) /= 0) AND (((i+1) mod 4) = 0) generate
				blockG_com: bigG port map 	(	G_ik => GSig(level-1)(i),
												P_ik => PSig(level-1)(i),
												G_kj => GSig(level-1)((i/2**(level-1))*2**(level-1) - 1),
												G => GSig(level)(i)
											);
			end generate Com_Gen_0;
			
			Com_Gen_i: if ((i+1) > 2**level) AND NOT(((i+1) mod 2**level) = 0) AND (((i/(2**(level-1))) mod 2) /= 0) AND (((i+1) mod 4) = 0) generate
				blockPG_com: bigPG port map (	G_ik => GSig(level-1)(i),
												P_ik => PSig(level-1)(i),
												G_kj => GSig(level-1)((i/2**(level-1))*2**(level-1) - 1),
												P_kj => PSig(level-1)((i/2**(level-1))*2**(level-1) - 1),
												G => GSig(level)(i),
												P => PSig(level)(i)
											);
			end generate Com_Gen_i;
			
			-- If it is the last row, connects the G signals to the carries output			
			CarriesOut_Gen: if (level = NRow-1) and (((i+1) mod 4) = 0) generate
				Carries((i+1)/4 - 1) <= GSig(level)(i);
			end generate CarriesOut_Gen;
			
		end generate ComLevelGen;
	end generate ComplementBranches;	
		
end architecture;



configuration CFG_CARRYGEN_STRUCTURAL of CARRYGENERATOR_GEN is
	for STRUCTURAL
		for PGNetwork_0: PGNETWORK_GEN
			use configuration WORK.CFG_PGNET_STRUCTURAL;
		end for;
		
		for BinaryTreeGen
			for BinLevelGen
				
				for Bin_Gen_0
					for all: bigG
						use configuration WORK.CFG_bigG_BEHAVIOURAL;
					end for;
				end for;

				for Bin_Gen_i
					for all: bigPG
						use configuration WORK.CFG_bigPG_BEHAVIOURAL;
					end for;
				end for;

			end for;
		end for;
		
		for ComplementBranches
			for ComLevelGen
				
				for Com_Gen_0
					for all: bigG
						use configuration WORK.CFG_bigG_BEHAVIOURAL;
					end for;
				end for;

				for Com_Gen_i
					for all: bigPG
						use configuration WORK.CFG_bigPG_BEHAVIOURAL;
					end for;
				end for;

			end for;
		end for;
		
	end for;
end configuration CFG_CARRYGEN_STRUCTURAL;
