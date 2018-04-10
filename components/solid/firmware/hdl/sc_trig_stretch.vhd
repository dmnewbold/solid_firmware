-- sc_trig_stretch
--
-- Pulse stretcher for trigger coincidence
--
-- Dave Newbold, March 2018

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_trig_stretch is
	generic(
		WIDTH: positive := 1
	);
	port(
		clk: in std_logic;
		del: in std_logic_vector(3 downto 0);
		d: in std_logic_vector(WIDTH - 1 downto 0);
		q: out std_logic_vector(WIDTH - 1 downto 0)
	);

end sc_trig_stretch;

architecture rtl of sc_trig_stretch is

	type r_t: array(2 ** del'width - 1 downto 0) of std_logic_vector(WIDTH - 1 downto 0);
	signal r: r_t;
	
begin
	
	r(0) <= d;
	r(r'left downto 1) <= r(r'left - 1 downto 0) when rising_edge(clk);
	q <= r(to_integer(unsigned(del)));

end rtl;
