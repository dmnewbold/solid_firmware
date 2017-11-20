-- sc_fake
--
-- Fake data generator for trigger testing
--
-- mode = 0 is random data; mode = 1 is fake pulses
-- NB: for sample lock mode, pulse is issued 2 cycles after setting
--
-- Dave Newbold, June 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_fake.all;
use work.ipbus_reg_types.all;

entity sc_fake is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		rand: in std_logic_vector(31 downto 0);
		sctr: in std_logic_vector(7 downto 0);
		fake: out std_logic_vector(13 downto 0)
	);

end sc_fake;

architecture rtl of sc_fake is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal ctrl_en, ctrl_mode, ctrl_force, ctrl_samp_lock: std_logic;
	signal params: ipb_reg_v(1 downto 0);
	signal params_freq_div: std_logic_vector(3 downto 0);
	signal params_n, params_gap, params_samp: std_logic_vector(7 downto 0);
	signal params_level, params_ped: std_logic_vector(13 downto 0);
	signal mask: std_logic_vector(15 downto 0);
	signal pulse: std_logic_vector(13 downto 0);
	signal p, go, samp, pend, act, done: std_logic;
	signal pcnt, gcnt: unsigned(7 downto 0);

begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_sc_fake(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Ctrl

	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_CTRL),
			ipb_out => ipbr(N_SLV_CTRL),
			slv_clk => clk40,
			q => ctrl,
			stb => stb
		);
		
	ctrl_en <= ctrl(0)(0);
	ctrl_mode <= ctrl(0)(1);
	ctrl_force <= ctrl(0)(2) and stb(0);
	ctrl_samp_lock <= ctrl(0)(3);
    
-- Parameters

	params_csr: entity work.ipbus_reg_v
		generic map(
			N_REG => 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_PARAMS),
			ipbus_out => ipbr(N_SLV_PARAMS),
			q => params
		);

	params_freq_div <= params(0)(3 downto 0);
	params_n <= params(0)(15 downto 8);
	params_gap <= params(0)(23 downto 16);
	params_samp <= params(0)(31 downto 24);
	params_level <= params(1)(13 downto 0);
	params_ped <= params(1)(29 downto 16);
	
-- Trigger

	process(params_freq_div)
	begin
		for i in mask'range loop
			if i > to_integer(unsigned(params_freq_div)) then
				mask(i) <= '0';
			else
				mask(i) <= '1';
			end if;
		end loop;
	end process;

	go <= '1' when ctrl_force = '1' or (ctrl_en = '1' and (or_reduce(mask and rand(27 downto 12)) = '0' and or_reduce(rand(11 downto 0)) = '0')) else '0';
	samp <= '1' when ctrl_samp_lock = '0' or sctr = params_samp else '0';
	pend <= (pend or (go and not act)) and not (rst40 or act) when rising_edge(clk40);
	act <= (act or (pend and samp)) and not (rst40 or done) when rising_edge(clk40);
	
-- Pulse generator

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or done = '1' then
				pcnt <= (others => '0');
				gcnt <= (others => '0');
				p <= '0';
			elsif act = '1' then
				if gcnt = 0 then
					gcnt <= unsigned(params_gap);
					p <= '1';
					pcnt <= pcnt + 1;
				else
					gcnt <= gcnt - 1;
					p <= '0';
				end if;
			end if;
		end if;
	end process;
				
	done <= '1' when pcnt = unsigned(params_n) else '0';
	
-- Output

	pulse <= params_level when p = '1' else params_ped;
	fake <= rand(13 downto 0) when ctrl_mode = '0' else pulse;
	
end rtl;
