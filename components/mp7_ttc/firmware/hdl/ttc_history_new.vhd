-- ttc_history
--
-- Stores the history of TTC A/B commands for debugging
--
-- mask bits are:
-- 0: mask bc0
-- 1: mask l1a
--
-- Dave Newbold, August 2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.mp7_ttc_decl.all;

entity ttc_history_new is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		ttc_clk: in std_logic; -- TTC clk40
		ttc_rst: in std_logic;
		ttc_l1a: in std_logic;
		ttc_cmd: in ttc_cmd_t;
		ttc_bx: in bctr_t;
		ttc_orb: in eoctr_t;
		ttc_evt: in eoctr_t
	);

end ttc_history_new;

architecture rtl of ttc_history_new is

	signal mask: std_logic_vector(7 downto 0);
	signal state: std_logic_vector(15 downto 0);
	signal strobe: std_logic;

begin

	state_buf: entity work.state_history
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			ttc_clk => ttc_clk,
			ttc_rst => ttc_rst,
			ttc_bx => ttc_bx,
			ttc_orb => ttc_orb,
			ttc_evt => ttc_evt,
--			mask_ctrl => mask,
			state => state
--			strobe => strobe
		);

	state <= X"0" & ttc_l1a & "000" & ttc_cmd; -- should be indepedent of ttc_cmd_length; fix later
	strobe <= '1' when (ttc_l1a = '1' and mask(1) = '0') or (ttc_cmd /= TTC_BCMD_NULL and not (ttc_cmd = TTC_BCMD_BC0 and mask(0) = '1')) else '0';

end rtl;
