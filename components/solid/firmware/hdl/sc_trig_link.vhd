-- sc_trig_link
--
-- Trigger communication between planes
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;

entity sc_trig_link is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk125: in std_logic;
		rst125: in std_logic;
		link_ok: out std_logic;
		clk40: in std_logic;
		rst40: in std_logic;
		d: in std_logic_vector(15 downto 0);
		d_valid: in std_logic;
		q: out std_logic_vector(15 downto 0);
		q_valid: out std_logic;
		ack: in std_logic
	);

end sc_trig_link;

architecture rtl of sc_trig_link is

begin

	ipb_out <= IPB_RBUS_NULL;
	q <= (others => '0');
	q_valid <= '0';
	link_ok <= '0';

end rtl;
