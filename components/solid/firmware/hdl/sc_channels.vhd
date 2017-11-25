-- sc_channels.vhd
--
-- Groups the input channels
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.ipbus.all;

use work.top_decl.all;

library unisim;
use unisim.VComponents.all;

entity sc_channels is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		chan: in std_logic_vector(7 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		clk160: in std_logic;
		clk280: in std_logic;
		d_p: inout std_logic_vector(N_CHAN - 1 downto 0);
		d_n: inout std_logic_vector(N_CHAN - 1 downto 0);
		sync_ctrl: in std_logic_vector(3 downto 0);
		zs_sel: in std_logic_vector(1 downto 0);
		sctr: in std_logic_vector(47 downto 0);
		fake: in std_logic_vector(13 downto 0);
		nzs_en: in std_logic;
		zs_en: in std_logic;
		keep: in std_logic_vector(N_CHAN - 1 downto 0);
		flush: in std_logic_vector(N_CHAN - 1 downto 0);
		err: out std_logic;
		veto: out std_logic_vector(N_CHAN - 1 downto 0);
		trig: out sc_trig_array;
		dr_chan: in std_logic_vector(7 downto 0);
		clk_dr: in std_logic;
		q: out std_logic_vector(31 downto 0);
		q_blkend: out std_logic;
		q_empty: out std_logic;
		ren: in std_logic
	);

end sc_channels;

architecture rtl of sc_channels is

	signal ipbw: ipb_wbus_array(N_CHAN - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_CHAN - 1 downto 0);
	signal chan_err: std_logic_vector(N_CHAN - 1 downto 0);
	type chan_q_t is array(N_CHAN - 1 downto 0) of std_logic_vector(31 downto 0);
	signal chan_q: chan_q_t;
	signal chan_q_blkend, chan_q_empty, chan_ren: std_logic_vector(N_CHAN - 1 downto 0);
	signal sel: integer range N_CHAN - 1 downto 0 := 0;

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

	sel <= to_integer(unsigned(dr_chan));
		
	cgen: for i in N_CHAN - 1 downto 0 generate
	
		signal ren_loc: std_logic;
		signal ltrig: std_logic_vector(N_CHAN_TRG - 1 downto 0);
	
	begin
		
		ren_loc <= ren when sel = i else '0';
	
		chan: entity work.sc_chan
			generic map(
				id => i
			)
			port map(
				clk => clk,
				rst => rst,
				ipb_in => ipbw(i),
				ipb_out => ipbr(i),
				clk40 => clk40,
				rst40 => rst40,
				clk160 => clk160,
				clk280 => clk280,				
				d_p => d_p(i),
				d_n => d_n(i),
				sync_ctrl => sync_ctrl,
				zs_sel => zs_sel,
				sctr => sctr,
				fake => fake,
				nzs_en => nzs_en,
				zs_en => zs_en,
				keep => keep(i),
				flush => flush(i),
				err => chan_err(i),
				veto => veto(i),
				trig => ltrig,
				clk_dr => clk_dr,
				q => chan_q(i),
				q_blkend => chan_q_blkend(i),
				q_empty => chan_q_empty(i),
				ren => ren_loc
			);
			
		tgen: for j in N_CHAN_TRG - 1 downto 0 generate
			trig(j)(i) <= ltrig(j);
		end generate;
						
	end generate;
	
	q <= chan_q(sel);
	q_blkend <= chan_q_blkend(sel);
	q_empty <= chan_q_empty(sel);
	err <= or_reduce(chan_err);
	
end rtl;
