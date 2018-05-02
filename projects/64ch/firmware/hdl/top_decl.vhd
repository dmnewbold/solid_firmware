-- top_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, September 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package top_decl is
  
	constant MAC_ADDR: std_logic_vector(47 downto 0) := X"020ddba11500"; -- last byte from local addr
	constant IP_ADDR: std_logic_vector(31 downto 0) := X"c0a8eb00"; -- last byte from local addr
	constant FW_REV: std_logic_vector(15 downto 0) := X"0017";

	constant N_CHAN: integer := 64;
	constant BLK_RADIX: integer := 8; -- 256 sample blocks
	constant BUF_RADIX: integer := 11; -- One BRAM for NZS / ZS buffer
	constant NZS_BLKS: integer := 2; -- Reserve two blocks of space for NZS buffer
	constant N_TRG: integer := 4; -- Number of trigger types
	constant N_ZS_THRESH: integer := 4; -- Number of ZS thresholds
	constant ZS_DEL: integer := 8;
	constant N_CHAN_TRG: integer := 3; -- Number of channel trigger bits
	constant FIFO_RADIX: integer := 3; -- 8 FIFO blocks in readout buffer
	
	type sc_trig_array is array(N_CHAN_TRG - 1 downto 0) of std_logic_vector(N_CHAN - 1 downto 0);
	type sc_ltrig_array is array(N_TRG - 1 downto 0) of std_logic_vector(N_CHAN - 1 downto 0);
	
	type sc_ch_array_t is array(N_CHAN / 4 - 1 downto 0) of integer;
	constant SC_CH_Y0: sc_ch_array_t := (24, 25, 26, 27, 28, 29, 30, 31, 0, 1, 2, 3, 4, 5, 6, 7);
	constant SC_CH_Y1: sc_ch_array_t := (39, 38, 37, 36, 35, 34, 33, 32, 63, 62, 61, 60, 59, 58, 57, 56);
	constant SC_CH_X0: sc_ch_array_t := (23, 22, 21, 20, 19, 18, 17, 16, 47, 46, 45, 44, 43, 42, 41, 40);
	constant SC_CH_X1: sc_ch_array_t := (8, 9, 10, 11, 12, 13, 14, 15, 48, 49, 50, 51, 52, 53, 54, 55);
	
end top_decl;
