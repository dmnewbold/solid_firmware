-- ttc_cmd_ctrs
--
-- Count the number of TTC commands of each type received
--
-- Dave Newbold, March 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.mp7_ttc_decl.all;
use work.top_decl.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity ttc_cmd_ctrs is
	port(
		clk: in std_logic; -- ipbus clock
		rst: in std_logic;
		ipb_in: in ipb_wbus; -- ipbus
		ipb_out: out ipb_rbus;
		ttc_clk: in std_logic;
		clr: in std_logic; -- counter clear (ttc clock domain)
		ttc_cmd: in ttc_cmd_t -- TTC command
	);

end ttc_cmd_ctrs;

architecture rtl of ttc_cmd_ctrs is

	constant ADDR_WIDTH: integer := calc_width(TTC_N_BCMD);
	signal ri: ipb_reg_v(2 ** ADDR_WIDTH - 1 downto 0);
	signal sel: integer range 0 to 2 ** ADDR_WIDTH - 1 := 0;

	type ctr_array_t is array(TTC_N_BCMD - 1 downto 0) of unsigned(31 downto 0);
	signal ctr_array: ctr_array_t;
	type bcmd_array_t is array(TTC_N_BCMD - 1 downto 0) of ttc_cmd_t;
	constant bcmd_array: bcmd_array_t := (
		TTC_BCMD_STOP,
		TTC_BCMD_START,
		TTC_BCMD_TEST_SYNC,
		TTC_BCMD_OC0,
		TTC_BCMD_RESYNC,
		TTC_BCMD_EC0,
		TTC_BCMD_BC0
	);
	
begin

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			if clr = '1' then
				ctr_array <= (others => (others => '0'));
			else
				for i in TTC_N_BCMD - 1 downto 0 loop
					if ttc_cmd = bcmd_array(i) and ctr_array(i) /= X"ffffffff" then
						ctr_array(i) <= ctr_array(i) + 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
	rgen: for i in TTC_N_BCMD - 1 downto 0 generate
		ri(i) <= std_logic_vector(ctr_array(i));
	end generate;
	
	ri(2 ** ADDR_WIDTH - 1 downto TTC_N_BCMD) <= (others => (others => '0'));
	
	sel <= to_integer(unsigned(ipb_in.ipb_addr(ADDR_WIDTH - 1 downto 0))) when ADDR_WIDTH > 0 else 0;
	ipb_out.ipb_rdata <= ri(sel);
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
	
end rtl;
