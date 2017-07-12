-- Top-level design for ipbus demo
--
-- This version is for Enclustra AX3 module, using the RGMII PHY on the PM3 baseboard
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, 4/10/16

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.ALL;

entity top is port(
		sysclk: in std_logic;
		leds: out std_logic_vector(3 downto 0); -- status LEDs
--		cfg: in std_logic_vector(3 downto 0); -- switches
		rgmii_txd: out std_logic_vector(3 downto 0);
		rgmii_tx_ctl: out std_logic;
		rgmii_txc: out std_logic;
		rgmii_rxd: in std_logic_vector(3 downto 0);
		rgmii_rx_ctl: in std_logic;
		rgmii_rxc: in std_logic;
		phy_rstn: out std_logic;
		clk_rstn_p: out std_logic;
		clk_rstn_n: out std_logic;
		clk_o_p: out std_logic;
		clk_o_n: out std_logic;
		clk_i_p: in std_logic;
		clk_i_n: in std_logic;
		trig_o_p: out std_logic;
		trig_o_n: out std_logic;
		trig_i_p: in std_logic;
		trig_i_n: in std_logic;
		sync_o_p: out std_logic;
		sync_o_n: out std_logic;
		sync_i_p: in std_logic;
		sync_i_n: in std_logic;
		trig_sel_p: out std_logic;
		trig_sel_n: out std_logic;
		sync_sel_p: out std_logic;
		sync_sel_n: out std_logic;
		scl_p: out std_logic;
		scl_n: out std_logic;
		sda_o_p: out std_logic;
		sda_o_n: out std_logic;
		sda_i_p: in std_logic;
		sda_i_n: in std_logic;
		busy_o_p: out std_logic;
		busy_o_n: out std_logic;
		busy_i_p: in std_logic_vector(9 downto 0);
		busy_i_n: in std_logic_vector(9 downto 0)
	);

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, nuke, soft_rst, phy_rst_e, userled, clk125: std_logic;
	signal mac_addr: std_logic_vector(47 downto 0);
	signal ip_addr: std_logic_vector(31 downto 0);
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal inf_leds: std_logic_vector(1 downto 0);
	
begin

-- Infrastructure

	infra: entity work.enclustra_ax3_pm3_infra
		port map(
			sysclk => sysclk,
			clk_ipb_o => clk_ipb,
			rst_ipb_o => rst_ipb,
			clk125_o => clk125,
			rst125_o => phy_rst_e,
			nuke => nuke,
			soft_rst => soft_rst,
			leds => inf_leds,
			rgmii_txd => rgmii_txd,
			rgmii_tx_ctl => rgmii_tx_ctl,
			rgmii_txc => rgmii_txc,
			rgmii_rxd => rgmii_rxd,
			rgmii_rx_ctl => rgmii_rx_ctl,
			rgmii_rxc => rgmii_rxc,
			mac_addr => mac_addr,
			ip_addr => ip_addr,
			ipb_in => ipb_in,
			ipb_out => ipb_out
		);
		
	leds <= not ('0' & userled & inf_leds);
	phy_rstn <= not phy_rst_e;
		
	mac_addr <= X"020ddba1ebc7"; -- Careful here, arbitrary addresses do not always work
	ip_addr <= X"c0a8ebc7"; -- 192.168.235.199

-- ipbus slaves live in the entity below, and can expose top-level ports
-- The ipbus fabric is instantiated within.

	slaves: entity work.payload
		port map(
			ipb_clk => clk_ipb,
			ipb_rst => rst_ipb,
			ipb_in => ipb_out,
			ipb_out => ipb_in,
			nuke => nuke,
			soft_rst => soft_rst,
			userled => userled,
			clk125 => clk125,
			clk_rstn_p => clk_rstn_p,
			clk_rstn_n => clk_rstn_n,
			clk_o_p => clk_o_p,
			clk_o_n => clk_o_n,
			clk_i_p => clk_i_p,
			clk_i_n => clk_i_n,
			trig_o_p => trig_o_p,
			trig_o_n => trig_o_n,
			trig_i_p => trig_i_p,
			trig_i_n => trig_i_n,
			sync_o_p => sync_o_p,
			sync_o_n => sync_o_n,
			sync_i_p => sync_i_p,
			sync_i_n => sync_i_n,
			trig_sel_p => trig_sel_p,
			trig_sel_n => trig_sel_n,
			sync_sel_p => sync_sel_p,
			sync_sel_n => sync_sel_n,
			scl_p => scl_p,
			scl_n => scl_n,
			sda_o_p => sda_o_p,
			sda_o_n => sda_o_n,
			sda_i_p => sda_i_p,
			sda_i_n => sda_i_n,
			busy_o_p => busy_o_p,
			busy_o_n => busy_o_n,
			busy_i_p => busy_i_p,
			busy_i_n => busy_i_n
		);

end rtl;
