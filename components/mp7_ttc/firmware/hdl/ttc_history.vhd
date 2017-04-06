-- ttc_history
--
-- Stores the history of TTC A/B commands for debugging
--
-- FIFO is cleared and then filled when 'go' is asserted
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.mp7_ttc_decl.all;

entity ttc_history is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		ttc_clk: in std_logic; -- TTC clk40
		go: in std_logic; -- Start signal (ttc_clk domain)
		mask_bc0: in std_logic;
		mask_l1a: in std_logic;
		ttc_l1a: in std_logic;
		ttc_cmd: in ttc_cmd_t;
		ttc_bx: in bctr_t;
		ttc_orb: in eoctr_t
	);

end ttc_history;

architecture rtl of ttc_history is

	COMPONENT ttc_history_fifo
		PORT (
			rst : IN STD_LOGIC;
			wr_clk : IN STD_LOGIC;
			rd_clk : IN STD_LOGIC;
			din : IN STD_LOGIC_VECTOR(40 DOWNTO 0);
			wr_en : IN STD_LOGIC;
			rd_en : IN STD_LOGIC;
			dout : OUT STD_LOGIC_VECTOR(40 DOWNTO 0);
			full : OUT STD_LOGIC;
			empty : OUT STD_LOGIC;
			valid : OUT STD_LOGIC
		);
	END COMPONENT;

	signal full, valid, wen, ren, ipb_ren, fifo_rst, go_d: std_logic;
	signal d, q: std_logic_vector(40 downto 0);

begin

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			go_d <= go;
		end if;
	end process;

	fifo_rst <= rst or (go and not go_d); -- CDC (unrelated clocks, async)

	d(3 downto 0) <= ttc_cmd;
	d(15 downto 4) <= ttc_bx;
	d(39 downto 16) <= ttc_orb;
	d(40) <= ttc_l1a;
	
	wen <= '1' when ((ttc_l1a = '1' and mask_l1a = '0') or (ttc_cmd /= (ttc_cmd'range => '0') and not (ttc_cmd = TTC_BCMD_BC0 and mask_bc0 = '1')))
		and go = '1' else '0';
	
	fifo: ttc_history_fifo
		port map(
			rst => fifo_rst,
			wr_clk => ttc_clk,
			rd_clk => clk,
			din => d,
			wr_en => wen,
			rd_en => ren,
			dout => q,
			full => full,
			empty => open,
			valid => valid
		);
	
	ipb_ren <= ipb_in.ipb_strobe and not ipb_in.ipb_write;
	ren <= ipb_ren and ipb_in.ipb_addr(0);

	ipb_out.ipb_rdata <= X"00" & q(39 downto 16) when ipb_in.ipb_addr(0) = '1' else
		valid & "000" & X"00" & "000" & q(40) & q(15 downto 4) & q(3 downto 0);

	ipb_out.ipb_ack <= ipb_ren;
	ipb_out.ipb_err <= '0';

end rtl;

