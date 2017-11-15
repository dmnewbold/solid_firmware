-- sc_trig_mgt_sim
--
-- Wrapper for GTP blocks; dummy version for sim
--
-- Dave Newbold, October 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sc_trig_mgt_wrapper is
	port(
		sysclk: in std_logic; -- DRP clock
		en: in std_logic;
		tx_rst: in std_logic;
		rx_rst: in std_logic;
		tx_good: out std_logic;
		rx_good: out std_logic;
		tx_stat: out std_logic_vector(1 downto 0);
		rx_stat: out std_logic_vector(2 downto 0);
		pllclk: in std_logic;
		pllrefclk: in std_logic;
		loopback: in std_logic_vector(2 downto 0);
		clk125: in std_logic;
		txd: in std_logic_vector(15 downto 0);
		txk: in std_logic;
		rxd: out std_logic_vector(15 downto 0);
		rxk: out std_logic
	)

end sc_trig_mgt_wrapper;

architecture rtl of sc_trig_mgt_wrapper is

begin

	tx_good <= en;
	rx_good <= en;
	tx_stat <= "00";
	rx_stat <= "000";
	rxd <= txd when rising_edge(clk125);
	rxk <= txk when rising_edge(clk125);

end rtl;
