-- sc_trig_link
--
-- Trigger communication between planes
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;

entity sc_trig_link is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		rst125: in std_logic;
		link_ok: out std_logic;
		clk40: in std_logic;
		rst40: in std_logic;
		d: in std_logic_vector(15 downto 0);
		d_valid: in std_logic;
		q: out std_logic_vector(15 downto 0);
		q_valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_link;

architecture rtl of sc_trig_link is

	signal txclk_us, txclk_ds: std_logic;
	signal rxd_us, rxd_ds, txd_us, txd_ds: std_logic_vector(15 downto 0);
	signal rxc_us, rxc_ds, rxk_us, rxk_ds, txk_us, txk_ds: std_logic;

begin

	sc_trig_link_mgt_i: sc_trig_link_mgt
		port map(
			SYSCLK_IN => clk,
			SOFT_RESET_TX_IN => '0', -- Connect to sw reset bit
			SOFT_RESET_RX_IN => '0', -- Connect to sw reset bit
			DONT_RESET_ON_DATA_ERROR_IN => '1', -- Check this
			GT0_TX_FSM_RESET_DONE_OUT => open, -- Connect to sw status bit
			GT0_RX_FSM_RESET_DONE_OUT => open,
			GT0_DRP_BUSY_OUT => open, -- Not using DRP
			GT0_DATA_VALID_IN => '1', -- Connect to sw bit for now, comma det later
			GT1_TX_FSM_RESET_DONE_OUT => open, -- Connect to sw status bit
			GT1_RX_FSM_RESET_DONE_OUT => open,
			GT1_DRP_BUSY_OUT => open, -- Not using DRP
			GT1_DATA_VALID_IN => '1', -- Connect to sw bit for now, comma det later
			gt0_drpaddr_in => (others => '0'), -- Not using DRP
			gt0_drpclk_in => clk,
			gt0_drpdi_in => (others => '0'),
			gt0_drpdo_out => open,
			gt0_drpen_in => '0',
			gt0_drprdy_out => open,
			gt0_drpwe_in => '0',
			gt0_loopback_in => "000", -- Connect to sw bit
			gt0_rxpd_in => "00", -- No power down
			gt0_txpd_in => "00",
			gt0_eyescanreset_in => '0', -- God knows
			gt0_rxuserrdy_in => '0', -- See AR #68829
			gt0_eyescandataerror_out => open,
			gt0_eyescantrigger_in => '0',
			gt0_rxclkcorcnt_out => open,
			gt0_rxdata_out => rxd_us, -- The data output
			gt0_rxusrclk_in => txclk_ds, -- comes from txclkout of ds,
			gt0_rxusrclk2_in => txclk_ds,
			gt0_rxprbserr_out => open,
			gt0_rxprbssel_in => "000", -- No PRBS
			gt0_rxprbscntreset_in => '0',
			gt0_rxchariscomma_out => rxc_us, -- The chariscomma
			gt0_rxcharisk_out => rxk_us, -- The charisk
			gt0_rxdisperr_out => open, -- Connect this?
			gt0_rxnotintable_out => open, -- Connect this?
			gt0_gtprxn_in => open, -- Auto-connected by tools
			gt0_gtprxp_in => open,
			gt0_rxbufstatus_out => open, -- Might want to connect this to sw status register
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
			gt0_txdata_in => txd_us, -- The data input
			gt0_txusrclk_in => txclk_us,
			gt0_txusrclk2_in => txclk_us,
			gt0_txelecidle_in => '0',
			gt0_txprbsforceerr_in => '0',
			gt0_txcharisk_in => txk_us, -- charisk
			gt0_txbufstatus_out => open, -- Might want to connect this to sw status register
			gt0_gtptxn_out => open, -- Auto-connected by tools
			gt0_gtptxp_out => open,
			gt0_txoutclk_out => txclk_us,
			gt0_txoutclkfabric_out => open,
			gt0_txoutclkpcs_out => open,
			gt0_txresetdone_out => open, -- Use FSM signals for monitoring
			gt0_txprbssel_in => "000", -- No PRBS
			gt1_drpaddr_in => (others => '0'), -- Not using DRP
			gt1_drpclk_in => clk,
			gt1_drpdi_in => (others => '0'),
			gt1_drpdo_out => open,
			gt1_drpen_in => '0',
			gt1_drprdy_out => open,
			gt1_drpwe_in => '0',
			gt1_loopback_in => "000", -- Connect to sw bit
			gt1_rxpd_in => "00", -- No power down
			gt1_txpd_in => "00",
			gt1_eyescanreset_in => '0', -- God knows
			gt1_rxuserrdy_in => '0', -- See AR #68829
			gt1_eyescandataerror_out => open,
			gt1_eyescantrigger_in => '0',
			gt1_rxclkcorcnt_out => open,
			gt1_rxdata_out => rxd_ds,
			gt1_rxusrclk_in => txclk_us, -- comes from txclkout of us
			gt1_rxusrclk2_in => txclk_us,
			gt1_rxprbserr_out => open,
			gt1_rxprbssel_in => "000", -- No PRBS
			gt1_rxprbscntreset_in => '0',
			gt1_rxchariscomma_out => rxc_ds,
			gt1_rxcharisk_out => rxk_ds,
			gt1_rxdisperr_out => open, -- Connect this?
			gt1_rxnotintable_out => open, -- Connect this?
			gt1_gtprxn_in => open, -- Auto-connected by tools
			gt1_gtprxp_in => open, -- Auto-connected by tools
			gt1_rxbufstatus_out => open, -- Might want to connect this to sw status register
			gt1_rxmcommaalignen_in => '1', -- We like alignment
			gt1_rxpcommaalignen_in => '1',
			gt1_dmonitorout_out => open, -- Don't need this
			gt1_rxlpmhfhold_in => '0', -- As per user guide
			gt1_rxlpmhfovrden_in => '0',
			gt1_rxlpmlfhold_in => '0',
			gt1_rxoutclk_out => open, -- We are doing clock correction, not needed
			gt1_rxoutclkfabric_out => open,
			gt1_gtrxreset_in => '0', -- Leave this to internal FSM
			gt1_rxlpmreset_in => '0',
			gt1_rxresetdone_out => open, -- Use FSM signals for monitoring
			gt1_gttxreset_in => '0', -- Leave this to internal FSM
			gt1_txuserrdy_in => '0', -- See AR #68829
			gt1_txdata_in => txd_ds, -- The data input
			gt1_txusrclk_in => txclk_ds,
			gt1_txusrclk2_in => txclk_ds,
			gt1_txelecidle_in => '0',
			gt1_txprbsforceerr_in => '0',
			gt1_txcharisk_in => txk_ds,
			gt1_txbufstatus_out => open, -- Might want to connect this to sw status register
			gt1_gtptxn_out => open, -- Auto-connected by tools
			gt1_gtptxp_out => open,
			gt1_txoutclk_out => txclk_ds,
			gt1_txoutclkfabric_out => open,
			gt1_txoutclkpcs_out => open,
			gt1_txresetdone_out => open, -- Use FSM signals for monitoring
			gt1_txprbssel_in => "000", -- No PRBS
			GT0_PLL0OUTCLK_IN => pllclk,
			GT0_PLL0OUTREFCLK_IN => pllrefclk
			GT0_PLL0RESET_OUT => open, -- We are slave to another MGT block
			GT0_PLL0LOCK_IN => '1', -- Dodgy, but hopefully will work
			GT0_PLL0REFCLKLOST_IN => '0',
			GT0_PLL1OUTCLK_IN => '0',
			GT0_PLL1OUTREFCLK_IN => '0'
		);

	txd_us <= (others => '0');
	txk_us <= '0',
	txd_ds <= (others => '0');
	txk_ds <= '0';
		
	ipb_out <= IPB_RBUS_NULL;
	q <= (others => '0');
	q_valid <= '0';
	link_ok <= '0';

end rtl;
