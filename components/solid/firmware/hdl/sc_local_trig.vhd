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

use work.top_decl.all;

entity sc_local_trig is
	port(
		clk40: in std_logic;
		rst40: in std_logic;
		en: in std_logic;
		mask: in std_logic_vector(N_TRG - 1 downto 0);
		mark: in std_logic;
		sctr: in std_logic_vector(47 downto 0);
		rand: in std_logic_vector(31 downto 0);
		chan_trig: in sc_trig_array;
		trig_q: out std_logic_vector(15 downto 0);
		trig_valid: out std_logic;
		trig_ack: in std_logic;
		force: in std_logic;
		ext_trig_in: in std_logic;
		ro_q: out std_logic_vector(31 downto 0);
		ro_valid: out std_logic;
		ro_blkend: out std_logic;
		ro_go: in std_logic;
		ro_ctr: in std_logic_vector(7 downto 0);
		rveto: in std_logic
	);

end sc_local_trig;

architecture rtl of sc_local_trig is

	signal tv, te, ta, tc: std_logic_vector(N_TRG - 1 downto 0);
	signal s: integer range N_TRG - 1 downto 0;
	signal ch: integer range 2 ** ro_ctr'length - 1 downto 0;
	signal ch_i: integer range N_CHAN - 1 downto 0 := 0;
	signal cact: sc_ltrig_array;
	signal go, blkend, rveto_d, last_gasp, hoorah: std_logic;
	signal bi: std_logic_vector(63 downto 0);
	signal b: std_logic_vector(31 downto 0);
	
begin
	
-- Threshold trigger generator

	tg0: entity work.sc_trig_gen_or
		generic map(
			TBIT => 0,
			DELAY => 2
		)
		port map(
			clk => clk40,
			en => en,
			mark => mark,
			chan_trig => chan_trig,
			chan_act => cact(0),
			valid => tv(0),
			ack => ta(0)
		);
		
-- peaks-over-threshold trigger generator

	tg1: entity work.sc_trig_gen_or
		generic map(
			TBIT => 1,
			DELAY => 3
		)
		port map(
			clk => clk40,
			en => en,
			mark => mark,
			chan_trig => chan_trig,
			chan_act => cact(1),
			valid => tv(1),
			ack => ta(1)
		);
	
-- time-over-threshold trigger generator

	tg2: entity work.sc_trig_gen_or
		generic map(
			TBIT => 2,
			DELAY => 2
		)
		port map(
			clk => clk40,
			en => en,
			mark => mark,
			chan_trig => chan_trig,
			chan_act => cact(2),
			valid => tv(2),
			ack => ta(2)
		);
		
-- random / external trigger generator

	tg3: entity work.sc_trig_gen
		generic map(
			DELAY => 2
		)
		port map(
			clk => clk40,
			en => en,
			mark => mark,
			trig => force,
			valid => tv(3),
			ack => ta(3)
		);
		
	cact(3) <= (others => '0');

-- Add more trigger generators here...

-- Priority encoder

	te <= tv and mask;

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
			if en = '0' or blkend = '1' then
				tc <= (others => '0');
			else
				tc <= tc or ta;
			end if;
		end if;
	end process;
	
-- Last gasp message flag

	rveto_d <= rveto and en when rising_edge(clk40) and mark = '1';
	last_gasp <= rveto and not rveto_d;
	hoorah <= rveto_d and not rveto;
	
-- Trigger data to readout

	go <= (go or (ro_go and ((or_reduce(tc) and not rveto) or last_gasp or hoorah))) and not blkend and en and not rst40 when rising_edge(clk40);
	blkend <= '1' when unsigned(ro_ctr) = 3 + 2 * N_TRG else '0';
	ro_valid <= go;
	ro_blkend <= blkend;

	ch <= to_integer(unsigned(ro_ctr(ro_ctr'length - 1 downto 1)));
	ch_i <= ch - 2 when ch > 1 and ch < N_TRG else 0;
	bi <= (63 downto N_CHAN => '0') & cact(ch_i);
	b <= bi(63 downto 32) when ro_ctr(0) = '1' else bi(31 downto 0);

	with ro_ctr select ro_q <=
		X"100" & "00" & last_gasp & hoorah & (15 downto N_TRG => '0') & tc when X"00", -- Type 1
		std_logic_vector(sctr(31 downto BLK_RADIX)) & (BLK_RADIX - 1 downto 0 => '0') when X"01",
		X"0000" & std_logic_vector(sctr(47 downto 32)) when X"02",
		X"00000000" when X"03",
		b when others;

end rtl;
