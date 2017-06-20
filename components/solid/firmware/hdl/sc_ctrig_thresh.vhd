-- sc_ctrig_thresh
--
-- Catch values above threshold within a block
--
-- Dave Newbold, April 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_ctrig_thresh is
	generic(
		VAL_WIDTH: natural
	);
	port(
		clk: in std_logic;
		d: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		threshold: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		trig: out std_logic
	);

end sc_ctrig_thresh;

architecture rtl of sc_ctrig_thresh is
	
	signal t: std_logic;

begin

	t <= '1' when unsigned(d) > unsigned(threshold) else '0';
	trig <= t when rising_edge(clk);
	
end rtl;
