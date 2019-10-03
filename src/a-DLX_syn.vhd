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
-- File: a-DLX_syn.vhd
-- Date: September 2019
-- Brief: Wrapper for DLX synthesis, containing datapath and control unit
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

entity DLX is
	generic (
		ADDR_SIZE 		: integer := Nbit_DATA;		-- Width of Address Bus
		DATA_SIZE 		: integer := Nbit_DATA;     -- Width of Data Bus
		IR_SIZE			: integer := Nbit_INSTR;    -- Size of Instruction Register
		OPC_SIZE		: integer := Nbit_OPCODE;   -- Size of Opcode field of IR
		REGADDR_SIZE	: integer := Nbit_GPRAddr;   -- Size of Register fields of IR
		STACKBUS_WIDTH	: integer := 4
	);
	port (
		Clk 			: in std_logic;
		Rst 			: in std_logic;				-- Asynchronous, active-low
			
		-- ** IRAM INTERFACE **
		PC_out 					: out std_logic_vector(ADDR_SIZE - 1 downto 0);
		IR_in       			: in std_logic_vector(IR_SIZE - 1 downto 0);
		
		-- ** DRAM INTERFACE **
		DataAddr 				: out std_logic_vector(DATA_SIZE - 1 downto 0);		
		DataOut		            : out std_logic_vector(DATA_SIZE - 1 downto 0);		
		DataIn_w 	            : in std_logic_vector(DATA_SIZE - 1 downto 0);		
		DataIn_hw	            : in std_logic_vector(DATA_SIZE/2 - 1 downto 0);	
		DataIn_b	  	        : in std_logic_vector(7 downto 0);	
		DRAM_WE         		: out std_logic; 
		DRAM_RE					: out std_logic;
		DRAMOP_SEL				: out std_logic;

		-- ** STACK INTERFACE **
		SPILL 					: out std_logic;
		FILL					: out std_logic;
		stackBus_In				: in std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0);
		stackBus_Out			: out std_logic_vector(DATA_SIZE*STACKBUS_WIDTH - 1 downto 0)
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
	
	signal stall, misprediction: std_logic;
	
	signal MUXImmTA_SEL, NPC_LATCH_IFID_EN, TA_LATCH_IFID_EN, PC_LATCH_IFID_EN,
		   RF_RD1EN, RF_RD2EN, RegA_LATCH_IDEX_EN, RegB_LATCH_IDEX_EN, RegIMM_LATCH_IDEX_EN, LPC_LATCH_IDEX_EN, RF_CALL, RF_RET,
		   MUXB_SEL, ALUOUT_LATCH_EXMEM_EN, RegB_LATCH_EXMEM_EN, LPC_LATCH_EXMEM_EN,
		   MUXLPC_SEL, LMD_LATCH_MEMWB_EN, ALUOUT_LATCH_MEMWB_EN, LPC_LATCH_MEMWB_EN,
		   RF_WE : std_logic;
		   
	signal MUXImm_SEL, MUXLMD_SEL, MUXWrAddr_SEL, MUXWB_SEL : std_logic_vector(1 downto 0);
		   
	signal ALU_OPCODE : aluOp;
	
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
			Rst						=> Rst,			-- DLX entity input
			Clk         		    => Clk,			-- DLX entity input
			stall_CU				=> stall,
			misprediction_CU		=> misprediction,
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
			PC_out 					=> PC_out,		-- DLX entity output   		
			IR_in       		    => IR_in,     	-- DLX entity input   	    
			DataAddr 				=> DataAddr, 	-- DLX entity output   			
			DataOut		            => DataOut,		-- DLX entity output             
			DataIn_w 	            => DataIn_w, 	-- DLX entity input               
			DataIn_hw	            => DataIn_hw,	-- DLX entity input               
			DataIn_b	  	        => DataIn_b,  	-- DLX entity input
			SPILL 					=> SPILL, 		-- DLX entity output
			FILL		            => FILL,		-- DLX entity output
			stackBus_In	            => stackBus_In,	-- DLX entity input
			stackBus_Out	        => stackBus_Out -- DLX entity output       
		);
		
		DLX_ControlUnit : dlx_cu
		generic map (
			IR_SIZE         	  => IR_SIZE
		)                               
		port map (
			Clk             	  => Clk,           -- DLX entity input
			Rst             	  => Rst,           -- DLX entity input
			stall				  => stall,				
			misprediction		  => misprediction,		
			IR_IN                 => IR_in,    		-- DLX entity input
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
			DRAM_WE         	  => DRAM_WE, 		-- DLX entity output     
			DRAM_RE         	  => DRAM_RE,  		-- DLX entity output            
			DRAMOP_SEL			  => DRAMOP_SEL,	-- DLX entity output   			
			MUXLPC_SEL			  => MUXLPC_SEL,		
			MUXLMD_SEL            => MUXLMD_SEL,
			LMD_LATCH_MEMWB_EN    => LMD_LATCH_MEMWB_EN,   
			ALUOUT_LATCH_MEMWB_EN => ALUOUT_LATCH_MEMWB_EN,
			LPC_LATCH_MEMWB_EN    => LPC_LATCH_MEMWB_EN,
			RF_WE           	  => RF_WE,           	
			MUXWrAddr_SEL		  => MUXWrAddr_SEL,		
			MUXWB_SEL      		  => MUXWB_SEL      		
		);

end dlx_rtl;
