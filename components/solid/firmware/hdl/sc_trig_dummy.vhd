-- sc_trig_dummy.vhd
--
-- Threshold-based placeholder for trigger generator block
--
-- Dave Newbold, July 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_trig_dummy is
	generic(
		VAL_WIDTH: natural
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		req: in std_logic;
		val: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		threshold: in std_logic_vector(VAL_WIDTH - 1 downto 0);
		trig: out std_logic
	);

end sc_trig_dummy;

architecture rtl of sc_trig_dummy is
	
begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				trig <= '0';
			elsif unsigned(val) > unsigned(threshold) then
				trig <= '1';
			elsif req = '1' then
				trig <= '0';
			end if;
		end if;
	end process;

end rtl;
