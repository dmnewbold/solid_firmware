-- Dave Newbold, February 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_top.all;
use work.ipbus_reg_types.all;

entity payload is
  generic (
    FW_REV : std_logic_vector(15 downto 0) := X"0004"
    );
  port(
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		nuke: out std_logic;
		soft_rst: out std_logic;
		userled: out std_logic;
		clk125: in std_logic;
		clk_rstn_p: out std_logic;
		clk_rstn_n: out std_logic;
		clk_o_p: out std_logic;
		clk_o_n: out std_logic;
		clk_i_p: in std_logic;
		clk_i_n: in std_logic;
		trig_o_p: out std_logic;
		trig_o_n: out std_logic;
		trig_i_p: in std_logic;
		trig_i_n: in std_logic;
		sync_o_p: out std_logic;
		sync_o_n: out std_logic;
		sync_i_p: in std_logic;
		sync_i_n: in std_logic;
		trig_sel_p: out std_logic;
		trig_sel_n: out std_logic;
		sync_sel_p: out std_logic;
		sync_sel_n: out std_logic;
		scl_p: out std_logic;
		scl_n: out std_logic;
		sda_o_p: out std_logic;
		sda_o_n: out std_logic;
		sda_i_p: in std_logic;
		sda_i_n: in std_logic;
		busy_o_p: out std_logic;
		busy_o_n: out std_logic;
		busy_i_p: in std_logic_vector(9 downto 0);
		busy_i_n: in std_logic_vector(9 downto 0)
	);

end payload;

architecture rtl of payload is

	constant BLK_RADIX: integer := 8; -- 256 sample blocks

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, sync_ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(3 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal scl, sda_i, sda_o: std_logic;
	signal ctrl_layer, ctrl_pll_rstn, ctrl_rst, ctrl_en_sync, ctrl_en_trig_out, ctrl_force_trig_out: std_logic;
	signal ctrl_trig_in_mask: std_logic_vector(9 downto 0) := (others => '0');
	signal clki: std_logic;
	signal clkdiv: std_logic_vector(0 downto 0);
	signal sync_sel, trig_sel, sync_in_us, sync_out_ds, trig_in_us, trig_out_ds, trig_out_us: std_logic;
	signal trig_in_ds, trig_i,trig_i_masked: std_logic_vector(9 downto 0);
	signal trig_ir: std_logic;
	signal ctr: unsigned(BLK_RADIX - 1 downto 0);
	signal sync_out_ctr, trig_out_ctr , trig_in_ctr : unsigned(31 downto 0) := ( others => '0' );
	signal trig_ir_d1 , trig_ir_d2 : std_logic := '0';
	signal rst_counters : std_logic := '0';

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
      sel => ipbus_sel_top(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 4
		)
		port map(
			clk => ipb_clk,
			reset => ipb_rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	soft_rst <= ctrl(0)(0);
	nuke <= ctrl(0)(1);
	ctrl_pll_rstn <= not ctrl(0)(2);
	ctrl_rst <= ctrl(0)(3);
	ctrl_layer <= ctrl(0)(4);
	ctrl_trig_in_mask <= ctrl(0)(15 downto 6);

	stat(0) <= X"a753" & FW_REV;
	stat(1) <= std_logic_vector(sync_out_ctr);
	stat(2) <= std_logic_vector(trig_out_ctr);
	stat(3) <= std_logic_vector(trig_in_ctr);

-- trigger and sync Counters

	process(clki)
	begin
		if rising_edge(clki) then
			if rst_counters = '1' then
				sync_out_ctr <= (others => '0');
				trig_out_ctr <= (others => '0');
				trig_in_ctr <= (others => '0');
			else
				if sync_out_ds = '1' then
					sync_out_ctr <= sync_out_ctr + 1;
				end if;
				if trig_out_ds = '1' then
					trig_out_ctr <= trig_out_ctr + 1;
				end if;
				if trig_ir_d1 = '1' and trig_ir_d2 = '0' then
					trig_in_ctr <= trig_in_ctr + 1;
				end if;
			end if;
			trig_ir_d1 <= or_reduce(trig_i and ctrl_trig_in_mask);
			trig_ir_d2 <= trig_ir_d1;
		end if;
	end process;
        
-- Sync ctrl

	sync_csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_SYNC_CTRL),
			ipb_out => ipbr(N_SLV_SYNC_CTRL),
			slv_clk => clki,
			q => sync_ctrl,
			stb => stb
		);
		
	ctrl_en_sync <= sync_ctrl(0)(0);
	ctrl_en_trig_out <= sync_ctrl(0)(1);
	ctrl_force_trig_out <= sync_ctrl(0)(2) and stb(0);
	rst_counters <= sync_ctrl(0)(3) and stb(0);

-- General IO

	userled <= '0';
	
-- I2C

	i2c_analog: entity work.ipbus_i2c_master
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_I2C),
			ipb_out => ipbr(N_SLV_I2C),
			scl => scl,
			sda_o => sda_o,
			sda_i => sda_i
		);
		
-- The business

	process(clki)
	begin
		if rising_edge(clki) then
			if ctrl_en_sync = '0' then
				ctr <= (others => '0');
			else
				ctr <= ctr + 1;
			end if;
		end if;
	end process;

-- ctrl_layer =0 --> sync,trig are controlled by local FPGA.
-- ctrl_layer=1 --> sync,trig are conrolled from upstream HDMI

	sync_sel <= not ctrl_layer; -- Set sync_sel=1 for output sync to be
                                    -- driven by FPGA. Set sync_sel=0 to be
                                    -- driven from upstream
                                    -- (From FPGA for layer 0, from upstream input for layer 1)
	trig_sel <= not ctrl_layer; -- From FPGA for layer 0, from upstream input for layer 1
	sync_out_ds <= ctrl_en_sync and not or_reduce(std_logic_vector(ctr)) when falling_edge(clki); -- Sync out downstream
	trig_i <= trig_in_ds when rising_edge(clki); -- Should be IOB reg
	trig_i_masked <= (trig_i and ctrl_trig_in_mask) when rising_edge(clki);
	trig_ir <= ((or_reduce(trig_i_masked) or ctrl_force_trig_out) and ctrl_en_trig_out) when rising_edge(clki) ;
	trig_out_ds <= trig_ir when falling_edge(clki); -- Trig out downstream
	trig_out_us <= trig_ir when falling_edge(clki); -- Trig out upstream

-- Cable IO

	bufs: entity work.sc_timing_iobufs
		port map(
			clk_rstn => ctrl_pll_rstn,
			clk_rstn_p => clk_rstn_p,
			clk_rstn_n => clk_rstn_n,
			clk => '0',
			clk_o_p => clk_o_p,
			clk_o_n => clk_o_n,
			clk_i => clki,
			clk_i_p => clk_i_p,
			clk_i_n => clk_i_n,
			trig_o => trig_out_ds,
			trig_o_p => trig_o_p,
			trig_o_n => trig_o_n,
			trig_i => trig_in_us,
			trig_i_p => trig_i_p,
			trig_i_n => trig_i_n,
			sync_o => sync_out_ds,
			sync_o_p => sync_o_p,
			sync_o_n => sync_o_n,
			sync_i => sync_in_us,
			sync_i_p => sync_i_p,
			sync_i_n => sync_i_n,
			trig_sel => trig_sel,
			trig_sel_p => trig_sel_p,
			trig_sel_n => trig_sel_n,
			sync_sel => sync_sel,
			sync_sel_p => sync_sel_p,
			sync_sel_n => sync_sel_n,
			scl => scl,
			scl_p => scl_p,
			scl_n => scl_n,
			sda_o => sda_o,
			sda_o_p => sda_o_p,
			sda_o_n => sda_o_n,
			sda_i => sda_i,
			sda_i_p => sda_i_p,
			sda_i_n => sda_i_n,
			busy_o => trig_out_us,
			busy_o_p => busy_o_p,
			busy_o_n => busy_o_n,
			busy_i => trig_in_ds,
			busy_i_p => busy_i_p,
			busy_i_n => busy_i_n
		);
		
-- Clock frequency counter
	
	div: entity work.freq_ctr_div
		port map(
			clk(0) => clki,
			clkdiv => clkdiv
		);
		
	cctr: entity work.freq_ctr
		port map(
			clk => ipb_clk,
			rst => ipb_rst,
			ipb_in => ipbw(N_SLV_FREQ_CTR),
			ipb_out => ipbr(N_SLV_FREQ_CTR),
			clkdiv => clkdiv
		);

end rtl;
