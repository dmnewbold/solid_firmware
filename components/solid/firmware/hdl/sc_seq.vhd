-- sc_seq
--
-- Maintains list of future readouts and issues them
-- This implementation assumes all channels are read out or not
-- In the future, might have to split into regions with one sequence buffer per region
--
-- Keep and flush are high on mark
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_decode_sc_seq.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_seq is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk40: in std_logic;
		rst40: in std_logic;
		zs_en: in std_logic;
		sctr: in std_logic_vector(31 downto 0);
		d_loc: in std_logic_vector(15 downto 0);
		valid_loc: in std_logic;
		ack_loc: out std_logic;
		d_ext: in std_logic_vector(15 downto 0);
		valid_ext: in std_logic;
		ack_ext: out std_logic;
		keep: out std_logic;
		flush: out std_logic;
		err: out std_logic
	);

end sc_seq;

architecture rtl of sc_seq is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal td: std_logic_vector(15 downto 0);
	signal tv, terr, tv_d: std_logic;
	signal we: std_logic;
	signal d_ram, q_ram: std_logic_vector(15 downto 0);
	signal a_ram: std_logic_vector(BUF_RADIX - 1 downto 0);
	signal ptr, ctr: unsigned(BUF_RADIX - 1 downto 0);
	signal nclk40, rseq, keep_i: std_logic;
	signal q_s_ram: std_logic_vector(31 downto 0);
	type tctr_t is array(N_TRG - 1 downto 0) of unsigned(31 downto 0);
	signal tctr: tctr_t;
	signal crst: std_logic;
	signal cinc: std_logic_vector(N_TRG - 1 downto 0);
	
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH
    )
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_sc_seq(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- Trigger input

	td <= d_loc when valid_loc = '1' else d_ext;
	tv <= (valid_loc or valid_ext) and not rseq and zs_en;
	tv_d <= tv and not tv_d when rising_edge(clk40);
	ack_loc <= valid_loc and tv_d;
	ack_ext <= valid_ext and not valid_loc and tv_d;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			terr <= (terr or ((valid_loc or valid_ext) and rseq)) and zs_en;
		end if;
	end process;

	err <= terr;
	
-- Trigger counters
	
	process(td, tv) -- Encoded -> one hot. God dammit VHDL.
	begin
		for i in N_TRG - 1 downto 0 loop
			if tv = '1' and to_integer(unsigned(td(3 downto 0))) = i then
				cinc(i) <= '1';
			else
				cinc(i) <= '0';
			end if;
		end loop;
	end process;
	
	crst <= not zs_en;
	
	cnt: entity work.ipbus_ctrs_ported
		generic map(
			N_CTRS => N_TRG
		)
		port map(
			ipb_clk => clk,
			ipb_rst => rst,
			ipb_in => ipbw(N_SLV_CTRS),
			ipb_out => ipbr(N_SLV_CTRS),
			clk => clk40,
			rst => crst,
			inc => cinc
		);

-- Trigger offset / length table

	nclk40 <= not clk40;

	sram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => 4,
			DATA_WIDTH => 32
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_CONF),
			ipb_out => ipbr(N_SLV_CONF),
			rclk => nclk40,
			we => '0',
			d => (others => '0'),
			q => q_s_ram,
			addr => td(3 downto 0)
		);
	
-- Current block pointer

	ptr <= unsigned(sctr(BLK_RADIX + BUF_RADIX - 1 downto BLK_RADIX));
	rseq <= and_reduce(sctr(BLK_RADIX - 1 downto 2));
	
-- Sequence RAM

	ram: entity work.ipbus_ported_dpram
		generic map(
			ADDR_WIDTH => BUF_RADIX,
			DATA_WIDTH => 16
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUF),
			ipb_out => ipbr(N_SLV_BUF),
			rclk => clk40,
			we => we,
			d => d_ram,
			q => q_ram,
			addr => a_ram
		);
		
	we <= '1' when (tv_d = '1' and unsigned(d_ram) > unsigned(q_ram)) or (rseq = '1' and sctr(1 downto 0) = "11") else '0';
	a_ram <= std_logic_vector(ptr + unsigned(q_s_ram(BUF_RADIX - 1 downto 0))) when rseq = '0' else std_logic_vector(ptr);
	d_ram <= q_s_ram(31 downto 16) when rseq = '0' else (others => '0');

-- Pending blocks counter

	process(clk40)
	begin
		if rising_edge(clk40) then
			if zs_en = '0' then
				ctr <= (others => '0');
				keep_i <= '0';
			elsif rseq = '1' then
				if sctr(1 downto 0) = "01" then
					if unsigned(q_ram(ctr'range)) > ctr then
						ctr <= unsigned(q_ram(ctr'range));
					end if;
				elsif sctr(1 downto 0) = "10" then
					if ctr /= (ctr'range => '0') then
						ctr <= ctr - 1;
						keep_i <= '1';
					else
						keep_i <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

	keep <= keep_i;
	flush <= not keep_i;
	
end rtl;
