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
-- File: a.b-DataPath.core\d-ALU.core\c-Comparator.vhd
-- Date: August 2019
-- Brief: Signed/unsigned integers magnitude comparator
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

-- ######## COMPARATOR ########
-- The following entity is the structure of a magnitude comparator capable of efficiently
-- performing comparisons between two signed or two unsigned integers. The comparator
-- exploits the result of the subtraction of the two input operands to be compared A - B
-- which is computed by an external adder; by analysing the Sum and the Carry Out outupts
-- of the adder, the correct outputs to signal the relative magnitude are set to 1, also
-- basing on the input use_borrow, to differentiate between signed and unsigned operations

entity comparator is
	generic(
		DATA_SIZE		: integer := Nbit_DATA			-- Data size
	);                                  
	port(
		Sum			: in  std_logic_vector(DATA_SIZE - 1 downto 0);
		Cout		: in  std_logic;
		use_borrow	: in std_logic;	-- '1' when borrow is used for comparisons instead of carry
		EQ			: out std_logic;	-- for signed
        NE			: out std_logic;	-- for signed
        LT			: out std_logic;	-- for signed/unsigned
        GT			: out std_logic;	-- for signed/unsigned
        LE			: out std_logic;	-- for signed/unsigned
        GE			: out std_logic		-- for signed/unsigned
	);
end comparator;

architecture Structural of comparator is

	-- The comparator structurally described in the following analyses the magnitude
	-- of the operands A and B, whose subtraction result is given by Sum and Cout.
	
	-- For UNSIGNED integers:
	-- the comparison is based on the observation that when A >= B, then the subtraction
	-- of B from A doesn't require any borrow from the bit at MSB+1, thus the borrow flag
	-- for the subtraction is 0 (and thus for the adder, which performs the subtraction
	-- with an addition in 2's complement, carryOut = not(borrow) = 1); if A < B, instead,
	-- a borrow is required (borrow = 1, carry = 0), while if A = B, then the result of
	-- the subtraction is 0.
	
	-- For SIGNED integers:
	-- when the two operands have the same sign, the adder still performs a subtraction
	-- (i.e. an addition where one of the two operands is written in 2's complement form);
	-- however, when the signs of A and B are different, the operation A - B ends up being
	-- an addition between two positive numbers or two negative numbers. The possible
	-- scenarios are:
	-- [A >= B] - When A>=0 and B<=0, A-B is an addition, thus it is always positive and
	--		never has a carry out = 1 since there is the sign bit which "absorbs" the
	--		potential carry out coming from the addition; so carry out = 0
	-- [A < B]  - When A<0 and B>0, A-B is an algebraic addition of two negative numbers,
	--		which will always give a carry out = 1 due to the sum of their MSB, which,
	--		being the addends negative, are both 1s
	
	-- From the described scenarios, it can be observed how the carry assumes an opposite
	-- meaning when the operands are SIGNED integers and they have OPPOSITE sign. This is
	-- why, in order to manage also signed comparisons, the Carry out of the adder has to
	-- be complemented (and thus, the BORROW is considered instead), when SIGNED integers
	-- with OPPOSITE sign gets compared, in order to use the same structure employed for
	-- unsigned comparisons.
	-- To achieve this, the input use_borrow is used: it is set to '0' when there an
	-- unsigned comparison in needed, and to "A(sign) XOR B(sign)" when there is a signed
	-- comparison, so that it is 1 when the signs of A and B are different, correctly
	-- complementing the Carry flag so that the Borrow is instead used.

	component XOR2_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			B 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	component ZeroDet_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic
		);
	end component;

	component INV_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	component OR2_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			B 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	component AND2_generic is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in std_logic_vector(N-1 downto 0);
			B 	: in std_logic_vector(N-1 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	signal cb_flag, cb_flag_n			: std_logic;	-- Carry/borrow flag (it's the borrow when use_borrow='1')
	signal zero_sum, zero_sum_n			: std_logic;	-- '1' when the output of the adder is 0

begin

	cb_XOR : XOR2_generic
		generic map (1)
		port map (
			A(0) => Cout,
		    B(0) => use_borrow,
		    Y(0) => cb_flag
		);
		
	cb_INV : INV_generic
		generic map (1)
		port map (
			A(0) => cb_flag, 
			Y(0) => cb_flag_n
		);
		
	zero_det : ZeroDet_generic
		generic map (DATA_SIZE)
		port map (Sum, zero_sum);
		
	zero_det_INV : INV_generic
		generic map (1)
		port map (
			A(0) => zero_sum,
		    Y(0) => zero_sum_n
		);
		
	-- A = B (EQ)
	EQ <= zero_sum;
	
	-- A /= B (NE)
	NE <= zero_sum_n;
	
	-- A < B (LT)
	LT <= cb_flag_n;
	
	-- A > B (GT)
	gt_AND : AND2_generic
		generic map (1)
		port map (
			A(0) => cb_flag,
			B(0) => zero_sum_n,
			Y(0) => GT
		);

	-- A <= B (LE)
	le_OR : OR2_generic
		generic map (1)
		port map (
			A(0) => cb_flag_n,
			B(0) => zero_sum,
			Y(0) => LE
		);
	
	-- A >= B (GE)
	GE <= cb_flag;

end Structural;

configuration CFG_COMP_STR of comparator is
	for Structural
		
		for cb_XOR : XOR2_generic
			use configuration work.CFG_XOR2_BEH;
		end for;
		
		for all : INV_generic
			use configuration work.CFG_INV_BEH;
		end for;
		
		for zero_det : ZeroDet_generic
			use configuration work.CFG_ZERODET_BEH;
		end for;
		
		for gt_AND : AND2_generic
			use configuration work.CFG_AND2_BEH;
		end for;
		
		for le_OR : OR2_generic
			use configuration work.CFG_OR2_BEH;
		end for;
		
	end for;
end CFG_COMP_STR;
