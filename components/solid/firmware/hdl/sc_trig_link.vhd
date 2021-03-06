-- sc_trig_link
--
-- Trigger communication between planes
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity sc_trig_link is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		rst125: in std_logic;
		pllclk: in std_logic;
		pllrefclk: in std_logic;
		link_ok: out std_logic;
		id: in std_logic_vector(7 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		sctr: in std_logic_vector(15 downto 0);
		d: in std_logic_vector(15 downto 0);
		d_valid: in std_logic;
		q: out std_logic_vector(15 downto 0);
		q_valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_link;

architecture rtl of sc_trig_link is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal ctrl_en_us_tx_phy, ctrl_en_us_rx_phy, ctrl_en_us_tx, ctrl_en_us_rx: std_logic;
	signal ctrl_en_ds_tx_phy, ctrl_en_ds_rx_phy, ctrl_en_ds_tx, ctrl_en_ds_rx: std_logic;
	signal ctrl_loopback_us, ctrl_loopback_ds: std_logic_vector(2 downto 0);
	signal rdy_us_tx, rdy_us_rx, rdy_ds_tx, rdy_ds_rx: std_logic;
	signal stat_us_tx, stat_ds_tx: std_logic_vector(1 downto 0);
	signal stat_us_rx, stat_ds_rx: std_logic_vector(2 downto 0);
	signal txd_us, rxd_us, txd_ds, rxd_ds: std_logic_vector(15 downto 0);
	signal txk_us, rxk_us, txk_ds, rxk_ds: std_logic_vector(1 downto 0);
	signal id_us, id_ds: std_logic_vector(7 downto 0);
	signal qv_us, qv_ds, ack_us, ack_ds, data_good_us, data_good_ds: std_logic;
	signal q_us, q_ds: std_logic_vector(15 downto 0);
	signal pstat_us_tx, pstat_ds_tx: std_logic_vector(1 downto 0);
	signal pstat_us_rx, pstat_ds_rx: std_logic_vector(4 downto 0);

begin

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);
		
	ctrl_en_us_tx_phy <= ctrl(0)(0);
	ctrl_en_us_rx_phy <= ctrl(0)(1);
	ctrl_en_us_tx <= ctrl(0)(2);
	ctrl_en_us_rx <= ctrl(0)(3);
	ctrl_en_ds_tx_phy <= ctrl(0)(4);
	ctrl_en_ds_rx_phy <= ctrl(0)(5);
	ctrl_en_ds_tx <= ctrl(0)(6);
	ctrl_en_ds_rx <= ctrl(0)(7);
	ctrl_loopback_us <= ctrl(0)(10 downto 8);
	ctrl_loopback_ds <= ctrl(0)(14 downto 12);
	stat(0) <= X"00" & id_us & '0' & pstat_us_rx & pstat_us_tx & '0' & stat_us_rx & stat_us_tx & rdy_us_rx & rdy_us_tx;
	stat(1) <= X"00" & id_ds & '0' & pstat_ds_rx & pstat_ds_tx & '0' & stat_ds_rx & stat_ds_tx & rdy_ds_rx & rdy_ds_tx;

-- MGTs

	mgt_us: entity work.sc_trig_mgt_wrapper
		port map(
			sysclk => clk,
			tx_en => ctrl_en_us_tx_phy,
			rx_en => ctrl_en_us_rx_phy,
			tx_good => rdy_us_tx,
			rx_good => rdy_us_rx,
			tx_stat => stat_us_tx,
			rx_stat => stat_us_rx,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			loopback => ctrl_loopback_us,
			clk125 => clk125,
			txd => txd_us,
			txk => txk_us,
			rxd => rxd_us,
			rxk => rxk_us
		);
			
	mgt_ds: entity work.sc_trig_mgt_wrapper
		port map(
			sysclk => clk,
			tx_en => ctrl_en_ds_tx_phy,
			rx_en => ctrl_en_ds_rx_phy,
			tx_good => rdy_ds_tx,
			rx_good => rdy_ds_rx,
			tx_stat => stat_ds_tx,
			rx_stat => stat_ds_rx,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			loopback => ctrl_loopback_ds,
			clk125 => clk125,
			txd => txd_ds,
			txk => txk_ds,
			rxd => rxd_ds,
			rxk => rxk_ds
		);
		
-- Data pipeline

	pipe_from_us: entity work.sc_trig_link_pipe
		port map(
			tx_en => ctrl_en_us_tx,
			rx_en => ctrl_en_us_rx,
			clk125 => clk125,
			rxd => rxd_us,
			rxk => rxk_us,
			link_good => rdy_us_rx,
			txd => txd_ds,
			txk => txk_ds,
			clk40 => clk40,
			rst40 => rst40,
			sctr => sctr,
			d => d,
			dv => d_valid,
			q => q_us,
			qv => qv_us,
			ack => ack_us,
			stat_rx => pstat_us_rx,
			stat_tx => pstat_us_tx,
			my_id => id,
			remote_id => id_us,
			data_good => data_good_us
		);

	pipe_from_ds: entity work.sc_trig_link_pipe
		port map(
			tx_en => ctrl_en_ds_tx,
			rx_en => ctrl_en_ds_rx,
			clk125 => clk125,
			rxd => rxd_ds,
			rxk => rxk_ds,
			link_good => rdy_ds_rx,
			txd => txd_us,
			txk => txk_us,
			clk40 => clk40,
			rst40 => rst40,
			sctr => sctr,
			d => d,
			dv => d_valid,
			q => q_ds,
			qv => qv_ds,
			ack => ack_ds,
			stat_rx => pstat_ds_rx,
			stat_tx => pstat_ds_tx,
			my_id => id,
			remote_id => id_ds,
			data_good => data_good_ds
		);
		
-- Merger

	q <= q_us when qv_us = '1' else q_ds;
	q_valid <= qv_us or qv_ds;
	ack_us <= ack and qv_us;
	ack_ds <= ack and not qv_us;
	
	link_ok <= '0';

end rtl;
