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
		leds: out std_logic_vector(1 downto 0); -- TE712 LEDs
		led: out std_logic; -- carrier LEDs
		addr: in std_logic_vector(7 downto 0); -- carrier switches
		sel: out std_logic_vector(4 downto 0); -- bus select lines to CPLD
		i2c_scl: out std_logic; -- I2C bus via CPLD
		i2c_sda_i: in std_logic;
		i2c_sda_o: out std_logic;
		spi_csn: out std_logic;
		spi_mosi: out std_logic;
		spi_miso: in std_logic;
		spi_sclk: out std_logic;
		clkgen_lol: in std_logic; -- si5345 LOL
		clkgen_rstn: out std_logic; -- si5345 RST
		clk_p: in std_logic; -- clk from si5345
		clk_n: in std_logic;
		sync_in: in std_logic; -- IO via timing interface
		trig_in: in std_logic;
		trig_out: out std_logic;
		adc_d_p: inout std_logic_vector(63 downto 0); -- ADC serial input data
		adc_d_n: inout std_logic_vector(63 downto 0)
	);

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, clk125, rst125, nuke, soft_rst, userled, clk200, stealth_mode: std_logic;
	signal pllclk, pllrefclk: std_logic;
	signal ipb_out: ipb_wbus;
	signal ipb_in: ipb_rbus;
	signal debug: std_logic_vector(3 downto 0);
	signal addrn: std_logic_vector(7 downto 0);
	signal infra_leds: std_logic_vector(1 downto 0);
	
begin

-- Infrastructure

	addrn <= not addr;

	infra: entity work.pc051b_infra -- Should work for artix also...
		port map(
			eth_clk_p => eth_clk_p,
			eth_clk_n => eth_clk_n,
			eth_tx_p => eth_tx_p,
			eth_tx_n => eth_tx_n,
			eth_rx_p => eth_rx_p,
			eth_rx_n => eth_rx_n,
			sfp_los => '0',
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
			mac_addr(47 downto 8) => MAC_ADDR(47 downto 8),
			mac_addr(7 downto 0) => addrn,
			ip_addr(31 downto 8) => IP_ADDR(31 downto 8),
			ip_addr(7 downto 0) => addrn,
			ipb_in => ipb_in,
			ipb_out => ipb_out
		);
		
	leds <= infra_leds when stealth_mode = '0' else "00";
		
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
			userled => led,
			addr => addrn,
			sel => sel,
			i2c_scl => i2c_scl,
			i2c_sda_i => i2c_sda_i,
			i2c_sda_o => i2c_sda_o,
			spi_csn => spi_csn,
			spi_mosi => spi_mosi,
			spi_miso => spi_miso,
			spi_sclk => spi_sclk,
			clkgen_lol => clkgen_lol,
			clkgen_rstn => clkgen_rstn,
			clk_p => clk_p,
			clk_n => clk_n,
			sync_in => sync_in,
			trig_in => trig_in,
			trig_out => trig_out,
			adc_d_p => adc_d_p,
			adc_d_n => adc_d_n
		);

end rtl;
