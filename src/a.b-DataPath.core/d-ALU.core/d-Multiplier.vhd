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
-- File: a.b-DataPath.core\d-ALU.core\d-Multiplier.vhd
-- Date: August 2019
-- Brief: Signed multiplier based on radix-4 Modified Booth Algorithm
--
--#######################################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.myTypes.all;

-- ######## BOOTH MULTIPLIER ########
-- Signed multiplier based on radix-4 Modified Booth Algorithm resorting to a structural
-- view: a Booth Encoder drives a number of muxes, all with the same data inputs 0,A,-A,
-- 2A,-2A computed a single time by a boothMuxCalc block and distributed to all muxes.
-- The recoded portions of operand B given by the muxes are serially summed up by means
-- of several Carry Save Adders and, as last step, the final sum and carry vector are
-- summed up by a Sparse Tree adder.

entity BOOTHMUL is
	generic (
		Nbit: natural := Nbit_DATA/2  -- Should be even and >= 16 (complete generalization still to do)
	);
	port (
		A 		: in  std_logic_vector(Nbit-1 downto 0);
		B 		: in  std_logic_vector(Nbit-1 downto 0);
		Sum_out : out std_logic_vector(2*Nbit-1 downto 0); -- Sum array output
		Car_out : out std_logic_vector(2*Nbit-1 downto 0)  -- Carry array output
	);
end BOOTHMUL;

architecture Structural of BOOTHMUL is
	-- The Carry Save Adders are all of the same size: the idea behind this architecture,
	-- which allows to use only 0,A,-A,2A,-2A instead of further shifts at each step, is
	-- that each adder works on a different portion of the partial sum: each time a sum
	-- is performed by a CSA, the LSBs of its output are directly sent to the final adder
	-- and another sum, with the output of the mux of the following level, is performed
	-- by another CSA of the same size. Working each time on a portion of the partial sum
	-- which is two bits forward corresponds to intrinsically shift the output of the mux
	-- of that level (and thus, the operand A) of two bits left, as the Booth algorithm
	-- requires. The last CSA sends its whole output to the remaining bits of the final
	-- adder, to let the carry finally ripple. Note that, to perform a signed operation,
	-- the inputs of the CSAs are sign-extended at each step.
	
	-- ### COMPONENTS DECLARATION ###
	
	component CSA_generic is 
		generic (
			N : integer := 16
		);
		port (	
			A	: in	std_logic_vector(N-1 downto 0);
			B	: in	std_logic_vector(N-1 downto 0);
			C	: in	std_logic_vector(N-1 downto 0);
			S	: out	std_logic_vector(N-1 downto 0);
			Co	: out	std_logic_vector(N-1 downto 0)
		);
	end component ; 

	component boothEnc_block is
		port(
			bits: IN std_logic_vector(2 downto 0);
			sel : OUT std_logic_vector(2 downto 0)
		);
	end component;
	
	component boothMuxCalc is
		generic (
			N: integer := 16
		);
		port(
			A: IN std_logic_vector(N-1 downto 0);
			p_A, m_A, p_2A, m_2A: OUT std_logic_vector(N+1 downto 0)
		);
	end component;

	component mux5_generic is
		generic(
			N : natural := 16
		);
		port(
			A, B, C, D, E: IN std_logic_vector (N-1 downto 0);
			SEL: IN std_logic_vector(2 downto 0);
			Z : OUT std_logic_vector(N-1 downto 0)
		);
	end component;
	
	-- component P4ADD is
		-- generic (
			-- Nbit : integer := 32
		-- );
		-- port(
			-- A : IN  std_logic_vector(Nbit-1 downto 0);
			-- B : IN  std_logic_vector(Nbit-1 downto 0);
			-- Cin : IN  std_logic;
			-- Sum : OUT  std_logic_vector(Nbit-1 downto 0);
			-- Cout : OUT Std_logic
		-- );
	-- end component;
	
	-- ### SIGNALS DECLARATION ###
	
	-- Data inputs for multiplexers for Booth algorithm (Nbit+2 bits)
	signal p_A, m_A, p_2A, m_2A : std_logic_vector(Nbit+1 downto 0);
	
	type ternArray is array(natural range <>) of std_logic_vector(2 downto 0);
	signal boothSel		: ternArray(0 to Nbit/2-1); -- There are Nbit/2 booth encoder blocks
	
	type dataArray is array(natural range <>) of std_logic_vector(Nbit+1 downto 0);
	signal muxOut		: dataArray(0 to Nbit/2-1); -- There are Nbit/2 multiplexers
	-- There are Nbit/2-2 CSA; Nbit/2-3 of them have the same size
	signal CSAIn_B		: dataArray(3 to Nbit/2-1);	-- Input B of CSA_i
	signal CSAIn_C		: dataArray(3 to Nbit/2-1); -- Input C of CSA_i (input A is muxOut_i)
	signal CSAOut_sum	: dataArray(3 to Nbit/2-1); -- Sum Output of CSA_i
	signal CSAOut_car	: dataArray(3 to Nbit/2-1); -- Carry Output of CSA_i
	-- Signals for the first CSA, which has a different size
	signal CSAIn_A_2	: std_logic_vector(Nbit+3 downto 0);
	signal CSAIn_B_2	: std_logic_vector(Nbit+3 downto 0);
	signal CSAIn_C_2	: std_logic_vector(Nbit+3 downto 0);
	signal CSAOut_sum_2	: std_logic_vector(Nbit+3 downto 0);
	signal CSAOut_car_2	: std_logic_vector(Nbit+3 downto 0);
	
	-- Operands for the final addition, to propagate the carries
	signal ADDERIn_sum	: std_logic_vector(2*Nbit-1 downto 0);
	signal ADDERIn_car	: std_logic_vector(2*Nbit-1 downto 0);
	
	-- To create the first tern (B[1], B[0], B[-1]) without compilation errors
	signal firstTern: std_logic_vector(2 downto 0);

begin
	
	-- Generation of signals to use for muxes data inputs (0,+A,-A,+2A,-2A)
	-- NB: boothMuxCalc returns Nbit+2 wide data, see such entity for more info
	boothCalc: boothMuxCalc 
		generic map (Nbit)
		port map ( 
			A => A,
			p_A => p_A,
			m_A => m_A,
			p_2A => p_2A,
			m_2A => m_2A
		);
		
		
	-- ### BOOTH ENCODER GENERATION ###
	
	-- First tern (B[1], B[0], B[-1])
	firstTern <= B(1 downto 0) & '0';
	
	BoothEncoderGen: for i in 0 to Nbit/2-1 generate
	
		G0: if (i = 0) generate
			boothEnc: boothEnc_block
				port map (
					firstTern,
					boothSel(0)
				);
		end generate G0;
		
		Gi: if (i > 0) generate
			boothEnc: boothEnc_block
				port map (
					B(i*2+1 downto i*2-1),
					boothSel(i)
				);
		end generate Gi;
		
	end generate BoothEncoderGen;

	
	-- ### MULTIPLEXERS GENERATION ###
	
	MuxGen: for i in 0 to Nbit/2-1 generate
		boothMux: mux5_generic
				generic map (Nbit+2)
				port map (
					A => (others => '0'),
					B => p_A,
					C => m_A,
					D => p_2A,
					E => m_2A,
					SEL => boothSel(i),
					Z => muxOut(i)
				);
	end generate MuxGen;
	
	-- ### CARRY-SAVE ADDERS GENERATION ###
	
	CSAGen: for i in 2 to Nbit/2-1 generate
	
		G2: if (i = 2) generate
			CSAIn_A_2 <= muxOut(2) & "00";
			-- CSA(2) inputs sign extension
			CSAIn_B_2 <= muxOut(1)(Nbit+1) & muxOut(1)(Nbit+1) & muxOut(1);
			CSAIn_C_2 <= muxOut(0)(Nbit+1) & muxOut(0)(Nbit+1) & muxOut(0)(Nbit+1) & muxOut(0)(Nbit+1) & muxOut(0)(Nbit+1 downto 2);
			
			-- 2 LSBs of muxOut(0) are never touched: directly bring to final adder
			ADDERIn_sum(1 downto 0) <= muxOut(0)(1 downto 0);
			
			boothCSA: CSA_generic 
				generic map (Nbit+4)
				port map (
					A  => CSAIn_A_2,
					B  => CSAIn_B_2,
					C  => CSAIn_C_2,
					S  => CSAOut_sum_2,
					Co => CSAOut_car_2
				);
			
			-- CSA(3) inputs sign extension
			CSAIn_B(3) <= CSAOut_sum_2(Nbit+3) & CSAOut_sum_2(Nbit+3) & CSAOut_sum_2(Nbit+3 downto 4);
			CSAIn_C(3) <= CSAOut_car_2(Nbit+3) & CSAOut_car_2(Nbit+3 downto 4) & '0';
			
			-- Bring 4 LSBs of the two CSA(2) outputs to the final adder operands
			ADDERIn_sum(5 downto 2) <= CSAOut_sum_2(3 downto 0);
			ADDERIn_car(6 downto 0) <= CSAOut_car_2(3 downto 0) & "000";
			-- The bits related to the carry array are shifted by 3 -> 2 (because first 2 bits of muxOut(0) are already at final
			-- adder input and they don't generate any carry) + 1 (because carry vector of CSA output has to be shifted by 1)

		end generate G2;
			
		Gi: if (i > 2 AND i < Nbit/2-1) generate
			boothCSA: CSA_generic 
				generic map (Nbit+2)
				port map (
					A  => muxOut(i),
					B  => CSAIn_B(i),
					C  => CSAIn_C(i),
					S  => CSAOut_sum(i),
					Co => CSAOut_car(i)
				);
			
			-- CSA(i+1) inputs sign extension
			CSAIn_B(i+1) <= CSAOut_sum(i)(Nbit+1) & CSAOut_sum(i)(Nbit+1) & CSAOut_sum(i)(Nbit+1 downto 2);
			CSAIn_C(i+1) <= CSAOut_car(i)(Nbit+1) & CSAOut_car(i)(Nbit+1 downto 2) & '0';
			
			-- Bring 2 LSBs of the two CSA(i) outputs, which will be only summed to 0, to the final adder inputs
			ADDERIn_sum(i*2+1 downto i*2)   <= CSAOut_sum(i)(1 downto 0);
			ADDERIn_car(i*2+2 downto i*2+1) <= CSAOut_car(i)(1 downto 0);

		end generate Gi;
		
			
		GN: if (i = Nbit/2-1) generate
			boothCSA: CSA_generic 
				generic map (Nbit+2)
				port map (
					A  => muxOut(i),
					B  => CSAIn_B(i),
					C  => CSAIn_C(i),
					S  => CSAOut_sum(i),
					Co => CSAOut_car(i)
				);
			
			-- Bring the whole outputs of last CSA to remaining bits of final adder inputs
			ADDERIn_sum(2*Nbit-1 downto i*2)   <= CSAOut_sum(i);
			ADDERIn_car(2*Nbit-1 downto i*2+1) <= CSAOut_car(i)(Nbit downto 0);

		end generate GN;
		
	end generate CSAGen;
	
	-- For the final adder, the addition should happen on 2*Nbit+1 bits (1 more wrt the original inputs),
	-- due to the employed structure of the multiplier and the needed preservation of the sign of the
	-- operations. However, the MSB of the result will never be used since the input operand are Nbit-wide
	-- only, so it can be truncated directly from the adder inputs
	
	-- finalAdder: P4ADD
		-- generic map (2*Nbit)
		-- port map (
			-- A => ADDERIn_sum,
			-- B => ADDERIn_car,
			-- Cin => '0',
			-- Sum => Y,
			-- Cout => open
		-- );
	
	-- Since this implemenation of the Booth Multiplier is thought to be included in an ALU, the final
	-- arrays of Sum and Carry coming from the Carry saver adders are considered as output of the entity,
	-- in order to be sent to the adder of the ALU, with the aim to optimize the area from an architectural
	-- point of view.
	
	Sum_out <= ADDERIn_sum;
	Car_out <= ADDERIn_car;

end Structural;


configuration CFG_BOOTHMUL_STR of BOOTHMUL is
	for Structural
	
		for boothCalc: boothMuxCalc
			use configuration work.CFG_BOOTHMUXCALC_BEH;
		end for;
		
		for BoothEncoderGen
			for G0
				for all : boothEnc_block
					use configuration work.CFG_BOOTHENCODER_BEH;
				end for;
			end for;
			
			for Gi
				for all : boothEnc_block
					use configuration work.CFG_BOOTHENCODER_BEH;
				end for;
			end for;
		end for;
		
		for MuxGen
			for all : mux5_generic
				use configuration work.CFG_MUX5_GENERIC_BEH;
			end for;
		end for;
		
		for CSAGen
			for G2
				for all : CSA_generic
					use configuration work.CFG_CSA_STR;
				end for;
			end for;
			
			for Gi
				for all : CSA_generic
					use configuration work.CFG_CSA_STR;
				end for;
			end for;
			
			for GN
				for all : CSA_generic
					use configuration work.CFG_CSA_STR;
				end for;
			end for;
		end for;
		
		-- for finalAdder: P4ADD
			-- use configuration work.CFG_P4ADD_STRUCTURAL;
		-- end for;
		
	end for;
end configuration CFG_BOOTHMUL_STR;
