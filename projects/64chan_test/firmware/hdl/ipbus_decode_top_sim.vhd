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

package ipbus_decode_top_sim is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_top_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Sat Aug 20 17:42:19 2016 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_CHAN: integer := 1;
  constant N_SLV_TIMING: integer := 2;
  constant N_SLV_TLINK: integer := 3;
  constant N_SLV_TRIG: integer := 4;
  constant N_SLV_ROC: integer := 5;
  constant N_SLAVES: integer := 6;
-- END automatically generated VHDL

    
end ipbus_decode_top_sim;

package body ipbus_decode_top_sim is

  function ipbus_sel_top_sim(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Sat Aug 20 17:42:19 2016 
    if    std_match(addr, "------------------------00000---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x000000f8
    elsif std_match(addr, "------------------------00001---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CHAN, IPBUS_SEL_WIDTH)); -- chan / base 0x00000008 / mask 0x000000f8
    elsif std_match(addr, "------------------------01000---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TIMING, IPBUS_SEL_WIDTH)); -- timing / base 0x00000040 / mask 0x000000f8
    elsif std_match(addr, "------------------------01010---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TLINK, IPBUS_SEL_WIDTH)); -- tlink / base 0x00000050 / mask 0x000000f8
    elsif std_match(addr, "------------------------0110----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TRIG, IPBUS_SEL_WIDTH)); -- trig / base 0x00000060 / mask 0x000000f0
    elsif std_match(addr, "------------------------1000----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_ROC, IPBUS_SEL_WIDTH)); -- roc / base 0x00000080 / mask 0x000000f0
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_top_sim;

end ipbus_decode_top_sim;

