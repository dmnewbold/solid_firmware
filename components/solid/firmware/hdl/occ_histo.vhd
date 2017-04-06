-- occ_histo
--
-- A simple histogrammer of buffer occupancy
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;

entity occ_histo is
	generic(
		BINS_RADIX: natural := 4; -- Number of bins (0 = 1, 1 = 2, etc)
		OCC_WIDTH: natural := 8 -- Occupancy counter width
	);
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_s: in std_logic;
		rst_s: in std_logic;
		occ: in std_logic_vector(OCC_WIDTH - 1 downto 0);
		freeze: in std_logic
	);

end occ_histo;

architecture rtl of occ_histo is

	type c_array_t is array(2 ** BINS_RADIX - 1 downto 0) of std_logic_vector(7 downto 0);
	signal m_array, e_array: c_array_t;
	signal sel: integer range 2 ** BINS_RADIX - 1 downto 0 := 0;

begin

-- ipbus

	sel <= to_integer(unsigned(ipb_in.ipb_addr(BINS_RADIX - 1 downto 0)));
	ipb_out.ipb_rdata <= X"0000" & std_logic_vector(e_array(sel)) & std_logic_vector(m_array(sel)); -- CDC
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
		
-- Bins

	bgen: for i in 2 ** BINS_RADIX - 1 downto 0 generate
	
		signal inc: std_logic;
		
	begin
	
		inc <= '1' when to_integer(unsigned(occ(OCC_WIDTH - 1 downto OCC_WIDTH - BINS_RADIX - 1))) = i and freeze = '0' else '0';
		
		sctr: entity work.scaled_ctr
			port map(
				clk => clk_s,
				rst => rst_s,
				inc => inc,
				m => m_array(i),
				e => e_array(i)
			);
		
	end generate;
	
end rtl;
