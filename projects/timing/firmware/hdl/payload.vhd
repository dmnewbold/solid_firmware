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

--	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
--	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);

--	attribute IOB: string;
--	attribute IOB of sfp_dout: signal is "TRUE";
	
begin

	bufs: entity work.sc_timing_iobufs
		port map(
			clk_rstn => '1',
			clk_rstn_p => clk_rstn_p,
			clk_rstn_n => clk_rstn_n,
			clk => '0',
			clk_o_p => clk_o_p,
			clk_o_n => clk_o_n,
			clk_i => open,
			clk_i_p => clk_i_p,
			clk_i_n => clk_i_n,
			trig_o => '0',
			trig_o_p => trig_o_p,
			trig_o_n => trig_o_n,
			trig_i => open,
			trig_i_p => trig_i_p,
			trig_i_n => trig_i_n,
			sync_o => '0',
			sync_o_p => sync_o_p,
			sync_o_n => sync_o_n,
			sync_i => open,
			sync_i_p => sync_i_p,
			sync_i_n => sync_i_n,
			trig_sel => '0',
			trig_sel_p => trig_sel_p,
			trig_sel_n => trig_sel_n,
			sync_sel => '0',
			sync_sel_p => sync_sel_p,
			sync_sel_n => sync_sel_n,
			scl => '0',
			scl_p => scl_p,
			scl_n => scl_n,
			sda_o => '0',
			sda_o_p => sda_o_p,
			sda_o_n => sda_o_n,
			sda_i => open,
			sda_i_p => sda_i_p,
			sda_i_n => sda_i_n,
			busy_o => '0',
			busy_o_p => busy_o_p,
			busy_o_n => busy_o_n,
			busy_i => open
			busy_i_p => busy_i_p,
			busy_i_n => busy_i_n
		);

end rtl;
