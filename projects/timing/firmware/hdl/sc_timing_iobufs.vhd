-- sc_timing_iobufs
--
-- The IO buffers for the timing board. Dull.
--
-- Dave Newbold, July 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.VComponents.all;

entity sc_timing_iobufs is
	port(
		clk_rstn: in std_logic;
		clk_rstn_p: out std_logic;
		clk_rstn_n: out std_logic;
		clk: in std_logic;
		clk_o_p: out std_logic;
		clk_o_n: out std_logic;
		clk_i: out std_logic;
		clk_i_p: in std_logic;
		clk_i_n: in std_logic;
		trig_o: in std_logic;
		trig_o_p: out std_logic;
		trig_o_n: out std_logic;
		trig_i: out std_logic;
		trig_i_p: in std_logic;
		trig_i_n: in std_logic;
		sync_o: in std_logic;
		sync_o_p: out std_logic;
		sync_o_n: out std_logic;
		sync_i: out std_logic;
		sync_i_p: in std_logic;
		sync_i_n: in std_logic;
		trig_sel: in std_logic;
		trig_sel_p: out std_logic;
		trig_sel_n: out std_logic;
		sync_sel: in std_logic;
		sync_sel_p: out std_logic;
		sync_sel_n: out std_logic;
		scl: in std_logic;
		scl_p: out std_logic;
		scl_n: out std_logic;
		sda_o: in std_logic;
		sda_o_p: out std_logic;
		sda_o_n: out std_logic;
		sda_i: out std_logic;
		sda_i_p: in std_logic;
		sda_i_n: in std_logic;
		busy_o: in std_logic;
		busy_o_p: out std_logic;
		busy_o_n: out std_logic;
		busy_i: out std_logic_vector(9 downto 0);
		busy_i_p: in std_logic_vector(9 downto 0);
		busy_i_n: in std_logic_vector(9 downto 0)
	);

end sc_timing_iobufs;

architecture rtl of sc_timing_iobufs is

	signal clk_o, clk_i_u: std_logic;
	signal sda_i_inv: std_logic;
	
begin

	obuf_clk_rstn: OBUFDS
		port map(
			i => clk_rstn,
			o => clk_rstn_p,
			ob => clk_rstn_n
		);

	oddr_clkout: ODDR -- Feedback clock, not through MMCM
		port map(
			q => clk_o,
			c => clk,
			ce => '1',
			d1 => '0',
			d2 => '1',
			r => '0',
			s => '0'
		);
		
	obuf_clk_o: OBUFDS
		port map(
			i => clk_o,
			o => clk_o_p,
			ob => clk_o_n
		);
		
	ibufg_clk_i: IBUFGDS
		port map(
			i => clk_i_p,
			ib => clk_i_n,
			o => clk_i_u
		);
		
	bufg_clk_i: BUFG
		port map(
			i => clk_i_u,
			o => clk_i
		);
		
	obuf_trig_o: OBUFDS
		port map(
			i => trig_o,
			o => trig_o_p,
			ob => trig_o_n
		);		
		
	ibuf_trig_i: IBUFDS
		port map(
			i => trig_i_p,
			ib => trig_i_n,
			o => trig_i
		);
		
	obuf_sync_o: OBUFDS
		port map(
			i => sync_o,
			o => sync_o_p,
			ob => sync_o_n
		);
		
	ibuf_sync_i: IBUFDS
		port map(
			i => sync_i_p,
			ib => sync_i_n,
			o => sync_i
		);
		
	obuf_trig_sel: OBUFDS
		port map(
			i => trig_sel,
			o => trig_sel_p,
			ob => trig_sel_n
		);

	obuf_sync_sel: OBUFDS
		port map(
			i => sync_sel,
			o => sync_sel_p,
			ob => sync_sel_n
		);
	
	obuf_scl: OBUFDS
		port map(
			i => scl,
			o => scl_p,
			ob => scl_n
		);
		
	obuf_sda_o: OBUFDS
		port map(
			i => sda_o,
			o => sda_o_p,
			ob => sda_o_n
		);

	ibuf_sda_i: IBUFDS
		port map(
			i => sda_i_p,
			ib => sda_i_n,
			o => sda_i_inv
		);
		
	sda_i <= not sda_i_inv;

	obuf_busy_o: OBUFDS
		port map(
			i => busy_o,
			o => busy_o_p,
			ob => busy_o_n
		);

	busy_i_gen: for i in 9 downto 0 generate
	
		ibuf_sda_i: IBUFDS
			port map(
				i => busy_i_p(i),
				ib => busy_i_n(i),
				o => busy_i(i)
			);

	end generate;
		
end rtl;
