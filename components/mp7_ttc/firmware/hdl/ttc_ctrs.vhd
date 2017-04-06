-- ttc_ctrs
--
-- Bunch / orbit / event counters
--
-- Dave Newbold, March 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.mp7_ttc_decl.all;
use work.top_decl.all;

entity ttc_ctrs is
	port(
		clk: in std_logic; -- Main TTC clock
		rst: in std_logic;
		ttc_cmd: in ttc_cmd_t;
		l1a: in std_logic;
		clr: in std_logic;
		en_int_bc0: in std_logic;
		bc0_lock: out std_logic;
		bc0_fr: out std_logic;
		ttc_cmd_out: out ttc_cmd_t;
		l1a_out: out std_logic;
		bunch_ctr: out bctr_t; -- TTC counters
		orb_ctr: out eoctr_t
	);

end ttc_ctrs;

architecture rtl of ttc_ctrs is
	
	signal cmd_d: ttc_cmd_t;
	signal bunch_ctr_i: bctr_t;
	signal evt_ctr_i: unsigned(eoctr_t'range);
	signal orb_ctr_i: std_logic_vector(eoctr_t'range);
	signal bc0, oc0, bmax, l1a_i, bc0_lock_i: std_logic;

begin

	ctrdel: entity work.del_array
		generic map(
			DWIDTH => ttc_cmd_t'length + 1,
			DELAY => TTC_DEL + 1
		)
		port map(
			clk => clk,
			d(ttc_cmd_t'length - 1 downto 0) => ttc_cmd,
			d(ttc_cmd_t'length) => l1a,
			q(ttc_cmd_t'length - 1 downto 0) => cmd_d,
			q(ttc_cmd_t'length) => l1a_i
		);

	ttc_cmd_out <= cmd_d;		
	l1a_out <= l1a_i;
	bc0 <= '1' when cmd_d = TTC_BCMD_BC0 and en_int_bc0 = '0' else '0';
	oc0 <= '1' when cmd_d = TTC_BCMD_OC0 else '0';
		
	bctr: entity work.bunch_ctr
		generic map(
			CLOCK_RATIO => 1,
			CTR_WIDTH => 12,
			OCTR_WIDTH => eoctr_t'length,
			LHC_BUNCH_COUNT => LHC_BUNCH_COUNT,
			BC0_BX => TTC_BC0_BX
		)
		port map(
			clk => clk,
			rst => rst,
			clr => clr,
			bc0 => bc0,
			oc0 => oc0,
			bctr => bunch_ctr_i,
			bmax => bmax,
			octr => orb_ctr_i,
			lock => bc0_lock_i
		);

	bc0_lock <= bc0_lock_i or en_int_bc0;		

	bunch_ctr <= bunch_ctr_i;
	bc0_fr <= '1' when bunch_ctr_i = std_logic_vector(to_unsigned(TTC_BC0_BX - TTC_DEL - 1, bunch_ctr'length)) and en_int_bc0 = '1' else '0';

	orb_ctr <= eoctr_t(orb_ctr_i);

end rtl;
