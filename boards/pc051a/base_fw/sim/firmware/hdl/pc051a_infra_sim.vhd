-- kc705_basex_infra
--
-- All board-specific stuff goes here.
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;

entity pc051a_infra_sim is
	port(
		clk_ipb_o: out std_logic; -- IPbus clock
		rst_ipb_o: out std_logic;
		clk125_o: out std_logic;
		rst125_o: out std_logic;
		nuke: in std_logic; -- The signal of doom
		soft_rst: in std_logic; -- The signal of lesser doom
		ipb_in: in ipb_rbus; -- ipbus
		ipb_out: out ipb_wbus
	);

end pc051a_infra_sim;

architecture rtl of pc051a_infra_sim is

	signal clk_ipb, clk_ipb_i, rst, rsti: std_logic;
	signal trans_in: ipbus_trans_in;
	signal trans_out: ipbus_trans_out;
	
begin

--	DCM clock generation for internal bus, ethernet

	clocks: entity work.clock_sim
		port map(
			clko125 => clk125_o,
			clko_ipb => clk_ipb_i,
			locked => open,
			nuke => nuke,
			soft_rst => soft_rst,
			rsto => rst,
			rsto_ctrl => rsti
		);

	clk_ipb <= clk_ipb_i; -- Best to align delta delays on all clocks for simulation
	clk_ipb_o <= clk_ipb_i;
	rst_ipb_o <= rst;
	rst125_o <= rst;
	
-- sim UDP transport

	udp: entity work.ipbus_sim_udp
		port map(
			clk_ipb => clk_ipb,
			rst_ipb => rsti,
			trans_out => trans_in,
			trans_in => trans_out
		);

-- IPbus transactor

	trans: entity work.transactor
		port map (
			clk => clk_ipb,
			rst => rsti,
			ipb_out => ipb_out,
			ipb_in => ipb_in,
			ipb_req => open,
			ipb_grant => '1',
			trans_in => trans_in,
			trans_out => trans_out,
			cfg_vector_in => (Others => '0'),
			cfg_vector_out => open
		);	
	
end rtl;
