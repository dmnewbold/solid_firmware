-- sc_rtrig
--
-- Random and external trigger generator
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

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

	signal q: ipb_reg_v(0 downto 0);
	signal ctrl_en, ctrl_mode: std_logic;
	signal ctrl_div: std_logic_vector(5 downto 0);
	signal mask: std_logic_vector(23 downto 0);

begin

	reg: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => q
		);

	ctrl_en <= q(0)(0);
	ctrl_mode <= q(0)(1);
	ctrl_div <= q(0)(13 downto 8);
	
	mgen: for i in mask'range generate
		mask(i) <= '0' when i > to_integer(unsigned(ctrl_div)) else '1';
	end generate;

	force <= ((not ctrl_mode and not or_reduce(rand(mask'range) and mask)) or
		(ctrl_mode and not or_reduce(sctr(BLK_RADIX + mask'left downto BLK_RADIX) and mask))) and
			ctrl_en and not or_reduce(sctr(BLK_RADIX - 1 downto 0));

end rtl;
