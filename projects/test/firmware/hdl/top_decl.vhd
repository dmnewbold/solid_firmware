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
	constant FW_REV: std_logic_vector(15 downto 0) := X"0003";

	constant N_CHAN: integer := 12;
	constant BLK_RADIX: integer := 8; -- 256 sample blocks
	constant NZS_BLKS: integer := 2; -- Reserve two blocks of space for NZS buffer
	constant N_TRG_T: integer := 2; -- Number of trigger types
	
end top_decl;
