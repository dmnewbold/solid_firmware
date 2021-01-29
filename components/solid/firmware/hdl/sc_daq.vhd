-- daq.vhd
--
-- Core components of the DAQ, independent of board type
--
-- Dave Newbold, May 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_decode_sc_daq.all;

use work.top_decl.all;

entity sc_daq is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rst_mmcm: in std_logic;
		locked: out std_logic;
		clk_in_p: in std_logic;
		clk_in_n: in std_logic;
		clk40: out std_logic;
		sync_in: in std_logic;
		trig_in: in std_logic;
		trig_out: out std_logic;
		led_out: out std_logic;
		chan: in std_logic_vector(7 downto 0);
		chan_err: out std_logic;
		d_p: in std_logic_vector(N_CHAN - 1 downto 0);
		d_n: in std_logic_vector(N_CHAN - 1 downto 0);
		clk125: in std_logic;
		rst125: in std_logic;
		pllclk: in std_logic;
		pllrefclk: in std_logic;
		board_id: in std_logic_vector(7 downto 0)
	);

end sc_daq;

architecture rtl of sc_daq is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal clk40_i, rst40_i, clk80, clk280: std_logic;
	signal sync_ctrl: std_logic_vector(3 downto 0);
	signal sctr: std_logic_vector(47 downto 0);
	signal dr_en, nzs_en, zs_en: std_logic;
	signal trig_keep, trig_flush: std_logic;
	signal trig_kack: std_logic_vector(N_CHAN - 1 downto 0);
	signal fake: std_logic_vector(13 downto 0);
	signal rand_trig, thresh_hit: std_logic;
	signal nzs_blks: std_logic_vector(3 downto 0);
	signal zs_sel: std_logic_vector(1 downto 0);
	signal chan_trig: sc_trig_array;
	signal link_d, link_q: std_logic_vector(15 downto 0);
	signal link_d_valid, link_q_valid, link_ack, link_ok: std_logic;
	signal ro_chan: std_logic_vector(7 downto 0);
	signal ro_d, trig_d: std_logic_vector(31 downto 0);
	signal ro_blkend, ro_empty, ro_ren, trig_sync, trig_blkend, trig_we, trig_roc_veto: std_logic;
	signal rand: std_logic_vector(31 downto 0);

begin
	
-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_sc_daq(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
 
-- Timing

	timing: entity work.sc_timing
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TIMING),
			ipb_out => ipbr(N_SLV_TIMING),
			rst_mmcm => rst_mmcm,
			locked => locked,
			clk_in_p => clk_in_p,
			clk_in_n => clk_in_n,
			clk40 => clk40_i,
			rst40 => rst40_i,
			clk80 => clk80,
			clk280 => clk280,
			sync_in => sync_in,
			trig_in => trig_in,
			led => led_out,
			sctr => sctr,
			chan_sync_ctrl => sync_ctrl,
			dr_en => dr_en,
			nzs_en => nzs_en,
			zs_en => zs_en,
			rand => rand,
			nzs_blks => nzs_blks
		);
		
	clk40 <= clk40_i;
	
-- Fake data generator

	faker: entity work.sc_fake
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FAKE),
			ipb_out => ipbr(N_SLV_FAKE),
			clk40 => clk40_i,
			rst40 => rst40_i,
			rand => rand,
			sctr => sctr(7 downto 0),
			fake => fake
		);
		
-- Random trigger generator
			
	rtrig: entity work.sc_rtrig
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_RTRIG),
			ipb_out => ipbr(N_SLV_RTRIG),	
			clk40 => clk40_i,
			rst40 => rst40_i,
			rand => rand,
			sctr => sctr,
			trig => rand_trig
		);
			
-- Data channels

	chans: entity work.sc_channels
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CHAN),
			ipb_out => ipbr(N_SLV_CHAN),
			chan => chan,
			clk40 => clk40_i,
			rst40 => rst40_i,
			clk80 => clk80,
			clk280 => clk280,
			d_p => d_p,
			d_n => d_n,
			sync_ctrl => sync_ctrl,
			zs_sel => zs_sel,
			sctr => sctr,
			fake => fake,
			nzs_blks => nzs_blks,
			nzs_en => nzs_en,
			zs_en => zs_en,
			dr_en => dr_en,
			keep => trig_keep,
			kack => trig_kack,
			err => chan_err,
			trig => chan_trig,
			dr_chan => ro_chan,
			clk_dr => ipb_clk,
			q => ro_d,
			q_blkend => ro_blkend,
			q_empty => ro_empty,
			ren => ro_ren
		);
		
-- Trigger

	trig: entity work.sc_trig
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TRIG),
			ipb_out => ipbr(N_SLV_TRIG),
			clk40 => clk40_i,
			rst40 => rst40_i,
			trig_en => dr_en,
			zs_en => zs_en,
			sctr => sctr,
			keep => trig_keep,
			kack => trig_kack,
			zs_sel => zs_sel,
			trig => chan_trig,
			rand_trig => rand_trig,
			ext_trig_in => trig_in,
			ext_trig_out => trig_out,
			ro_d => trig_d,
			ro_blkend => trig_blkend,
			ro_we => trig_we,
			ro_veto => trig_roc_veto,
			q => link_d,
			q_valid => link_d_valid,
			d => link_q,
			d_valid => link_q_valid,
			d_ack => link_ack
		);

-- Trigger serial links

	tlink: entity work.sc_trig_link
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TLINK),
			ipb_out => ipbr(N_SLV_TLINK),
			clk125 => clk125,
			rst125 => rst125,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			link_ok => link_ok,
			id => board_id,
			clk40 => clk40_i,
			rst40 => rst40_i,
			sctr => sctr(15 downto 0),
			d => link_d,
			d_valid => link_d_valid,
			q => link_q,
			q_valid => link_q_valid,
			ack => link_ack
		);
		
-- Readout

	roc: entity work.sc_roc
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_ROC),
			ipb_out => ipbr(N_SLV_ROC),
			board_id => board_id,
			clk40 => clk40_i,
			rst40 => rst40_i,
			d_trig => trig_d,
			blkend_trig => trig_blkend,
			we_trig => trig_we,
			veto_trig => trig_roc_veto,
			chan => ro_chan,
			d => ro_d,
			blkend => ro_blkend,
			empty => ro_empty,
			ren => ro_ren
		);
	
end rtl;
