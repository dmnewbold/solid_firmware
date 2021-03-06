-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_sc_daq is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_sc_daq(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Tue Nov 14 21:11:12 2017 
  constant N_SLV_CHAN: integer := 0;
  constant N_SLV_TIMING: integer := 1;
  constant N_SLV_FAKE: integer := 2;
  constant N_SLV_RTRIG: integer := 3;
  constant N_SLV_TLINK: integer := 4;
  constant N_SLV_TRIG: integer := 5;
  constant N_SLV_ROC: integer := 6;
  constant N_SLAVES: integer := 7;
-- END automatically generated VHDL

    
end ipbus_decode_sc_daq;

package body ipbus_decode_sc_daq is

  function ipbus_sel_sc_daq(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Tue Nov 14 21:11:12 2017 
    if    std_match(addr, "------------------------0000----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CHAN, IPBUS_SEL_WIDTH)); -- chan / base 0x00000000 / mask 0x000000f0
    elsif std_match(addr, "------------------------0001----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TIMING, IPBUS_SEL_WIDTH)); -- timing / base 0x00000010 / mask 0x000000f0
    elsif std_match(addr, "------------------------00100---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_FAKE, IPBUS_SEL_WIDTH)); -- fake / base 0x00000020 / mask 0x000000f8
    elsif std_match(addr, "------------------------00101---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_RTRIG, IPBUS_SEL_WIDTH)); -- rtrig / base 0x00000028 / mask 0x000000f8
    elsif std_match(addr, "------------------------00110---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TLINK, IPBUS_SEL_WIDTH)); -- tlink / base 0x00000030 / mask 0x000000f8
    elsif std_match(addr, "------------------------01------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TRIG, IPBUS_SEL_WIDTH)); -- trig / base 0x00000040 / mask 0x000000c0
    elsif std_match(addr, "------------------------100-----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ROC, IPBUS_SEL_WIDTH)); -- roc / base 0x00000080 / mask 0x000000e0
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_sc_daq;

end ipbus_decode_sc_daq;

