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
-- File: a.b-DataPath.core\000-Adder.core\b-SumGenerator_gen.vhd
-- Date: August 2019
-- Brief: Sum Generator component of the Pentium 4 adder based upon Carry Select adders
--
--#######################################################################################

library ieee; 
use ieee.std_logic_1164.all;
use WORK.functions.all;

entity SUMGENERATOR_GEN is
	generic(
		Nbit : integer := 32 ;	-- Number of bits of operands
		Nbb : integer := 4 		-- Number of bits per carry-sel block
	);
	port(
		A, B: in std_logic_vector(Nbit-1 downto 0);
		Ci: in std_logic_vector(ceilDiv(Nbit, Nbb)-1 downto 0);
		S: out std_logic_vector(Nbit-1 downto 0)
	);
end SUMGENERATOR_GEN;

architecture STRUCTURAL of SUMGENERATOR_GEN is

	component CARRYSEL_GEN is
		generic(
			N: integer := 4
		);
		port(
			A, B: in std_logic_vector(N-1 downto 0);
			Ci: in std_logic;
			S: out std_logic_vector(N-1 downto 0)
		);
	end component;
	
	constant remndr : integer := Nbit mod Nbb;
	
begin

	CS_GEN: for i in 0 to Nbit/Nbb generate
	
		WholeBlocks: if (i < (Nbit/Nbb)) generate
			CSel_i: CARRYSEL_GEN generic map (N => Nbb)
								 port map(	A((i+1)*Nbb-1 downto i*Nbb),
											B((i+1)*Nbb-1 downto i*Nbb),
											Ci(i),
											S((i+1)*Nbb-1 downto i*Nbb)
										  );
		end generate WholeBlocks;
		
		PartialBlock: if (i = (Nbit/Nbb)) AND (remndr /= 0) generate
			CSel_last: CARRYSEL_GEN generic map (N => remndr)
									port map(	A((i*Nbb)+remndr-1 downto i*Nbb), 
												B((i*Nbb)+remndr-1 downto i*Nbb),
												Ci(i),
												S((i*Nbb)+remndr-1 downto i*Nbb)
											 );
		end generate PartialBlock;
		
	end generate CS_GEN;

end STRUCTURAL;

configuration CFG_SUMGEN_STRUCTURAL of SUMGENERATOR_GEN is
	for STRUCTURAL
		for CS_GEN

			for WholeBlocks
				for all: CARRYSEL_GEN
					use configuration WORK.CFG_CARRYSEL_GEN_STRUCTURAL;
				end for;
			end for;

			for PartialBlock
				for all: CARRYSEL_GEN
					use configuration WORK.CFG_CARRYSEL_GEN_STRUCTURAL;
				end for;
			end for;

		end for;
	end for;
end configuration CFG_SUMGEN_STRUCTURAL;
