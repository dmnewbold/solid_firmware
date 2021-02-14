-- sc_zs
--
-- Channel zero suppression block.
--
-- The logic in here is kind of fiddly; see doc file in repo
--
-- Dave Newbold, January 2021

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_zs is
	generic(
		CTR_W: positive
	);
	port(
		clk: in std_logic;
		en: in std_logic;
		thresh: in std_logic_vector(13 downto 0);
		supp: in std_logic;
		d: in std_logic_vector(15 downto 0);
		q: out std_logic_vector(15 downto 0);
		we: out std_logic
	);

end sc_zs;

architecture rtl of sc_zs is

	signal ctr: unsigned(CTR_W - 1 downto 0);
	signal z0, z1, ed, sd, f: std_logic;
	signal di: std_logic_vector(15 downto 0);
	
begin

	z0 <= '1' when unsigned(d(13 downto 0)) < unsigned(thresh) or supp = '1' else '0';
	f <= (supp xor sd) or di(15);
	
	process(clk)
	begin
		if rising_edge(clk) then
			ed <= en;
			sd <= supp;
			di <= d;
			z1 <= z0;
			if en = '0' or z0 = '0' or f = '1' then
				ctr <= (others => '0');
			elsif z1 = '1' then
				ctr <= ctr + 1;
			end if;
			we <= ((not (z0 and z1)) or f) and ed;
			if z1 = '1' then
				q <= di(15) & '1' & sd & (12 - CTR_W downto 0 => '0') & std_logic_vector(ctr);
			else
				q <= di;
			end if;
		end if;
	end process;

end rtl;
