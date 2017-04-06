-- tmt_sync
--
-- Provide sync signals for TMT
--
-- Dave Newbold, July 2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_ttc_decl.all;

entity tmt_sync is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		ttc_clk: in std_logic;
		bctr: in bctr_t;
		tmt_l1a_sync: out std_logic;
		tmt_pkt_sync: out std_logic
	);

end tmt_sync;

architecture rtl of tmt_sync is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal ctr: unsigned(3 downto 0) := (others => '0');
	signal en : std_logic;

begin

-- Control reg

	reg: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl,
			qmask => (0 => X"0001FFFF")
		);

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			if (bctr(bctr'left downto 4) = (bctr'left downto 4 => '0') and bctr(3 downto 0) = ctrl(0)(7 downto 4)) or ctr = unsigned(ctrl(0)(3 downto 0)) then
				ctr <= X"0";
			else
				ctr <= ctr + 1;
			end if;
		end if;
	end process;

	tmt_l1a_sync <= '1' when ctr = unsigned(ctrl(0)(11 downto 8)) and en = '1' else '0';
	tmt_pkt_sync <= '1' when ctr = unsigned(ctrl(0)(15 downto 12)) and en = '1' else '0';
	
	en <= ctrl(0)(16);
	
end rtl;
