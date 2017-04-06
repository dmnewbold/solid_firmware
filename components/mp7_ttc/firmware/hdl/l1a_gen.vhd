-- l1a_gen
--
-- Poisson L1A generator
--
-- div signal is used as simple threshold on 32b random
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_ttc_decl.all;

entity l1a_gen is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		tclk: in std_logic;
		trst: in std_logic;
		l1a: out std_logic
	);

end l1a_gen;

architecture rtl of l1a_gen is

	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal r: std_logic_vector(31 downto 0);
	signal l1a_d: std_logic_vector(N_RULES downto 0);
	signal tcnt: unsigned(31 downto 0);	
	signal l1a_c, l1a_i: std_logic;
	signal rveto: std_logic_vector(N_RULES - 1 downto 0);

begin

-- control register

	reg: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => tclk,
			d => stat,
			q => ctrl,
			stb => stb
		);

	stat(0) <= std_logic_vector(tcnt);
		
-- RNG
		
	rng: entity work.rng_wrapper
		port map(
			clk => tclk,
			rst => trst,
			random => r
		);
		
	l1a_c <= '1' when r(31 downto 30) = "00" and unsigned(r(29 downto 0)) < unsigned(ctrl(0)(29 downto 0)) else '0';
	
-- Trigger counter (pre-rules)

	process(tclk)
	begin
		if rising_edge(tclk) then
			if trst = '1' then
				tcnt <= (others => '0');
			elsif l1a_c = '1' then
				tcnt <= tcnt + 1;
			end if;
		end if;
	end process;
	
-- Veto
	
	l1a_i <= l1a_c and not or_reduce(rveto);
	l1a <= l1a_i;
	
-- Trigger rules

	l1a_d(0) <= l1a_i;

	rgen: for i in 0 to N_RULES - 1 generate
	
		signal delay: integer;
		signal ctr: unsigned(2 downto 0);
	
	begin

		del: entity work.del_array
			generic map(
				DWIDTH => 1,
				DELAY => TRIG_RULES(i).window_del
			)
			port map(
				clk => tclk,
				d(0) => l1a_d(i),
				q(0) => l1a_d(i + 1)
			);

		process(tclk) -- keep track of trigger count in rolling window
		begin
			if rising_edge(tclk) then
				if trst = '1' or ctrl(0)(31) = '0' then
					ctr <= (others => '0');
				else
					if l1a_d(0) = '1' and l1a_d(i + 1) = '0' then
						ctr <= ctr + 1;
					elsif l1a_d(0) = '0' and l1a_d(i + 1) = '1' then
						ctr <= ctr - 1;
					end if;
				end if;
			end if;
		end process;
		
		rveto(i) <= '1' when ctr = to_unsigned(TRIG_RULES(i).maxtrig, 3) else '0';
			
	end generate;

end rtl;
