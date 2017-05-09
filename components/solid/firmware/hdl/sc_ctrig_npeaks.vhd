-- sc_ctrig_npeaks
--
-- Peaks-above-threshold trigger
--
-- Dave Newbold, May 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_ctrig_npeaks is
	generic(
		VAL_WIDTH: natural;
		DELAY: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		clr: in std_logic;
		d: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		cthresh: in std_logic_vector(8 downto 0);
		wsize: in std_logic_vector(3 downto 0);
		pthresh: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		trig: out std_logic
	);

end sc_ctrig_npeaks;

architecture rtl of sc_ctrig_npeaks is
	
	signal d1, d2: std_logic_vector(VAL_WIDTH - 1 downto 0);
	signal p: std_logic;
	signal count: std_logic_vector(cthresh'range);
	
begin

	d1 <= d when rising_edge(clk);
	d2 <= d1 when rising_edge(clk);
	p <= '1' when unsigned(d1) > unsigned(pthresh) and unsigned(d2) < unsigned(d1) and unsigned(d) <= unsigned(d1) else '0';
	
	count: entity work.sc_ctrig_window
		generic map(
			C_WIDTH => cthresh'length
		)
		port map(
			clk => clk,
			rst => rst,
			wsize => wsize,
			p => p,
			count => count
		);

	thresh: entity work.sc_ctrig_thresh
		generic map(
			VAL_WIDTH => cthresh'length,
			DELAY => 2
		)
		port map(
			clk => clk,
			rst => rst,
			clr => clr,
			d => count,
			threshold => cthresh,
			trig => trig
		);

end rtl;
