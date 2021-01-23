-- sc_clocks
--
-- Generates 40MHz sample clock and other related clocks for iserdes, etc.
--
-- Dave Newbold, February 2016

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
		clk280: out std_logic; -- iserdes clock (7 * clk_s)
		locked: out std_logic;
		rst_mmcm: in std_logic;
		rsti: in std_logic;
		rst40: out std_logic
	);

end sc_clocks;

architecture rtl of sc_clocks is

	signal clk_in_ub, clk_in, clkfb: std_logic;
	signal clk40_u, clk40_i, clk80_u, clk280_u: std_logic;
	signal locked_i: std_logic;

begin

	ibufgds0: IBUFGDS port map(
		i => clk_in_p,
		ib => clk_in_n,
		o => clk_in_ub
	);

	bufg_clk_in: BUFG port map(
		i => clk_in_ub,
		o => clk_in
	);
	
	mmcm: MMCME2_BASE
		generic map(
			CLKIN1_PERIOD => 25.0,
			CLKFBOUT_MULT_F => 28.0,
			CLKOUT0_DIVIDE_F => 28.0, 
			CLKOUT1_DIVIDE => 14,
			CLKOUT2_DIVIDE => 4
		)
		port map(
			clkin1 => clk_in,
			clkfbin => clkfb,
			clkout0 => clk40_u,
			clkout1 => clk80_u,
			clkout2 => clk280_u,
			clkfbout => clkfb,
			locked => locked_i,
			rst => rst_mmcm,
			pwrdwn => '0'
		);

	locked <= locked_i;
	
	bufg40: BUFG
		port map(
			i => clk40_u,
			o => clk40_i
		);
		
	clk40 <= clk40_i;
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			rst40 <= rsti or not locked_i;
		end if;
	end process;
	
	bufg80: BUFG
		port map(
			i => clk80_u,
			o => clk80
		);

	bufg280: BUFG
		port map(
			i => clk280_u,
			o => clk280
		);
		
end rtl;
