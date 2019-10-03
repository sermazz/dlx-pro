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
-- File: a.b-DataPath.core\d-ALU.vhd
-- Date: August 2019
-- Brief: Architecturally-optimized Arithmetic-Logic Unit for DLX datapath
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

-- ######## ARITHMETIC-LOGIC UNIT ########
-- This entity implements the ALU for the DLX datapath; such implementation has been
-- optimized at architectural level in terms of area (SHARING) and power consumption
-- (GUARDED EVALUATION): the outputs of all components are not simply muxed basing on the
-- opcode, but their inputs are buffered in latches; the input buffers of a module get
-- enabled only when an opcode belonging to such component is received by the ALU.
-- In this way, the component inputs switch (activating the whole component internal nets)
-- exclusively when actually needed and not at each operation, greatly reducing the
-- overall switching activity of the ALU. Moreover, sharing has been improved to optimize
-- the area: apart from additions and subtractions, the ADDER component is also needed
-- for COMPARISONS and MULTIPLICATIONS; a further internal muxing, basing on the ALU
-- opcode, has been built in order to share the same adder among adder/subtractor
-- itself, multiplier and comparator.

entity ALU is
	generic(
		DATA_SIZE		: integer := Nbit_DATA				-- Data size
	);                                  
	port(
		A		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
		B		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
		opcode	: in  aluOp;
		Z		: out std_logic_vector(DATA_SIZE - 1 downto 0)
	);
end ALU;

architecture Structural of ALU is

	-- Adder/subtractor
	component P4ADD is
		generic (
			Nbit : integer := 32
		);
		port(
			A 		: IN  std_logic_vector(Nbit-1 downto 0);
			B 		: IN  std_logic_vector(Nbit-1 downto 0);
			Cin 	: IN  std_logic;
			Sum 	: OUT  std_logic_vector(Nbit-1 downto 0);
			Cout 	: OUT Std_logic
		);
	end component;

	-- Multiplier
	component BOOTHMUL is
		generic (
			Nbit: natural := Nbit_DATA/2 -- Should be even and >= 16 (complete generalization still to do)
		);
		port (
			A 		: in  std_logic_vector(Nbit-1 downto 0);
			B 		: in  std_logic_vector(Nbit-1 downto 0);
			Sum_out : out std_logic_vector(2*Nbit-1 downto 0); -- Sum array output
			Car_out : out std_logic_vector(2*Nbit-1 downto 0)  -- Carry array output
		);
	end component;

	-- Comparator
	component comparator is
		generic(
			DATA_SIZE		: integer := Nbit_DATA			-- Data size
		);                                  
		port(
			Sum			: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			Cout		: in  std_logic;
			use_borrow	: in std_logic;		-- '1' when borrow is used for comparisons instead of carry
			EQ			: out std_logic;	-- for signed
			NE			: out std_logic;	-- for signed
			LT			: out std_logic;	-- for signed/unsigned
			GT			: out std_logic;	-- for signed/unsigned
			LE			: out std_logic;	-- for signed/unsigned
			GE			: out std_logic		-- for signed/unsigned
		);
	end component;
	
	-- Logic Unit
	component LU is
		generic (
			N	: integer := Nbit_DATA
		);
		port (
			A 	: in  std_logic_vector(N-1 downto 0);
			B 	: in  std_logic_vector(N-1 downto 0);
			SEL	: in std_logic_vector(3 downto 0);
			Y 	: out std_logic_vector(N-1 downto 0)
		);
	end component;

	-- Shifter
	component shifter is
		generic(
			N		: integer := Nbit_DATA		-- Data size
		);                                  
		port(
			A		: in  std_logic_vector(N - 1 downto 0);
			B		: in  std_logic_vector(log2(N) - 1 downto 0);
			SEL		: in  std_logic_vector(1 downto 0);
			Y		: out std_logic_vector(N - 1 downto 0)
		);
	end component;
	
	-- Define signals to be synthetized as latches for the components inputs
	signal A_add, B_add		: std_logic_vector(DATA_SIZE-1 downto 0);
	signal Cin_add 			: std_logic;
	
	signal A_mul, B_mul		: std_logic_vector(DATA_SIZE/2-1 downto 0);
	
	signal A_log, B_log		: std_logic_vector(DATA_SIZE-1 downto 0);
	signal sel_log			: std_logic_vector(3 downto 0);
	
	signal A_shf			: std_logic_vector(DATA_SIZE-1 downto 0);
	signal B_shf			: std_logic_vector(log2(DATA_SIZE)-1 downto 0);
	signal sel_shf			: std_logic_vector(1 downto 0);
	
	signal Sum_cmp			: std_logic_vector(DATA_SIZE-1 downto 0);
	signal Cout_cmp, useBorrow_cmp : std_logic;
	
	-- Define signal for outputs of components, to be able to mux them
	signal Sum_add			: std_logic_vector(DATA_SIZE-1 downto 0);
	signal Cout_add			: std_logic;
	
	signal Sum_mul, Car_mul	: std_logic_vector(DATA_SIZE-1 downto 0);
	
	signal EQ_cmp, NE_cmp, LT_cmp, GT_cmp, LE_cmp, GE_cmp : std_logic;
	
	signal Out_log			: std_logic_vector(DATA_SIZE-1 downto 0);
	
	signal Out_shf			: std_logic_vector(DATA_SIZE-1 downto 0);
	

begin

	ALU_adder : P4ADD
		generic map (DATA_SIZE)
		port map (
			A 	 => A_add,
		    B 	 => B_add,
		    Cin  => Cin_add,
		    Sum  => Sum_add,
		    Cout => Cout_add
		);
	
	ALU_mult : BOOTHMUL
		generic map (DATA_SIZE/2)
		port map (
			A 		=> A_mul,	
		    B 		=> B_mul,
		    Sum_out => Sum_mul,
		    Car_out => Car_mul
		);
	
	ALU_comp : comparator
		generic map (DATA_SIZE)
		port map (
			Sum		   => Sum_cmp,
			Cout	   => Cout_cmp,
			use_borrow => useBorrow_cmp,
			EQ		   => EQ_cmp, 
		    NE		   => NE_cmp,
		    LT		   => LT_cmp,
		    GT		   => GT_cmp,
		    LE		   => LE_cmp,
		    GE		   => GE_cmp
		);
	
	ALU_logicals : LU
		generic map (DATA_SIZE)
		port map (
			A 	=> A_log,
		    B 	=> B_log,
		    SEL	=> sel_log,
		    Y 	=> Out_log
		);
	
	ALU_shift : shifter
		generic map (DATA_SIZE)
		port map (
			A	=> A_shf,
		    B	=> B_shf,
		    SEL	=> sel_shf,
		    Y	=> Out_shf
		);
		
	-- purpose: Drive input latches of components
	-- type   : sequential
	-- input  : A, B, opcode, Sum_mul, Car_mul
	-- output : all components input signals but Sum_cmp, Cout_cmp
	ALUIn_proc : process (A, B, opcode, Sum_mul, Car_mul)
	begin
		-- In the following, input signals of components are assigned only when the
		-- opcode of the corresponding component is given, making its output observable at
		-- the output multiplexer; all the other signals which do not correspond to the
		-- activated component are voluntarily left unassigned, so that their previous
		-- value is kept (sequential behaviour synthesized with latches), achieving the
		-- desired GUARDED EVALUATION
		
		case opcode is			
			when LSL	=>	A_shf   <= A;
							B_shf   <= B(log2(DATA_SIZE)-1 downto 0);
							sel_shf	<= "00";
							
			when RSL	=>	A_shf   <= A;
			                B_shf   <= B(log2(DATA_SIZE)-1 downto 0);
			                sel_shf	<= "01";
			
			when RSA	=>	A_shf   <= A;
			                B_shf   <= B(log2(DATA_SIZE)-1 downto 0);
			                sel_shf	<= "10";
			
			when ADD	=>	A_add	<= A;
							B_add   <= B;
							Cin_add <= '0';
							
			when SUB	=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
			
			when ANDalu	=>	A_log   <= A;
							B_log   <= B;
							sel_log <= "1000";
			
			when ORalu	=>	A_log   <= A;
							B_log   <= B;
							sel_log <= "1110";
			
			when XORalu	=>	A_log   <= A;
							B_log   <= B;
							sel_log <= "0110";
			
			when EQ		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when NE		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when LT		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when GT		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when LE		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when GE		=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when LTU 	=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when GTU 	=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when LEU 	=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
									
			when GEU 	=>	A_add	<= A;
							B_add	<= not(B);
							Cin_add	<= '1';
			
			-- The same ADDER component used for additions/subtractions is needed for the
			-- final step of the CSA-base MULTIPLIER; since the inputs of the adder A_add,
			-- B_add, Cin_add are already driven by this ALUIn_proc process, in order to
			-- avoid multiple drivers, they are assigned in this process as well, to
			-- correctly obtain their muxing. For this reason the multiplier outputs
			-- Sum_mul, Car_mul needs to be inserted in the sensitivity list to correctly
			-- obtain the desired combinational behaviour
			
			when MULT	=>	A_mul	<= A(DATA_SIZE/2-1 downto 0);
							B_mul	<= B(DATA_SIZE/2-1 downto 0);
							A_add	<= Sum_mul;
							B_add	<= Car_mul;
							Cin_add <= '0';
							
			when others	=>	null;
							
		end case;
	end process;
	
	-- purpose: Drive input latches of the COMPARATOR
	-- type   : sequential
	-- input  : A, B, opcode, Sum_add, Cout_add
	-- output : Sum_cmp, Cout_cmp
	CMPIn_proc : process (A, B, Sum_add, Cout_add, opcode)
	begin
		-- This process assigns to the inputs latches of the comparator the output Sum
		-- and Carry as soon as they are ready, this creates the desired combinational
		-- behaviour for the comparator, as it composed an individual circuit together
		-- with the adder.
		
		case opcode is
			
			when EQ		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);

			when NE		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);
			
			when LT		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);
			
			when GT		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);
			
			when LE		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);
			
			when GE		=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= A(DATA_SIZE-1) xor B(DATA_SIZE-1);
			
			when LTU 	=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= '0';
			
			when GTU 	=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= '0';
										  
			when LEU 	=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= '0';
										  
			when GEU 	=>	Sum_cmp 	  <= Sum_add;
							Cout_cmp	  <= Cout_add;
							useBorrow_cmp <= '0';
							
			when others	=>	null;
							
		end case;
	end process;
	
	-- purpose: Drive the ALU output muxing all components outputs
	-- type   : combinational
	-- input  : A, B, opcode, Sum_add, Cout_add
	-- output : Sum_cmp, Cout_cmp
	ALUOut_proc : process (B, opcode, Out_shf, Sum_add, Out_log, EQ_cmp, NE_cmp, LT_cmp, GT_cmp, LE_cmp, GE_cmp)
		variable Z_cmp : std_logic_vector(DATA_SIZE-1 downto 0);
	begin
		Z_cmp := (others => '0');
		
		case opcode is
			when NOP 	=>	null;
			when LSL	=>	Z <= Out_shf;
			when RSL	=>	Z <= Out_shf;
			when RSA	=>	Z <= Out_shf;
			when ADD	=>	Z <= Sum_add;				
			when SUB	=>	Z <= Sum_add;
			when ANDalu	=>	Z <= Out_log;
			when ORalu	=>	Z <= Out_log;
			when XORalu	=>	Z <= Out_log;
			when EQ		=>	Z_cmp(0) := EQ_cmp;
							Z <= Z_cmp;
			when NE		=>	Z_cmp(0) := NE_cmp;
							Z <= Z_cmp;		
			when LT		=>	Z_cmp(0) := LT_cmp;
							Z <= Z_cmp;			
			when GT		=>	Z_cmp(0) := GT_cmp;
							Z <= Z_cmp;			
			when LE		=>	Z_cmp(0) := LE_cmp;
							Z <= Z_cmp;			
			when GE		=>	Z_cmp(0) := GE_cmp;
							Z <= Z_cmp;			
			when LTU 	=>	Z_cmp(0) := LT_cmp;
							Z <= Z_cmp;			
			when GTU 	=>	Z_cmp(0) := GT_cmp;
							Z <= Z_cmp;			
			when LEU 	=>	Z_cmp(0) := LE_cmp;
							Z <= Z_cmp;			
			when GEU 	=>	Z_cmp(0) := GE_cmp;
							Z <= Z_cmp;			
			when MULT	=>	Z <= Sum_add;		
			when THR_B	=>	Z <= B;
		end case;
	end process;
	
end Structural;

configuration CFG_DLX_ALU of ALU is
	for Structural
		
		for ALU_adder : P4ADD
			use configuration work.CFG_P4ADD_STRUCTURAL;
		end for;
		
		for ALU_mult : BOOTHMUL
			use configuration work.CFG_BOOTHMUL_STR;
		end for;
		
		for ALU_comp : comparator
			use configuration work.CFG_COMP_STR;
		end for;
		
		for ALU_logicals : LU
			use configuration work.CFG_LU_STR;
		end for;
		
		for ALU_shift : shifter
			use configuration work.CFG_SHIFTER_BEH;
		end for;
		
	end for;
end CFG_DLX_ALU;