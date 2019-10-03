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
-- File: a.b-DataPath.core\b-BJ_Logic.vhd
-- Date: August 2019
-- Brief: Branch&Jump logic for  DLX datapath, based on BHT with 2-bit prediction scheme
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;
use work.myTypes.all;

-- ######## BRANCH & JUMP LOGIC ########
-- The Branch & Jump logic provides the IF stage with a taken/not_taken prediction by means of
-- a BHT (Branch History Table) with 2-bits prediction scheme: a small memory is indexed by the
-- low-order bits of branches program counter; each entry of the memory contains 2 bits (note
-- that such prediction is just an hint, it might not belong to the branch which indexed it).
-- If the fetched instruction is a jump, the target address is always latched to the PC register;
-- if instead it is a branch, the prediction is used to decide whether to update PC with PC+4 or TA.
-- In case of misprediction, which is actually checked during the ID stage of the branch, the
-- fetched instruction is aborted, substituting it with a NOP in IF stage (a bubble is propagated by
-- disabling the PC register and synchronously flushing the IF/ID storage block while the branch
-- is in ID stage) and latching the correct PC on the following clock cycle; also the prediction
-- for the indexed row of the memory is updated basing on actual branch outcome.
-- Jump Registers are handled differently: since their target address is obtained only in ID stage,
-- they always have a delay slot of 1, which can be filled with a NOP at compilation time if no
-- suitable instructions exist to fill it.

-- NB: opcode_IFID and bAddr_IFID (= PC coming from IF) are not stored internally to bj_logic
-- but taken as additional inputs from the datapath, so that in case a branch instruction stalls
-- in the IF stage, the stall has not to be managed by the Branc&Jump logic but only by datapath

entity bj_logic is
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
end bj_logic;

architecture Behavioural of bj_logic is
	
	-- The Prediction Memory implements the actual predictions; each 2-bits row (here implicitly coded) 
	-- represents the state of an FSM, which is updated basing on the prediction made during IF (= the
	-- current state, i.e. the 2 bits of the row) and the actual outcome of the branch (actually computed
	-- during the ID stafe of the branch using REG_A)
	
	type state_type is (NotTaken, weak_NotTaken, weak_Taken, Taken);
	type mem_array is array (natural range <>) of state_type;
	
	signal pred_mem, nextPred_mem : mem_array(0 to MEM_SIZE-1);
	
begin
	
	-- purpose: Prediction FSM sequential logic
	-- type   : sequential
	-- inputs : nextPred_mem
	-- outputs: pred_mem
	PREDICTION_SEQ: process (Clk, Rst)
	begin
		if (Rst = '0') then	-- active-low, asynchronous reset
			pred_mem <= (others => NotTaken);
		elsif (Clk = '1' and Clk'EVENT) then
			if (STALL = '0') then
				pred_mem <= nextPred_mem;
			end if;
		end if;
	end process PREDICTION_SEQ;
	
	
	-- purpose: Prediction FSM next state & output logic
	-- type   : combinational
	-- inputs : pred_mem, REG_A, NPC, TA
	-- outputs: nextPred_mem, flush_IFID, muxPC_SEL, correct_PC
	PREDICTION_COMB: process (pred_mem, opcode_IFID, bAddr_IFID, REG_A, NPC, TA)
		variable tempMem 	: mem_array(0 to MEM_SIZE-1);
		variable index 		: integer;
	begin
		tempMem := pred_mem; -- to avoid multiple modifications of RAM content within same cc (e.g. glitches)
		-- To take log2(MEM_SIZE) bits of the branch address without considering the 2 LSBs, which are always 0
		index := to_integer(unsigned(bAddr_IFID(log2(MEM_SIZE) - 1+2 downto 2)));
		
		-- Output default values
		flush_IFID <= '0';
		muxPC_SEL <= '0';
		correct_PC <= (OTHERS => '0');
		
		-- ** Branch when equal zero (BEQZ) **
		if (opcode_IFID = ITYPE_BEQZ) then
			case pred_mem(index) is
			
				when NotTaken =>
					if (unsigned(REG_A) = 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= TA;
						tempMem(index) := weak_NotTaken;
					end if;
					
				when weak_NotTaken =>
					if (unsigned(REG_A) = 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= TA;
						tempMem(index) := weak_Taken;
					else
						tempMem(index) := NotTaken;
					end if;
					
				when weak_Taken =>
					if (unsigned(REG_A) = 0) then
						tempMem(index) := Taken;
					else
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= NPC;
						tempMem(index) := weak_NotTaken;
					end if;
					
				when Taken =>
					if (unsigned(REG_A) /= 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= NPC;
						tempMem(index) := weak_NotTaken;
					end if;
			end case;
			
		-- ** Branch when different from zero (BNEZ) **
		elsif (opcode_IFID = ITYPE_BNEZ) then
		
			case pred_mem(index) is
				when NotTaken =>
					if (unsigned(REG_A) /= 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= TA;
						tempMem(index) := weak_NotTaken;
					end if;
					
				when weak_NotTaken =>
					if (unsigned(REG_A) /= 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= TA;
						tempMem(index) := weak_Taken;
					else
						tempMem(index) := NotTaken;
					end if;
					
				when weak_Taken =>
					if (unsigned(REG_A) /= 0) then
						tempMem(index) := Taken;
					else
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= NPC;
						tempMem(index) := weak_NotTaken;
					end if;
					
				when Taken =>
					if (unsigned(REG_A) = 0) then
						flush_IFID <= '1';
						muxPC_SEL <= '1';
						correct_PC <= NPC;
						tempMem(index) := weak_NotTaken;
					end if;
			end case;
			
		-- ** Jump register (JR, JALR) **
		elsif (opcode_IFID = ITYPE_JR OR opcode_IFID = ITYPE_JALR) then
			-- Only latch into PC the correct PC for the Jump taken from REG_A
			-- without flushing the instruction fetched during the delay slot
			muxPC_SEL <= '1';
			correct_PC <= REG_A;
		end if;
		
		nextPred_mem <= tempMem;
	end process PREDICTION_COMB;
	
	
	-- purpose: Prediction reading from IF stage
	-- type   : combinational
	-- inputs : pred_mem
	-- outputs: take_bj
	PRED_MUX: process (pred_mem, opcode_IRAM, bAddr_PC)
		variable index 		: integer;
	begin
		if (opcode_IRAM = JTYPE_J OR opcode_IRAM = JTYPE_JAL) then
			-- If unconditional jump (no Jump Reg), always use Next PC = Target Address
			take_bj <= '1';
		elsif (opcode_IRAM = ITYPE_BEQZ OR opcode_IRAM = ITYPE_BNEZ) then
			-- If branch, use prediction to decide Next PC = PC+4 or Target Address
			-- To take log2(MEM_SIZE) bits of the branch address without considering the 2 LSBs, which are always 0
			index := to_integer(unsigned(bAddr_PC(log2(MEM_SIZE) - 1+2 downto 2)));
			
			case pred_mem(index) is
				when NotTaken =>
					take_bj <= '0';
				when weak_NotTaken =>
					take_bj <= '0';
				when weak_Taken =>
					take_bj <= '1';
				when Taken =>
					take_bj <= '1';
			end case;
		else
			take_bj <= '0';		-- default choice: Next PC = PC+4
		end if;
	end process PRED_MUX;
	
end architecture;

configuration CFG_DLX_BJLOGIC of bj_logic is
	for Behavioural
	end for;
end CFG_DLX_BJLOGIC;