-- sc_zs_sel
--
-- Zero suppression threshold select logic - range of blocks
-- 
-- zscfg is eight bits for each trigger type
-- b7-4: blocks for change threshold for (from start of nzs buffer)
-- b1-0: ZS threshold ID for this trigger
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.top_decl.all;

entity sc_zs_sel_rolling is
	port(
		clk40: in std_logic;
		rst40: in std_logic;
		mark: in std_logic;
		zscfg: in std_logic_vector(31 downto 0);
		trig: in std_logic_vector(15 downto 0);
		trig_valid: in std_logic;
		sel: out std_logic_vector(1 downto 0)
	);

end sc_zs_sel_rolling;

architecture rtl of sc_zs_sel_rolling is

	signal ti: integer range 15 downto 0 := 0;
	signal zs_cnt: std_logic_vector(3 downto 0);
	type cnt_t is array(N_TRG - 1 downto 0) of unsigned(3 downto 0);
	signal cnt: cnt_t;
	signal ts: std_logic_vector(1 downto 0);
	signal scnt: unsigned(3 downto 0);

begin

	ti <= to_integer(unsigned(trig(3 downto 0)));
	zs_cnt <= zscfg(ti * 8 + 7 downto ti * 8 + 4);
	
-- Rolling block counters
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' then
				cnt <= (others => (others => '0'));
			else
				for i in N_TRG - 1 downto 0 loop
					if i = ti and trig_valid = '1' then
						cnt(i) <= unsigned(zs_cnt);
					elsif mark = '1' and cnt(i) /= 0 then
						cnt(i) <= cnt(i) - 1;
					end if;
				end loop;
			end if;
		end if;
	end process;
	
-- Select highest ZS threshold of active triggers

	process(cnt)
		variable t, k: unsigned(1 downto 0);
	begin
		t := "00";
		for i in N_TRG - 1 downto 0 loop
			k := unsigned(zscfg(i * 8 + 1 downto i * 8));
			if cnt(i) /= 0 and k > t then
				t := k;
			end if;
		end loop;
		ts <= t;
	end process;
	
-- Pipelining; send new ZS threshold choice at correct time

	process(clk40)
	begin
		if mark = '1' then
			scnt <= (others => '0');
		elsif and_reduce(std_logic_vector(scnt)) = '0' then
			scnt <= scnt + 1;
		end if;
		if scnt = to_unsigned(ZS_DEL - 1, scnt'length) then
			sel <= ts;
		end if;
	end process;
	
end rtl;
