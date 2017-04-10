-- sc_chan_trig.vhd
--
-- Per-channel trigger generator
-- Trigger flags for last block are valid 1 cycle after block end (i.e. sctr = 0x00)
--
-- Dave Newbold, July 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_chan_trig is
	generic(
		VAL_WIDTH: natural := 14 -- bit
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		d: in std_logic_vector(13 downto 0);
		req: in std_logic;
		trig: out std_logic_vector(N_CHAN_TRG - 1 downto 0)
	);

end sc_chan_trig;

architecture rtl of sc_chan_trig is

	signal ctrl: ipb_reg_v(2 downto 0);
	signal threshold_trig, threshold_sig, threshold_fe: std_logic_vector(VAL_WIDTH - 1 DOWNTO 0);

begin

	threshold_trig <= ctrl(0)(VAL_WIDTH-1 DOWNTO 0);
	threshold_sig <= ctrl(1)(VAL_WIDTH-1 DOWNTO 0);
	threshold_fe <= ctrl(2)(VAL_WIDTH-1 DOWNTO 0);

	reg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 3,
			N_STAT => 0
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl
		);

	trg0: entity work.sc_trig_dummy
		generic map(
			VAL_WIDTH => VAL_WIDTH
		)
		port map(
			clk => clk40,
			rst => rst40,
			req => req,
			val => d,
			threshold => threshold_trig,
			trig => trig(0)
		);
		
	trg1: entity work.sc_npeaks_thresh
		generic map(
			VAL_WIDTH => VAL_WIDTH
		)
		port map(
			clk => clk40,
			rst => rst40,
			req => req,
			d => d,
			threshold_trig => threshold_sig,
			threshold_fe => threshold_fe,
			trig => trig(1)
		);
		
end rtl;
