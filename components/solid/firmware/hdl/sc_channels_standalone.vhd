-- sc_channels.vhd
--
-- Groups the input channels
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;

use work.top_decl.all;

library unisim;
use unisim.VComponents.all;

entity sc_channels_standalone is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		chan: in std_logic_vector(7 downto 0);
		sync_ctrl: in std_logic_vector(3 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		clk280: in std_logic;
		d_p: in std_logic_vector(N_CHAN - 1 downto 0);
		d_n: in std_logic_vector(N_CHAN - 1 downto 0)
	);

end sc_channels_standalone;

architecture rtl of sc_channels_standalone is

	signal ipbw: ipb_wbus_array(N_CHAN - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_CHAN - 1 downto 0);

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

-- channels
		
	cgen: for i in N_CHAN - 1 downto 0 generate
	begin
	
		chan: entity work.sc_chan_standalone
			generic map(
				id => i
			)
			port map(
				clk => clk,
				rst => rst,
				ipb_in => ipbw(i),
				ipb_out => ipbr(i),
				sync_ctrl => sync_ctrl,
				clk40 => clk40,
				rst40 => rst40,
				clk160 => clk160,
				clk280 => clk280,				
				d_p => d_p(i),
				d_n => d_n(i)
			);
			
	end generate;
	
end rtl;
