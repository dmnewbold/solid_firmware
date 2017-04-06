-- sc_chan_buf.vhd
--
-- The buffer chain for one input channel
--
-- Dave Newbold, May 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

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
	
	signal rst_ctr: unsigned(3 downto 0);
	signal rsti, fifo_rst, wen_i: std_logic;
	signal di, qi: std_logic_vector(63 downto 0);
	signal dip, qip: std_logic_vector(7 downto 0);

begin

	process(clk_w)
	begin
		if rising_edge(clk_w) then
			if rst_w = '1' then
				rst_ctr <= "0000";
			elsif rsti = '1' then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	
	rsti <= '0' when rst_ctr = "1111" else '1';
	fifo_rst <= rsti and rst_ctr(3);
	wen_i <= wen and not rsti;

	di <= X"00000000" & d;
	dip <= X"0" & "000" & d_blkend;

	fifo: FIFO36E1
		generic map(
			DATA_WIDTH => 36,
			FIRST_WORD_FALL_THROUGH => true,
			ALMOST_FULL_OFFSET => to_bitvector(std_logic_vector(to_unsigned(2 ** (BLK_RADIX - 1) + 8, 16)))
		)
		port map(
			di => di,
			dip => dip,
			do => qi,
			dop => qip,
			empty => empty,
			full => full,
			almostfull => warn,
			injectdbiterr => '0',
			injectsbiterr => '0',
			rdclk => clk_r,
			rden => ren,
			regce => '1',
			rst => rst_w,
			rstreg => '0',
			wrclk => clk_w,
			wren => wen_i
		);
		
	q <= qi(31 downto 0);
	q_blkend <= qip(0);

end rtl;
