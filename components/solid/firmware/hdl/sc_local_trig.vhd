-- sc_local_trig
--
-- Generates local triggers based on channel trigger outputs
--
-- Send data to ROC on 32nd cycle of block
-- All channel trigger inputs must be frozen by then
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_local_trig is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		trig_en: in std_logic;
		mark: in std_logic;
		sctr: in std_logic_vector(47 downto 0);
		rand: in std_logic_vector(31 downto 0);
		chan_trig: in sc_trig_array;
		trig_q: out std_logic_vector(15 downto 0);
		trig_valid: out std_logic;
		trig_ack: in std_logic;
		ro_q: out std_logic_vector(31 downto 0);
		ro_valid: out std_logic;
		ro_blkend: out std_logic;
		ro_go: in std_logic;
		ro_ctr: in std_logic_vector(7 downto 0);
		rveto: in std_logic
	);

end sc_local_trig;

architecture rtl of sc_local_trig is

	signal ctrl: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal ctrl_trig_en: std_logic_vector(7 downto 0);
	signal ctrl_rnd_mode: std_logic_vector(1 downto 0);
	signal ctrl_trig_force: std_logic;
	signal ctrl_rnd_div: std_logic_vector(5 downto 0);
	signal tv, te, ta, tc: std_logic_vector(N_TRG - 1 downto 0);
	signal s: integer range N_TRG - 1 downto 0;
	signal ch: integer range 2 ** ro_ctr'length - 1 downto 0;
	signal ch_i: integer range N_CHAN - 1 downto 0 := 0;
	signal go, blkend, rveto_d, last_gasp, hoorah: std_logic;
	signal bi: std_logic_vector(63 downto 0);
	signal b: std_logic_vector(31 downto 0);
	
begin

-- Control register
	
	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk40,
			q => ctrl,
			stb => stb
		);

	ctrl_trig_en <= ctrl(0)(7 downto 0);
	ctrl_trig_force <= ctrl(0)(8);
	ctrl_rnd_mode <= ctrl(0)(17 downto 16);
	ctrl_rnd_div <= ctrl(0)(23 downto 18);
	
-- Random trigger generator

	tg0: entity work.sc_trig_gen_random
		port map(
			clk => clk40,
			en => trig_en,
			mode => ctrl_rnd_mode,
			sctr => sctr(31 downto 0),
			rand => rand,
			div => ctrl_rnd_div,
			mark => mark,
			force => ctrl_trig_force,
			valid => tv(0),
			ack => ta(0)
		);

-- Threshold trigger generator

	tg1: entity work.sc_trig_gen_or
		generic map(
			TBIT => 0,
			DELAY => 2
		)
		port map(
			clk => clk40,
			en => trig_en,
			mark => mark,
			chan_trig => chan_trig,
			valid => tv(1),
			ack => ta(1)
		);
		
-- peaks-over-threshold trigger generator

	tg2: entity work.sc_trig_gen_or
		generic map(
			TBIT => 1,
			DELAY => 3
		)
		port map(
			clk => clk40,
			en => trig_en,
			mark => mark,
			chan_trig => chan_trig,
			valid => tv(2),
			ack => ta(2)
		);
	
-- time-over-threshold trigger generator

	tg3: entity work.sc_trig_gen_or
		generic map(
			TBIT => 2,
			DELAY => 2
		)
		port map(
			clk => clk40,
			en => trig_en,
			mark => mark,
			chan_trig => chan_trig,
			valid => tv(3),
			ack => ta(3)
		);

-- Add more trigger generators here...

-- Priority encoder

	te <= tv and ctrl_trig_en(tv'range);

	process(te)
	begin
		s <= 0;
		for i in te'reverse_range loop
			if te(i) = '1' then
				s <= i;
			end if;
		end loop;
	end process;

	trig_q <= X"00" & X"0" & std_logic_vector(to_unsigned(s, 4)); -- Hop count will go in 7:4 one day
	trig_valid <= or_reduce(te) and not rveto;
	
	process(s, trig_ack)
	begin
		for i in N_TRG - 1 downto 0 loop
			if trig_ack = '1' and s = i then
				ta(i) <= '1';
			else
				ta(i) <= '0';
			end if;
		end loop;
	end process;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if trig_en = '0' or blkend = '1' then
				tc <= (others => '0');
			else
				tc <= tc or ta;
			end if;
		end if;
	end process;
	
-- Last gasp message flag

	rveto_d <= rveto and trig_en when rising_edge(clk40) and mark = '1';
	last_gasp <= rveto and not rveto_d;
	hoorah <= rveto_d and not rveto;
	
-- Trigger data to readout

	go <= (go or (ro_go and ((or_reduce(tc) and not rveto) or last_gasp or hoorah))) and not blkend and trig_en and not rst40 when rising_edge(clk40);
	blkend <= '1' when unsigned(ro_ctr) = 3 + 2 * N_CHAN_TRG else '0';
	ro_valid <= go;
	ro_blkend <= blkend;

	ch <= to_integer(unsigned(ro_ctr(ro_ctr'length - 1 downto 1)));
	ch_i <= ch - 2 when ch > 1 and ch < N_CHAN_TRG else 0;
	bi <= (63 downto N_CHAN => '0') & chan_trig(ch_i);
	b <= bi(63 downto 32) when ro_ctr(0) = '1' else bi(31 downto 0);

	with ro_ctr select ro_q <=
		X"100" & "00" & last_gasp & hoorah & (15 downto N_TRG => '0') & tc when X"00", -- Type 1
		std_logic_vector(sctr(31 downto BLK_RADIX)) & (BLK_RADIX - 1 downto 0 => '0') when X"01",
		X"0000" & std_logic_vector(sctr(47 downto 32)) when X"02",
		X"00000000" when X"03",
		b when others;

end rtl;
