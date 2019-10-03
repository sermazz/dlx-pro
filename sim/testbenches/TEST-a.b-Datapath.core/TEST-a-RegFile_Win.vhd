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
-- File: testbenches\TEST-a.b-Datapath.core\TEST-a-RegFile_Win.vhd
-- Date: September 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.functions.all;

entity TB_REGISTERFILE is
end TB_REGISTERFILE;

architecture TEST of TB_REGISTERFILE is

	component RegFile_Win is
		generic (
			DATA_SIZE	: integer := Nbit_DATA;		-- Width of registers
			M   		: integer := RF_GLOB_num;	-- Number of GLOBALS registers
			N   		: integer := RF_ILO_num;	-- Number of registers of IN, OUT, OUT
			F			: integer := RF_WIND_num;	-- Number of windows
			BUS_WIDTH	: integer := 4				-- Memory Bus width (in registers of DATA_SIZE bits each)
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
	
    signal CLK_s		: std_logic := '1';
    signal RESET_S		: std_logic := '0';
    signal RD1_s		: std_logic;
    signal RD2_S		: std_logic;
    signal WR_S			: std_logic;
    signal ADD_WR_S		: std_logic_vector(4 downto 0);
    signal ADD_RD1_S	: std_logic_vector(4 downto 0);
    signal ADD_RD2_S	: std_logic_vector(4 downto 0);
    signal DATAIN_S		: std_logic_vector(31 downto 0);
    signal OUT1_S		: std_logic_vector(31 downto 0);
    signal OUT2_S		: std_logic_vector(31 downto 0);
	signal SPILL_s, FILL_S, CALL_S, RET_s : std_logic;	
	signal STACKtoRF, RFtoSTACK 	: std_logic_vector(32*4-1 downto 0);
	signal CWP_out_s		: std_logic_vector(2 downto 0);

begin 

	RF : RegFile_Win
	port map (
		Clk 	 => CLK_s,
		Rst		 => RESET_S,	
		wr_en 	 => WR_S,	
		Wr_Addr	 => ADD_WR_S,	
		DataIn 	 => DATAIN_S,	
		rd1_en 	 => RD1_s,	
		rd2_en 	 => RD2_S,	
		Rd1_Addr => ADD_RD1_S,	
		Rd2_Addr => ADD_RD2_S,	
		Out1 	 => OUT1_S,	
		Out2 	 => OUT2_S,	
		CALL 	 => CALL_S,	
		RET 	 => RET_s,	
		SPILL 	 => SPILL_s,	
		FILL	 => FILL_S,	
		memBus_In  => STACKtoRF,
		memBus_out => RFtoSTACK
	);

	CLK_S 	  <= not(CLK_s) after 0.5 ns;
	RESET_s   <= '0','1' after 0.6 ns;
	
	WR_s 	  <= '0', '1' after 1.6 ns, '0' after 13.1 ns;
	ADD_WR_s  <= "00010", "00011" after 1.2 ns, "01000" after 3 ns;
	DATAIN_s  <= X"FFFFFFFF", X"AAAAAAAA" after 3.1 ns, X"BBBBBBBB" after 4.1 ns, X"CCCCCCCC" after 5.1 ns, X"DDDDDDDD" after 6.1 ns, X"EEEEEEEE" after 7.1 ns, X"FFFFFFFF" after 8.1 ns,
				 X"AAAAAAAA" after 10.1 ns, X"BBBBBBBB" after 11.1 ns, X"CCCCCCCC" after 12.1 ns;
	
	RD1_s 	  <= '1', '0' after 3 ns; 
	ADD_RD1_s <= "00000", "00010" after 1.2 ns, "00100" after 2.2 ns;
	RD2_s 	  <= '1', '0' after 3 ns; 
	ADD_RD2_s <= "00001", "00011" after 1.2 ns, "00101" after 2.2 ns;
		

	CALL_s	  <= '0', '1' after 3.1 ns, '0' after 6.1 ns, '1' after 14.1 ns, '0' after 34.1 ns, '1' after 57.1 ns, '0' after 60.1 ns;
	RET_S 	  <= '0', '1' after 10.1 ns, '0' after 13.1 ns, '1' after 35.1 ns, '0' after 56.1 ns;

end TEST;


configuration TEST_RFWIND of TB_REGISTERFILE is
  for TEST
	for RF : RegFile_Win
		use configuration WORK.CFG_RFWIN_BEH;
	end for; 
  end for;
end TEST_RFWIND; 
