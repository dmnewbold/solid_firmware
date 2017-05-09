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
		VAL_WIDTH: natural;
		DELAY: positive := 1
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		clr: in std_logic;
		d: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		threshold: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		trig: out std_logic
	);

end sc_ctrig_thresh;

architecture rtl of sc_ctrig_thresh is

	signal cdel: std_logic_vector(DELAY - 1 downto 0);
	
begin

	cdel <= cdel(DELAY - 2 downto 0) & clr when rising_edge(clk);

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				trig <= '0';
			elsif unsigned(d) > unsigned(threshold) then
				trig <= '1';
			elsif cdel(DELAY - 1) = '1' then
				trig <= '0';
			end if;
		end if;
	end process;

end rtl;
