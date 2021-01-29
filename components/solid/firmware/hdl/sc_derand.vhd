-- sc_derand
--
-- Derandomiser buffer
--
-- Dave Newbold, May 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

use work.top_decl.all;

entity sc_derand is
	port(
		clk_w: in std_logic;
		rst_w: in std_logic;
		d: in std_logic_vector(31 downto 0);
		d_blkend: in std_logic;
		wen: in std_logic;
		clk_r: in std_logic;
		q: out std_logic_vector(31 downto 0);
		q_blkend: out std_logic;
		empty: out std_logic;
		ren: in std_logic;
		warn: out std_logic;
		full: out std_logic
	);

end sc_derand;

architecture rtl of sc_derand is
	
begin
	
	fifo: xpm_fifo_async
		generic map(
			FIFO_READ_LATENCY => 0,
			FIFO_WRITE_DEPTH => DERAND_DEPTH,
			PROG_FULL_THRESH => DERAND_DEPTH - 2 ** BLK_RADIX - 8,
			READ_DATA_WIDTH => 33,
			READ_MODE => "fwft",
			WRITE_DATA_WIDTH => 33
		)
		port map(
			dout(31 downto 0) => q,
			dout(32) => q_blkend,
			empty => empty,
			full => full,
			prog_full => warn,
			din(31 downto 0) => d,
			din(32) => d_blkend,
			injectdbiterr => '0',
			injectsbiterr => '0',
			rd_clk => clk_r,
			rd_en => ren,
			rst => rst_w,
			sleep => '0',
			wr_clk => clk_w,
			wr_en => wen
		);

end rtl;
