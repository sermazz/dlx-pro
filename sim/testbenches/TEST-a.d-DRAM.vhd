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
-- File: testbenches\TEST-a.d-DRAM.vhd
-- Date: August 2019
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.functions.all;

entity dlx_dram_test is
end dlx_dram_test;

architecture TEST of dlx_dram_test is

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

    signal Clock: std_logic := '0';
    signal Reset: std_logic	:= '1';
	
	signal Rd_en_s, Wr_en_s, Wr_byte_s : std_logic := '0';
	signal Din_s : std_logic_vector(Nbit_DATA - 1 downto 0) := (OTHERS => '0');
	signal Dout_w_s : std_logic_vector(Nbit_DATA - 1 downto 0);
	signal Dout_hw_s : std_logic_vector(Nbit_DATA/2 - 1 downto 0);
	signal Dout_b_s : std_logic_vector(7 downto 0);
	signal Addr_s : std_logic_vector(3 downto 0);

begin

		-- instance of Data memory
		dut: DRAM 	generic map (
						RAM_SIZE => 4,
					    WORD_SIZE => Nbit_DATA
					)
					port map (
						Clk   	=> Clock,
						Rst   	=> Reset,
						Rd_en 	=> Rd_en_s,
						Wr_en 	=> Wr_en_s,
						Wr_byte => Wr_byte_s,
						Addr	=> Addr_s,
						Din 	=> Din_s,
						Dout_w 	=> Dout_w_s,
						Dout_hw	=> Dout_hw_s,
						Dout_b 	=> Dout_b_s
					);

        Clock <= not Clock after 1 ns;
		Reset <= '0', '1' after 0.5 ns;
		
        STIMULI_PROC: process
        begin
		
			Rd_en_s <= '0';
			Addr_s <= (OTHERS => '0');
			Din_s <= X"FFFFFFFF";
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test synchronous write of whole word at address 0x00 but addressed as 0x02
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(2, Addr_s'LENGTH));
			Wr_en_s <= '1';
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test that only last write within a clock cycle is actually picked
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(3, Addr_s'LENGTH));
			Din_s <= X"EEEEEEEE";
			wait for 0.1 ns;
			Addr_s <= std_logic_vector(to_unsigned(4, Addr_s'LENGTH));
			Din_s <= X"EEEEEEEE";
			wait for 0.1 ns;
			Addr_s <= std_logic_vector(to_unsigned(8, Addr_s'LENGTH));
			Din_s <= X"EEEEEEEE";
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test synchronous write of whole word at address 0x04 but addressed as 0x06
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(6, Addr_s'LENGTH));
			Din_s <= X"AAAAAAAA";
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test asyncrhonous read of whole word at address 0x04 but addressed as 0x06
			wait for 0.5 ns;
			Rd_en_s <= '1';
			Addr_s <= std_logic_vector(to_unsigned(6, Addr_s'LENGTH));
			Din_s <= X"77777777";
			Wr_en_s <= '0';
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test asyncrhonous read of whole word at address 0x00	but addressed as 0x01
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(1, Addr_s'LENGTH));
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test asyncrhonous read of whole word at address 0x04
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(4, Addr_s'LENGTH));
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test synchronous write of byte at address 0x12 (only least significant byte "CB" should be written)
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(15, Addr_s'LENGTH));
			Din_s <= X"BBBBBBCB";
			Wr_en_s <= '1';
			Wr_byte_s <= '1';
			wait until (Clock = '1' AND Clock'EVENT);
			
			-- Test synchronous write of byte at address 0x00 (only least significant byte "CB" should be written)
			wait for 0.5 ns;
			Addr_s <= std_logic_vector(to_unsigned(0, Addr_s'LENGTH));
			
			wait;
        end process;

end TEST;

configuration TEST_DLX_DRAM of dlx_dram_test is
	for TEST
		for dut: DRAM
			use configuration WORK.CFG_DLX_DRAM;
		end for;
	end for;
end TEST_DLX_DRAM;