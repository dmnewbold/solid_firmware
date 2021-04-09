-- sc_timing_startup
--
-- Controls various enables to set up data flow through buffers, etc
--
-- Dave Newbold, July 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.top_decl.all;

entity sc_timing_startup is
	port(
		clk40: in std_logic;
		rst40: in std_logic;
		en: in std_logic;
		zs_blks: in std_logic_vector(7 downto 0);
		nzs_blks: in std_logic_vector(3 downto 0);
		sync: in std_logic;
		sctr: in unsigned(47 downto 0);
		zs_en: out std_logic;
		dr_en: out std_logic
	);

end sc_timing_startup;

architecture rtl of sc_timing_startup is

	signal up: std_logic;

begin

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or en = '0' then
				up <= '0';
				zs_en <= '0';
				dr_en <= '0';
			else
				if sync = '1' then
					up <= '1';
				end if;
				if up = '1' then
					if unsigned(sctr(3 + BLK_RADIX downto 0)) = unsigned(nzs_blks) + 1 & to_unsigned(ZS_DEL, BLK_RADIX) then
						zs_en <= '1';
					elsif unsigned(sctr(7 + BLK_RADIX downto 0)) = unsigned(nzs_blks) + unsigned(zs_blks) & X"00" then
						dr_en <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;

end rtl;
