-- sc_io
--
-- Interfaces to board chipset
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_io_64chan.all;
use work.ipbus_reg_types.all;

entity sc_io_64chan is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		i2c_scl: out std_logic; -- I2C bus via CPLD
		i2c_sda_i: in std_logic;
		i2c_sda_o: out std_logic;
		spi_csn: out std_logic;
		spi_mosi: out std_logic;
		spi_miso: in std_logic;
		spi_sclk: out std_logic;
		clkgen_lol: in std_logic;
		clkgen_rstn: out std_logic
	);

end sc_io_64chan;

architecture rtl of sc_io_64chan is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);
	signal clkdiv: std_logic_vector(0 downto 0);
	signal ss: std_logic_vector(0 downto 0);

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
      sel => ipbus_sel_sc_io_64chan(ipb_in.ipb_addr),
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
			qmask(0) => X"00000001"
		);
		
	stat(0) <= X"0000000" & "000" & clkgen_lol;
	clkgen_rstn <= not ctrl(0)(0);
 
-- I2C master
	
	i2c_clock: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => i2c_scl,
			sda_o => i2c_sda_o,
			sda_i => i2c_sda_i
		);

-- SPI master
	
	spi: entity work.ipbus_spi
		generic map(
			N_SS => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_SPI),
			ipb_out => ipbr(N_SLV_SPI),
			ss => ss,
			mosi => spi_mosi,
			miso => spi_miso, 
			sclk => spi_sclk 
		);

	spi_csn <= not ss(0);
	
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
