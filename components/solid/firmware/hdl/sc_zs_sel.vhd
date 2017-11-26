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

	signal sel_i: std_logic_vector(1 downto 0);
	signal ti: integer range 15 downto 0 := 0;
	signal zs: std_logic_vector(1 downto 0);

begin

	ti <= to_integer(unsigned(trig(3 downto 0)));
	zs <= zscfg(ti * 2 + 1 downto ti * 2);
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or mark = '1' then
				sel_i <= "00";
			elsif trig_valid = '1' and unsigned(zs) > unsigned(sel_i) then
				sel_i <= zs;
			end if;
		end if;
	end process;

	sel <= sel_i;
	
end rtl;
