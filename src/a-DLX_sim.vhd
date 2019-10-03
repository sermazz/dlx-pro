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
-- File: a-DLX_sim.vhd
-- Date: September 2019
-- Brief: Wrapper for DLX simulation, containing datapath, control unit and memories
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

	-- ** COMPONENTS DECLARATION **
	
	component DATAPATH is
		generic (
			ADDR_SIZE 		: integer := Nbit_DATA;			-- Width of Address Bus
			DATA_SIZE 		: integer := Nbit_DATA;     	-- Width of Data Bus
			IR_SIZE			: integer := Nbit_INSTR;    	-- Size of Instruction Register
			OPC_SIZE		: integer := Nbit_OPCODE;   	-- Size of Opcode field of IR
			REGADDR_SIZE	: integer := Nbit_GPRAddr;   	-- Size of Register fields of IR
			STACKBUS_WIDTH 	: integer := 4					-- Width of data bus between Stack and RegFile (in registers)
		);	
		port(	
			Rst						: in std_logic;		-- Active-low, asynchronous
			Clk         			: in std_logic;
			
			-- ** CU INTERFACE **
			stall_CU				: out std_logic;
			misprediction_CU		: out std_logic;
			-- Instruction Fetch
			MUXImmTA_SEL			: in std_logic;
			NPC_LATCH_IFID_EN   	: in std_logic;
			TA_LATCH_IFID_EN   		: in std_logic;
			PC_LATCH_IFID_EN   		: in std_logic;
			-- Instruction Decode
			MUXImm_SEL				: in std_logic_vector(1 downto 0);
			RF_RD1EN				: in std_logic;
			RF_RD2EN				: in std_logic;
			RegA_LATCH_IDEX_EN   	: in std_logic;
			RegB_LATCH_IDEX_EN   	: in std_logic;
			RegIMM_LATCH_IDEX_EN 	: in std_logic;
			LPC_LATCH_IDEX_EN       : in std_logic;
			RF_CALL					: in std_logic;
			RF_RET					: in std_logic;
			-- Execution
			MUXB_SEL				: in std_logic;
			ALUOUT_LATCH_EXMEM_EN	: in std_logic;
			RegB_LATCH_EXMEM_EN   	: in std_logic;
			LPC_LATCH_EXMEM_EN		: in std_logic;
			ALU_OPCODE      		: in aluOp;
			-- Memory
			MUXLPC_SEL				: in std_logic;
			MUXLMD_SEL				: in std_logic_vector(1 downto 0);
			LMD_LATCH_MEMWB_EN    	: in std_logic;
			ALUOUT_LATCH_MEMWB_EN	: in std_logic;
			LPC_LATCH_MEMWB_EN		: in std_logic;
			-- Write-Back
			RF_WE           		: in std_logic;
			MUXWrAddr_SEL			: in std_logic_vector(1 downto 0);
			MUXWB_SEL      			: in std_logic_vector(1 downto 0);
			
			-- ** IRAM INTERFACE **
			PC_out 					: out std_logic_vector(ADDR_SIZE - 1 downto 0);
			IR_in       			: in std_logic_vector(IR_SIZE - 1 downto 0);
			
			-- ** DRAM INTERFACE **
			DataAddr 				: out std_logic_vector(DATA_SIZE - 1 downto 0);		
			DataOut		            : out std_logic_vector(DATA_SIZE - 1 downto 0);		
			DataIn_w 	            : in std_logic_vector(DATA_SIZE - 1 downto 0);		
			DataIn_hw	            : in std_logic_vector(DATA_SIZE/2 - 1 downto 0);	
			DataIn_b	  	        : in std_logic_vector(7 downto 0);

			-- ** STACK INTERFACE **
			SPILL 					: out std_logic;
			FILL					: out std_logic;
			stackBus_In				: in std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0);
			stackBus_Out			: out std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0)		
		);
	end component;
	
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
			-- Number of bytes = RAM_SIZE * WORD_SIZE/8
			-- Number of bits for address (byte-addressable) = log2(RAM_SIZE * WORD_SIZE/8)
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
		
	component dlx_cu is
		generic(
			MEM_SIZE 		: integer := 62;			-- Microcode Memory size
			CW_SIZE         : integer := 30;			-- Control Word size
			IR_SIZE         : integer := Nbit_INSTR		-- Instruction Register size
			-- Opcode and func field sizes are not generic but taken directly from the package
			-- myTypes in order to make IR_opcode and IR_func signals locally static for case/when
		);                                  
		port(
			Clk             		: in std_logic; 					-- Clock
			Rst             		: in std_logic; 					-- Reset (active-low) 
			stall					: in std_logic;
			misprediction			: in std_logic;
			-- Instruction Register
			IR_IN           		: in std_logic_vector(IR_SIZE - 1 downto 0);
			
			-- **INSTRUCTION FETCH** control signals
			MUXImmTA_SEL			: out std_logic;					-- Imm to sum to PC for Target Address (branch/jump)
			-- IF/ID latches
			NPC_LATCH_IFID_EN   	: out std_logic;					-- Next Program Counter (PC+4) Register Latch Enable
			TA_LATCH_IFID_EN   		: out std_logic;					-- Target Address Register Latch Enable
			PC_LATCH_IFID_EN   		: out std_logic;					-- Program Counter (PC) Register Latch Enable
			
			-- **INSTRUCTION DECODE** control signals
			MUXImm_SEL				: out std_logic_vector(1 downto 0);	-- Mux for extended immediate selection
			RF_RD1EN				: out std_logic;					-- RegFile Read port 1 Enable
			RF_RD2EN				: out std_logic;					-- RegFile Read port 2 Enable
			-- ID/EX latches
			RegA_LATCH_IDEX_EN   	: out std_logic; 					-- Register A Latch Enable
			RegB_LATCH_IDEX_EN   	: out std_logic; 					-- Register B Latch Enable
			RegIMM_LATCH_IDEX_EN 	: out std_logic; 					-- Immediate Register Latch Enable
			LPC_LATCH_IDEX_EN 		: out std_logic;					-- Link Address Register Latch Enable
			-- RegisterFile Management Logic
			RF_CALL					: out std_logic;					-- Signals a Subroutine Call to the Register File
			RF_RET					: out std_logic;					-- Signals a Subroutine Return to the Register File
			
			-- **EXECUTION** control signals
			MUXB_SEL        		: out std_logic; 					-- ALU input B Mux Sel
			-- EX/MEM latches
			ALUOUT_LATCH_EXMEM_EN	: out std_logic; 					-- ALU Output Register Enable
			RegB_LATCH_EXMEM_EN   	: out std_logic;					-- Register B Latch Enable
			LPC_LATCH_EXMEM_EN 		: out std_logic;					-- Link Address Register Latch Enable
			-- ALU Opcode				
			ALU_OPCODE      		: out aluOp;    					-- Implicit coding (defined in myTypes)
			
			-- **MEMORY** control signals		
			DRAM_WE         		: out std_logic; 					-- Data RAM Write Enable
			DRAM_RE					: out std_logic;					-- Data RAM Read Enable
			DRAMOP_SEL				: out std_logic; 					-- Data RAM operation selection (on word or on byte)
			MUXLPC_SEL				: out std_logic; 					-- Mux for Link Address selection (PC+4 for JAL, PC+8 for JALR)
			MUXLMD_SEL				: out std_logic_vector(1 downto 0); -- Mux for selection of extension mode for Data RAM output
			-- MEM/WB latches
			LMD_LATCH_MEMWB_EN    	: out std_logic; 					-- Load Memory Data Register Latch Enable
			ALUOUT_LATCH_MEMWB_EN	: out std_logic;					-- ALU Output Register Enable
			LPC_LATCH_MEMWB_EN		: out std_logic;					-- Link Address Register Latch Enable
			
			-- **WRITE BACK** control signals				
			RF_WE           		: out std_logic;					-- Register File Write Enable
			MUXWrAddr_SEL			: out std_logic_vector(1 downto 0);	-- Mux for selection of RF Write Address
			MUXWB_SEL      			: out std_logic_vector(1 downto 0) 	-- Write Back MUX Sel
		);
	end component;
	
	component STACK is
		generic (
			MEM_SIZE  : integer := 32;			-- in multiple of BUS_WIDTH
			DATA_SIZE : integer := Nbit_DATA;	-- in bits (multiple of 8 bits)
			BUS_WIDTH : integer := 4			-- RegFile Bus width (in registers of DATA_SIZE bits each)
			-- With default generics, stack size is: 32 entries * 4 registers * 32 bits / 8 bits = 512 kB
			-- and it can hold up to: 32 entries * 4 registers / 2*8 registers/window = 8 windows
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
	
	-- ** CU INTERFACE **
	signal stall, misprediction: std_logic;
	signal MUXImmTA_SEL, NPC_LATCH_IFID_EN, TA_LATCH_IFID_EN, PC_LATCH_IFID_EN,
		   RF_RD1EN, RF_RD2EN, RegA_LATCH_IDEX_EN, RegB_LATCH_IDEX_EN, RegIMM_LATCH_IDEX_EN, LPC_LATCH_IDEX_EN, RF_CALL, RF_RET,
		   MUXB_SEL, ALUOUT_LATCH_EXMEM_EN, RegB_LATCH_EXMEM_EN, LPC_LATCH_EXMEM_EN,
		   DRAM_WE, DRAM_RE, DRAMOP_SEL, MUXLPC_SEL, LMD_LATCH_MEMWB_EN, ALUOUT_LATCH_MEMWB_EN, LPC_LATCH_MEMWB_EN,
		   RF_WE : std_logic;  
	signal MUXImm_SEL, MUXLMD_SEL, MUXWrAddr_SEL, MUXWB_SEL : std_logic_vector(1 downto 0);  
	signal ALU_OPCODE : aluOp;
	
	-- ** STACK INTERFACE **
	signal SPILL, FILL					: std_logic;
	signal rf2stack_bus, stack2rf_bus	: std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0);
	
begin

	DLX_Datapath : DATAPATH
		generic map (
			ADDR_SIZE 			 	=> ADDR_SIZE,		
			DATA_SIZE 			 	=> DATA_SIZE, 				
			IR_SIZE				 	=> IR_SIZE,					
			OPC_SIZE			 	=> OPC_SIZE,				
			REGADDR_SIZE		 	=> REGADDR_SIZE,
			STACKBUS_WIDTH			=> STACKBUS_WIDTH
		)
		port map(
			Rst						=> Rst,
			Clk         		    => Clk,
			stall_CU				=> stall,
			misprediction_CU	    => misprediction,
			MUXImmTA_SEL			=> MUXImmTA_SEL,
			NPC_LATCH_IFID_EN   	=> NPC_LATCH_IFID_EN,
			TA_LATCH_IFID_EN   		=> TA_LATCH_IFID_EN,   		
			PC_LATCH_IFID_EN   		=> PC_LATCH_IFID_EN,   		
			MUXImm_SEL				=> MUXImm_SEL,
			RF_RD1EN				=> RF_RD1EN,
			RF_RD2EN				=> RF_RD2EN,
			RegA_LATCH_IDEX_EN      => RegA_LATCH_IDEX_EN,      
			RegB_LATCH_IDEX_EN      => RegB_LATCH_IDEX_EN,      
			RegIMM_LATCH_IDEX_EN    => RegIMM_LATCH_IDEX_EN,    
			LPC_LATCH_IDEX_EN       => LPC_LATCH_IDEX_EN,      
			RF_CALL					=> RF_CALL,					
			RF_RET			        => RF_RET,			        
			MUXB_SEL				=> MUXB_SEL,				
			ALUOUT_LATCH_EXMEM_EN   => ALUOUT_LATCH_EXMEM_EN,   
			RegB_LATCH_EXMEM_EN     => RegB_LATCH_EXMEM_EN,     
			LPC_LATCH_EXMEM_EN		=> LPC_LATCH_EXMEM_EN,		
			ALU_OPCODE              => ALU_OPCODE,              
			MUXLPC_SEL				=> MUXLPC_SEL,				
			MUXLMD_SEL				=> MUXLMD_SEL,				
			LMD_LATCH_MEMWB_EN      => LMD_LATCH_MEMWB_EN,      
			ALUOUT_LATCH_MEMWB_EN   => ALUOUT_LATCH_MEMWB_EN,   
			LPC_LATCH_MEMWB_EN	    => LPC_LATCH_MEMWB_EN,	    
			RF_WE           		=> RF_WE,           		
			MUXWrAddr_SEL			=> MUXWrAddr_SEL,
			MUXWB_SEL      			=> MUXWB_SEL,      			
			PC_out 					=> PC_fetch,				
			IR_in       		    => IR_fetched,     		    
			DataAddr 				=> DataAddr, 				
			DataOut		            => DataOut,		            
			DataIn_w 	            => DataIn_w, 	            
			DataIn_hw	            => DataIn_hw,	            
			DataIn_b	  	        => DataIn_b,
			SPILL 					=> SPILL, 		
			FILL		            => FILL,		
			stackBus_In	            => stack2rf_bus,	
			stackBus_Out	        => rf2stack_bus  
		);
		
		DLX_ControlUnit : dlx_cu
		generic map (
			IR_SIZE         	  => IR_SIZE
		)                               
		port map (
			Clk             	  => Clk,            	
			Rst             	  => Rst,             	
			stall				  => stall,				
			misprediction		  => misprediction,		
			IR_IN                 => IR_fetched,        
			MUXImmTA_SEL	      => MUXImmTA_SEL,	
			NPC_LATCH_IFID_EN     => NPC_LATCH_IFID_EN,   
			TA_LATCH_IFID_EN   	  => TA_LATCH_IFID_EN,   	
			PC_LATCH_IFID_EN   	  => PC_LATCH_IFID_EN,   	
			MUXImm_SEL		      => MUXImm_SEL,
			RF_RD1EN			  => RF_RD1EN,
			RF_RD2EN			  => RF_RD2EN,		
			RegA_LATCH_IDEX_EN    => RegA_LATCH_IDEX_EN,   
			RegB_LATCH_IDEX_EN    => RegB_LATCH_IDEX_EN,   
			RegIMM_LATCH_IDEX_EN  => RegIMM_LATCH_IDEX_EN, 
			LPC_LATCH_IDEX_EN 	  => LPC_LATCH_IDEX_EN, 	
			RF_CALL				  => RF_CALL,				
			RF_RET				  => RF_RET,				
			MUXB_SEL              => MUXB_SEL,        
			ALUOUT_LATCH_EXMEM_EN => ALUOUT_LATCH_EXMEM_EN,
			RegB_LATCH_EXMEM_EN   => RegB_LATCH_EXMEM_EN,  
			LPC_LATCH_EXMEM_EN 	  => LPC_LATCH_EXMEM_EN, 	
			ALU_OPCODE            => ALU_OPCODE,     
			DRAM_WE         	  => DRAM_WE,      
			DRAM_RE         	  => DRAM_RE,            	
			DRAMOP_SEL			  => DRAMOP_SEL,			
			MUXLPC_SEL			  => MUXLPC_SEL,		
			MUXLMD_SEL            => MUXLMD_SEL,
			LMD_LATCH_MEMWB_EN    => LMD_LATCH_MEMWB_EN,   
			ALUOUT_LATCH_MEMWB_EN => ALUOUT_LATCH_MEMWB_EN,
			LPC_LATCH_MEMWB_EN    => LPC_LATCH_MEMWB_EN,
			RF_WE           	  => RF_WE,           	
			MUXWrAddr_SEL		  => MUXWrAddr_SEL,		
			MUXWB_SEL      		  => MUXWB_SEL      		
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
