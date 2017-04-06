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

entity sc_tot is
generic(windowlength:	natural := 7; --bit
	VAL_WIDTH:	integer := 14 --bit
); -- -1

port(	rst:		in std_logic;
	clk:		in std_logic;
	data_in:	in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	threshold:	in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	totval:		out std_logic_vector(windowlength-1 DOWNTO 0)
);
end sc_tot;

architecture rtl of sc_tot is
	signal totbuff		: integer range 0 to (2**VAL_WIDTH)-1;
	signal shiftreg 	: std_logic_vector((2**windowlength)-1 DOWNTO 0); 
				-- Shift register from 0-1 (current) to windowlength-1
				-- = 0 to windowlength-2
	
begin

process(rst,clk)
	variable val		: boolean				:= False;
	variable val_start  	: integer range 0 to 1			:= 0;
	variable val_end	: integer range 0 to 1			:= 0;
	begin
	if rst='1' then
		totval<= 	(others=>'0');
		totbuff<=	0;
		--shiftreg <= 	(others => '0');
	elsif rising_edge(clk) then
	--------------------------------
	--	Find Maximum          --
	--------------------------------
		val :=	to_integer(unsigned(data_in)) >= to_integer(unsigned(threshold));
	--------------------------------
	--	Count ToT	      --
	--------------------------------
		case val is
			when False =>	val_start	:= 0;
					shiftreg(0)	<= '0';
			when True =>	val_start	:= 1;
					shiftreg(0)	<= '1';
		end case;
		case shiftreg(windowlength-1) is
			when '0' =>	val_end		:= 0;
			when '1' =>	val_end		:= 1;
		end case;

		for i in 1 to windowlength-1 loop -- not first element
			shiftreg(i) <=	shiftreg(i-1);
		end loop;
		totbuff <= totbuff + val_start - val_end;

	end if;		
	totval <= std_logic_vector(to_unsigned(totbuff,windowlength));
end process;		

end architecture rtl;
