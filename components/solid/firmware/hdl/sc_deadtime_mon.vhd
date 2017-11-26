-- sc_deadtime_mon
--
-- Deadtime counters
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_deadtime_mon is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		en: in std_logic;
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		mark: in std_logic;
		sctr: in std_logic_vector(BLK_RADIX - 1 downto 0);
		keep: in std_logic_vector(N_CHAN - 1 downto 0);
		veto: in std_logic_vector(N_CHAN - 1 downto 0)
	);

end sc_deadtime_mon;

architecture rtl of sc_deadtime_mon is

	constant ADDR_BITS: integer := calc_width(N_CHAN) + 2;
	signal c: unsigned(1 downto 0);
	signal en_i, first: std_logic;
	signal d_ram, q_ram: std_logic_vector(31 downto 0);
	signal a_ram: std_logic_vector(ADDR_BITS - 1 downto 0);
	signal we, inc, done, p: std_logic;
	signal sel: integer range 2 ** (ADDR_BITS - 1) - 1 downto 0 := 0;
	signal sel_c: integer range N_CHAN - 1 downto 0 := 0;
	signal veto_r: std_logic_vector(N_CHAN - 1 downto 0);

begin

-- Timing

	process(clk160)
	begin
		if rising_edge(clk160) then
			if rst40 = '1' then
				c <= "00";
			else
				c <= c + 1;
			end if;
		end if;
	end process;
	
-- Enable

	process(clk40)
	begin
		if rising_edge(clk40) then	
			if rst40 = '1' then
				first <= '0';
				en_i <= '0';
				done <= '1';
			elsif mark = '1' then
				en_i <= en;
				first <= en and not en_i;
			elsif and_reduce(sctr(BLK_RADIX - 2 downto 0)) = '1' then
				done <= '0';
			elsif sel = N_CHAN then
				done <= '1';
			end if;
		end if;
	end process;

-- RAM for counters

	ram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => ADDR_BITS,
			DATA_WIDTH => 32
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
	
	d_ram <= std_logic_vector(unsigned(q_ram) + unsigned(std_logic_vector'(0 => inc))) when first = '0' else (0 => inc, others => '0');
	we <= c(0) and not done;
	a_ram <= sctr(ADDR_BITS - 2 downto 0) & c(1); 
	
-- Counter enables

	sel <= to_integer(unsigned(sctr(ADDR_BITS - 1 downto 1)));
	sel_c <= sel when sel < N_CHAN else 0;
	
	veto_r <= veto when rising_edge(clk40); -- Pipelining to meet timing
	
	with std_logic_vector'(sctr(0) & c(1)) select inc <=
		'1' when "00",
		keep(sel_c) when "01",
		veto_r(sel_c) when "10",
		keep(sel_c) and veto_r(sel_c) when others;
		
end rtl;
