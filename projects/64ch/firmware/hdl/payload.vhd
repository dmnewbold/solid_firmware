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
	signal clk40: std_logic;
	signal ctrl_rst_mmcm, locked, idelayctrl_rdy, ctrl_rst_idelayctrl: std_logic;
	signal ctrl_chan: std_logic_vector(7 downto 0);
	signal chan_err: std_logic;

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
	stat(1) <= X"00000" & addr & '0' & chan_err & idelayctrl_rdy & locked;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	ctrl_rst_mmcm <= ctrl(0)(2);
	ctrl_rst_idelayctrl <= ctrl(0)(3);
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
	
-- DAQ core

	daq: entity work.sc_daq
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in => ipbw(N_SLV_DAQ),
			ipb_out => ipbr(N_SLV_DAQ),
			rst_mmcm => ctrl_rst_mmcm,
			locked => locked,
			clk_in_p => clk_p,
			clk_in_n => clk_n,
			clk40 => clk40,
			sync_in => t_sync,
			sync_out => t_busy,
			trig_in => t_trig,
			chan => ctrl_chan,
			chan_err => chan_err,
			d_p => adc_d_p,
			d_n => adc_d_n,
			clk125 => clk125,
			rst125 => rst125,
			board_id => addr
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
