-- sc_chan_buf.vhd
--
-- The buffer chain for one input channel
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
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus; -- clk dom
		ipb_out: out ipb_rbus; -- clk dom
		ipb_in_ptr: in ipb_wbus; -- clk dom
		ipb_out_ptr: out ipb_rbus; -- clk dom
		mode: in std_logic_vector(1 downto 0); -- buffer counter mode; clk dom
		clk40: in std_logic;
		clk160: in std_logic;
		buf_rst: in std_logic; -- general reset; clk40 dom
		d: in std_logic_vector(13 downto 0); -- data in; clk40 dom
		blkend: in std_logic;
		nzs_en: in std_logic; -- enable nzs buffer; clk40 dom
		cap_full: out std_logic;
		zs_thresh: in std_logic_vector(13 downto 0); -- ZS threshold; clk40 dom
		q_test: out std_logic_vector(13 downto 0); -- test data output to adjacent channel; clk40 dom
		zs_en: in std_logic; -- enable zs buffer; clk40 dom
		buf_full: out std_logic; -- buffer err flag; clk40 dom
		keep: in std_logic; -- block transfer cmd; clk40 dom
		flush: in std_logic; -- block discard cmd; clk40 dom
		q: out std_logic_vector(31 downto 0); -- output to derand; clk40 dom
		q_blkend: out std_logic;
		wen: out std_logic -- derand write enable
	);

end sc_chan_buf;

architecture rtl of sc_chan_buf is

	constant NZS_LAST_ADDR: integer := NZS_BLKS * 2 ** BLK_RADIX - 1;
	constant ZS_FIRST_ADDR: integer := NZS_BLKS * 2 ** BLK_RADIX;
	constant ZS_LAST_ADDR: integer := 2 ** BUF_RADIX - 1;

	signal norm_mode, pb_mode, cap_mode: std_logic;
	signal c: unsigned(1 downto 0);
	signal we: std_logic;
	signal d_ram, q_ram, d_nzs, q_nzs, d_zs, q_zs, q_zs_b: std_logic_vector(15 downto 0);
	signal a_ram: std_logic_vector(BUF_RADIX - 1 downto 0);
	signal pnz, pzw, pzr: unsigned(BUF_RADIX - 1 downto 0);
	signal cap_done: std_logic;
	signal zctr: unsigned(BLK_RADIX - 1 downto 0);
	signal z0, z1: std_logic;
	signal zs_en_d, zs_en_dd, nzs_en_d, wenz, wez, rez, wez_d: std_logic;
	signal go, zs_run, zs_keep, buf_full_i, p, q_blkend_i: std_logic;
	
begin

	norm_mode <= '1' when mode = "00" else '0';
	pb_mode <= '1' when mode = "01" else '0';
	cap_mode <= '1' when mode = "10" else '0';

-- NZS / ZS buffer

	ram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => BUF_RADIX,
			DATA_WIDTH => 16
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
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

-- Pointer access

	ipb_out_ptr.ipb_rdata <= X"0000" & (15 - BUF_RADIX downto 0 => '0') & std_logic_vector(pnz) when ipb_in_ptr.ipb_addr(0) = '0' else
		(15 - BUF_RADIX downto 0 => '0') & std_logic_vector(pzw) & (15 - BUF_RADIX downto 0 => '0') & std_logic_vector(pzr);
	ipb_out_ptr.ipb_ack <= ipb_in_ptr.ipb_strobe;
	ipb_out_ptr.ipb_err <= '0';
	
-- NZS pointer control

	process(clk40)
	begin
		if rising_edge(clk40) then
			nzs_en_d <= nzs_en;
			zs_en_d <= zs_en;
			zs_en_dd <= zs_en_d;
		end if;
	end process;
	
	process(clk40)
	begin
		if falling_edge(clk40) then
			if (pb_mode = '1' and nzs_en = '0') or (pb_mode = '0' and nzs_en_d = '0') then
				pnz <= to_unsigned(0, pnz'length);
				cap_done <= '0';
			else
				if (norm_mode = '1' and pnz = NZS_LAST_ADDR) or pnz = ZS_LAST_ADDR then
					pnz <= (others => '0');
					if cap_mode = '1' then
						cap_done <= '1';
					end if;
				else
					pnz <= pnz + 1;
				end if;
			end if;
		end if;
	end process;
	
	wenz <= (norm_mode or cap_mode) and nzs_en and not cap_done;
	d_nzs <= blkend & '0' & d;
	cap_full <= cap_done;
	
-- Zero suppression

	q_test <= q_ram(13 downto 0);
		
	z0 <= '1' when unsigned(q_ram(13 downto 0)) < unsigned(zs_thresh) and q_ram(15) = '0' else '0';

	process(clk160)
	begin
		if rising_edge(clk160) and c = "00" then
			if zs_en_d = '0' then
				zctr <= (others => '0');
			else
				q_nzs <= q_ram(15) & '0' & q_ram(13 downto 0);
				z1 <= z0;
				if z0 = '0' then
					zctr <= (others => '0');
				else
					zctr <= zctr + 1;
				end if;
			end if;
			wez <= (not (z0 and z1)) and zs_en_dd and norm_mode and not buf_full_i;
			if z1 = '1' and zctr /= 1 then
				d_zs <= "01" & (13 - BLK_RADIX downto 0 => '0') & std_logic_vector(zctr);
			else
				d_zs <= q_nzs;
			end if;
		end if;
	end process;
	
-- ZS pointer control

	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' or norm_mode = '0' then
				pzw <= to_unsigned(ZS_FIRST_ADDR, pzw'length);
				pzr <= to_unsigned(ZS_FIRST_ADDR, pzr'length);
			elsif buf_full_i = '0' then
				if wez = '1' then
					if pzw = ZS_LAST_ADDR then
						pzw <= to_unsigned(ZS_FIRST_ADDR, pzw'length);
					else
						pzw <= pzw + 1;
					end if;
				end if;
				if rez = '1' then
					if pzr = ZS_LAST_ADDR then
						pzr <= to_unsigned(ZS_FIRST_ADDR, pzr'length);
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

	go <= keep or flush;

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
