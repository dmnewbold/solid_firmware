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

entity sc_thresh is

generic( VAL_WIDTH:	natural := 8 -- bit
);

port(	rst:		in std_logic;
	clk:		in std_logic;
	req:		in std_logic; -- request information
	val:		in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	threshold:	in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	trig:		out std_logic
);
end sc_thresh;

architecture rtl of sc_thresh is
    signal triggered        : std_logic;
begin
process(rst,clk)
	variable abovethreshold : boolean				:= False;

	begin
	if rst='1' then
		trig	<= 	'0';
		triggered <=	'0';
		abovethreshold := False;
	elsif rising_edge(clk) then
		abovethreshold := to_integer(unsigned(val))>=to_integer(unsigned(threshold));
		if abovethreshold = True then
			triggered <= '1';
		end if;
		if req='1' then
			triggered <= '0';			
		end if;
		if req='1' and triggered='1' then
		 trig <= '1';
	     else
	     trig <= '0';
	     end if;
	end if;		
end process;

end architecture rtl;
