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
-- File: a.b-DataPath.core\a-RegFile_Win.vhd
-- Date: September 2019
-- Brief: Windowed Register File for the integer DLX datapath
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.functions.all;

-- ######## WINDOWED REGISTER FILE ########
-- This entity implements a Windowed Register File; it has 2 read ports (asynchronous with
-- enable signals) and 1 write port (synchronous). It is meant to be integrated in the DLX
-- datapath, thus it provides the solution for the structural hazard due to simultaneous
-- ID and WB stages: the read and the write ports are not only discoupled, but if a read
-- address is the same of a write address (and they refer to the same window), DataIn is
-- directly passed to read port output while being stored in the register file. Also, the
-- CWP is given in output so that the Hazard Detection Unit can actually understand if an
-- actual physical register is subject to a RAW, even if addressed with a different name
-- by instructions belonging to different subroutine.
-- The global registers are in the lowest addresses (from R0 to R7); R8 to R15 are reserved
-- to INPUT registers, while R16 to R23 contain LOCAL variables and R24 to R31 OUTPUT ones
-- Also, register R0, part of the global registers, is tied to 0 and writes which have R0
-- as destination do not have any effect. Since global registers are in the lowest
-- addresses of the physical register file (from 0 to 7), only one actual register has to
-- be tied to 0, the actual physical R0, and not the first register of every virtual window.
-- The CWP (Current Window Pointer) has been pipelined to let the instructions which are
-- issued before a CALL (i.e. a Jump&Link) or a RETURN (i.e. a Jump Register) write back
-- their results in the correct window, the one which was pointed by CWP before the context
-- switch.

entity RegFile_Win is
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
end RegFile_Win;

architecture Behavioural of RegFile_Win is
	
	-- Register file signal
	type REG_ARRAY is array (natural range <>) of std_logic_vector(DATA_SIZE-1 downto 0);
	signal phy_regfile, next_phy_regfile			: REG_ARRAY(0 to 2 * N * F + M - 1);
	-- 2*N because, in the overall Physical RegFile, every IN group overlaps with the OUT
	-- group of the following window
	
	-- * CWP points to the beginning of IN of the current window; it's used to translate
	-- from external address to physical RF address, and is shifted of 2*N registers
	-- forward at each subroutine call (OUT_i = IN_i+1)
	-- * SWP points to the end of the last IN+LOCALS window spilled in the stack (namely
	-- it points to the beginning of the OUT group of the last spilled window, which
	-- corresponds to the IN group of the following window, thus the SWP is the index of
	-- the window following the last spilled one)
	signal CWP, next_CWP				: unsigned(log2(F) - 1 downto 0);
	signal SWP, next_SWP				: unsigned(log2(F) - 1 downto 0);
	signal old_CWP1, old_CWP2			: unsigned(log2(F) - 1 downto 0);
	
	type StateType is (None, Spilling, Filling);
	signal RF_state, next_RF_state		: StateType;
	
	-- Register to hold the number of transfer (of BUS_WIDTH registers) still to make for SPILL/FILL
	signal to_transfer, next_to_transfer	: unsigned(log2(2*N/BUS_WIDTH) - 1 downto 0);
	
	
begin

	CWP_out <= std_logic_vector(CWP);

	-- purpose: Sequentially update physical register file for writes and fills from stack;
	--			updates window pointers, state and number of transfers still to do; manages
	--			the pipeline for the old values of CWP
	-- type   : sequential
	-- inputs : next_CWP, next_SWP, next_RF_state, next_phy_regfile, next_to_transfer
	-- outputs: CWP, SWP, RF_state, phy_regfile, to_transfer, memBus_out
	REG_proc : process (Clk, Rst)
		variable WrAddr_v 	 : integer;
	begin
		
		-- ### RESET (Asynchronous, active-low) ###
		if (Rst = '0') then
			-- Physical register file reset
			phy_regfile <= (others => (others => '0'));
			-- Useful for debug:
			-- for i in 0 to 2*N*F+M-1 loop
				-- phy_regfile(i) <= std_logic_vector(to_unsigned(i, DATA_SIZE));
			-- end loop;
			
			-- Window pointers reset
			CWP 	 <= (others => '0');
			SWP 	 <= (others => '0');
			old_CWP1 <= (others => '0');
			old_CWP2 <= (others => '0');
			-- State reset
			RF_state <= None;
			to_transfer <= (others => '0');
			
		-- ### SYNCHRONOUS BEHAVIOUR ###
		elsif (Clk = '1' and Clk'EVENT) then
		
			CWP <= next_CWP;
			SWP <= next_SWP;
			RF_state <= next_RF_state;
			phy_regfile <= next_phy_regfile;
			to_transfer <= next_to_transfer;
			
			-- Pipeline to let the correct old CWP arrive to WB stage
			-- Since CWP gets updated on the rising edge which follows the rising of the signal CALL,
			-- two additional registers to contain old_CWP1 and old_CWP2 are needed: as a result, CWP
			-- is updated during the EX stage of the CALL instruction (Jump&Link), old_CWP1 during
			-- its MEM stage and old_CWP2 during its WB stage: thus, the Jump&Link correctly writes
			-- back the Link address in the new window, so that the callee subroutine can return, and
			-- all instructions before the Jump&Link wrote back in the previous window, since write-
			-- backs are always performed considering old_CWP2 (i.e. the one which arrives to WB stage)
			old_CWP1 <= CWP;
			old_CWP2 <= old_CWP1;
			-- NB: Note that this pipeline does not need stalls since old_CWP1 and old_CWP2 registers
			-- respectively correspond to MEM and WB stage, which in this architecture are never stalled
					
			-- WRITE PORT
			if (wr_en = '1') then
				WrAddr_v := to_integer(unsigned(Wr_Addr));
				-- If write addres is not 0 (R0 is tied to 0 and cannot be written)
				if (WrAddr_v /= 0) then
					-- Write global variables (in the upper part of physical regfile)
					if (WrAddr_v < M) then
						phy_regfile(WrAddr_v) <= DataIn;
					else
					-- Write window of correct subroutine (writes to CWP of 3 clock cycles before
					-- because if a context switch happens, the write-back stage occurs after 3 cc
					-- and thus need the corresponding correct CWP
						WrAddr_v := WrAddr_v - M + 2*N*to_integer(old_CWP2);
						-- To perform MOD operation inexpensively = truncate the address on log2(2*N*F) bits
						-- This is needed in order to wrap around the physical register file (while avoiding the
						-- global registers, which are at the initial addresses) (same is done for read ops)
						phy_regfile(to_integer(to_unsigned(WrAddr_v, log2(2*N*F))) + M) <= DataIn;
					end if;
				end if;
			end if;

		end if;
	end process REG_proc;
	
	
	-- purpose: Manage the combinational part of the RegisterFile FSM (compute next state,
	--			next registers value like CWP and SWP, new combinational output value like
	--			FILL, SPILL and memBus_out)
	-- type   : combinational
	-- inputs : CWP, SWP, phy_regfile, RF_state, to_transfer, memBus_in
	-- outputs: next_CWP, next_SWP, next_phy_regfile, next_RF_state, next_to_transfer, SPILL, FILL, memBus_out
	FSM_STATE_proc : process (CWP, SWP, CALL, RET, RF_state, phy_regfile, to_transfer, memBus_in)
	begin
		-- Default registers assignment
		next_CWP <= CWP;
		next_SWP <= SWP;
		next_phy_regfile <= phy_regfile;
		next_RF_state <= RF_state;
		next_to_transfer <= (others => '0');
		
		-- Default output values
		SPILL 	<= '0';
		FILL  	<= '0';
		memBus_out <= (others => 'Z');
	
		case RF_state is
		
			-- ** RegisterFile normal operation mode (no stalling for fill/spill)**
			when None =>
				-- WINDOW POINTERS MANAGEMENT
				
				-- when a CALL of subroutine occurs (i.e. Jump&Link: JAL or JALR)
				if (CALL = '1') then
					next_CWP <= CWP + 1;
					if (CWP = SWP - 2) then		-- We need to compare CWP+1 (new CWP) to SWP-1, but CWP is updated on next cc, so we compare CWP with SWP-2
						next_SWP <= SWP + 1;
						next_RF_state <= Spilling;
						SPILL <= '1';
						
						-- Begin spilling during this clock cycle to save 1 cc
						next_to_transfer <= to_unsigned(2*N/BUS_WIDTH-1, next_to_transfer'LENGTH);
						for i in 0 to BUS_WIDTH-1 loop
							memBus_out(DATA_SIZE*BUS_WIDTH-1 - i*DATA_SIZE downto DATA_SIZE*BUS_WIDTH - (i+1)*DATA_SIZE) <= phy_regfile(M + 2*N*to_integer(SWP) + i);
						end loop;
					end if;
					
				-- when a RETURN from a subroutine occurs (i.e. Jump Register to R23: JR r23)
				elsif (RET = '1') then
					next_CWP <= CWP - 1;
					if (CWP = SWP) then			-- We need to compare CWP-1 (new CWP) to SWP-1, but CWP is updated on next cc, so we compare CWP with SWP
						next_SWP <= SWP - 1;
						next_RF_state <= Filling;
						FILL <= '1';
						
						next_to_transfer <= to_unsigned(2*N/BUS_WIDTH-1, next_to_transfer'LENGTH);
					end if;
				end if;
			
			-- ** Need to spill data to stack before context switch **
			when Spilling =>
				-- Spill registers from M+(SWP-1)*2*N to M+SWP*2*N (because SWP has been already incremented of 2*N)
				SPILL <= '1';
				for i in 0 to BUS_WIDTH-1 loop
					memBus_out(DATA_SIZE*BUS_WIDTH-1 - i*DATA_SIZE downto DATA_SIZE*BUS_WIDTH - (i+1)*DATA_SIZE) <= phy_regfile(M + 2*N*to_integer(SWP-1) + i + BUS_WIDTH*(2*N/BUS_WIDTH-to_integer(to_transfer)));
				end loop;
				next_to_transfer <= to_transfer - 1;
				if (to_transfer <= 0) then
					SPILL <= '0';
					next_RF_state <= None;
					memBus_out <= (others => 'Z');
				end if;
				
			-- ** Need to fill data from stack before context switch **
			when Filling =>
				-- Spill registers from M+SWP*2*N to M+(SWP+1)*2*N (because SWP has been already decremented of 2*N)
				FILL <= '1';
				for i in 0 to BUS_WIDTH-1 loop
					next_phy_regfile(M + 2*N*to_integer(SWP) + i + BUS_WIDTH*to_integer(to_transfer)) <= memBus_in(DATA_SIZE*BUS_WIDTH - 1 - i*DATA_SIZE downto DATA_SIZE*BUS_WIDTH - (i+1)*DATA_SIZE);
				end loop;
				next_to_transfer <= to_transfer - 1;
				if (to_transfer <= 0) then
					FILL <= '0';
					next_RF_state <= None;
				end if;
				
		end case;
	end process FSM_STATE_proc;
	
	
	-- purpose: Asynchronously manage the two read ports of the RegisterFile
	-- type   : sequential (asynchronous)
	-- inputs : rd1_en, rd2_en, Rd1_Addr, Rd2_Addr, wr_en, Wr_Addr, DataIn, CWP, RF_state, phy_regfile
	-- outputs: Out1, Out2
	RD_proc : process (rd1_en, rd2_en, Rd1_Addr, Rd2_Addr, wr_en, Wr_Addr, DataIn, CWP, RF_state, phy_regfile, old_CWP2)
		variable RdAddr_v : integer;
		variable WrAddr_v : integer;
	begin
		-- ** RegisterFile normal operation mode (no stalling for fill/spill)**
		if (RF_state = None) then
		
			-- READ PORT 1
			if (rd1_en = '1') then
				RdAddr_v := to_integer(unsigned(Rd1_Addr));
				WrAddr_v := to_integer(unsigned(Wr_Addr));
				
				-- R0 is tied to 0
				if (RdAddr_v = 0) then
					Out1 <= (others => '0');
					
				else
					-- Read global variables
					if (RdAddr_v < M) then
					
						if(wr_en = '1' and Wr_Addr = Rd1_Addr) then
							-- To solve structural hazard of ID and WB at same time, when referring to global variables
							Out1 <= DataIn;
						else
							Out1 <= phy_regfile(RdAddr_v);
						end if;

					-- Read variables of the subroutine window
					else
						RdAddr_v := RdAddr_v - M + 2*N*to_integer(CWP);
						-- To perform MOD operation inexpensively = truncate the address on log2(2*N*F) bits
						RdAddr_v := to_integer(to_unsigned(RdAddr_v, log2(2*N*F)));
						WrAddr_v := WrAddr_v - M + 2*N*to_integer(old_CWP2);
						if(wr_en = '1' and RdAddr_v = WrAddr_v) then
							-- To solve structural hazard of ID and WB at same time, when referring to same window
							Out1 <= DataIn;
						else
							Out1 <= phy_regfile(RdAddr_v + M);
						end if;						
					end if;
					
				end if;
			end if;
			
			-- READ PORT 2
			if (rd2_en = '1') then
				RdAddr_v := to_integer(unsigned(Rd2_Addr));
				WrAddr_v := to_integer(unsigned(Wr_Addr));
				
				-- R0 is tied to 0
				if (RdAddr_v = 0) then
					Out2 <= (others => '0');
					
				else
					-- Read global variables
					if (RdAddr_v < M) then
					
						if(wr_en = '1' and Wr_Addr = Rd2_Addr) then
							-- To solve structural hazard of ID and WB at same time, when referring to global variables
							Out2 <= DataIn;
						else
							Out2 <= phy_regfile(RdAddr_v);
						end if;

					-- Read variables of the subroutine window
					else
						RdAddr_v := RdAddr_v - M + 2*N*to_integer(CWP);
						-- To perform MOD operation inexpensively = truncate the address on log2(2*N*F) bits
						RdAddr_v := to_integer(to_unsigned(RdAddr_v, log2(2*N*F)));
						WrAddr_v := WrAddr_v - M + 2*N*to_integer(old_CWP2);
						if(wr_en = '1' and RdAddr_v = WrAddr_v) then
							-- To solve structural hazard of ID and WB at same time, when referring to same window
							Out2 <= DataIn;
						else
							Out2 <= phy_regfile(RdAddr_v + M);
						end if;						
					end if;
					
				end if;
			end if;

		end if;
	end process RD_proc;

end architecture;

configuration CFG_RFWIN_BEH of RegFile_Win is
  for Behavioural
  end for;
end configuration CFG_RFWIN_BEH;