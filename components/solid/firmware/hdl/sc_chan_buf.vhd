-- sc_chan_buf.vhd
--
-- The buffer chain for one input channel
--
-- Seriously, this stuff is mindfuck. If you are reading this, you are doomed.
--
-- Dave Newbold, May 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;

use work.top_decl.all;

entity sc_chan_buf is
	port(
--		clk: in std_logic;
--		rst: in std_logic;
--		ipb_in: in ipb_wbus; -- clk dom
--		ipb_out: out ipb_rbus; -- clk dom
--		mode: in std_logic; -- buffer counter mode; clk dom
		clk40: in std_logic;
		clk160: in std_logic;
		nzs_blks: in std_logic_vector(3 downto 0); -- number of blocks in NZS buffer
		buf_rst: in std_logic; -- general reset; clk40 dom
		d: in std_logic_vector(15 downto 0); -- data in; clk40 dom
		blkend: in std_logic;
		nzs_en: in std_logic; -- enable nzs buffer; clk40 dom
--		cap: in std_logic;
--		cap_full: out std_logic;
		zs_thresh: in std_logic_vector(13 downto 0); -- ZS threshold; clk40 dom
		zs_en: in std_logic; -- enable zs buffer; clk40 dom
		buf_full: out std_logic; -- buffer err flag; clk40 dom
		dr_en: in std_logic;
		suppress: in std_logic;
		keep: in std_logic; -- block transfer cmd; clk40 dom
		kack: out std_logic;
		q: out std_logic_vector(31 downto 0); -- output to derand; clk40 dom
		q_blkend: out std_logic;
		wen: out std_logic -- derand write enable
	);

end sc_chan_buf;

architecture rtl of sc_chan_buf is

	constant ZS_LAST_ADDR: integer := 2 ** BUF_RADIX - 1;

	signal c: unsigned(1 downto 0);
	signal we: std_logic;
	signal d_ram, q_ram, d_nzs, q_nzs, d_zs, q_zs, q_zs_b: std_logic_vector(15 downto 0);
	signal a_ram: std_logic_vector(BUF_RADIX - 1 downto 0);
	signal pnz, pzw, pzr, zs_first_addr: unsigned(BUF_RADIX - 1 downto 0);
--	signal cap_run, cap_done: std_logic;
	signal zctr: unsigned(BLK_RADIX - 1 downto 0);
	signal z0, z1: std_logic;
	signal zs_en_d, zs_en_dd, nzen, nzen_d, wenz, wez, rez, wez_d: std_logic;
	signal go, zs_run, zs_keep, buf_full_i, p, q_blkend_i: std_logic;
	
begin

	zs_first_addr <= shift_left(unsigned(std_logic_vector'((BUF_RADIX - 1 downto 4 => '0') & nzs_blks)), BLK_RADIX) + ZS_DEL;

-- NZS / ZS buffer

	ram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => BUF_RADIX,
			DATA_WIDTH => 16
		)
		port map(
			clk => '0',
			rst => '0',
			ipb_in => IPB_RBUS_NULL,
			ipb_out => open,
			rclk => clk160,
			we => we,
			d => d_ram,
			q => q_ram,
			addr => a_ram
		);

	process(clk160)
	begin
		if rising_edge(clk160) then
			if buf_rst = '1' then
				c <= "00";
			else
				c <= c + 1;
			end if;
		end if;
	end process;
	
	with c select a_ram <=
		std_logic_vector(pnz) when "11", -- data / to from nzs on 1st edge of clk160 (clk40 rising)
		std_logic_vector(pzw) when "01", -- data to zs on 3rd edge of clk160
		std_logic_vector(pzr) when others; -- data from zs on 4th edge of clk160
	
	with c select d_ram <=
		d_nzs when "11",
		d_zs when others;
		
	with c select we <=
		wenz when "11",
		wez when "01",
		'0' when others;
	
-- NZS pointer control

--	cap_run <= (cap_run or cap) and not (cap_done or buf_rst) when rising_edge(clk40);
--	nzen <= nzs_en or cap_run;
	nzen <= nzs_en;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			nzen_d <= nzen;
			zs_en_d <= zs_en;
			zs_en_dd <= zs_en_d;
		end if;
	end process;
	
	process(clk40)
	begin
		if falling_edge(clk40) then
			if nzen_d = '0' then
				pnz <= (others => '0');
			else
				if pnz = zs_first_addr - 1 then
					pnz <= (others => '0');
				else
					pnz <= pnz + 1;
				end if;
			end if;
		end if;
	end process;
	
--	cap_done <= '1' when pnz = ZS_LAST_ADDR else '0';
--	wenz <= nzs_en or cap_run or cap;
	wenz <= nzs_en;
--	cap_full <= not nzen;
	d_nzs <= blkend & '0' & d(13 downto 0);
	
-- Zero suppression
		
	z0 <= '1' when unsigned(q_ram(13 downto 0)) < unsigned(zs_thresh) else '0';

	process(clk160)
	begin
		if rising_edge(clk160) and c = "00" then
			if zs_en_d = '0' then
				zctr <= (others => '0');
			else
				q_nzs <= q_ram;
				z1 <= z0;
				if z0 = '0' or q_nzs(15) = '1' then
					zctr <= (others => '0');
				elsif z1 = '1' then
					zctr <= zctr + 1;
				end if;
			end if;
			wez <= ((not (z0 and z1)) or q_nzs(15)) and zs_en_dd and not buf_full_i;
			if z1 = '1' then
				d_zs <= q_nzs(15) & '1' & (13 - BLK_RADIX downto 0 => '0') & std_logic_vector(zctr);
			else
				d_zs <= q_nzs;
			end if;
		end if;
	end process;
	
-- ZS pointer control

	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				pzw <= zs_first_addr;
				pzr <= zs_first_addr;
			elsif buf_full_i = '0' then
				if wez = '1' then
					if pzw = ZS_LAST_ADDR then
						pzw <= zs_first_addr;
					else
						pzw <= pzw + 1;
					end if;
				end if;
				if rez = '1' then
					if pzr = ZS_LAST_ADDR then
						pzr <= zs_first_addr;
					else
						pzr <= pzr + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				buf_full_i <= '0';
			elsif pzw = pzr and wez_d = '1' then
				buf_full_i <= '1';
			end if;
			wez_d <= wez;
		end if;
	end process;
	
	buf_full <= buf_full_i;

-- Readout to derand

	go <= blkend and dr_en;
	kack <= go and keep and not (q_zs_b(15) and q_zs_b(14) and suppress);
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				zs_run <= '0';
				p <= '0';
			else
				if go = '1' then
					zs_run <= '1';
					zs_keep <= keep;
				elsif p = '1' and q_blkend_i = '1' then
					zs_run <= '0';
				end if;
				p <= not p;
			end if;
			q_zs <= q_ram;
			q_zs_b <= q_zs;
		end if;
	end process;
	
	rez <= go or (zs_run and not (q_zs(15) or (q_zs_b(15) and p)));
	q_blkend_i <= q_zs(15) or q_zs_b(15);

	q <= q_zs & q_zs_b;
	q_blkend <= q_blkend_i;
	wen <= zs_run and zs_keep and p;		
	
end rtl;
