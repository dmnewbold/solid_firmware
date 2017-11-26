-- sc_chan.vhd
--
-- All the stuff belonging to one input channel
--
-- ctrl_mode: 0 normal; 1 playback / capture
-- ctrl_src: 0 external; 1 playback buffer; 2 counter; 3 fake data
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_chan.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_chan is
	generic(
		id: integer
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		clk280: in std_logic;
		d_p: in std_logic;
		d_n: in std_logic;
		sync_ctrl: in std_logic_vector(3 downto 0);
		zs_sel: in std_logic_vector(1 downto 0);
		sctr: in std_logic_vector(47 downto 0);		
		fake: in std_logic_vector(13 downto 0);		
		nzs_en: in std_logic;
		zs_en: in std_logic;
		keep: in std_logic;
		flush: in std_logic;
		err: out std_logic;
		veto: out std_logic;
		trig: out std_logic_vector(N_CHAN_TRG - 1 downto 0);
		clk_dr: in std_logic;
		q: out std_logic_vector(31 downto 0);
		q_blkend: out std_logic;
		q_empty: out std_logic;
		ren: in std_logic
	);

end sc_chan;

architecture rtl of sc_chan is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);		
	signal d_in, d_in_i, d_buf: std_logic_vector(15 downto 0);
	signal d_c: std_logic_vector(1 downto 0);
	signal slip_l, slip_h, chan_rst, cap, inc: std_logic;
	signal act_slip: unsigned(7 downto 0);
	signal cntout: std_logic_vector(4 downto 0);
	signal ctrl_en_sync, ctrl_en_buf, ctrl_invert: std_logic;
	signal ctrl_mode: std_logic;
	signal ctrl_src: std_logic_vector(1 downto 0);
	signal cap_full, buf_full, dr_full, dr_warn: std_logic;
	signal zs_thresh_v: ipb_reg_v(N_ZS_THRESH - 1 downto 0);
	signal zs_sel_i: integer range 2 ** zs_sel'length - 1 downto 0 := 0;
	signal zs_thresh: std_logic_vector(13 downto 0);
	signal sctr_p: std_logic_vector(11 downto 0);
	signal dr_d: std_logic_vector(31 downto 0);
	signal ro_en, keep_i, flush_i, err_i, req, blkend, dr_blkend, dr_wen: std_logic;
	signal ctrl_tt: std_logic;
	
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
      sel => ipbus_sel_sc_chan(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	ctrl_en_sync <= ctrl(0)(0);
	ctrl_en_buf <= ctrl(0)(1);
	ctrl_invert <= ctrl(0)(2);
	ctrl_mode <= ctrl(0)(4);
	ctrl_src <= ctrl(0)(7 downto 6);
	
	slip_l <= sync_ctrl(0) and ctrl_en_sync; -- CDC
	slip_h <= sync_ctrl(1) and ctrl_en_sync; -- CDC
	cap <= sync_ctrl(2) and ctrl_en_sync; -- CDC
	inc <= sync_ctrl(3) and ctrl_en_sync; -- CDC
	
	stat(0) <= X"00" & "000" & cntout & std_logic_vector(act_slip) & "000" & err_i & dr_warn & dr_full & buf_full & cap_full; -- CDC

-- Keep track of slips and taps for debug

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' then
				act_slip <= X"00";
			elsif slip = '1' then
				act_slip <= act_slip + 1;
			end if;
		end if;
	end process;

-- Input logic
	
	io: entity work.sc_input_serdes
		port map(
			clk => clk40,
			rst => rst40,
			clk_s => clk280,
			d_p => d_p,
			d_n => d_n,
			slip_l => slip_l,
			slip_h => slip_h,
			inc => inc,
			cntout => cntout,
			q => d_in
		);
		
	d_in_i <= d_in when ctrl_invert = '0' else not d_in;
	
	with sctr(1 downto 0) select sctr_p <=
		sctr(11 downto 0) when "00",
		sctr(23 downto 12) when "01",
		sctr(35 downto 24) when "10",
		sctr(47 downto 36) when others;
	
	with ctrl_src select d_buf <=
		d_in_i when "00",
		(others => '0') when "01",
		"0000" & sctr_p when "10",
		"00" & fake when others;
		
-- Channel status

	err_i <= buf_full or dr_full;
	err <= err_i;
	ro_en <= not (ctrl_mode or err_i) and ctrl_en_buf;
	keep_i <= keep and ro_en;
	flush_i <= flush and ro_en;
	veto <= dr_warn or not ro_en;
	
-- ZS thresholds

	zs_t: entity work.ipbus_reg_v
		generic map(
			N_REG => N_ZS_THRESH
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_ZS_THRESH),
			ipbus_out => ipbr(N_SLV_ZS_THRESH),
			q => zs_thresh_v,
			qmask => (others => X"00003fff")
		);
		
	zs_sel_i <= to_integer(unsigned(zs_sel)); -- Might need pipelining here

	process(clk)
	begin
		if rising_edge(clk) and blkend = '1' then
			if zs_sel_i < N_ZS_THRESH then
				zs_thresh <= (others => '0');
			else
				zs_thresh <= zs_thresh_v(zs_sel_i)(13 downto 0);
			end if;
		end if;
	end process;
	
-- Buffers
	
	blkend <= and_reduce(sctr(BLK_RADIX - 1 downto 0));

	buf: entity work.sc_chan_buf
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			mode => ctrl_mode,
			clk40 => clk40,
			clk160 => clk160,
			buf_rst => rst40,
			d => d_buf,
			blkend => blkend,	
			nzs_en => nzs_en,
			cap => cap,
			cap_full => cap_full,
			zs_thresh => zs_thresh,
			zs_en => zs_en,
			buf_full => buf_full,
			keep => keep_i,
			flush => flush_i,
			q => dr_d,
			q_blkend => dr_blkend,
			wen => dr_wen
		);

-- Derandomiser

	derand: entity work.sc_derand
		port map(
			clk_w => clk40,
			rst_w => rst40,
			d => dr_d,
			d_blkend => dr_blkend,
			wen => dr_wen,
			clk_r => clk_dr,
			q => q,
			q_blkend => q_blkend,
			empty => q_empty,
			ren => ren,
			warn => dr_warn,
			full => dr_full
		);
	
-- Local triggers
	
	ctrig: entity work.sc_chan_trig
		generic map(
			VAL_WIDTH => 14
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_TRIG_THRESH),
			ipb_out => ipbr(N_SLV_TRIG_THRESH),
			clk40 => clk40,
			rst40 => rst40,
			mark => blkend,
			en => nzs_en,
			d => d_buf(13 downto 0),
			trig => trig
		);

end rtl;
