-- sc_input_serdes.vhd
--
-- Input logic for serial-parallel conversation of ADC data
--
-- Dave Newbold, February 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.VComponents.all;

entity sc_input_serdes is
	port(
		clk: in std_logic;
		rst: in std_logic;
		clk_s: in std_logic;
		d_p: in std_logic;
		d_n: in std_logic;
		slip: in std_logic;
		inc: in std_logic;
		cntout: out std_logic_vector(4 downto 0);
		q: out std_logic_vector(13 downto 0)
	);

end sc_input_serdes;

architecture rtl of sc_input_serdes is

	signal d_b, d_d: std_logic;
	signal d: std_logic_vector(13 downto 0);
	signal s1, s2: std_logic;
	signal clk_sb: std_logic;
	
begin

	ibuf: IBUFDS
		port map(
			i => d_p,
			ib => d_n,
			o => d_b
		);

	idel: IDELAYE2
		generic map(
			IDELAY_TYPE => "VARIABLE"
		)
		port map(
			c => clk,
			regrst => '0',
			ld => rst,
			ce => inc,
			inc => '1',
			cinvctrl => '0',
			cntvaluein => "00000",
			idatain => d_b,
			datain => '0',
			ldpipeen => '0',
			dataout => d_d,
			cntvalueout => cntout
		);

	clk_sb <= not clk_s;	
	
	m_serdes: ISERDESE2
		generic map(
			DATA_WIDTH => 14,
			INTERFACE_TYPE => "NETWORKING",
			SERDES_MODE => "MASTER",
			IOBDELAY => "BOTH" -- Essential. And undocumented.
		)
		port map(
			q1 => q(0),
			q2 => q(1),
			q3 => q(2),
			q4 => q(3),
			q5 => q(4),
			q6 => q(5),
			q7 => q(6),
			q8 => q(7),
			shiftout1 => s1,
			shiftout2 => s2,
			d => '0',
			ddly => d_d,
			clk => clk_s,
			clkb => clk_sb,
			ce1 => '1',
			ce2 => '1',
			rst => rst,
			clkdiv => clk,
			clkdivp => '0', -- WTF is this? Not in the user guide
			oclk => '0',
			oclkb => '0',
			bitslip => slip,
			shiftin1 => '0',
			shiftin2 => '0',
			ofb => '0',
			dynclkdivsel => '0',
			dynclksel => '0'
		);

	s_serdes: ISERDESE2
		generic map(
			DATA_WIDTH => 14,
			INTERFACE_TYPE => "NETWORKING",
			SERDES_MODE => "SLAVE",
			IOBDELAY => "BOTH" -- Essential. And undocumented.
		)
		port map(
			q1 => open,
			q2 => open,
			q3 => q(8),
			q4 => q(9),
			q5 => q(10),
			q6 => q(11),
			q7 => q(12),
			q8 => q(13),
			shiftout1 => open,
			shiftout2 => open,
			d => '0',
			ddly => '0',
			clk => clk_s,
			clkb => clk_sb,
			ce1 => '1',
			ce2 => '1',
			rst => rst,
			clkdiv => clk,
			clkdivp => '0', -- WTF is this? Not in the user guide
			oclk => '0',
			oclkb => '0',
			bitslip => slip,
			shiftin1 => s1,
			shiftin2 => s2,
			ofb => '0',
			dynclkdivsel => '0',
			dynclksel => '0'
		);

end rtl;
