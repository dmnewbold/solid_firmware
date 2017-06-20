-- sc_ctrig_tot
--
-- Time-over-threshold trigger
--
-- Dave Newbold, May 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_ctrig_tot is
	generic(
		VAL_WIDTH: natural
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		en: in std_logic;
		d: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		cthresh: in std_logic_vector(8 downto 0);
		wsize: in std_logic_vector(3 downto 0);
		pthresh: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		trig: out std_logic
	);

end sc_ctrig_tot;

architecture rtl of sc_ctrig_tot is
	
	signal p, rsti: std_logic;
	signal count: std_logic_vector(cthresh'range);
	
begin

	rsti <= rst or not en;

	p <= '1' when unsigned(d) > unsigned(pthresh) else '0';
	
	cnt: entity work.sc_ctrig_window
		generic map(
			C_WIDTH => cthresh'length
		)
		port map(
			clk => clk,
			rst => rsti,
			wsize => wsize,
			p => p,
			count => count
		);

	thresh: entity work.sc_ctrig_thresh
		generic map(
			VAL_WIDTH => cthresh'length
		)
		port map(
			clk => clk,
			d => count,
			threshold => cthresh,
			trig => trig
		);

end rtl;
