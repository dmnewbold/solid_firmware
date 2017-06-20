-- sc_trig_gen
--
-- Local trigger module based on an incoming bit
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.top_decl.all;

entity sc_trig_gen is
	generic(
		DELAY: positive := 1
	);
	port(
		clk: in std_logic;
		en: in std_logic;
		mark: in std_logic;
		trig: in std_logic;
		hit: out std_logic;
		valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_gen;

architecture rtl of sc_trig_gen is

	signal t, m, tc, v: std_logic;
	signal mark_del: std_logic_vector(DELAY - 1 downto 0);

begin

-- Define the trigger condition and block boundary

	t <= trig;
	mark_del <= mark_del(DELAY - 2 downto 0) & mark when rising_edge(clk);
	m <= mark_del(DELAY - 1);
	
-- Catch a trigger feature with the block

	process(clk)
	begin
		if rising_edge(clk) then
			if en = '0' then
				tc <= '0';
			elsif t = '1' then
				tc <= '1';
			elsif m = '1' then
				tc <= '0';
			end if;
		end if;
	end process;
				
-- Trigger request output

	hit <= t;
	v <= (v or (tc and m)) and not (mark or ack or not en) when rising_edge(clk);
	valid <= v;
	
end rtl;
