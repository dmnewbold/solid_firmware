-- payload.vhd
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_top_sim.all;

use work.top_decl.all;

entity payload_sim is
	port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		rst125: in std_logic;
		nuke: out std_logic;
		soft_rst: out std_logic
	);

end payload_sim;

architecture rtl of payload_sim is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal clk40, rst40, clk160, clk280: std_logic;
	signal ctrl_rst_mmcm, locked, idelayctrl_rdy, ctrl_rst_idelayctrl: std_logic;
	signal ctrl_chan: std_logic_vector(7 downto 0);
	signal ctrl_board_id: std_logic_vector(7 downto 0);
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
      sel => ipbus_sel_top_sim(ipb_in.ipb_addr),
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
		
	stat(0) <= X"a754" & FW_REV;
	stat(1) <= X"0000000" & "0" & chan_err & idelayctrl_rdy & locked;
	
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	ctrl_rst_mmcm <= ctrl(0)(2);
	ctrl_rst_idelayctrl <= ctrl(0)(3);
	ctrl_chan <= ctrl(0)(15 downto 8);
	ctrl_board_id <= ctrl(0)(23 downto 16);
	
-- Board IO

	idelayctrl_rdy <= '1';
	
-- DAQ core

	daq: entity work.sc_daq
		port map(
			ipb_clk => ipb_clk,
			ipb_rst => ipb_rst,
			ipb_in_timing => ipbw(N_SLV_TIMING),
			ipb_out_timing => ipbr(N_SLV_TIMING),
			ipb_in => ipbw(N_SLV_DAQ),
			ipb_out => ipbr(N_SLV_DAQ),
			rst_mmcm => ctrl_rst_mmcm,
			locked => locked,
			clk_in_p => '0',
			clk_in_n => '1',
			clk40 => clk40,
			sync_in => '0',
			sync_out => open,
			trig_in => '0',
			chan => ctrl_chan,
			chan_err => chan_err,
			d_p => (others => '0'),
			d_n => (others => '1'),
			clk125 => clk125,
			rst125 => rst125,
			board_id => ctrl_board_id
		);
		
end rtl;
