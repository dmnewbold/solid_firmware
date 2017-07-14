-- sc_timing
--
-- MMCM, sample counters and synchronous control
--
-- Dave Newbold, September 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_timing is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rst_mmcm: in std_logic; -- MMCM reset
		locked: out std_logic; -- MMCM locked signal
		clk_in_p: in std_logic; -- 40MHz clock from pins
		clk_in_n: in std_logic;
		clk40: out std_logic; -- chip 40MHz clock
		rst40: out std_logic; -- clk40 domain reset
		clk160: out std_logic; -- chip 160MHz clock
		clk280: out std_logic; -- chip 280MHz clock
		sync_in: in std_logic; -- external sync signal in
		trig_in: in std_logic; -- external trigger in
		sctr: out std_logic_vector(47 downto 0); -- sample counter
		chan_sync_ctrl: out std_logic_vector(3 downto 0); -- Timing signals to channels
		trig_en: out std_logic;
		nzs_en: out std_logic;
		zs_en: out std_logic;
		rand: out std_logic_vector(31 downto 0)
	);

end sc_timing;

architecture rtl of sc_timing is

	signal clk40_a,  rst40_a, clk160_a, clk280_a, clk40_i, rst40_i: std_logic;
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal sctr_i, sctr_s: unsigned(47 downto 0);
	signal rst_ctr: unsigned(3 downto 0);
	signal ctrl_rst_ctr, ctrl_cap_ctr, ctrl_en_sync, ctrl_force_sync, ctrl_pipeline_en, ctrl_send_sync: std_logic;
	signal ctrl_chan_slip, ctrl_chan_rst_buf, ctrl_chan_cap, ctrl_chan_inc: std_logic;
	signal frst, sync, sync_f, wait_sync, sync_err, io_err: std_logic;
	signal sync_in_r, trig_in_r, trig_in_r_d: std_logic;
	signal sync_ctr, trig_ctr: unsigned(31 downto 0);

begin

-- Clock generation	

	mmcm: entity work.sc_clocks
		port map(
			clk_in_p => clk_in_p,
			clk_in_n => clk_in_n,
			clk40 => clk40_a,
			clk160 => clk160_a,
			clk280 => clk280_a,
			locked => locked,
			rst_mmcm => rst_mmcm,
			rsti => ctrl(0)(0),
			rst40 => rst40_a
		);
		
	clk40_i <= clk40_a;
	clk40 <= clk40_a;
	rst40_i <= rst40_a;
	rst40 <= rst40_a;
	clk160 <= clk160_a;
	clk280 <= clk280_a;

-- Control register
	
	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 5
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk40_i,
			d => stat,
			q => ctrl,
			stb => stb
		);

	ctrl_rst_ctr <= ctrl(0)(1);
	ctrl_cap_ctr <= ctrl(0)(2);
	ctrl_en_sync <= ctrl(0)(3);
	ctrl_force_sync <= ctrl(0)(4);
	ctrl_pipeline_en <= ctrl(0)(5);
	ctrl_send_sync <= ctrl(0)(6);
	ctrl_chan_slip <= ctrl(0)(12);
	ctrl_chan_rst_buf <= ctrl(0)(13);
	ctrl_chan_cap <= ctrl(0)(14);
	ctrl_chan_inc <= ctrl(0)(15);
	stat(0) <= X"0000000" & '0' & io_err & sync_err & wait_sync;
	stat(1) <= std_logic_vector(sctr_s(31 downto 0));
	stat(2) <= X"0000" & std_logic_vector(sctr_s(47 downto 32));
	stat(3) <= std_logic_vector(sync_ctr);
	stat(4) <= std_logic_vector(trig_ctr);
	
-- External timing signals

	sync_in_r <= sync_in when rising_edge(clk40_i); -- Should be IOB reg
	trig_in_r <= trig_in when rising_edge(clk40_i); -- Should be IOB reg
	trig_in_r_d <= trig_in_r when rising_edge(clk40_i);
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' then
				sync_ctr <= (others => '0');
				trig_ctr <= (others => '0');
			else
				if sync_in_r = '1' then
					sync_ctr <= sync_ctr + 1;
				end if;
				if trig_in_r = '1' and trig_in_r_d = '0' then
					trig_ctr <= trig_ctr + 1;
				end if;
			end if;
		end if;
	end process;
	
-- Sync signals
	
	sync <= (sync_in_r and ctrl_en_sync) or (ctrl_force_sync and stb(0));
	sync_f <= sync and wait_sync;

	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' then
				wait_sync <= '1';
				sync_err <= '0';
			else
				if sync = '1' then
					wait_sync <= '0';
					if wait_sync = '0' and or_reduce(std_logic_vector(sctr_i(BLK_RADIX - 1 downto 0))) /= '0' then
						sync_err <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	io_err <= '1';
	
-- Sample counter
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' or sync_f = '1' then
				sctr_i <= (others => '0');
			else
				sctr_i <= sctr_i + 1;
			end if;
			if stb(0) = '1' and ctrl_cap_ctr = '1' then
				sctr_s <= sctr_i;
			end if;
		end if;
	end process;
		
	sctr <= std_logic_vector(sctr_i);
	
-- Random number gen

	rng: entity work.rng_wrapper
		port map(
			clk => clk40_i,
			rst => wait_sync,
			random => rand
		);
		
-- System enables

	timing: entity work.sc_timing_startup
		port map(
			clk40 => clk40_i,
			rst40 => rst40_i,
			en => ctrl_pipeline_en,
			sync => sync_f,
			sctr => sctr_i,
			nzs_en => nzs_en,
			zs_en => zs_en,
			trig_en => trig_en
		);
	
-- Channel sync control
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' then
				rst_ctr <= "0000";
			elsif frst = '1' or (ctrl_chan_rst_buf = '1' and stb(0) = '1') then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	
	frst <= '1' when rst_ctr /= "1111" else '0';

	chan_sync_ctrl(0) <= ctrl_chan_slip and stb(0); -- bitslip for serdes
	chan_sync_ctrl(1) <= frst; -- reset channel
	chan_sync_ctrl(2) <= ctrl_chan_cap and stb(0); -- cap start
	chan_sync_ctrl(3) <= ctrl_chan_inc and stb(0); -- cap start
	
end rtl;
