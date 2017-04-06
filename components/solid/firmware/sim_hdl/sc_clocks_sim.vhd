-- sc_clocks_sim
--
-- Simulation of clock generation; should be OK for delta delays
--
-- Dave Newbold, July 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

entity sc_clocks is
	port(
		clk_in_p: in std_logic; -- Input clock (nominally 40MHz)
		clk_in_n: in std_logic;
		clk40: out std_logic; -- Sample clock (nominally 40MHz)
		clk80: out std_logic; -- Processing clock (2 * clk_s)
		clk160: out std_logic; -- Processing clock (4 * clk_s)
		clk280: out std_logic; -- iserdes clock (7 * clk_s)
		locked: out std_logic;
		rst_mmcm: in std_logic;
		rsti: in std_logic;
		rst40: out std_logic
	);

end sc_clocks;

architecture rtl of sc_clocks is

	signal clk_master: std_logic := '0';
	signal ctr: unsigned(4 downto 0) := "00000";
	signal clk40_u, clk40_i, clk80_u, clk160_u, clk280_u: std_logic := '1';
	signal locked_i: std_logic := '0';

begin

	process
	begin
		if ctr = 27 then
			ctr <= "00000";
		else
			ctr <= ctr + 1;
		end if;
		wait for 0.5 ns;
	end process;
	
	clk40_u <= not clk40_u when ctr'event and ctr mod 28 = 0;
	clk80_u <= not clk80_u when ctr'event and ctr mod 14 = 0;
	clk160_u <= not clk160_u when ctr'event and ctr mod 7 = 0;
	clk280_u <= not clk280_u when ctr'event and ctr mod 4 = 0;

	clk40 <= clk40_u;
	clk40_i <= clk40_u;
	clk80 <= clk80_u;
	clk160 <= clk160_u;
	clk280 <= clk280_u;
	
	locked_i <= '1' after 200 ns;
	locked <= locked_i;
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			rst40 <= rsti or not locked_i;
		end if;
	end process;
	
end rtl;
