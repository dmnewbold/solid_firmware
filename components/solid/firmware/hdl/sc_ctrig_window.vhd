-- sc_ctrig_window
--
-- Count features in sliding window
--
-- Dave Newbold, May 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_ctrig_window is
	generic(
		C_WIDTH: natural
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		wsize: in std_logic_vector(3 downto 0);
		p: in std_logic;
		count: out std_logic_vector(C_WIDTH - 1 downto 0)
	);

end sc_ctrig_window;

architecture rtl of sc_ctrig_window is

	constant WINDOW_LEN: integer := BLK_RADIX;
	
	signal w, f: std_logic_vector(2 ** wsize'length downto 0);
	signal p, r: std_logic;
	signal count_i: unsigned(C_WIDTH - 1 downto 0);
	
begin

	w(0) <= p;

	dgen: for i in 2 ** wsize'length - 1 downto 0 generate
	
		srl: SRL32CE
			port map(
				clk => clk,
				ce => '1',
				a => "11111",
				d => w(i),
				q31 => w(i + 1)
				q => f(i)
			);
			
	end generate;

	r <= f(to_integer(unsigned(wsize)));
	
	process(clk)
	begin	
		if rising_edge(clk) then
			if rst = '1' then
				count_i <= (others => '0');
			else
				if p = '1' and r = '0' then
					count_i <= count_i + 1;
				elsif p = '0' and r = '1' and count_i /= 0 then
					count_i <= count_i - 1;
				end if;
			end if;
		end if;
	end process;
	
	count <= std_logic_vector(count_i);

end rtl;
