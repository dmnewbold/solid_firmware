-- sc_zs_sel
--
-- Random and external trigger generator
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.top_decl.all;

entity sc_zs_sel is
	port(
		clk40: in std_logic;
		rst40: in std_logic;
		mark: in std_logic;
		zscfg: in std_logic_vector(31 downto 0);
		trig: in std_logic_vector(15 downto 0);
		trig_valid: in std_logic;
		sel: out std_logic_vector(1 downto 0)
	);

end sc_zs_sel;

architecture rtl of sc_zs_sel is

	signal mark_del: std_logic_vector(ZS_DEL - 1 downto 0);
	signal m, g: std_logic;
	signal t: unsigned(3 downto 0);

begin

	mark_del <= mark_del(ZS_DEL - 2 downto 0) & mark when rising_edge(clk40);
	m <= mark_del(ZS_DEL - 1);
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or m = '1' then
				t <= (others => '0');
				g <= '0';
			elsif trig_valid = '1' then
				g <= '1';
				if unsigned(trig(3 downto 0)) > t then
					t <= unsigned(trig(3 downto 0));
				end if;
			end if;
			if rst40 = '1' then
				sel <= "00";
			elsif m = '1' then
				if g = '0' then
					sel <= "00";
				else
					sel <= zscfg(to_integer(t) * 2 + 1 downto to_integer(t) * 2);
				end if;
			end if;
		end if;
	end process;

end rtl;
