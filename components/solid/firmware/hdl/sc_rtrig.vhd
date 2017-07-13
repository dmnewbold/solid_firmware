-- sc_rtrig
--
-- Random and external trigger generator
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;

entity sc_rtrig is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		rand: in std_logic_vector(31 downto 0);
		sctr: in std_logic_vector(47 downto 0);
		force: out std_logic
	);

end sc_rtrig;

architecture rtl of sc_rtrig is

begin

	ipb_out <= IPB_RBUS_NULL;
	force <= '0';

end rtl;
