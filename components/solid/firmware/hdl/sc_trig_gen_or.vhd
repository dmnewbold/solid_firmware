-- sc_trig_gen_thresh
--
-- Local trigger module for simple 'ored' threshold triggers
-- This trigger will fire if any channel has a high bit in a given block
--
-- Assume threshold bits are valid 2 cycles after mark (i.e. 2nd cycle of block)
-- We produce valid flag 3 cycles after mark
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.top_decl.all;

entity sc_trig_gen_or is
	generic(
		TBIT: natural := 0;
		DELAY: positive := 1
	);
	port(
		clk: in std_logic;
		en: in std_logic;
		mark: in std_logic;
		chan_trig: in sc_trig_array;
		valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_gen_or;

architecture rtl of sc_trig_gen_or is

	signal mark_d, mark_dd: std_logic;
	signal mark_del: std_logic_vector(DELAY - 1 downto 0);

begin

	mark_del <= mark_del(DELAY - 2 downto 0) & mark when rising_edge(clk);
	valid <= (or_reduce(chan_trig(TBIT)) and mark_del(DELAY - 1)) and not (ack or not en) when rising_edge(clk);

end rtl;
