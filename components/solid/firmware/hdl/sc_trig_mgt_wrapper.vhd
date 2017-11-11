-- sc_trig_mgt_wrapper
--
-- Wrapper for GTP blocks
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
		tx_rdy: out std_logic;
		rx_rdy: out std_logic;
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

	signal tx_rst_i, rx_rst_i: std_logic;

begin

	tx_rst_i <= tx_rst or not en;
	rx_rst_i <= rx_rst or not en;

	sc_trig_link_mgt_i: sc_trig_link_mgt
		port map(
			SYSCLK_IN => sysclk,
			SOFT_RESET_TX_IN => tx_rst_i,
			SOFT_RESET_RX_IN => rx_rst_i,
			DONT_RESET_ON_DATA_ERROR_IN => '0',
			GT0_TX_FSM_RESET_DONE_OUT => tx_rdy,
			GT0_RX_FSM_RESET_DONE_OUT => rx_rdy,
			GT0_DRP_BUSY_OUT => open,
			GT0_DATA_VALID_IN => '1',
			gt0_drpaddr_in => (others => '0'), -- Not using DRP
			gt0_drpclk_in => clk,
			gt0_drpdi_in => (others => '0'),
			gt0_drpdo_out => open,
			gt0_drpen_in => '0',
			gt0_drprdy_out => open,
			gt0_drpwe_in => '0',
			gt0_loopback_in => loopback, -- Connect to sw bit
			gt0_rxpd_in => "00", -- No power down
			gt0_txpd_in => "00",
			gt0_eyescanreset_in => '0', -- God knows
			gt0_rxuserrdy_in => '0', -- See AR #68829
			gt0_eyescandataerror_out => open,
			gt0_eyescantrigger_in => '0',
			gt0_rxclkcorcnt_out => open,
			gt0_rxdata_out => rxd,
			gt0_rxusrclk_in => clk125,
			gt0_rxusrclk2_in => clk125,
			gt0_rxprbserr_out => open,
			gt0_rxprbssel_in => "000", -- No PRBS
			gt0_rxprbscntreset_in => '0',
			gt0_rxchariscomma_out => open,
			gt0_rxcharisk_out => rxk,
			gt0_rxdisperr_out => open, -- Connect this?
			gt0_rxnotintable_out => open, -- Connect this?
			gt0_gtprxn_in => open, -- Auto-connected by tools
			gt0_gtprxp_in => open,
			gt0_rxbufstatus_out => rx_stat,
			gt0_rxmcommaalignen_in => '1', -- We like alignment
			gt0_rxpcommaalignen_in => '1',
			gt0_dmonitorout_out => open, -- Don't need this
			gt0_rxlpmhfhold_in => '0', -- As per user guide
			gt0_rxlpmhfovrden_in => '0',
			gt0_rxlpmlfhold_in => '0',
			gt0_rxoutclk_out => open, -- We are doing clock correction, not needed
			gt0_rxoutclkfabric_out => open,
			gt0_gtrxreset_in => '0', -- Leave this to internal FSM
			gt0_rxlpmreset_in => '0',
			gt0_rxresetdone_out => open, -- Use FSM signals for monitoring
			gt0_gttxreset_in => '0', -- Leave this to internal FSM
			gt0_txuserrdy_in => '0', -- See AR #68829
			gt0_txdata_in => txd,
			gt0_txusrclk_in => clk125,
			gt0_txusrclk2_in => clk125,
			gt0_txelecidle_in => '0',
			gt0_txprbsforceerr_in => '0',
			gt0_txcharisk_in => txk,
			gt0_txbufstatus_out => tx_stat,
			gt0_gtptxn_out => open, -- Auto-connected by tools
			gt0_gtptxp_out => open,
			gt0_txoutclk_out => txclk_us,
			gt0_txoutclkfabric_out => open,
			gt0_txoutclkpcs_out => open,
			gt0_txresetdone_out => open, -- Use FSM signals for monitoring
			gt0_txprbssel_in => "000", -- No PRBS
			GT0_PLL0OUTCLK_IN => pllclk,
			GT0_PLL0OUTREFCLK_IN => pllrefclk,
			GT0_PLL0RESET_OUT => open, 
			GT0_PLL0LOCK_IN => '1',
			GT0_PLL0REFCLKLOST_IN => '0',      
			GT0_PLL1OUTCLK_IN => '0',
			GT0_PLL1OUTREFCLK_IN => '0'
		);

end rtl;
