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
		clk80: out std_logic; -- chip 80MHz clock
		clk280: out std_logic; -- chip 280MHz clock
		sync_in: in std_logic; -- external sync signal in
		trig_in: in std_logic; -- external trigger in
		led: out std_logic; -- LED flash out
		sctr: out std_logic_vector(47 downto 0); -- sample counter
		chan_sync_ctrl: out std_logic_vector(3 downto 0); -- Timing signals to channels
		dr_en: out std_logic;
		nzs_en: out std_logic;
		zs_en: out std_logic;
		rand: out std_logic_vector(31 downto 0);
		nzs_blks: out std_logic_vector(3 downto 0)
	);

end sc_timing;

architecture rtl of sc_timing is

	signal clk40_a,  rst40_a, clk80_a, clk280_a, clk40_i, rst40_i: std_logic;
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(4 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal sctr_i, sctr_s: unsigned(47 downto 0);
	signal ctrl_rst_ctr, ctrl_cap_ctr, ctrl_en_sync, ctrl_force_sync, ctrl_pipeline_en, ctrl_send_sync: std_logic;
	signal ctrl_chan_slip_l, ctrl_chan_slip_h, ctrl_chan_rst_buf, ctrl_chan_cap, ctrl_chan_inc: std_logic;
	signal ctrl_zs_blks: std_logic_vector(7 downto 0);
	signal ctrl_nzs_blks: std_logic_vector(3 downto 0);
	signal sync, wait_sync, sync_err, io_err, dr_en_i: std_logic;
	signal sync_in_r, trig_in_r, trig_in_r_d: std_logic;
	signal sync_ctr, trig_ctr: unsigned(31 downto 0);
	
	attribute IOB: string;
	attribute IOB of sync_in_r, trig_in_r: signal is "TRUE";

begin

-- Clock generation	

	mmcm: entity work.sc_clocks
		port map(
			clk_in_p => clk_in_p,
			clk_in_n => clk_in_n,
			clk40 => clk40_a,
			clk80 => clk80_a,
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
	clk80 <= clk80_a;
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
	ctrl_chan_slip_l <= ctrl(0)(12);
	ctrl_chan_slip_h <= ctrl(0)(13);
	ctrl_chan_cap <= ctrl(0)(14);
	ctrl_chan_inc <= ctrl(0)(15);
	ctrl_zs_blks <= ctrl(0)(23 downto 16);
	ctrl_nzs_blks <= ctrl(0)(27 downto 24);
	stat(0) <= X"0000000" & '0' & dr_en_i & sync_err & wait_sync;
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
	wait_sync <= (wait_sync and not sync) or rst40_i when rising_edge(clk40_i);
		
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' then
				sync_err <= '0';
			elsif wait_sync = '0' and
				((sync = '1' and or_reduce(std_logic_vector(sctr_i(BLK_RADIX - 1 downto 0))) /= '0') or
				(sync = '0' and or_reduce(std_logic_vector(sctr_i(BLK_RADIX - 1 downto 0))) = '0')) then
				sync_err <= '1';
			end if;
		end if;
	end process;
	
	led <= not (wait_sync or sync_err);
	
-- Sample counter
	
	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			if rst40_i = '1' or wait_sync = '1' then
				sctr_i <= X"000000000001";
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
			zs_blks => ctrl_zs_blks,
			nzs_blks => ctrl_nzs_blks,
			sync => sync,
			sctr => sctr_i,
			nzs_en => nzs_en,
			zs_en => zs_en,
			dr_en => dr_en_i
		);

	nzs_blks <= ctrl_nzs_blks;
	dr_en <= dr_en_i;
	
-- Channel sync control

	chan_sync_ctrl(0) <= ctrl_chan_slip_l and stb(0); -- bitslip for serdes
	chan_sync_ctrl(1) <= ctrl_chan_slip_h and stb(0);
	chan_sync_ctrl(2) <= ctrl_chan_cap and stb(0); -- cap start
	chan_sync_ctrl(3) <= ctrl_chan_inc and stb(0); -- inc for idelay
	
end rtl;
