-- sc_trig_link_pipe
--
-- Data path logic for trigger links
--
-- Dave Newbold, October 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity sc_trig_link_pipe is
	port(
		clk125: in std_logic;
		rxd: in std_logic_vector(15 downto 0);
		rxk: in std_logic_vector(1 downto 0);
		txd: out std_logic_vector(15 downto 0);
		txk: out std_logic_vector(1 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		d: in std_logic_vector(15 downto 0);
		dv: in std_logic;
		q: out std_logic_vector(15 downto 0);
		qv: out std_logic;
		ack: in std_logic;
		err_i: out std_logic;
		err_o: out std_logic;
		my_id: in std_logic_vector(7 downto 0);
		debug: out std_logic_vector(31 downto 0)
	);

end sc_trig_link_pipe;

architecture rtl of sc_trig_link_pipe is

	signal p: std_logic := '0';
	signal c: unsigned(15 downto 0) := X"0000";

begin

	p <= not p when rising_edge(clk125);
	c <= c + 1 when rising_edge(clk125) and p = '1';
	
	txd <= X"bc" & my_id when p = '0' else std_logic_vector(c);
	txk <= "10" when p = '0' else "00";
	q <= (others => '0');
	qv <= '0';
	err_i <= '0';
	err_o <= '0';
	
	process(clk125)
	begin
		if rising_edge(clk125) then
			if rxk /= "00" then
				debug(15 downto 0) <= rxd;
			else
				debug(31 downto 16) <= rxd;
			end if;
		end if;
	end process;

end rtl;
