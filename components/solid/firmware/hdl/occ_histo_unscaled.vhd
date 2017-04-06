-- occ_histo
--
-- A simple histogrammer of buffer occupancy
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

entity occ_histo_unscaled is
	generic(
		BINS_RADIX: natural := 4; -- Number of bins (0 = 1, 1 = 2, etc)
		OCC_WIDTH: natural := 8 -- Occupancy counter width
	);
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_s: in std_logic;
		rst_s: in std_logic;
		occ: in std_logic_vector(OCC_WIDTH - 1 downto 0);
		freeze: in std_logic
	);

end occ_histo_unscaled;

architecture rtl of occ_histo_unscaled is

	type c_t is array(2 ** BINS_RADIX - 1 downto 0) of unsigned(31 downto 0);
	signal c: c_t;
	signal sel: integer range 2 ** BINS_RADIX - 1 downto 0 := 0;

begin

-- ipbus

	sel <= to_integer(unsigned(ipb_in.ipb_addr(BINS_RADIX - 1 downto 0)));
	ipb_out.ipb_rdata <= std_logic_vector(c(sel)); -- CDC
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
		
-- Bins

	process(clk_s)
	begin
		if rising_edge(clk_s) then
			if rst_s = '1' then
				c <= (others => (others => '0'));
			else
				for i in 2 ** BINS_RADIX - 1 downto 0 loop
					if to_integer(unsigned(occ(OCC_WIDTH - 1 downto OCC_WIDTH - BINS_RADIX - 1))) = i and freeze = '0' then
						c(i) <= c(i) + 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
end rtl;
