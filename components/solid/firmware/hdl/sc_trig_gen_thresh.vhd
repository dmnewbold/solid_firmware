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

entity sc_trig_gen_thresh is
	generic(
		TBIT: natural := 0
	);
	port(
		clk: in std_logic;
		en: in std_logic;
		mark: in std_logic;
		chan_trig: in sc_trig_array;		
		valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_gen_thresh;

architecture rtl of sc_trig_gen_thresh is

	signal mark_d, mark_dd: std_logic;

begin

	mark_d <= mark when rising_edge(clk);
	mark_dd <= mark_d when rising_edge(clk);
			
	valid <= (or_reduce(chan_trig(TBIT)) and mark_dd) and not (ack or not en) when rising_edge(clk);

end rtl;
