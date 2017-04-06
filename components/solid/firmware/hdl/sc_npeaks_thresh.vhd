----------------------------------------------------------------------------------
-- Lukas Arnold, University of Bristol
-- 21 September 2016
-- SoLid Experiment
-- r0.01
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;


entity sc_npeaks_thresh is

generic( VAL_WIDTH:	natural := 14 -- bit
);

port(	rst:		in std_logic;
	clk:		in std_logic;
	req:		in std_logic; -- request information
	d:		in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	threshold_trig:	in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	threshold_fe:	in std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
	trig:		out std_logic
);
end sc_npeaks_thresh;

architecture rtl of sc_npeaks_thresh is
    signal feat_val : std_logic_vector(VAL_WIDTH-1 DOWNTO 0);
begin

	featextract: entity work.sc_npeaks
	generic map (
		windowlength => 14, -- bits
		VAL_WIDTH => VAL_WIDTH -- bits
	)
	port map(
		rst => rst,
		clk => clk,
		data_in => d,
		threshold => threshold_fe,
		npeaks => feat_val
	);

	thresh : entity work.sc_thresh
	generic map (
		VAL_WIDTH	=> VAL_WIDTH -- bits
	)
	port map(
		rst 		=> rst,
		clk		=> clk,
		req		=> req,
		val		=> feat_val,
		threshold	=> threshold_trig,
		trig		=> trig
	);

end architecture rtl;
