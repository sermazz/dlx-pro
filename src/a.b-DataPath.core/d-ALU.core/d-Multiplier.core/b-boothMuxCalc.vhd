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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.core\a-boothMuxCalc.vhd
-- Date: August 2019
-- Brief: Block to calculate all the needed inputs for Booth Algorithm muxes only once
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- ######## BOOTH MUX INPUTS CALCULATOR ########
-- This module takes a multiplicand for the radix-4 Booth algorithm and outputs all the
-- needed inputs for the muxes driven by the Booth encodings; the computed values, given
-- the input operand A, are: 0, A, -A, 2A, -2A.
-- Note that the N-bit inputs, considered a signed value, is extended to N+2 bits to
-- correctly manage the multiplication by 2 (shift of 1 bit to left) and signed operations

entity boothMuxCalc is
	generic (
		N: integer := 16
	);
	port(
		A: IN std_logic_vector(N-1 downto 0);
		p_A, m_A, p_2A, m_2A: OUT std_logic_vector(N+1 downto 0)
	);
end boothMuxCalc;

architecture Behavioural of boothMuxCalc is
	
	signal A_ext, doubleA_ext : std_logic_vector(N+1 downto 0);
	
begin
	-- Extend the sign of A input to N+2 bits
	A_ext <= A(N-1) & A(N-1) & A;
	-- Extend sign of A and double it
	doubleA_ext <= A(N-1) & A & '0';

	-- Generate outputs
	p_A <= A_ext;
	m_A <= not(A_ext) + 1;
	p_2A <= doubleA_ext;
	m_2A <= not(doubleA_ext) + 1;

end Behavioural;

configuration CFG_BOOTHMUXCALC_BEH of boothMuxCalc is
	for Behavioural
	end for;
end CFG_BOOTHMUXCALC_BEH;

