-- sc_chan.vhd
--
-- All the stuff belonging to one input channel
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.ipbus.all;
use work.ipbus_decode_sc_chan_standalone.all;
use work.ipbus_reg_types.all;

entity sc_chan_standalone is
	generic(
		id: integer
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		sync_ctrl: in std_logic_vector(3 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		clk280: in std_logic;
		d_p: in std_logic;
		d_n: in std_logic
	);

end sc_chan_standalone;

architecture rtl of sc_chan_standalone is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(0 downto 0);		
	signal d_in: std_logic_vector(13 downto 0);
	signal d_c: std_logic_vector(1 downto 0);
	signal ctrl_en_sync, ctrl_en_comp, slip, chan_rst, buf_we, inc: std_logic;
	signal we, empty, full: std_logic;
	signal ctrl_patt: std_logic_vector(13 downto 0);
	signal err_cnt: unsigned(15 downto 0);
	
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
      sel => ipbus_sel_sc_chan_standalone(ipb_in.ipb_addr),
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
			q => ctrl,
			qmask(0) => X"3FFF0003"
		);
		
	ctrl_en_sync <= ctrl(0)(0);
	ctrl_en_comp <= ctrl(0)(1);
	ctrl_patt <= ctrl(0)(29 downto 16);
	slip <= sync_ctrl(0) and ctrl_en_sync; -- CDC
	chan_rst <= (sync_ctrl(1) and ctrl_en_sync) or rst40; -- CDC
	buf_we <= sync_ctrl(2) and ctrl_en_sync; -- CDC
	inc <= sync_ctrl(3) and ctrl_en_sync; -- CDC
	
	stat(0) <= std_logic_vector(err_cnt) & X"000" & "00" & full & empty; -- CDC
	
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
	
	we <= (we or buf_we) and not (full or chan_rst) when rising_edge(clk40);
			
	cap_buf: entity work.sc_cap_fifo_16
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_FIFO),
			ipb_out => ipbr(N_SLV_FIFO),
			clk_p => clk40,
			rst_p => chan_rst,
			d(13 downto 0) => d_in,
			d(15 downto 14) => "00",
			we => we,
			empty => empty,
			full => full,
			frst => chan_rst
		);

	process(clk40)
	begin
		if rising_edge(clk40) then
			if ctrl_en_comp = '0' then
				err_cnt <= (others => '0');
			elsif d_in /= ctrl_patt and err_cnt /= (err_cnt'range => '1') then
				err_cnt <= err_cnt + 1;
			end if;
		end if;
	end process;
	
end rtl;
