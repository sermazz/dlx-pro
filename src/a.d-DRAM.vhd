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
-- File: a.d-DRAM.vhd
-- Date: August 2019
-- Brief: Custom Data Memory for the DLX (not synthesized)
--
--#######################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.myTypes.all;
use work.functions.all;

-- ######## DATA MEMORY for DLX ########
-- The following entity is a Data RAM to be employed for simulation of the DLX custom
-- architecture. At reset, the memory is filled with the content of text file "data.mem",
-- to have the possibility of loading starting data. The file must contain 4 bytes in
-- hexadecimal for each line; if the file is empty, the memory is loaded with zeroes.

-- CHARACTERISTICS: big-endian; byte-addressable with possibility to perform store operations
--		on single bytes and on whole words; default word size of 4 bytes; since exceptions are
--		not implemented in this DLX, addresses of words and half words are automatically aligned
--		to be divisible respectively by 4 and by 2
-- READ and WRITE OPERATIONS: 1 asynchronous read port and 1 synchronous write port with enables;
--		those two ports share their address line; the read port gives as output the word, the half
--		word and the byte corresponding to the input address aligned respectively to word, half word
--		and byte; the write port transfers the data on Din (only least significant byte if Wr_byte
--		is HIGH or whole word otherwise) to the content of the memory on clock active edge.
-- This data memory is used to fully implement LB, LH, LW, SB, SW assembly instructions: while
-- the complexity of differentiating between SB and SW is managed by the memory (thanks to the
-- additional Wr_byte input), read operations always affect a whole word, and it is up to the
-- datapath to actually take the provided byte, half word or whole word.

entity DRAM is
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
end DRAM;

architecture Behavioural of DRAM is

	-- big-endian and byte addressable data memory type
	type RAMtype is array (0 to RAM_SIZE*WORD_SIZE/8 - 1) of std_logic_vector(7 downto 0);
	signal DRAM_mem : RAMtype;

begin

	-- purpose: Update content of Data memory on clock active edge basing on last write
	--			operation; implements synchronous write and asynchronous reset
	-- type   : sequential
	-- inputs : Rst, Addr, Din, DRAM_mem
	-- outputs: DRAM_mem
	WR_PROC: process (Clk, Rst)
		-- for Reset
		file dmem_file		: text;
		variable file_line 	: line;
		variable line_unsgn	: std_logic_vector(WORD_SIZE-1 downto 0);
		variable index 		: integer;
		-- for Write
		variable wordAddr_b	: std_logic_vector(log2(RAM_SIZE*WORD_SIZE/8) - 1 downto 0);
		variable wordAddr 	: integer;
	begin
	
		if (Rst = '0') then
			DRAM_mem <= (others => (others => '0'));
			-- On reset, fill the memory with data from "data.mem" textfile
			file_open(dmem_file, "data.mem", READ_MODE);				-- Open file in read mode
				
			index := 0;
			-- Loop until file ends or memory fills up
			while (not endfile(dmem_file) and index < RAM_SIZE*WORD_SIZE/8) loop
			
				readline(dmem_file, file_line);							-- Read a line from text file
				hread(file_line, line_unsgn);	
				for i in 0 to WORD_SIZE/8-1 loop
					DRAM_mem(index) <= line_unsgn(WORD_SIZE - i*8 - 1 downto WORD_SIZE - i*8 - 8);
					index := index + 1;
				end loop;
			end loop;
			
			file_close(dmem_file);
			
		elsif (Clk = '1' and Clk'EVENT) then
		
			if (Wr_en = '1') then
				-- Write operation requested
				if (Wr_byte = '1') then
					-- Write addressed byte only
					DRAM_mem(to_integer(unsigned(Addr))) <= Din(7 downto 0);
				else
					-- Write whole word to which address belongs
					wordAddr_b := Addr(log2(RAM_SIZE*WORD_SIZE/8) - 1 downto 2) & "00";	-- mask 2 LSBs to point to 4-bytes word
					wordAddr := to_integer(unsigned(wordAddr_b)); 		-- convert from binary to integer
					for i in 0 to WORD_SIZE/8-1 loop
						DRAM_mem(wordAddr + i) <= Din(WORD_SIZE - i*8 - 1 downto WORD_SIZE - i*8 - 8);
					end loop;
				end if;
			end if;
		
		end if;
		
	end process WR_PROC;

	-- purpose: Output the value at the address given by Addr input aligned to the word,
	--			to the half word and to the byte; implements the asynchronous read
	-- type   : combinational
	-- inputs : Addr, DRAM_mem
	-- outputs: Dout_w, Dout_hw, Dout_b
	RD_PROC: process (Addr, DRAM_mem, Rd_en)
		variable maskedAddr_b	: std_logic_vector(log2(RAM_SIZE*WORD_SIZE/8)- 1 downto 0);
		variable maskedAddr 	: integer;
	begin
		if (Rd_en = '1') then
			-- Output WORD on Dout_w
			maskedAddr_b := Addr(log2(RAM_SIZE*WORD_SIZE/8) - 1 downto 2) & "00";		-- mask 2 LSBs to point to 4-bytes word
			maskedAddr := to_integer(unsigned(maskedAddr_b));
			for i in 0 to WORD_SIZE/8-1 loop
				Dout_w(WORD_SIZE - i*8 - 1 downto WORD_SIZE - i*8 - 8) <= DRAM_mem(maskedAddr + i);
			end loop;
			
			-- Output HALF WORD on Dout_hw
			maskedAddr_b := Addr(log2(RAM_SIZE*WORD_SIZE/8) - 1 downto 1) & '0';			-- mask 1 LSB to point to half word
			maskedAddr := to_integer(unsigned(maskedAddr_b));
			for i in 0 to WORD_SIZE/8/2-1 loop
				Dout_hw(WORD_SIZE/2 - i*8 - 1 downto WORD_SIZE/2 - i*8 - 8) <= DRAM_mem(maskedAddr + i);
			end loop;
			
			-- Output BYTE on Dout_b
			Dout_b <= DRAM_mem(to_integer(unsigned(Addr)));
		end if;
	end process RD_PROC;

end Behavioural;

configuration CFG_DLX_DRAM of DRAM is
	for Behavioural
	end for;
end CFG_DLX_DRAM;