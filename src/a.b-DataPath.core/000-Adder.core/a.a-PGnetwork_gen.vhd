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
-- File: a.b-DataPath.core\000-Adder.core\a.a-PGnetwork_gen.vhd
-- Date: August 2019
-- Brief: PG Netork for generic A and B inputs
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

 entity PGNETWORK_GEN is
	generic(
		Nbit : integer := 32
	);
	port(
		A, B: in std_logic_vector(Nbit-1 downto 0);
		Cin: in std_logic;
		P, G: out std_logic_vector(Nbit-1 downto 0)
	);
end PGNETWORK_GEN;

architecture STRUCTURAL of PGNETWORK_GEN is

	component smallPG is
		PORT (
			A, B : IN STD_LOGIC;
			p, g : OUT STD_LOGIC
		);
	end component;
	
	signal gen_0: std_logic;
	
begin

	PGNet_gen: for i in 0 to Nbit-1 generate
		G0: if i=0 generate
			smallPG_0: smallPG port map (A(i), B(i), P(i), gen_0);
		end generate G0;
		Gi: if i>0 generate
			smallPG_i: smallPG port map (A(i), B(i), P(i), G(i));
		end generate Gi;
	end generate PGNet_gen;
	
	-- To consider the carry in in the first block of the PG network
	G(0) <= gen_0 OR (A(0) AND Cin) OR (B(0) AND Cin);

end architecture;

configuration CFG_PGNET_STRUCTURAL of PGNETWORK_GEN is
	for STRUCTURAL
		for PGNet_gen

			for G0
				for all : smallPG
					use configuration WORK.CFG_smallPG_BEHAVIOURAL;
				end for;
			end for;

			for Gi
				for all : smallPG
					use configuration WORK.CFG_smallPG_BEHAVIOURAL;
				end for;
			end for;

		end for;
	end for;
end configuration CFG_PGNET_STRUCTURAL;
