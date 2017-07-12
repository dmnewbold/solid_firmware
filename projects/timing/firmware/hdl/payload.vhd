-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
 use work.ipbus_decode_top.all;

entity payload is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk125: in std_logic;
		clk_rstn_p: out std_logic;
		clk_rstn_n: out std_logic;
		clk_o_p: out std_logic;
		clk_o_n: out std_logic;
		clk_i_p: in std_logic;
		clk_i_n: in std_logic;
		trig_o_p: out std_logic;
		trig_o_n: out std_logic;
		trig_i_p: in std_logic;
		trig_i_n: in std_logic;
		sync_o_p: out std_logic;
		sync_o_n: out std_logic;
		sync_i_p: in std_logic;
		sync_i_n: in std_logic;
		trig_sel_p: out std_logic;
		trig_sel_n: out std_logic;
		sync_sel_p: out std_logic;
		sync_sel_n: out std_logic;
		scl_p: out std_logic;
		scl_n: out std_logic;
		sda_o_p: out std_logic;
		sda_o_n: out std_logic;
		sda_i_p: in std_logic;
		sda_i_n: in std_logic;
		busy_o_p: out std_logic;
		busy_o_n: out std_logic;
		busy_i_p: in std_logic_vector(9 downto 0);
		busy_i_n: in std_logic_vector(9 downto 0)
	);

end payload;

architecture rtl of payload is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal scl, sda_i, sda_o: std_logic;
	signal ctrl_trig, ctrl_sync, ctrl_trig_sel, ctrl_sync_sel, ctrl_busy: std_logic;
	signal clki, clkdiv: std_logic;

--	attribute IOB: string;
--	attribute IOB of sfp_dout: signal is "TRUE";
	
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
			N_STAT => 5
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	rst <= ctrl(0)(2);
	ctrl_trig <= ctrl(0)(3);
	ctrl_sync <= ctrl(0)(4);
	ctrl_trig_sel <= ctrl(0)(5);
	ctrl_sync_sel <= ctrl(0)(6);
	ctrl_busy <= ctrl(0)(7);
	
-- General IO

	userled <= '0';
	
-- I2C

	i2c_analog: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda_i
		);

-- Cable IO

	bufs: entity work.sc_timing_iobufs
		port map(
			clk_rstn => '1',
			clk_rstn_p => clk_rstn_p,
			clk_rstn_n => clk_rstn_n,
			clk => '0',
			clk_o_p => clk_o_p,
			clk_o_n => clk_o_n,
			clk_i => clki,
			clk_i_p => clk_i_p,
			clk_i_n => clk_i_n,
			trig_o => ctrl_trig_o,
			trig_o_p => trig_o_p,
			trig_o_n => trig_o_n,
			trig_i => open,
			trig_i_p => trig_i_p,
			trig_i_n => trig_i_n,
			sync_o => ctrl_sync_o,
			sync_o_p => sync_o_p,
			sync_o_n => sync_o_n,
			sync_i => open,
			sync_i_p => sync_i_p,
			sync_i_n => sync_i_n,
			trig_sel => ctrl_trig_sel,
			trig_sel_p => trig_sel_p,
			trig_sel_n => trig_sel_n,
			sync_sel => ctrl_sync_sel,
			sync_sel_p => sync_sel_p,
			sync_sel_n => sync_sel_n,
			scl => scl,
			scl_p => scl_p,
			scl_n => scl_n,
			sda_o => sda_o,
			sda_o_p => sda_o_p,
			sda_o_n => sda_o_n,
			sda_i => sda_i,
			sda_i_p => sda_i_p,
			sda_i_n => sda_i_n,
			busy_o => ctrl_busy_o,
			busy_o_p => busy_o_p,
			busy_o_n => busy_o_n,
			busy_i => open,
			busy_i_p => busy_i_p,
			busy_i_n => busy_i_n
		);
		
-- Clock frequency counter
	
	div: entity work.freq_ctr_div
		port map(
			clk(0) => clki,
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
