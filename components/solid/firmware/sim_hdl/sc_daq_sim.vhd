-- daq.vhd
--
-- Core components of the DAQ, independent of board type
--
-- Dave Newbold, May 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;

use work.top_decl.all;

entity sc_daq_sim is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in_timing: in ipb_wbus;
		ipb_out_timing: out ipb_rbus;
		ipb_in_chan: in ipb_wbus;
		ipb_out_chan: out ipb_rbus;
		ipb_in_trig: in ipb_wbus;
		ipb_out_trig: out ipb_rbus;
		ipb_in_tlink: in ipb_wbus;
		ipb_out_tlink: out ipb_rbus;		
		ipb_in_roc: in ipb_wbus;
		ipb_out_roc: out ipb_rbus;
		rst_mmcm: in std_logic;
		locked: out std_logic;
		clk_in_p: in std_logic;
		clk_in_n: in std_logic;
		clk40: out std_logic;
		sync_in: in std_logic;
		sync_out: out std_logic;
		trig_in: in std_logic;
		chan: in std_logic_vector(7 downto 0);
		d_p: in std_logic_vector(N_CHAN - 1 downto 0);
		d_n: in std_logic_vector(N_CHAN - 1 downto 0);
		clk125: in std_logic;
		rst125: in std_logic;
		board_id: in std_logic_vector(7 downto 0)
	);

end sc_daq_sim;

architecture rtl of sc_daq_sim is

	signal clk40_i, rst40_i, clk160, clk280: std_logic;
	signal sync_ctrl: std_logic_vector(3 downto 0);
	signal sctr: std_logic_vector(47 downto 0);
	signal trig_en, nzs_en, zs_en, chan_err: std_logic;
	signal trig_keep, trig_flush, trig_veto: std_logic_vector(N_CHAN - 1 downto 0);
	signal chan_trig: sc_trig_array;
	signal link_d, link_q: std_logic_vector(15 downto 0);
	signal link_d_valid, link_q_valid, link_ack: std_logic;
	signal ro_chan: std_logic_vector(7 downto 0);
	signal ro_d, trig_d: std_logic_vector(31 downto 0);
	signal ro_blkend, ro_empty, ro_ren, en_ro, trig_sync, trig_blkend, trig_we, trig_roc_veto: std_logic;
	signal rand: std_logic_vector(31 downto 0);

begin
	
-- Timing

	timing: entity work.sc_timing
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in_timing,
			ipb_out => ipb_out_timing,
			rst_mmcm => rst_mmcm,
			locked => locked,
			clk_in_p => clk_in_p,
			clk_in_n => clk_out_n,
			clk40 => clk40_i,
			rst40 => rst40_i,
			clk160 => clk160,
			clk280 => clk280,
			sync_in => sync_in,
			sync_out => sync_out,
			ext_trig_in => trig_in,
			sctr => sctr,
			chan_sync_ctrl => sync_ctrl,
			trig_en => trig_en,
			nzs_en => nzs_en,
			zs_en => zs_en,
			rand => rand
		);
		
	clk40 <= clk40_i;

-- Data channels

	chans: entity work.sc_channels
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipb_in_chan,
			ipb_out => ipb_out_chan,
			chan => chan,
			clk40 => clk40_i,
			rst40 => rst40_i,
			clk160 => clk160,
			clk280 => clk280,
			d_p => adc_d_p,
			d_n => adc_d_n,
			sync_ctrl => sync_ctrl,
			sctr => sctr(13 downto 0),
			rand => rand(13 downto 0),
			nzs_en => nzs_en,
			zs_en => zs_en,
			keep => trig_keep,
			flush => trig_flush,
			err => chan_err,
			veto => trig_veto,
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
			ipb_in => ipb_in_trig,
			ipb_out => ipb_out_trig,
			clk40 => clk40_i,
			rst40 => rst40_i,
			clk160 => clk160,
			trig_en => trig_en,
			zs_en => zs_en,
			sctr => sctr,
			rand => rand,
			keep => trig_keep,
			flush => trig_flush,
			veto => trig_veto,
			trig => chan_trig,
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
			ipb_in => ipb_in_tlink,
			ipb_out => ipb_out_tlink,
			clk125 => clk125,
			rst125 => rst125,
			clk40 => clk40_i,
			rst40 => rst40_i,
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
			ipb_in => ipb_in_roc,
			ipb_out => ipb_out_roc,
			board_id => board_id,
			clk40 => clk40_i,
			rst40 => rst40_i,
			rand => rand,
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
