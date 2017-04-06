-- scaled_ctr
--
-- Exponent + mantissa counter for large values
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity scaled_ctr is
	generic(
		MANTISSA_BITS: natural := 8;
		EXPONENT_BITS: natural := 8
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		inc: in std_logic;
		m: out std_logic_vector(MANTISSA_BITS - 1 downto 0);
		e: out std_logic_vector(EXPONENT_BITS - 1 downto 0)		
	);

end scaled_ctr;

architecture rtl of scaled_ctr is

	signal mctr: unsigned(MANTISSA_BITS - 1 downto 0);
	signal ectr: unsigned(EXPONENT_BITS - 1 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				mctr <= (others => '0');
				ectr <= (others => '0');
			elsif inc = '1' then
				if mctr = (mctr'range => '1') then
					if ectr /= (ectr'range => '1') then
						mctr(mctr'left) <= '1';
						mctr(mctr'left - 1 downto 0) <= (others => '0');
						ectr <= ectr + 1;
					end if;
				else
					mctr <= mctr + 1;
				end if;
			end if;
		end if;
	end process;

	m <= std_logic_vector(mctr);
	e <= std_logic_vector(ectr);
	
end rtl;
