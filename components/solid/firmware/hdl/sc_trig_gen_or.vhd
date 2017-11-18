-- sc_trig_gen_or
--
-- Local trigger module for simple 'ored' threshold triggers
-- This trigger will fire if any channel has a high bit in a given block
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
		hit: out std_logic;
		chan_act: out std_logic_vector(N_CHAN - 1 downto 0);
		valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_gen_or;

architecture rtl of sc_trig_gen_or is

	signal t, m, tc, v: std_logic;
	signal mark_del: std_logic_vector(DELAY downto 0);
	signal c: std_logic_vector(N_CHAN - 1 downto 0);

begin

-- Define the trigger condition and block boundary

	t <= or_reduce(chan_trig(TBIT));
	mark_del <= mark_del(DELAY - 1 downto 0) & mark when rising_edge(clk);
	m <= mark_del(DELAY);
	
-- Catch a trigger feature with the block

	process(clk)
	begin
		if rising_edge(clk) then
			if en = '0' then
				tc <= '0';
				c <= (others => '0');
			elsif t = '1' then
				tc <= '1';
				if m = '0' then
					c <= c or chan_trig(TBIT);
				else
					c <= chan_trig(TBIT);
				end if;
			elsif m = '1' then
				tc <= '0';
				c <= (others => '0');
			end if;
		end if;
	end process;
				
-- Trigger request output

	hit <= t;
	v <= (v or (tc and m)) and not (mark or ack or not en) when rising_edge(clk);
	valid <= v;
	chan_act <= c when m = '1' and rising_edge(clk);
	
end rtl;
