----------------------------------------------------------------------------------
-- Lukas Arnold, University of Bristol
-- 2 May 2016
-- SoLid Experiment
-- r0.01
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity peakcount is
generic(windowlength:	natural := 7; -- bits
	adc_max:	integer := 14 -- bits
);

port(	rst:		in std_logic;
	clk:		in std_logic;
	data_in:	in std_logic_vector(adc_max-1 DOWNTO 0);
	threshold:	in std_logic_vector(adc_max-1 DOWNTO 0);
	npeaks:		out std_logic_vector(windowlength-1 DOWNTO 0)
);
end peakcount;

architecture rtl of peakcount is
	signal delayed   	: integer range 0 to (2**adc_max)-1;
	signal delayed_two	: integer range 0 to (2**adc_max)-1;
	signal shiftreg 	: std_logic_vector((2**windowlength)-2 DOWNTO 0); 
	signal npeaks_buf	: integer range 0 to (2**windowlength)-1;
	
begin

process(rst,clk)
	variable maximum	: boolean						:= False;
	variable maximum_start  : integer range 0 to 1					:= 0;
	variable maximum_end	: integer range 0 to 1					:= 0;

	begin
	if rst='1' then
		npeaks <= 	(others=>'0');
		delayed <=	0;
		delayes_two <=	0;
--		shiftreg <= 	(others => '0');
		npeaks_buf <=	0;
	elsif rising_edge(clk) then
	--------------------------------
	--	Find Maximum          --
	--------------------------------
		delayed <= 	to_integer(unsigned(data_in));
		delayed_two<=	delayes;
		
		--Conditions
		maximum :=	(delayed > to_integer(unsigned(threshold)))AND (to_integer(unsigned(data_in))<=delayed) AND (delayed_two < delayed); --//1 clock cycle
	--------------------------------
	--	Count Maxima          --
	--------------------------------
		case maximum is
			when False =>	maximum_start	:= 0;
					shiftreg(0)	<= '0';
			when True =>	maximum_start	:= 1;
					shiftreg(0)	<= '1';
		end case;
		case shiftreg((2**windowlength)-2) is
			when '0' =>	maximum_end	:= 0;
			when '1' =>	maximum_end	:= 1;
		end case;

		for i in 1 to ((2**windowlength)-2) loop -- not first element
			shiftreg(i) <=	shiftreg(i-1);
		end loop;

		npeaks_buf <= npeaks_buf + maximum_start - maximum_end; --//1 clock cycle
	end if;		
	npeaks <=	std_logic_vector(to_unsigned(npeaks_buf,windowlength)); --//1 clock cycle
end process;

end architecture rtl;
