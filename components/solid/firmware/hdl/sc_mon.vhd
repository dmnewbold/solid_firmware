-- sc_mon.vhd
--
-- Monitors Temperature and Voltages using a Xilinx XADC IP Block
--
-- Lukas Arnold, September 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.ipbus.all;

use work.top_decl.all;

library unisim;
use unisim.VComponents.all;

entity sc_mon is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
	);

end sc_mon;

architecture rtl of sc_mon is

	signal ipbw: ipb_wbus_array(N_CHAN - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_CHAN - 1 downto 0);
	signal daddr: std_logic_vector(6 downto 0);
	signal regcnt: integer(range 0 to 3);

begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_CHAN,
			SEL_WIDTH => 8
		)
		port map(
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			sel => chan,
			ipb_to_slaves => ipbw,
			ipb_from_slaves => ipbr
		);

	
	process(clk40)
	begin
		if rst='1' then
			regcnt=0;
		elsif rising_edge(clk40) then
			if regcnt = 3 then
				regcnt <= 0;
			else
				regcnt <= regcnt + 1;
			end if;
		end if;
	end process;

	mon : xadc_wiz_0
	  port map (
	    di_in => (others => '0'),
	    daddr_in => std_logic_vector(to_unsigned(regcnt, 6)),
	    den_in => '1',
	    dwe_in => '0',
	    drdy_out => drdy_out,
	    do_out => do_out,
	    dclk_in => clk,
	    reset_in => rst,
	    vp_in => vp_in,
	    vn_in => vn_in,
	    vccaux_alarm_out => vccaux_alarm_out,
	    channel_out => channel_out,
	    eoc_out => eoc_out,
	    alarm_out => alarm_out,
	    eos_out => eos_out,
	    busy_out => busy_out
	  );
	
						
	
	q <= chan_q(sel);
	q_blkend <= chan_q_blkend(sel);
	q_empty <= chan_q_empty(sel);
	err <= or_reduce(chan_err);
	
end rtl;
