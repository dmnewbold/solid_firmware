-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_top.all;

use work.top_decl.all;

library unisim;
use unisim.VComponents.all;

entity payload is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		rst125: in std_logic;
		clk200: in std_logic;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userleds: out std_logic_vector(2 downto 0);
		addr: in std_logic_vector(7 downto 0);
		sel: out std_logic_vector(4 downto 0);
		i2c_scl: out std_logic; -- I2C bus via CPLD
		i2c_sda_i: in std_logic;
		i2c_sda_o: out std_logic;
		spi_csn: out std_logic;
		spi_mosi: out std_logic;
		spi_miso: in std_logic;
		spi_sclk: out std_logic;
		clkgen_lol: in std_logic;
		clkgen_rstn: out std_logic;
		clk_p: in std_logic;
		clk_n: in std_logic;
		t_sync: in std_logic;
		t_trig: in std_logic;
		t_busy: out std_logic;
		adc_d_p: in std_logic_vector(63 downto 0);
		adc_d_n: in std_logic_vector(63 downto 0)
	);

end payload;

architecture rtl of payload is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal clk40, rst40, clk160, clk280: std_logic;
	signal sync_in, sync_out: std_logic;
	signal ctrl_rst_mmcm, locked, idelayctrl_rdy, ctrl_rst_idelayctrl, ctrl_sync_mode: std_logic;
	signal ctrl_chan: std_logic_vector(7 downto 0);
	signal sync_ctrl: std_logic_vector(3 downto 0);
	signal adc_d: std_logic_vector(63 downto N_CHAN);
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

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 2
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl,
			qmask(0) => X"FFFFFF0F"
		);
		
	stat(0) <= X"a753" & FW_REV;
	stat(1) <= X"00000" & addr & '0' & chan_err & idelayctrl_rdy & locked;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	ctrl_rst_mmcm <= ctrl(0)(2);
	ctrl_rst_idelayctrl <= ctrl(0)(3);
	ctrl_sync_mode <= ctrl(0)(4);
	ctrl_chan <= ctrl(0)(15 downto 8);
	sel <= ctrl(0)(28 downto 24);
	userleds <= ctrl(0)(31 downto 29);
	
-- Required for timing alignment at inputs

	idelctrl: IDELAYCTRL -- Docs claim this should be replicated as necessary
		port map(
			rdy => idelayctrl_rdy,
			refclk => clk200,
			rst => ctrl_rst_idelayctrl -- Careful, need at least 50ns reset pulse here
		);

-- Board IO

	io: entity work.sc_io_64chan
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_IO),
			ipb_out => ipbr(N_SLV_IO),
			clk40 => clk40,
			i2c_scl => i2c_scl,
			i2c_sda_i => i2c_sda_i,
			i2c_sda_o => i2c_sda_o,
			spi_csn => spi_csn,
			spi_mosi => spi_mosi,
			spi_miso => spi_miso,
			spi_sclk => spi_sclk,
			clkgen_lol => clkgen_lol,
			clkgen_rstn => clkgen_rstn
		);
	
-- Timing

	timing: entity work.sc_timing
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_TIMING),
			ipb_out => ipbr(N_SLV_TIMING),
			rst_mmcm => ctrl_rst_mmcm,
			locked => locked,
			clk_in_p => clk_p,
			clk_in_n => clk_n,
			clk40 => clk40,
			rst40 => rst40,
			clk160 => clk160,
			clk280 => clk280,
			sync_in => t_sync,
			sync_out => t_busy,
			ext_trig_in => t_trig,
			sctr => sctr,
			chan_sync_ctrl => sync_ctrl,
			trig_en => trig_en,
			nzs_en => nzs_en,
			zs_en => zs_en,
			rand => rand
		);

-- Data channels

	chans: entity work.sc_channels
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_CHAN),
			ipb_out => ipbr(N_SLV_CHAN),
			chan => ctrl_chan,
			clk40 => clk40,
			rst40 => rst40,
			clk160 => clk160,
			clk280 => clk280,
			d_p => adc_d_p(N_CHAN - 1 downto 0),
			d_n => adc_d_n(N_CHAN - 1 downto 0),
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
			ipb_in => ipbw(N_SLV_TRIG),
			ipb_out => ipbr(N_SLV_TRIG),
			clk40 => clk40,
			rst40 => rst40,
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
			ipb_in => ipbw(N_SLV_TLINK),
			ipb_out => ipbr(N_SLV_TLINK),
			clk125 => clk125,
			rst125 => rst125,
			clk40 => clk40,
			rst40 => rst40,
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
			board_id => addr,
			clk40 => clk40,
			rst40 => rst40,
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
		
-- Unused channels

	cgen: for i in 63 downto N_CHAN generate
	
		attribute DONT_TOUCH: string;
		attribute DONT_TOUCH of buf: label is "TRUE";
	
	begin
	
		buf: IBUFDS
			port map(
				i => adc_d_p(i),
				ib => adc_d_n(i),
				o => open
			);

	end generate;
	
end rtl;
