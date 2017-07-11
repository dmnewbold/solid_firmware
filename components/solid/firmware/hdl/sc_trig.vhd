-- sc_trig
--
-- Trigger generation
--
-- Dave Newbold, September 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_trig.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_trig is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		trig_en: in std_logic;
		zs_en: in std_logic;
		sctr: in std_logic_vector(47 downto 0);
		rand: in std_logic_vector(31 downto 0);
		keep: out std_logic_vector(N_CHAN - 1 downto 0);
		flush: out std_logic_vector(N_CHAN - 1 downto 0);
		veto: in std_logic_vector(N_CHAN - 1 downto 0);
		zs_sel: out std_logic_vector(1 downto 0);
		trig: in sc_trig_array;
		force: in std_logic;
		thresh_hit: out std_logic;
		ro_d: out std_logic_vector(31 downto 0);
		ro_blkend: out std_logic;
		ro_we: out std_logic;
		ro_veto: in std_logic;
		q: out std_logic_vector(15 downto 0);
		q_valid: out std_logic;
		d: in std_logic_vector(15 downto 0);
		d_valid: in std_logic;
		d_ack: out std_logic
	);

end sc_trig;

architecture rtl of sc_trig is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal ctrl_dtmon_en: std_logic;
	signal masks: ipb_reg_v(N_CHAN_TRG * 2 - 1 downto 0);
	signal trig_mask: std_logic_vector(N_TRG - 1 downto 0);
	signal ctrig: sc_trig_array;
	signal lq: std_logic_vector(15 downto 0);
	signal rveto, lvalid, lack, mark, err: std_logic;
	signal zs_cfg: std_logic_vector(31 downto 0);
	signal veto_p, veto_i, keep_i, flush_i: std_logic_vector(N_CHAN - 1 downto 0);
	signal b_q, t_q: std_logic_vector(31 downto 0);
	signal b_go, t_go, b_valid, t_valid, b_blkend, t_blkend, blkend: std_logic;
	signal tctr: std_logic_vector(27 downto 0);
	signal ro_ctr: std_logic_vector(7 downto 0);

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
      sel => ipbus_sel_sc_trig(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Control register
	
	csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 2
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => clk40,
			d => stat,
			q => ctrl
		);

	ctrl_dtmon_en <= ctrl(0)(0);
	stat(0) <= X"0" & tctr;
	stat(1) <= X"0000000" & "00" & rveto & err;

-- Readout veto (eventually also set under error conditions
-- on trigger links, dtmon, etc)

	mark <= trig_en and and_reduce(sctr(BLK_RADIX - 1 downto 0));

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' then
				rveto <= '0';
			elsif mark = '1' then
				rveto <= ro_veto;
			end if;
		end if;
	end process;
	
-- Channel trigger masks

	mask: entity work.ipbus_reg_v
		generic map(
			N_REG => N_CHAN_TRG * 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CHAN_MASK),
			ipbus_out => ipbr(N_SLV_CHAN_MASK),
			q => masks
		);
		
	mgen: for i in N_CHAN_TRG - 1 downto 0 generate
		signal m: std_logic_vector(63 downto 0);
	begin
		m <= masks(i * 2 + 1) & masks(i * 2);
		ctrig(i) <= trig(i) and m(N_CHAN - 1 downto 0);
	end generate;
		
-- Local trigger logic

	ltrig_reg: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_LOC_MASK),
			ipbus_out => ipbr(N_SLV_LOC_MASK),
			q => trig_mask,
			qmask(0) => (N_TRG - 1 downto 0 => '1', others => '0')
		);

	ltrig: entity work.sc_local_trig
		port map(
			clk40 => clk40,
			rst40 => rst40,
			en => trig_en,
			mask => trig_mask,
			mark => mark,
			sctr => sctr,
			rand => rand,
			chan_trig => ctrig,
			trig_q => lq,
			trig_valid => lvalid,
			trig_ack => lack,
			force => force,
			thresh_hit => thresh_hit,
			ro_q => t_q,
			ro_valid => t_valid,
			ro_blkend => t_blkend,
			ro_go => t_go,
			ro_ctr => ro_ctr,		
			rveto => rveto
		);
	
	q <= lq;
	q_valid <= lvalid;
	
-- ZS threshold select

	zsreg: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_ZS_CFG),
			ipbus_out => ipbr(N_SLV_ZS_CFG),
			q(0) => zs_cfg
		);

	zssel: entity work.sc_zs_sel
		port map(
			clk40 => clk40,
			rst40 => rst40,
			mark => mark,
			zscfg => zs_cfg,
			trig => lq,
			trig_valid => lvalid,
			sel => zs_sel
		);

-- Readout sequencer

	seq: entity work.sc_seq
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_SEQ),
			ipb_out => ipbr(N_SLV_SEQ),
			clk40 => clk40,
			rst40 => rst40,
			zs_en => zs_en,
			sctr => sctr(31 downto 0),
			d_loc => lq,
			valid_loc => lvalid,
			ack_loc => lack,
			d_ext => d,
			valid_ext => d_valid,
			ack_ext => d_ack,
			keep => keep_i,
			flush => flush_i,
			err => err
		);
			
-- Channel interface

	veto_p <= veto or (veto'range => rveto);
	keep <= keep_i and not veto_p when mark = '1' else (others => '0');
	flush <= not keep_i or veto_p when mark = '1' else (others => '0');
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			if trig_en = '0' then
				veto_i <= (others => '0');
			elsif mark = '1' then
				veto_i <= veto_p;
			end if;
		end if;
	end process;
			
-- Readout header to ROC

	rdata: entity work.sc_trig_ro_block
		port map(
			clk40 => clk40,
			rst40 => rst40,
			trig_en => trig_en,
			sctr => sctr,
			mark => mark,
			keep => keep_i,
			veto => veto_i,
			tctr => tctr,
			ro_q => b_q,
			ro_valid => b_valid,
			ro_blkend => b_blkend,
			ro_go => b_go,
			ro_ctr => ro_ctr,
			rveto => rveto
		);
		
-- ROC output

	b_go <= mark;
	t_go <= and_reduce(sctr(4 downto 0)) and not or_reduce(sctr(BLK_RADIX - 1 downto 5));

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or blkend = '1' then
				ro_ctr <= (others => '0');
			elsif b_valid = '1' or t_valid = '1' then
				ro_ctr <= std_logic_vector(unsigned(ro_ctr) + 1);
			end if;
		end if;
	end process;

	ro_d <= t_q when t_valid = '1' else b_q;
	ro_we <= b_valid or t_valid;
	blkend <= (b_blkend and b_valid) or (t_blkend and t_valid);
	ro_blkend <= blkend;

-- Deadtime monitor

	dmon: entity work.sc_deadtime_mon
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_DTMON),
			ipb_out => ipbr(N_SLV_DTMON),
			en => ctrl_dtmon_en,
			clk40 => clk40,
			rst40 => rst40,
			clk160 => clk160,
			mark => mark,
			sctr => sctr(BLK_RADIX - 1 downto 0),
			keep => keep_i,
			veto => veto_i
		);

end rtl;
