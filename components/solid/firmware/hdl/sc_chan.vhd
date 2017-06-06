-- sc_chan.vhd
--
-- All the stuff belonging to one input channel
--
-- ctrl_mode: 0 normal; 1 playback; 2 capture; 3 reserved
-- ctrl_src: 0 external; 1 playback buffer; 2 counter; 3 fake data
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

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
		d_test: in std_logic_vector(13 downto 0);
		q_test: out std_logic_vector(13 downto 0);
		sync_ctrl: in std_logic_vector(3 downto 0);
		sctr: in std_logic_vector(13 downto 0);		
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
	signal norm_mode, pb_mode, cap_mode: std_logic;
	signal d_in, d_in_i, d_buf: std_logic_vector(13 downto 0);
	signal d_c: std_logic_vector(1 downto 0);
	signal slip, chan_rst, buf_we, inc: std_logic;
	signal ctrl_en_sync, ctrl_en_buf, ctrl_invert: std_logic;
	signal ctrl_mode, ctrl_src: std_logic_vector(1 downto 0);
	signal cap_full, buf_full, dr_full, dr_warn: std_logic;
	signal sctr_p: std_logic_vector(11 downto 0);
	signal dr_d: std_logic_vector(31 downto 0);
	signal ro_en, keep_i, flush_i, err_i, req, blkend, dr_blkend, dr_wen: std_logic;
	
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
	ctrl_mode <= ctrl(0)(5 downto 4);
	ctrl_src <= ctrl(0)(7 downto 6);
	
	slip <= sync_ctrl(0) and ctrl_en_sync; -- CDC
	chan_rst <= (sync_ctrl(1) and ctrl_en_sync) or rst40; -- CDC
	buf_we <= sync_ctrl(2) and ctrl_en_sync; -- CDC
	inc <= sync_ctrl(3) and ctrl_en_sync; -- CDC
	
	stat(0) <= X"000000" & "000" & err_i & dr_warn & dr_full & buf_full & cap_full; -- CDC

	norm_mode <= '1' when ctrl_mode = "00" else '0';
	pb_mode <= '1' when ctrl_mode = "01" else '0';
	cap_mode <= '1' when ctrl_mode = "10" else '0';

-- Input logic
	
	io: entity work.sc_input_serdes
		port map(
			clk => clk40,
			rst => rst40,
			clk_s => clk280,
			d_p => d_p,
			d_n => d_n,
			slip => slip,
			inc => inc,
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
		d_test when "01",
		"00" & sctr_p when "10",
		fake when others;
		
-- Channel status

	err_i <= buf_full or dr_full;
	err <= err_i;
	ro_en <= not (pb_mode or cap_mode or err_i) and ctrl_en_buf;
	keep_i <= keep and ro_en;
	flush_i <= flush and ro_en;
	veto <= dr_warn or not ro_en;
	
-- Buffers
	
	blkend <= and_reduce(sctr(BLK_RADIX - 1 downto 0));

	buf: entity work.sc_chan_buf
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			ipb_in_ptr => ipbw(N_SLV_PTRS),
			ipb_out_ptr => ipbr(N_SLV_PTRS),
			mode => ctrl_mode,
			clk40 => clk40,
			clk160 => clk160,
			buf_rst => chan_rst,
			d => d_buf,
			blkend => blkend,	
			nzs_en => nzs_en,
			cap_full => cap_full,
			zs_thresh => ctrl(0)(29 downto 16), -- CDC
			q_test => q_test,
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
			rst40 => chan_rst,
			mark => blkend,
			en => nzs_en,
			d => d_buf,
			trig => trig
		);

end rtl;
