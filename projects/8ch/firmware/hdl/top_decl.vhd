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
	constant FW_REV: std_logic_vector(15 downto 0) := X"000b";

	constant N_CHAN: integer := 8;
	constant BLK_RADIX: integer := 8; -- 256 sample blocks
	constant SUPERBLK_RADIX: integer := 16; -- Superblock is 64k blocks
	constant BUF_RADIX: integer := 11; -- One BRAM for NZS / ZS buffer
	constant NZS_BLKS: integer := 2; -- Reserve two blocks of space for NZS buffer
	constant ZS_BLKS: integer := 2; -- Time window for ZS buffer
	constant N_TRG: integer := 4; -- Number of trigger types
	constant N_CHAN_TRG: integer := 3; -- Number of channel trigger bits
	constant FIFO_RADIX: integer := 3; -- 8 FIFO blocks in readout buffer
	
	subtype sc_trig_t is std_logic_vector(N_CHAN - 1 downto 0);
	type sc_trig_array is array(N_CHAN_TRG - 1 downto 0) of sc_trig_t;
	
end top_decl;
