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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.core\a-boothEnc_block.vhd
-- Date: August 2019
-- Brief: Encoder for 3-bits group of the B operand for Modified Booth Algorithm
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;

-- ######## BOOTH ENCODER BLOCK ########
-- Implements the LUT of a radix-4 Modified Booth algorithm along with a mux whose SEL
-- output of boothEnc_block is the selection input, with data inputs 0,A,-A,2A,-2A given
-- by a boothMuxCalc block

entity boothEnc_block is
	port(
		bits: IN std_logic_vector(2 downto 0);
		sel : OUT std_logic_vector(2 downto 0)
	);
end boothEnc_block;

architecture Behavioural of boothEnc_block is

begin

	-- Mux DATA inputs are supposed to correspond to following SEL signal of mux:
	-- 000 -> +0
	-- 001 -> +A
	-- 010 -> -A
	-- 011 -> +2A
	-- 100 -> -2A

	with bits select
		sel <= 	"000" when "000",
				"001" when "001",
				"001" when "010",
				"011" when "011",
				"100" when "100",
				"010" when "101",
				"010" when "110",
				"000" when others;

end Behavioural;

configuration CFG_BOOTHENCODER_BEH of boothEnc_block is
	for Behavioural
	end for;
end configuration;

