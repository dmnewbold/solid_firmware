-- top_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, September 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package top_decl is
  
	constant MAC_ADDR: std_logic_vector(47 downto 0) := X"020ddba11503";
	constant IP_ADDR: std_logic_vector(31 downto 0) := X"c0a8eb00";
	constant FW_REV: std_logic_vector(15 downto 0) := X"0021";

	constant N_CHAN: integer := 8;
	constant BLK_RADIX: integer := 8; -- 256 sample blocks
	constant BUF_RADIX: integer := 11; -- One BRAM for NZS / ZS buffer
	constant NZS_BLKS: integer := 2; -- Reserve two blocks of space for NZS buffer
	constant N_TRG: integer := 4; -- Number of trigger types
	constant N_ZS_THRESH: integer := 4; -- Number of ZS thresholds
	constant ZS_DEL: integer := 8;
	constant N_CHAN_TRG: integer := 3; -- Number of channel trigger bits
	constant DERAND_DEPTH: integer := 2048; -- Number of 32kb FIFOs in the derand buffer	
	constant FIFO_RADIX: integer := 3; -- 8 FIFO blocks in readout buffer
	
	type sc_trig_array is array(N_CHAN_TRG - 1 downto 0) of std_logic_vector(N_CHAN - 1 downto 0);
	type sc_ltrig_array is array(N_TRG - 1 downto 0) of std_logic_vector(N_CHAN - 1 downto 0);

	type sc_ch_array_t is array(N_CHAN / 4 - 1 downto 0) of integer;
	constant SC_CH_Y0: sc_ch_array_t := (0, 1);
	constant SC_CH_Y1: sc_ch_array_t := (2, 3);
	constant SC_CH_X0: sc_ch_array_t := (4, 5);
	constant SC_CH_X1: sc_ch_array_t := (6, 7);
	
end top_decl;
