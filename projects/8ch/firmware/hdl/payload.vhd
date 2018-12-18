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
		pllclk: in std_logic;
		pllrefclk: in std_logic;
		nuke: out std_logic;
		soft_rst: out std_logic;
		stealth_mode: out std_logic;
		userleds: out std_logic_vector(3 downto 0);
		si5326_scl: out std_logic;
		si5326_sda_o: out std_logic;
		si5326_sda_i: in std_logic;
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
		adc_cs: out std_logic_vector(1 downto 0);
		adc_mosi: out std_logic;
		adc_miso: in std_logic_vector(1 downto 0);
		adc_sclk: out std_logic;
		adc_d_p: in std_logic_vector(N_CHAN - 1 downto 0);
		adc_d_n: in std_logic_vector(N_CHAN - 1 downto 0);
		analog_scl: out std_logic;
		analog_sda_i: in std_logic;
		analog_sda_o: out std_logic;
		sync_in_p: in std_logic;
		sync_in_n: in std_logic;
		trig_in_p: in std_logic;
		trig_in_n: in std_logic;
		trig_out_p: out std_logic;
		trig_out_n: out std_logic;		
		clk_pll_p: out std_logic;
		clk_pll_n: out std_logic
	);

end payload;

architecture rtl of payload is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal clk40: std_logic;
	signal sync_in, trig_in, trig_out: std_logic;
	signal ctrl_rst_mmcm, locked, idelayctrl_rdy, ctrl_rst_idelayctrl, ctrl_sync_mode, ctrl_stealth_mode: std_logic;
	signal ctrl_chan: std_logic_vector(7 downto 0);
	signal ctrl_board_id: std_logic_vector(7 downto 0);
	signal chan_err, led, daq_led: std_logic;

    attribute mark_debug: string;
    attribute mark_debug of ctrl_chan : signal is "true";
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
			q => ctrl
		);
		
	stat(0) <= X"a753" & FW_REV;
	stat(1) <= X"0000000" & "0" & chan_err & idelayctrl_rdy & locked;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	ctrl_rst_mmcm <= ctrl(0)(2);
	ctrl_rst_idelayctrl <= ctrl(0)(3);
	ctrl_sync_mode <= ctrl(0)(4);
	ctrl_stealth_mode <= ctrl(0)(5);
	ctrl_chan <= ctrl(0)(15 downto 8);
	ctrl_board_id <= ctrl(0)(23 downto 16);
	
	stealth_mode <= ctrl_stealth_mode;
	userleds <= "000" & daq_led when ctrl_stealth_mode = '0' else (others => '0');

-- Required for timing alignment at inputs

	idelctrl: IDELAYCTRL -- Docs claim this should be replicated as necessary
		port map(
			rdy => idelayctrl_rdy,
			refclk => clk200,
			rst => ctrl_rst_idelayctrl -- Careful, need at least 50ns reset pulse here
		);

-- Board IO

	io: entity work.sc_io
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_IO),
			ipb_out => ipbr(N_SLV_IO),
			clk40 => clk40,
			si5326_scl => si5326_scl,
			si5326_sda_o => si5326_sda_o,
			si5326_sda_i => si5326_sda_i,
			si5326_rstn => si5326_rstn,
			si5326_phase_inc => si5326_phase_inc,
			si5326_phase_dec => si5326_phase_dec,
			si5326_clk1_validn => si5326_clk1_validn,
			si5326_clk2_validn => si5326_clk2_validn,
			si5326_lol => si5326_lol,
			si5326_clk_sel => si5326_clk_sel,
			si5326_rate0 => si5326_rate0,
			si5326_rate1 => si5326_rate1,
			adc_cs => adc_cs,
			adc_mosi => adc_mosi,
			adc_miso => adc_miso,
			adc_sclk => adc_sclk,
			analog_scl => analog_scl,
			analog_sda_o => analog_sda_o,
			analog_sda_i => analog_sda_i
		);

-- iobufs

	ibuf_sync_in: IBUFDS
		port map(
			i => sync_in_p,
			ib => sync_in_n,
			o => sync_in
		);
		
	ibuf_trig_in: IBUFDS
		port map(
			i => trig_in_p,
			ib => trig_in_n,
			o => trig_in
		);
		
	obuf_trig_out: OBUFDS
		port map(
			i => trig_out,
			o => trig_out_p,
			ob => trig_out_n
		);
		
	obuf_clk_pll: OBUFDS
		port map(
			i => '0',
			o => clk_pll_p,
			ob => clk_pll_n
		);

-- DAQ core

	daq: entity work.sc_daq
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_DAQ),
			ipb_out => ipbr(N_SLV_DAQ),
			rst_mmcm => ctrl_rst_mmcm,
			locked => locked,
			clk_in_p => clk40_p,
			clk_in_n => clk40_n,
			clk40 => clk40,
			sync_in => sync_in,
			trig_in => trig_in,
			trig_out => trig_out,
			led_out => daq_led,
			chan => ctrl_chan,
			chan_err => chan_err,
			d_p => adc_d_p,
			d_n => adc_d_n,
			clk125 => clk125,
			rst125 => rst125,
			pllclk => pllclk,
			pllrefclk => pllrefclk,
			board_id => ctrl_board_id
		);
			
end rtl;
