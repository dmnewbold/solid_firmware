-- sc_zs.vhd
--
-- Channel zero suppression block
--
-- Dave Newbold, January 2021

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_zs is
	generic
		CTR_W: positive
	);
	port(
		clk: in std_logic;
		clken: in std_logic;
		en: in std_logic;
		thresh: in std_logic_vector(13 downto 0);
		d: in std_logic_vector(15 downto 0);
		q: out std_logic_vector(15 downto 0);
		we: out std_logic
	);

end sc_zs;

architecture rtl of sc_zs is

	signal ctr: unsigned(CTR_W - 1 downto 0);
	signal z0, z1, en_d: std_logic;
	signal di: std_logic_vector(15 downto 0);
	
begin

	z0 <= '1' when unsigned(d(13 downto 0)) < unsigned(thresh) else '0';
	
	process(clk)
	begin
		if rising_edge(clk) and clken = '1' then
			en_d <= en;
			if en = '0' then
				ctr <= (others => '0');
			else
				di <= d;
				z1 <= z0;
				if z0 = '0' or di(15) = '1' then
					ctr <= (others => '0');
				elsif z1 = '1' then
					ctr <= ctr + 1;
				end if;
			end if;
			we <= ((not (z0 and z1)) or di(15)) and en_d;
			if z1 = '1' then
				q <= di(15) & '1' & (13 - CTR_W downto 0 => '0') & std_logic_vector(ctr);
			else
				q <= di;
			end if;
		end if;
	end process;	
	
end rtl;
