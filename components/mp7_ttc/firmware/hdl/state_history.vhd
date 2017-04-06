-- state_history
--
-- Circular buffer for storing ttc commands, tts transitions, etc
--
-- ctrl(0): freeze
-- ctrl(1): reset
-- ctrl(15 downto 8): mask bits
-- stat(ADDR_WIDTH - 1 downto 0): write pointer
-- stat(16): wrap-around flag
--
-- 72b RAM word is organised as
-- 71:56 state_data; 55:36 evt_num; 35:16 orb_num; 15:4 bx_num; 3:0 cyc_num 
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_state_history.all;
use work.mp7_ttc_decl.all;

entity state_history is
	generic(
		ADDR_WIDTH: integer := 9
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		ttc_clk: in std_logic; -- TTC clk40
		ttc_rst: in std_logic;
		ttc_bx: in bctr_t;
		ttc_cyc: in pctr_t := (pctr_t'range => '0'); 
		ttc_orb: in eoctr_t;
		ttc_evt: in eoctr_t;
		state: in std_logic_vector(15 downto 0)
	);

end state_history;

architecture rtl of state_history is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal addr: std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal freeze, brst, we, wrap, strobe: std_logic;
	signal state_d, mask: std_logic_vector(15 downto 0);
	signal d: std_logic_vector(71 downto 0);

begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_state_history(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- control register

	ctrlreg: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_CSR),
			ipb_out => ipbr(N_SLV_CSR),
			slv_clk => ttc_clk,
			d => stat,
			q => ctrl,
			qmask(0) => X"ffff0003"
		);

	freeze <= ctrl(0)(0);
	brst <= ctrl(0)(1);
	mask <= ctrl(0)(31 downto 16);

	stat(0)(ADDR_WIDTH - 1 downto 0) <= addr;
	stat(0)(15 downto ADDR_WIDTH) <= (others => '0');
	stat(0)(16) <= wrap;
	stat(0)(31 downto 17) <= (others => '0');
	
-- strobe

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			state_d <= state;
		end if;
	end process;
	
	strobe <= or_reduce((state xor state_d) and not mask);
	
-- address pointer

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			we <= strobe and not freeze;
			d <= state & ttc_evt(19 downto 0) & ttc_orb(19 downto 0) & ttc_bx & '0' & ttc_cyc;
			if ttc_rst = '1' or brst = '1' then
				addr <= (others => '0');
				wrap <= '0';
			elsif we = '1' then
				addr <= std_logic_vector(unsigned(addr) + 1);
				if addr = (addr'range => '1') then
					wrap <= '1';
				end if;
			end if;
		end if;
	end process;

-- buffer

	buf: entity work.ipbus_ported_sdpram72
		generic map(
			ADDR_WIDTH => ADDR_WIDTH
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUFFER),
			ipb_out => ipbr(N_SLV_BUFFER),
			wclk => ttc_clk,
			we => we,
			d => d,
			addr => addr
		);

end rtl;
