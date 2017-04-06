-- sc_io
--
-- Interfaces to board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_io.all;
use work.ipbus_reg_types.all;

entity sc_io is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
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
		adc_cs: out std_logic_vector(1 downto 0);
		adc_mosi: out std_logic;
		adc_miso: in std_logic_vector(1 downto 0);
		adc_sclk: out std_logic;
		analog_scl: out std_logic;
		analog_sda_o: out std_logic;
		analog_sda_i: in std_logic
	);

end sc_io;

architecture rtl of sc_io is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal clkdiv: std_logic_vector(0 downto 0);
	signal adc_ss: std_logic_vector(1 downto 0);
	signal adc_miso_i: std_logic;
	signal adc_d: std_logic_vector(11 downto 0);
	signal adc_v: std_logic;

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
      sel => ipbus_sel_sc_io(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl,
			qmask(0) => X"0000000F"
		);
		
	stat(0) <= X"0000000" & '0' & si5326_clk2_validn & si5326_clk1_validn & si5326_lol;
 
-- I2C master
	
	i2c_clock: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_CLOCK_I2C),
			ipb_out => ipbr(N_SLV_CLOCK_I2C),
			scl => si5326_scl,
			sda_o => si5326_sda_o,
			sda_i => si5326_sda_i
		);

	si5326_rstn <= not ctrl(0)(0);
	si5326_phase_inc <= '0';
	si5326_phase_dec <= '0';
	si5326_clk_sel <= ctrl(0)(1);
	si5326_rate0 <= ctrl(0)(2);
	si5326_rate1 <= ctrl(0)(3);
	
-- I2C master to analogue board
	
	i2c_analog: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_ANALOG_I2C),
			ipb_out => ipbr(N_SLV_ANALOG_I2C),
			scl => analog_scl,
			sda_o => analog_sda_o,
			sda_i => analog_sda_i
		);

-- SPI master
	
	spi: entity work.ipbus_spi
		generic map(
			N_SS => 2
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_SPI),
			ipb_out => ipbr(N_SLV_SPI),
			ss => adc_ss,
			mosi => adc_mosi,
			miso => adc_miso_i, 
			sclk => adc_sclk 
		);

	adc_cs <= not adc_ss;
	adc_miso_i <= and_reduce(adc_miso);
	
-- Clock frequency counter
	
	div: entity work.freq_ctr_div
		port map(
			clk(0) => clk40,
			clkdiv => clkdiv
		);
		
	ctr: entity work.freq_ctr
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_FREQ_CTR),
			ipb_out => ipbr(N_SLV_FREQ_CTR),
			clkdiv => clkdiv
		);
		
end rtl;
