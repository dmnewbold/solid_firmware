-- sc_trig_gen_random
--
-- Local trigger module for random / regular triggers
--
-- We produce valid signal on cycle after mark
--
-- mode(1): enable random / seq triggers
-- mode(0): 0: random; 1: seq
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.top_decl.all;

entity sc_trig_gen_random is
	port(
		clk: in std_logic;
		en: in std_logic;
		mode: in std_logic_vector(1 downto 0);
		sctr: in std_logic_vector(31 downto 0);
		rand: in std_logic_vector(31 downto 0);
		div: in std_logic_vector(5 downto 0);
		mark: in std_logic;
		force: in std_logic;
		valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_gen_random;

architecture rtl of sc_trig_gen_random is

	signal mask: std_logic_vector(23 downto 0);
	signal rtrig, force_c, force_d: std_logic;
	signal v: std_logic;

begin

	mgen: for i in mask'range generate
		mask(i) <= '0' when i > to_integer(unsigned(div)) else '1';
	end generate;
	
	process(clk)
	begin
		if rising_edge(clk) then
			force_d <= force;
			force_c <= (force_c or (force and not force_d)) and not mark and en;
		end if;
	end process;
	
	rtrig <= ((not mode(0) and not or_reduce(rand(mask'range) and mask)) or
		(mode(0) and not or_reduce(sctr(BLK_RADIX + mask'left downto BLK_RADIX) and mask))) and mode(1);
		
	v <= ((v and not mark) or ((rtrig or force_c) and mark)) and not (ack or not en) when rising_edge(clk);
	valid <= v and not ack;
	
end rtl;
