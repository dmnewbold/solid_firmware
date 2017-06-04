-- sync_routing
--
-- Switchyard for the various ways of using the HDMI connector
--
-- sync_a input is always routed to clk_pll, but might be unused at PLL end
-- sync_a output is always crappy clk40
-- sync_b is an output for ctrl = '0', but an input for ctrl = '1'
-- sync_c exists on the cable but is not used
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.VComponents.all;

entity sync_routing is
	port(
		clk40: in std_logic;
		ctrl: in std_logic;
		sync_out: out std_logic;
		sync_in: in std_logic;
		sync_a_p: inout std_logic;
		sync_a_n: inout std_logic;
		sync_b_p: inout std_logic;
		sync_b_n: inout std_logic;
		clk_pll_p: out std_logic;
		clk_pll_n: out std_logic
	);

end sync_routing;

architecture rtl of sync_routing is

	signal sync_a_i, sync_a_o: std_logic;

begin

	oclk: ODDR
		port map(
			q => sync_a_o,
			c => clk40,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		); -- DDR register for clock forwarding

	ia: IOBUFDS
		port map(
			O => sync_a_i,
			IO => sync_a_p,
			IOB => sync_a_n,
			I => sync_a_o,
			T => '0'
		);
					
	obclk: OBUFDS
		port map(
			i => sync_a_i,
			o => clk_pll_p,
			ob => clk_pll_n
		);
			
	ib: IOBUFDS
		port map(
			O => sync_out,
			IO => sync_b_p,
			IOB => sync_b_n,
			I => sync_in,
			T => ctrl
		);
		
end rtl;
