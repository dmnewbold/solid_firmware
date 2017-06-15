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
		mark: in std_logic;
		en: in std_logic;
		d: in std_logic_vector(13 downto 0);
		trig: out std_logic_vector(N_CHAN_TRG - 1 downto 0)
	);

end sc_chan_trig;

architecture rtl of sc_chan_trig is

	signal ctrl: ipb_reg_v(2 downto 0);
	signal dd: std_logic_vector(13 downto 0);
	signal trig_i: std_logic_vector(N_CHAN_TRG - 1 downto 0);

begin

	reg: entity work.ipbus_ctrlreg_v -- CDC between ctrl (ipb_clk) and (clk40)
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

	dd <= d when rising_edge(clk40); -- pipeline register
			
	trg0: entity work.sc_ctrig_thresh -- direct threshold trigger, delay = 1
		generic map(
			VAL_WIDTH => VAL_WIDTH,
			DELAY => 2
		)
		port map(
			clk => clk40,
			rst => rst40,
			clr => mark,
			d => dd,
			threshold => ctrl(0)(VAL_WIDTH - 1 downto 0),
			trig => trig_i(0)
		);

	trg1: entity work.sc_ctrig_npeaks -- peaks-above-threshold trigger, delay = 2
		generic map(
			VAL_WIDTH => VAL_WIDTH
		)
		port map(
			clk => clk40,
			rst => rst40,
			clr => mark,
			en => en,
			d => dd,
			cthresh => ctrl(1)(24 downto 16),
			wsize => ctrl(1)(31 downto 28),
			pthresh => ctrl(1)(VAL_WIDTH - 1 downto 0),
			trig => trig_i(1)
		);

	trg2: entity work.sc_ctrig_tot -- time-over-threshold trigger, delay = 1
		generic map(
			VAL_WIDTH => VAL_WIDTH
		)
		port map(
			clk => clk40,
			rst => rst40,
			clr => mark,
			en => en,
			d => dd,
			cthresh => ctrl(2)(24 downto 16),
			wsize => ctrl(2)(31 downto 28),
			pthresh => ctrl(2)(VAL_WIDTH - 1 downto 0),
			trig => trig_i(2)
		);
		
	trig <= trig_i when en = '1' else (others => '0');
		
end rtl;
