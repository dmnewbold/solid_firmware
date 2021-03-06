-- Top-level design for ipbus demo
--
-- You must edit this file to set the IP and MAC addresses
--
-- Dave Newbold, 08/01/16

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.top_decl.all;

entity top is port(
		eth_clk_p: in std_logic; -- 125MHz MGT clock
		eth_clk_n: in std_logic;
		eth_rx_p: in std_logic; -- Ethernet MGT input
		eth_rx_n: in std_logic;
		eth_tx_p: out std_logic; -- Ethernet MGT output
		eth_tx_n: out std_logic;
		sfp_los: in std_logic;
		sfp_tx_disable: out std_logic;
		sfp_scl: out std_logic;
		sfp_sda: out std_logic;
		leds: out std_logic_vector(1 downto 0); -- TE712 LEDs
		leds_c: out std_logic_vector(3 downto 0); -- carrier LEDs
		dip_sw: in std_logic_vector(3 downto 0); -- carrier switches
		si5326_scl: out std_logic;
		si5326_sda: inout std_logic;
		si5326_rstn: out std_logic;
		si5326_phase_inc: out std_logic;
		si5326_phase_dec: out std_logic;
		si5326_clk1_validn: in std_logic;
		si5326_clk2_validn: in std_logic;
		si5326_lol: in std_logic;
		si5326_clk_sel: out std_logic;
		si5326_rate0: out std_logic;
		si5326_rate1: out std_logic;
		clk40_p: in std_logic;
		clk40_n: in std_logic;
		adc_spi_cs: out std_logic_vector(1 downto 0);
		adc_spi_mosi: out std_logic;
		adc_spi_miso: in std_logic_vector(1 downto 0);
		adc_spi_sclk: out std_logic;
		adc_d_p: in std_logic_vector(N_CHAN - 1 downto 0);
		adc_d_n: in std_logic_vector(N_CHAN - 1 downto 0);
		analog_scl: out std_logic;
		analog_sda: inout std_logic;
		sync_in_p: in std_logic;
		sync_in_n: in std_logic;
		trig_in_p: in std_logic;
		trig_in_n: in std_logic;
		trig_out_p: out std_logic;
		trig_out_n: out std_logic;
		clk_pll_p: out std_logic;
		clk_pll_n: out std_logic
	);

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, clk125, rst125, nuke, soft_rst, userled, clk200, stealth_mode: std_logic;
	signal pllclk, pllrefclk: std_logic;
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal debug: std_logic_vector(3 downto 0);
	signal si5326_sda_o, analog_sda_o: std_logic;
	signal infra_leds: std_logic_vector(1 downto 0);
	
begin

-- Infrastructure

	infra: entity work.pc051a_infra -- Should work for artix also...
		port map(
			eth_clk_p => eth_clk_p,
			eth_clk_n => eth_clk_n,
			eth_tx_p => eth_tx_p,
			eth_tx_n => eth_tx_n,
			eth_rx_p => eth_rx_p,
			eth_rx_n => eth_rx_n,
			sfp_los => sfp_los,
			clk_ipb_o => clk_ipb,
			rst_ipb_o => rst_ipb,
			clk125_o => clk125,
			rst125_o => rst125,
			clk200 => clk200,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			nuke => nuke,
			soft_rst => soft_rst,
			leds => infra_leds,
			debug => open,
			mac_addr(47 downto 4) => MAC_ADDR(47 downto 4),
			mac_addr(3 downto 0) => dip_sw,
			ip_addr(31 downto 4) => IP_ADDR(31 downto 4),
			ip_addr(3 downto 0) => dip_sw,
			ipb_in => ipb_in,
			ipb_out => ipb_out
		);
		
	leds <= infra_leds when stealth_mode = '0' else "00";
	
	sfp_tx_disable <= '0';
	sfp_scl <= '1';
	sfp_sda <= '1';

	payload: entity work.payload
		port map(
			ipb_clk => clk_ipb,
			ipb_rst => rst_ipb,
			ipb_in => ipb_out,
			ipb_out => ipb_in,
			clk125 => clk125,
			rst125 => rst125,
			clk200 => clk200,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			nuke => nuke,
			soft_rst => soft_rst,
			stealth_mode => stealth_mode,
			userleds => leds_c,
			si5326_scl => si5326_scl,
			si5326_sda_o => si5326_sda_o,
			si5326_sda_i => si5326_sda,
			si5326_rstn => si5326_rstn,
			si5326_phase_inc => si5326_phase_inc,
			si5326_phase_dec => si5326_phase_dec,
			si5326_clk1_validn => si5326_clk1_validn,
			si5326_clk2_validn => si5326_clk2_validn,
			si5326_lol => si5326_lol,
			si5326_clk_sel => si5326_clk_sel,
			si5326_rate0 => si5326_rate0,
			si5326_rate1 => si5326_rate1,
			clk40_p => clk40_p,
			clk40_n => clk40_n,
			adc_cs => adc_spi_cs,
			adc_mosi => adc_spi_mosi,
			adc_miso => adc_spi_miso,
			adc_sclk => adc_spi_sclk,
			adc_d_p => adc_d_p,
			adc_d_n => adc_d_n,
			analog_scl => analog_scl,
			analog_sda_o => analog_sda_o,
			analog_sda_i => analog_sda,
			sync_in_p => sync_in_p,
			sync_in_n => sync_in_n,
			trig_in_p => trig_in_p,
			trig_in_n => trig_in_n,
			trig_out_p => trig_out_p,
			trig_out_n => trig_out_n,
			clk_pll_p => clk_pll_p,
			clk_pll_n => clk_pll_n
		);

	si5326_sda <= '0' when si5326_sda_o = '0' else 'Z';
	analog_sda <= '0' when analog_sda_o = '0' else 'Z';

end rtl;
