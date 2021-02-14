-- sc_chan_buf
--
-- The buffer chain for one input channel
--
-- Seriously, this stuff is mindf**k. If you are reading this, you are doomed.
--
-- Dave Newbold, December 2020

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;

use work.top_decl.all;

entity sc_chan_buf is
	port(
		clk40: in std_logic;
		clk80: in std_logic;
		nzs_blks: in std_logic_vector(3 downto 0); -- number of blocks in NZS buffer
		buf_rst: in std_logic; -- general reset; clk40 dom
		d: in std_logic_vector(15 downto 0); -- data in; clk40 dom
		blkend: in std_logic;
		nzs_en: in std_logic; -- enable nzs buffer; clk40 dom
		zs_thresh: in std_logic_vector(13 downto 0); -- ZS threshold; clk40 dom
		zs_en: in std_logic; -- enable zs buffer; clk40 dom
		buf_full: out std_logic; -- buffer err flag; clk40 dom
		veto: in std_logic;
		soft: in std_logic;
		keep: in std_logic; -- block transfer cmd; clk40 dom
		kack: out std_logic;
		q: out std_logic_vector(31 downto 0); -- output to derand; clk40 dom
		q_blkend: out std_logic;
		wen: out std_logic; -- derand write enable
		zs_err: out std_logic
	);

end sc_chan_buf;

architecture rtl of sc_chan_buf is

	constant ZS_LAST_ADDR: integer := 2 ** BUF_RADIX - 1;
	constant MARGIN: integer := 4;

	signal c: std_logic;
	signal d_nzs, q_nzs, d_zs, q_zs, q_zs_d, q_zs_dd: std_logic_vector(15 downto 0);
	signal addra, addrb: std_logic_vector(BUF_RADIX - 1 downto 0);
	signal pnz, pzw, pzr, zs_first_addr, ctr, max_cont: unsigned(BUF_RADIX - 1 downto 0);
	signal zs_en_d, nzen_d, wenz, wez, wezu, rez: std_logic;
	signal zs_run, zs_keep, supp, buf_doom, buf_full_i, p, q_blkend_i: std_logic;
	signal bcnt: unsigned(7 downto 0);
	
begin

	zs_first_addr <= shift_left(unsigned(std_logic_vector'((BUF_RADIX - 1 downto 4 => '0') & nzs_blks)), BLK_RADIX) + ZS_DEL;
	max_cont <= ZS_LAST_ADDR - zs_first_addr - MARGIN;
	
-- NZS / ZS buffer

	ram: entity work.sc_dpram
		generic map(
			ADDR_WIDTH => BUF_RADIX
		)
		port map(
			clk => clk80,
			wea => c,
			da => d_nzs, -- NZS data in on r/e of clk40
			qa => q_nzs, -- NZS data out on r/e of clk40
			addra => addra,
			web => c,
			db => d_zs, -- ZS data in on r/e of clk40
			qb => q_zs, -- ZS data out on f/e of clk40
			addrb => addrb
		);

	process(clk80)
	begin
		if rising_edge(clk80) then
			if buf_rst = '1' then
				c <= '0';
			else
				c <= not c;
			end if;
		end if;
	end process;
	
	addra <= std_logic_vector(pnz);
	addrb <= std_logic_vector(pzw) when c = '1' else std_logic_vector(pzr);

-- NZS pointer control

	nzen_d <= nzs_en when rising_edge(clk40);
	
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
	
	wenz <= nzs_en;
	d_nzs <= blkend & '0' & d(13 downto 0);
	
-- Zero suppression

	zs_en_d <= zs_en when rising_edge(clk40);
	supp <= buf_doom and soft;
		
	zs: entity work.sc_zs
		generic map(
			CTR_W => BLK_RADIX
		)
		port map(
			clk => clk40,
			en => zs_en_d,
			thresh => zs_thresh,
			supp => supp,
			d => q_nzs,
			q => d_zs,
			we => wezu
		);
		
	wez <= wezu and (soft or not buf_doom);

-- ZS pointer control

	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				pzw <= zs_first_addr;
				pzr <= zs_first_addr;
				ctr <= (others => '0');
			else
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
				if wez = '1' and rez = '0' then
					ctr <= ctr + 1;
				elsif wez = '0' and rez = '1' then
					ctr <= ctr - 1;
				end if;
			end if;
		end if;
	end process;
	
	buf_doom <= '1' when ctr > max_cont else '0';
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				buf_full_i <= '0';
			elsif buf_doom = '1' and soft = '0' then
				buf_full_i <= '1';
			end if;
		end if;
	end process;
	
	buf_full <= buf_full_i;

-- Readout to derand

	kack <= blkend and keep and not veto;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				zs_run <= '0';
				p <= '0';
			else
				if blkend = '1' then
					zs_run <= '1';
					zs_keep <= keep and not veto;
				elsif p = '1' and q_blkend_i = '1' then
					zs_run <= '0';
				end if;
				p <= not p;
			end if;
			q_zs_d <= q_zs;
			q_zs_dd <= q_zs_d;
		end if;
	end process;
	
	rez <= blkend or (zs_run and not (q_zs_d(15) or (q_zs_dd(15) and p)));
	q_blkend_i <= q_zs_d(15) or q_zs_dd(15);

	q <= q_zs_d & q_zs_dd;
	q_blkend <= q_blkend_i;
	wen <= zs_run and zs_keep and p;
	
-- ZS sanity check

	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_run = '0' then
				bcnt <= X"00";
			else
				if q_zs(14) = '1' then
					bcnt <= bcnt + unsigned(q_zs(7 downto 0));
				else
					bcnt <= bcnt + 1;
				end if;
				if q_zs(15) = '1' then
					bcnt <= X"00";
					if bcnt /= X"00" then
						zs_err <= '1';
					else
						zs_err <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

end rtl;
