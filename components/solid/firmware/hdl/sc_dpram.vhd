-- sc_dpram
--
-- Dual port RAM for channel buffer. This version has a common clock for both ports.
--
-- Dave Newbold, January 2021

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity sc_dpram is
	generic(
		ADDR_WIDTH: positive
	);
	port(
		clk: in std_logic;
		wea: in std_logic;
		da: in std_logic_vector(15 downto 0);
		qa: out std_logic_vector(15 downto 0);
		addra: in std_logic_vector(ADDR_WIDTH - 1 downto 0);
		web: in std_logic;
		db: in std_logic_vector(15 downto 0);
		qb: out std_logic_vector(15 downto 0);
		addrb: in std_logic_vector(ADDR_WIDTH - 1 downto 0)	
	);
	
end sc_dpram;

architecture rtl of sc_dpram is

begin

	dpram: xpm_memory_tdpram
		generic map(
			ADDR_WIDTH_A => ADDR_WIDTH,
			ADDR_WIDTH_B => ADDR_WIDTH,
			BYTE_WRITE_WIDTH_A => 16,
			BYTE_WRITE_WIDTH_B => 16,
			MEMORY_SIZE => 2 ** ADDR_WIDTH * 16,
			READ_DATA_WIDTH_A => 16,
			READ_DATA_WIDTH_B => 16,
			READ_LATENCY_A => 1,
			READ_LATENCY_B => 1,
			USE_MEM_INIT => 0,
			WRITE_DATA_WIDTH_A => 16,
			WRITE_DATA_WIDTH_B => 16,
			WRITE_MODE_A => "read_first",
			WRITE_MODE_B => "read_first"
		)
		port map(
			dbiterra => open,
			dbiterrb => open,
			douta => qa,
			doutb => qb,
			sbiterra => open,
			sbiterrb => open,
			addra => addra,
			addrb => addrb,
			clka => clk,
			clkb => clk,
			dina => da,
			dinb => db,
			ena => '1',
			enb => '1',
			injectdbiterra => '0',
			injectdbiterrb => '0',
			injectsbiterra => '0',
			injectsbiterrb => '0',
			regcea => '1',
			regceb => '1',
			rsta => '0',
			rstb => '0',
			sleep => '0',
			wea(0) => wea,
			web(0) => web
		);

end rtl;
