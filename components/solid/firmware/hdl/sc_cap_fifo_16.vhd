-- sc_cap_fifo_16
--
-- Simple ipbus interface to a 16b wide FIFO
--
-- Dave Newbold, September 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.ipbus.all;

entity sc_cap_fifo_16 is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic;
		rst_p: in std_logic;
		d: in std_logic_vector(15 downto 0);
		we: in std_logic;
		empty: out std_logic;
		full: out std_logic;
		frst: in std_logic -- Need at least three cycles long reset pulse
	);

end sc_cap_fifo_16;

architecture rtl of sc_cap_fifo_16 is
	
	signal clkn, empty_i, full_i, rden: std_logic;
	signal fifo_q: std_logic_vector(63 downto 0);

begin

	clkn <= not clk;

	fifo: FIFO36E1
		generic map(
			DATA_WIDTH => 18
		)
		port map(
			di(63 downto 16) => X"000000000000",
			di(15 downto 0) => d,
			dip => X"00",
			do => fifo_q,
			empty => empty_i,
			full => full_i,
			injectdbiterr => '0',
			injectsbiterr => '0',
			rdclk => clkn,
			rden => rden,
			regce => '1',
			rst => frst,
			rstreg => '0',
			wrclk => clk_p,
			wren => we
		);

	rden <= ipb_in.ipb_strobe and not ipb_in.ipb_write;
	
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
	ipb_out.ipb_rdata <= X"000" & "00" & full_i & empty_i & fifo_q(15 downto 0);
	
	empty <= empty_i;
	full <= full_i;

end rtl;

