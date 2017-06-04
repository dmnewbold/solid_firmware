-- sc_fake
--
-- Fake data generator for trigger testing
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity sc_fake is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rand: in std_logic_vector(31 downto 0);
		fake: out std_logic_vector(13 downto 0)
	);

end sc_fake

architecture rtl of sc_fake is

begin

	ipb_out <= IPB_RBUS_NULL;

	fake <= rand(13 downto 0);
	
end rtl;
