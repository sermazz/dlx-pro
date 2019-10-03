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
-- File: a-DLX_postsyn_sim.vhd
-- Date: September 2019
-- Brief: Wrapper for post-synthesis DLX simulation including non-synthesized memories
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

entity DLX is
	generic (
		ADDR_SIZE 		: integer := Nbit_DATA;		-- Width of Address Bus
		DATA_SIZE 		: integer := Nbit_DATA;		-- Width of Data Bus
		IR_SIZE			: integer := Nbit_INSTR;	-- Size of Instruction Register
		OPC_SIZE		: integer := Nbit_OPCODE;	-- Size of Opcode field of IR
		REGADDR_SIZE	: integer := Nbit_GPRAddr;	-- Size of Register fields of IR
		IRAM_size 		: integer := 128; 			-- in words (of IR_SIZE bits = instructions)
		DRAM_size 		: integer := 128; 			-- in words (of DATA_SIZE bits)
		STACKBUS_WIDTH	: integer := 4;
		STACK_size		: integer := 32				-- in words (of DATA_SIZE*STACKBUS_WIDTH bits)
	);
	port (
		Clk 			: in std_logic;
		Rst 			: in std_logic				-- Asynchronous, active-low
	);
end DLX;

architecture dlx_rtl of DLX is

	-- Synthetized DLX (DATAPATH + CONTROL UNIT)
	component DLX_ADDR_SIZE32_DATA_SIZE32_IR_SIZE32_OPC_SIZE6_REGADDR_SIZE5_STACKBUS_WIDTH4 is
		port(
			Clk, Rst : in std_logic;
			PC_out : out std_logic_vector (31 downto 0);
			IR_in : in std_logic_vector (31 downto 0);
			DataAddr, DataOut : out std_logic_vector (31 downto 0);
			DataIn_w : in std_logic_vector (31 downto 0);
			DataIn_hw : in std_logic_vector (15 downto 0);
			DataIn_b : in std_logic_vector (7 downto 0);
			DRAM_WE, DRAM_RE, DRAMOP_SEL, SPILL, FILL : out std_logic;
			stackBus_In : in std_logic_vector (127 downto 0);
			stackBus_Out : out std_logic_vector (127 downto 0)
		);
	end  component;
	
	component IRAM is
		generic (
			RAM_SIZE	: integer := 48;								-- IRAM size (in words)
			I_SIZE		: integer := Nbit_DATA							-- IRAM word size (in bits)
		);
		port (
			Rst 		: in  std_logic;								-- Reset (active-low)
			Addr		: in  std_logic_vector(I_SIZE - 1 downto 0);
			Dout		: out std_logic_vector(I_SIZE - 1 downto 0)
		);
	end component;
	
	component DRAM is
		generic (
			RAM_SIZE  : integer := 64;			-- in words (of WORD_SIZE bits each; power of 2)
			WORD_SIZE : integer := Nbit_DATA	-- in bits (multiple of 8 bits)
		);
		port (
			Clk    	: in  std_logic; 									-- Clock
			Rst  	: in std_logic;										-- Reset (active-low)
			Rd_en 	: in std_logic;										-- Read enable
			Wr_en	: in std_logic;										-- Write enable
			Wr_byte	: in std_logic;										-- 1 = write byte; 0 = write word
			Addr 	: in std_logic_vector(log2(RAM_SIZE*WORD_SIZE/8) - 1 downto 0);		-- Read/write address
			Din		: in std_logic_vector(WORD_SIZE - 1 downto 0);		-- Data in for write operations
			Dout_w 	: out std_logic_vector(WORD_SIZE - 1 downto 0);		-- Data out for read operations on WORDS
			Dout_hw	: out std_logic_vector(WORD_SIZE/2 - 1 downto 0);	-- Data out for read operations on HALF WORDS
			Dout_b	: out std_logic_vector(7 downto 0)					-- Data out for read operations on BYTES
		);
	end component;
	
	component STACK is
		generic (
			MEM_SIZE  : integer := 32;			-- in multiple of BUS_WIDTH
			DATA_SIZE : integer := Nbit_DATA;	-- in bits (multiple of 8 bits)
			BUS_WIDTH : integer := 4			-- RegFile Bus width (in registers of DATA_SIZE bits each)
		);
		port (
			Clk 		: in std_logic;
			Rst			: in std_logic;
			-- Interface to RF
			SPILL 		: in std_logic;
			FILL		: in std_logic;
			RfBus_in	: in std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0);
			RfBus_out	: out std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0)
		);
	end component;
	
	-- ** IRAM INTERFACE **
	signal PC_fetch 				: std_logic_vector(ADDR_SIZE - 1 downto 0);
	signal IR_fetched     			: std_logic_vector(IR_SIZE - 1 downto 0);
	
	-- ** DRAM INTERFACE **   
	signal DataAddr 				: std_logic_vector(DATA_SIZE - 1 downto 0);		
	signal DataOut		            : std_logic_vector(DATA_SIZE - 1 downto 0);		
	signal DataIn_w 	            : std_logic_vector(DATA_SIZE - 1 downto 0);		
	signal DataIn_hw	            : std_logic_vector(DATA_SIZE/2 - 1 downto 0);	
	signal DataIn_b	  	        	: std_logic_vector(7 downto 0);
	signal DRAM_WE, DRAM_RE, DRAMOP_SEL : std_logic;  
		
	-- ** STACK INTERFACE **
	signal SPILL, FILL					: std_logic;
	signal rf2stack_bus, stack2rf_bus	: std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0);
	
begin

	DLX : DLX_ADDR_SIZE32_DATA_SIZE32_IR_SIZE32_OPC_SIZE6_REGADDR_SIZE5_STACKBUS_WIDTH4
		port map (
			Clk          => Clk,
			Rst          => Rst,
			PC_out       => PC_fetch,
			IR_in        => IR_fetched,
			DataAddr     => DataAddr,
			DataOut      => DataOut,
			DataIn_w     => DataIn_w,
			DataIn_hw    => DataIn_hw,
			DataIn_b     => DataIn_b, 
			DRAM_WE      => DRAM_WE,
			DRAM_RE      => DRAM_RE,
			DRAMOP_SEL   => DRAMOP_SEL,
			SPILL        => SPILL,
			FILL         => FILL,
			stackBus_In  => stack2rf_bus,
			stackBus_Out => rf2stack_bus
		);
		
		DLX_IRAM : IRAM
			generic map (
				RAM_SIZE  => IRAM_size,
				I_SIZE	  => IR_SIZE
			)
			port map (
				Rst 	  => Rst,
				Addr	  => PC_fetch,
				Dout	  => IR_fetched
			);
		
		DLX_DRAM : DRAM
			generic map (
				RAM_SIZE  => DRAM_size,
				WORD_SIZE => DATA_SIZE
			)
			port map (
				Clk    	  => Clk,
				Rst       => Rst,
				Rd_en	  => DRAM_RE,
				Wr_en     => DRAM_WE,
				Wr_byte   => DRAMOP_SEL,
				Addr      => DataAddr(log2(DRAM_size*DATA_SIZE/8)-1 downto 0),
				Din	      => DataOut,
				Dout_w    => DataIn_w,
				Dout_hw   => DataIn_hw,
				Dout_b    => DataIn_b
			);
			
		DLX_Stack : STACK
			generic map (
			MEM_SIZE  => STACK_size,	
			DATA_SIZE => Nbit_DATA,
			BUS_WIDTH => STACKBUS_WIDTH
		)
			port map(
			Clk 	  => Clk,
			Rst		  => Rst,
			SPILL 	  => SPILL,
			FILL	  => FILL,
			RfBus_in  => rf2stack_bus,
			RfBus_out => stack2rf_bus
		);
		
end dlx_rtl;
