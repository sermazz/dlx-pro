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
-- File: a.b-DataPath.vhd
-- Date: September 2019
-- Brief: Wrapper for the DLX datapath
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

entity DATAPATH is
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
end DATAPATH;

architecture RTL of DATAPATH is
	
	-- ####### COMPONENTS #######
	
	component P4ADD is
		generic (
			Nbit 	: integer := 32
		);
		port(
			A 		: in  std_logic_vector(Nbit-1 downto 0);
			B 		: in  std_logic_vector(Nbit-1 downto 0);
			Cin 	: in  std_logic;
			Sum 	: out std_logic_vector(Nbit-1 downto 0);
			Cout	: out Std_logic
		);
	end component;
	
	component bj_logic is
		generic(
			MEM_SIZE		: integer := 64;								-- Size (in words of 2 bits) for prediction memory
			OPC_SIZE        : integer := Nbit_OPCODE;						-- Opcode size
			ADDR_SIZE		: integer := Nbit_DATA;							-- Addresses size
			DATA_SIZE		: integer := Nbit_DATA							-- Data size
		);                                  
		port(
			Clk				: in std_logic;									-- Clock for prediction memory
			Rst				: in std_logic;									-- Reset (active-low, asynchronous) for prediction memory
			STALL			: in std_logic;
			opcode_IRAM		: in  std_logic_vector(OPC_SIZE - 1 downto 0);	-- Opcode from IRAM Dout
			opcode_IFID		: in  std_logic_vector(OPC_SIZE - 1 downto 0);	-- Opcode from instruction in IF/ID storage
			-- Addresses
			bAddr_PC		: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Address of the instruction coming from PC register
			bAddr_IFID		: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Address of instruction stored in IF/ID storage block
			NPC				: in std_logic_vector(ADDR_SIZE - 1 downto 0);	-- Next Program Counter from IF stage (PC+4)
			TA				: in std_logic_vector(ADDR_SIZE - 1 downto 0); 	-- Target Address computed in IF stage
			-- Register A for zero comparison
			REG_A			: in std_logic_vector(DATA_SIZE - 1 downto 0);
			-- Signals for Branch & Jump management
			take_bj			: out std_logic;	-- Prediction outcome: 0 for normal PC increment, 1 to branch/jump
			flush_IFID		: out std_logic;	-- Can be raised during ID; signals to abort previously fetched instr
			muxPC_SEL		: out std_logic;
			correct_PC		: out std_logic_vector(ADDR_SIZE - 1 downto 0)
		);
	end component;
	
    component hdu_dlx is
		generic(
			IR_SIZE         : integer := Nbit_INSTR		-- Instruction Register size
		);                                  
		port(
			-- Instruction Registers of different stages
			IR_IFID           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
			IR_IDEX           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
			IR_EXMEM           		: in  std_logic_vector(IR_SIZE - 1 downto 0);
			IR_MEMWB          		: in  std_logic_vector(IR_SIZE - 1 downto 0);
			-- Current window pointer (register file with 8 windows)
			CWP_IDEX				: in std_logic_vector(2 downto 0);
			CWP_EXMEM               : in std_logic_vector(2 downto 0);
			CWP_MEMWB               : in std_logic_vector(2 downto 0);
			-- Control signals for Hazard management
			BJ_regA_MUX				: out std_logic;
			ALU_inputA_MUX  		: out std_logic_vector(1 downto 0);
			ALU_inputB_MUX  		: out std_logic_vector(1 downto 0);
			B_latchEM_MUX   		: out std_logic_vector(1 downto 0);
			WrIN_DRAM_MUX   		: out std_logic_vector(1 downto 0);
			STALL					: out std_logic
		);
	end  component;
	
	component RegFile_Win is
		generic (
			DATA_SIZE	: integer := Nbit_DATA;	-- Width of registers
			M   		: integer := RF_GLOB_num;			-- Number of GLOBALS registers
			N   		: integer := RF_ILO_num;			-- Number of registers of IN, OUT, OUT
			F			: integer := RF_WIND_num;			-- Number of windows
			BUS_WIDTH	: integer := 4			-- Memory Bus width (in registers of DATA_SIZE bits each)
			-- Number of registers in each window is M + 3*N (GLOBALS + IN+LOCALS+OUT)
		);
		port (
			Clk 			: in std_logic;
			Rst				: in std_logic;
			-- Write port
			wr_en 			: in std_logic;
			Wr_Addr			: in std_logic_vector(log2(M + 3*N) - 1 downto 0);
			DataIn 			: in std_logic_vector(DATA_SIZE - 1 downto 0);
			-- Read ports
			rd1_en 			: in std_logic;
			rd2_en 			: in std_logic;
			Rd1_Addr		: in std_logic_vector(log2(M + 3*N) - 1 downto 0);
			Rd2_Addr		: in std_logic_vector(log2(M + 3*N) - 1 downto 0);
			Out1 			: out std_logic_vector(DATA_SIZE - 1 downto 0);
			Out2 			: out std_logic_vector(DATA_SIZE - 1 downto 0);
			-- Register Management Logic
			CALL 			: in std_logic;
			RET 			: in std_logic;
			-- Interface to Stack
			SPILL 			: out std_logic;
			FILL			: out std_logic;
			memBus_In		: in std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0);
			memBus_out		: out std_logic_vector(DATA_SIZE*BUS_WIDTH - 1 downto 0);
			-- CWP to output
			CWP_out			: out std_logic_vector(log2(F) - 1 downto 0)
		);
	end component;
	
	component ALU is
		generic(
			DATA_SIZE		: integer := Nbit_DATA				-- Data size
		);                                  
		port(
			A		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			B		: in  std_logic_vector(DATA_SIZE - 1 downto 0);
			opcode	: in  aluOp;
			Z		: out std_logic_vector(DATA_SIZE - 1 downto 0)
		);
	end component;
	
	-- ####### REGISTERS #######
	signal PC								: std_logic_vector(ADDR_SIZE - 1 downto 0);	-- next_PC is MUX_PC
	-- IF/ID		
	signal NPC_IFID,     next_NPC_IFID 		: std_logic_vector(ADDR_SIZE - 1 downto 0);
	signal TA_IFID,      next_TA_IFID		: std_logic_vector(ADDR_SIZE - 1 downto 0);
	signal PC_IFID							: std_logic_vector(ADDR_SIZE - 1 downto 0);	-- next_PC_IFID is PC
	signal IR_IFID							: std_logic_vector(IR_SIZE - 1 downto 0);	-- next_IR_IFID is IR_in
	-- ID/EX		
	signal LPC_IDEX     					: std_logic_vector(ADDR_SIZE - 1 downto 0);	-- next_LPC_IDEX is NPC_IFID
	signal A_IDEX,       next_A_IDEX	    : std_logic_vector(DATA_SIZE - 1 downto 0);
	signal B_IDEX,       next_B_IDEX	    : std_logic_vector(DATA_SIZE - 1 downto 0);
	signal Imm_IDEX							: std_logic_vector(DATA_SIZE - 1 downto 0);	-- next_Imm_IDEX is MUXImm
	signal IR_IDEX      					: std_logic_vector(IR_SIZE - 1 downto 0);	-- next_IR_IDEX is IR_IFID
	signal CWP_IDEX							: std_logic_vector(2 downto 0);				-- managed directly by Register File; size = log2(F)-1 downto 0
	-- EX/MEM
	signal LPC_EXMEM						: std_logic_vector(ADDR_SIZE - 1 downto 0);	-- next_LPC_EXMEM is LPC_IDEX
	signal ALUOut_EXMEM, next_ALUOut_EXMEM	: std_logic_vector(DATA_SIZE - 1 downto 0);
	signal B_EXMEM							: std_logic_vector(DATA_SIZE - 1 downto 0); -- next_B_EXMEM is MUX_HDU_Blatch
	signal IR_EXMEM     					: std_logic_vector(IR_SIZE - 1 downto 0);	-- next_IR_EXMEM is IR_IDEX
	signal CWP_EXMEM						: std_logic_vector(2 downto 0);				-- next CWP_EXMEM is CWP_IDEX
	-- MEM/WB
	signal LMD_MEMWB			    		: std_logic_vector(DATA_SIZE - 1 downto 0);	-- next_LMD_MEMWB is MUX_LMD
	signal ALUOut_MEMWB						: std_logic_vector(DATA_SIZE - 1 downto 0);	-- next_ALUOut_MEMWB is ALUOut_EXMEM
	signal LPC_MEMWB    					: std_logic_vector(ADDR_SIZE - 1 downto 0);	-- next_LPC_MEMWB is MUX_LPC
	signal IR_MEMWB	    					: std_logic_vector(IR_SIZE - 1 downto 0);	-- next_IR_MEMWB is IR_EXMEM
	signal CWP_MEMWB						: std_logic_vector(2 downto 0);				-- next CWP_MEMWB is CWP_EXMEM

	-- ####### INTERNAL CONTROL SIGNALS #######
	-- Branch&Jump Logic
	signal BJ_take, BJ_MUXPC_SEL			: std_logic;
	signal BJ_flushIFID						: std_logic;
	signal BJ_correctPC						: std_logic_vector(ADDR_SIZE - 1 downto 0);
	-- Hazard Detection Unit
	signal HDU_stall						: std_logic;
	signal HDU_BJRegA_SEL					: std_logic;
	signal HDU_ALUInA_SEL, HDU_ALUInB_SEL	: std_logic_vector(1 downto 0);
	signal HDU_Blatch_SEL					: std_logic_vector(1 downto 0);
	signal HDU_DRAMIn_SEL					: std_logic_vector(1 downto 0);
	
	signal STALL							: std_logic;
	
	-- ####### STAGES SIGNALS #######
	-- Instruction Fetch
	signal MUX_ImmTA, MUX_BJNPC, MUX_PC		: std_logic_vector(ADDR_SIZE - 1 downto 0);
	signal ImmTA_16ext						: std_logic_vector(31 downto 16);
	signal ImmTA_26ext						: std_logic_vector(31 downto 26);
	-- Instruction Decode
	signal RF_spill, RF_fill				: std_logic;
	signal MUX_Imm							: std_logic_vector(DATA_SIZE - 1 downto 0);
	signal Imm_16signExt, Imm_16zeroPad		: std_logic_vector(15 downto 0);
	signal MUX_HDU_BJRegA					: std_logic_vector(DATA_SIZE - 1 downto 0);
	-- Execution
	signal MUX_ALUB							: std_logic_vector(DATA_SIZE - 1 downto 0);
	signal MUX_HDU_ALUInA, MUX_HDU_ALUInB	: std_logic_vector(DATA_SIZE - 1 downto 0);
	signal MUX_HDU_Blatch					: std_logic_vector(DATA_SIZE - 1 downto 0);
	-- Memory
	signal MUX_LMD							: std_logic_vector(DATA_SIZE - 1 downto 0);
	signal DataIn_8signExt, DataIn_8zeroPad : std_logic_vector(31 downto 8);
	signal DataIn_16zeroPad					: std_logic_vector(31 downto 16);
	signal LPC_plus4, MUX_LPC				: std_logic_vector(ADDR_SIZE - 1 downto 0);
	-- Write-back
	signal MUX_WBAddr						: std_logic_vector(REGADDR_SIZE - 1 downto 0);
	signal MUX_WBData						: std_logic_vector(DATA_SIZE - 1 downto 0);
	
begin
	
	-- Branch&Jump logic
	BrancJump_logic : bj_logic
		generic map (
			MEM_SIZE  	=> 32,			-- Number of predictions that can be held
			OPC_SIZE  	=> OPC_SIZE,
			ADDR_SIZE 	=> ADDR_SIZE,
			DATA_SIZE 	=> DATA_SIZE
		)   
		port map (
			Clk			=> Clk,
			Rst			=> Rst,
			STALL		=> STALL,
			opcode_IRAM	=> IR_in(31 downto 26),
			opcode_IFID => IR_IFID(31 downto 26),
			bAddr_PC	=> PC,
			bAddr_IFID	=> PC_IFID,
			NPC			=> NPC_IFID,
			TA			=> TA_IFID,
			REG_A	    => MUX_HDU_BJRegA,
			take_bj		=> BJ_take,
			flush_IFID	=> BJ_flushIFID,
			muxPC_SEL	=> BJ_MUXPC_SEL,
			correct_PC	=> BJ_correctPC
		);
	
	-- Hazard Detection Unit
	HazardDetUnit : hdu_dlx
		generic map (
			IR_SIZE 		=> IR_SIZE
		)                                  
		port map (               
			IR_IFID         => IR_IFID,
			IR_IDEX         => IR_IDEX,
			IR_EXMEM        => IR_EXMEM,
			IR_MEMWB        => IR_MEMWB,
			CWP_IDEX		=> CWP_IDEX,
			CWP_EXMEM       => CWP_EXMEM,
			CWP_MEMWB       => CWP_MEMWB,
			BJ_regA_MUX		=> HDU_BJRegA_SEL,
			ALU_inputA_MUX  => HDU_ALUInA_SEL,
			ALU_inputB_MUX  => HDU_ALUInB_SEL,
			B_latchEM_MUX   => HDU_Blatch_SEL,
			WrIN_DRAM_MUX   => HDU_DRAMIn_SEL,
			STALL			=> HDU_stall
		);
		
	-- Computation of actual STALL necessity
	-- Actual STALL is not only given by data/control hazards, but also by memory hazards:
	-- if a window of the register file needs fill/spill, the ID stage hs to stall and no
	-- new instructions can be fetched or decoded in the meantime
	STALL <= HDU_stall or RF_spill or RF_fill;
	
	-- Share misprediction and stall signals with Control Unit
	misprediction_CU <= BJ_flushIFID;
	stall_CU		 <= STALL;

	-- ####### INSTRUCTION FETCH Stage #######
	
	-- Interface to Instruction Memory
	PC_out <= PC;
	
	-- B&J Target Address Immediate addendum multiplexer
	ImmTA_16ext <= (others => IR_in(15));
	ImmTA_26ext <= (others => IR_in(25));
	
	with MUXImmTA_SEL select
		MUX_ImmTA <= ImmTA_16ext & IR_in(15 downto 0) when '0',		-- when BEQZ, BNEZ: extend sign of Imm16
					 ImmTA_26ext & IR_in(25 downto 0) when others;	-- when J, JAL: extend sign of Imm26
	
	-- B&J Target Addres adder
	TA_adder : P4ADD
		generic map (ADDR_SIZE)
		port map (
			A 	 => MUX_ImmTA,		-- Imm16 (when branch) or Imm26 (when jump)
		    B 	 => PC,
		    Cin  => '0',
		    Sum  => next_TA_IFID,	-- new value of PC+Imm16 (when branch) or PC+Imm26 (when jump)
		    Cout => open
		);
	
	-- Next Program Counter adder
	NPC_adder : P4ADD
		generic map (ADDR_SIZE)
		port map (
			A 	 => X"00000004",
		    B 	 => PC,
		    Cin  => '0',
		    Sum  => next_NPC_IFID,	-- new value of PC+4
		    Cout => open
		);
		
	-- Mux for Branch&Jump anticipation
	with BJ_take select
		MUX_BJNPC <= next_NPC_IFID when '0',	-- when normal instruction or BEQZ, BNEZ predicted not taken
					 next_TA_IFID when others;	-- when BEQZ, BNEZ predicted taken or J, JAL
				   
	-- Mux for Branch misprediction correction			   
	with BJ_MUXPC_SEL select
		MUX_PC <= MUX_BJNPC when '0',			-- when no branch misprediction occurred
				  BJ_correctPC when others;	    -- when branch misprediction occurred, signalled by B&J Logic
				  
	-- Registers
	PC_register_p : process (Rst, Clk)
	begin
		if (Rst = '0') then
			-- Asynchronous, active-low reset
			PC	 <= (others => '0');
		elsif (Clk = '1' and Clk'EVENT) then
			-- If stall is not needed
			if (STALL = '0') then
				PC <= MUX_PC;
			end if;
		end if;
	end process PC_register_p;
	
	IFID_registers_p : process (Rst, Clk)
	begin
		if (Rst = '0') then
			-- Asynchronous, active-low reset
			NPC_IFID <= (others => '0');
		    TA_IFID	 <= (others => '0');
		    PC_IFID	 <= (others => '0');
		    IR_IFID	 <= ITYPE_NOP & "00" & X"000000";
		elsif (Clk = '1' and Clk'EVENT) then
			if (STALL = '0') then 	-- (priority given to STALL rather than to MISPREDICTION)
				-- If stall is not needed
				if (BJ_flushIFID = '1') then
					-- Synchronous flush for branch misprediction
					NPC_IFID <= (others => '0');
					TA_IFID	 <= (others => '0');
					PC_IFID	 <= (others => '0');
					IR_IFID	 <= ITYPE_NOP & "00" & X"000000";	-- fetch NOP
				else
					IR_IFID <= IR_in;
					
					if (NPC_LATCH_IFID_EN = '1') then
						NPC_IFID <= next_NPC_IFID;
					end if;
					
					if (TA_LATCH_IFID_EN = '1') then
						TA_IFID <= next_TA_IFID;
					end if;
					
					if (PC_LATCH_IFID_EN = '1') then
						PC_IFID <= PC;
					end if;
				end if;
			end if;
		end if;
	end process IFID_registers_p;
	
	
	
	-- ####### INSTRUCTION DECODE Stage #######
	
	-- General-purpose integer Register File
	RegisterFile : RegFile_Win			
			generic map (
				DATA_SIZE  => DATA_SIZE,
				M 		   => RF_GLOB_num,
				N 		   => RF_ILO_num,
				F		   => RF_WIND_num,
				BUS_WIDTH  => STACKBUS_WIDTH
			)          
			port map (
				Clk 	   => Clk,
				Rst	       => Rst,
				wr_en 	   => RF_WE,
				Wr_Addr	   => MUX_WBAddr,
				DataIn     => MUX_WBData,
				rd1_en 	   => RF_RD1EN,
				rd2_en 	   => RF_RD2EN,
				Rd1_Addr   => IR_IFID(25 downto 21),
				Rd2_Addr   => IR_IFID(20 downto 16),
				Out1 	   => next_A_IDEX,
				Out2 	   => next_B_IDEX,
				CALL 	   => RF_CALL,
				RET 	   => RF_RET,
				SPILL 	   => RF_spill,	
				FILL	   => RF_fill,
				memBus_In  => stackBus_In,
				memBus_out => stackBus_Out,
				CWP_out	   => CWP_IDEX
		);
		
	-- Share SPILL and FILL signals with the Stack
	SPILL <= RF_spill;	
	FILL  <= RF_fill;
	
	-- 16-bit Immediate field extension and selection
	Imm_16zeroPad <= (others => '0');          
	Imm_16signExt <= (others => IR_IFID(15));
	
	with MUXImm_SEL select
		MUX_Imm <= Imm_16zeroPad & IR_IFID(15 downto 0) when "00",		-- when I-Type unsigned instruction
		           Imm_16signExt & IR_IFID(15 downto 0) when "01",		-- when I-Type signed instruction
		           IR_IFID(15 downto 0) & Imm_16zeroPad when others;	-- when LHI
	
	-- Bypassing multiplexer for Register A RAW hazards
	with HDU_BJRegA_SEL select
		MUX_HDU_BJRegA <= next_A_IDEX when '0',      -- RegFile/RdOut1
						  ALUOut_EXMEM when others;  -- EX/MEM.ALUOut
						  
	-- Registers
	IDEX_registers_p : process (Rst, Clk)
	begin
		if (Rst = '0') then
			-- Asynchronous, active-low reset
			LPC_IDEX <= (others => '0');
		    A_IDEX   <= (others => '0');
		    B_IDEX   <= (others => '0');
		    Imm_IDEX <= (others => '0');
			IR_IDEX  <= ITYPE_NOP & "00" & X"000000";
		elsif (Clk = '1' and Clk'EVENT) then
			if (STALL = '1') then
				-- Synchronous flush to issue a stall
				LPC_IDEX <= (others => '0');
				A_IDEX   <= (others => '0');
				B_IDEX   <= (others => '0');
				Imm_IDEX <= (others => '0');
				IR_IDEX  <= ITYPE_NOP & "00" & X"000000";	-- issue NOP
			else
				-- If stall is not needed
				IR_IDEX <= IR_IFID;
				
				if (LPC_LATCH_IDEX_EN = '1') then
					LPC_IDEX <= NPC_IFID;
				end if;
				
				if (RegA_LATCH_IDEX_EN = '1') then
					A_IDEX <= next_A_IDEX;
				end if;
				
				if (RegB_LATCH_IDEX_EN = '1') then
					B_IDEX <= next_B_IDEX;
				end if;
				
				if (RegIMM_LATCH_IDEX_EN = '1') then
					Imm_IDEX <= MUX_Imm;
				end if;
			end if;
		end if;
	end process IDEX_registers_p;
	
	
	
	-- ####### EXECUTION Stage #######
	
	-- Arithmetic Logic Unit
	ArithLogUnit : ALU
		generic map (DATA_SIZE)          
		port map (
			A	   => MUX_HDU_ALUInA,
			B	   => MUX_HDU_ALUInB,
			opcode => ALU_OPCODE,
			Z	   => next_ALUOut_EXMEM
		);
		
	-- Multiplexer for RegB/Immediate choice for ALU second operand
	with MUXB_SEL select
		MUX_ALUB <= B_IDEX when '0',		-- for R-Type instructions
					Imm_IDEX when others;	-- for I-Type instructions
					
	-- Bypassing multiplexer for ALU Input A
	with HDU_ALUInA_SEL select
		MUX_HDU_ALUInA <= A_IDEX when "00",		 	-- ID/EX.A
						  ALUOut_EXMEM when "01",   -- EX/MEM.ALUOut
						  ALUOut_MEMWB when "10",   -- MEM/WB.ALUOut
						  LMD_MEMWB when others;    -- MEM/WB.LMD
	
	-- Bypassing multiplexer for ALU Input B	
	with HDU_ALUInB_SEL select
		MUX_HDU_ALUInB <= MUX_ALUB when "00",	 	-- ID/EX.A
						  ALUOut_EXMEM when "01",   -- EX/MEM.ALUOut
						  ALUOut_MEMWB when "10",   -- MEM/WB.ALUOut
						  LMD_MEMWB when others;    -- MEM/WB.LMD
	
	-- Bypassing multiplexer for register EX/MEM.B
	with HDU_Blatch_SEL select
		MUX_HDU_Blatch <= B_IDEX when "00",		   	-- ID/EX.B
						  ALUOut_MEMWB when "01",  	-- MEM/WB.ALUOut
						  LMD_MEMWB when others;   	-- MEM/WB.LMD
						                           
	-- Registers
	EXMEM_registers_p : process (Rst, Clk)
	begin
		if (Rst = '0') then
			-- Asynchronous, active-low reset
			LPC_EXMEM 	 <= (others => '0');
		    ALUOut_EXMEM <= (others => '0');
		    B_EXMEM   	 <= (others => '0');
		    IR_EXMEM 	 <= ITYPE_NOP & "00" & X"000000";
		elsif (Clk = '1' and Clk'EVENT) then
			IR_EXMEM <= IR_IDEX;
			
			if (LPC_LATCH_EXMEM_EN = '1') then
				LPC_EXMEM <= LPC_IDEX;
			end if;
			
			if (ALUOUT_LATCH_EXMEM_EN = '1') then
				ALUOut_EXMEM <= next_ALUOut_EXMEM;
			end if;
			
			if (RegB_LATCH_EXMEM_EN = '1') then
				B_EXMEM <= MUX_HDU_Blatch;
			end if;
			
			CWP_EXMEM <= CWP_IDEX;
			
		end if;
	end process EXMEM_registers_p;
	
	
	
	-- ####### MEMORY Stage #######
	
	-- EX/MEM.ALUOut to Data Memory address port
	DataAddr <= ALUOut_EXMEM;
	
	-- Bypassing multiplexer for Data Memory Write Input
	with HDU_DRAMIn_SEL select
		DataOut <= B_EXMEM when "00",		-- EX/MEM.B
				   ALUOut_MEMWB when "01",  -- MEM/WB.ALUOut
				   LMD_MEMWB when others;   -- MEM/WB.LMD
				   
	-- Extension of Data Memory outputs and LMD selection
	DataIn_16zeroPad <= (others => 	'0');
	DataIn_8zeroPad  <= (others => 	'0');
	DataIn_8signExt	 <= (others => 	DataIn_b(7));
	
	with MUXLMD_SEL select
		MUX_LMD <= DataIn_w when "00",						 -- when LW
				   DataIn_16zeroPad & DataIn_hw when "01",   -- when LHU
				   DataIn_8zeroPad  & DataIn_b  when "10",   -- when LBU
				   DataIn_8signExt  & DataIn_b  when others; -- when LB
				   
	-- Link Program Counter adder
	LPC_adder : P4ADD
		generic map (ADDR_SIZE)
		port map (
			A 	 => LPC_EXMEM,		-- PC+4
		    B 	 => X"00000004",
		    Cin  => '0',
		    Sum  => LPC_plus4,		-- PC+8
		    Cout => open
		);
	
	-- Multiplexer for LPC selection
	with MUXLPC_SEL select
		MUX_LPC <= LPC_EXMEM when '0',		-- when JAL  (no delay slot)
				   LPC_plus4 when others;	-- when JALR (has 1 delay slot)
				   
	-- Registers
	MEMWB_registers_p : process (Rst, Clk)
	begin
		if (Rst = '0') then
			-- Asynchronous, active-low reset
			LMD_MEMWB	 <= (others => '0');
		    ALUOut_MEMWB <= (others => '0');
		    LPC_MEMWB    <= (others => '0');
		    IR_MEMWB	 <= ITYPE_NOP & "00" & X"000000";
		elsif (Clk = '1' and Clk'EVENT) then
			IR_MEMWB <= IR_EXMEM;
			
			if (LMD_LATCH_MEMWB_EN = '1') then
				LMD_MEMWB <= MUX_LMD;
			end if;
			
			if (ALUOUT_LATCH_MEMWB_EN = '1') then
				ALUOut_MEMWB <= ALUOut_EXMEM;
			end if;
			
			if (LPC_LATCH_MEMWB_EN = '1') then
				LPC_MEMWB <= MUX_LPC;
			end if;
			
			CWP_MEMWB <= CWP_EXMEM;
			
		end if;
	end process MEMWB_registers_p;
		
		
		
	-- ####### WRITE-BACK Stage #######
	
	-- Write-back address selection for Register File
	with MUXWrAddr_SEL select
		MUX_WBAddr <= IR_MEMWB(15 downto 11) when "00", -- Reg C for R-Type
					  IR_MEMWB(20 downto 16) when "01", -- Reb B for I-Type
					  "10111" when others;				-- 23 for JAL, JALR
					  
	with MUXWB_SEL select
		MUX_WBData <= LMD_MEMWB when "00",		-- for Loads
					  ALUOut_MEMWB when "01",	-- for ALU instructions
					  LPC_MEMWB when others;	-- for JAL, JALR
	
end architecture RTL;