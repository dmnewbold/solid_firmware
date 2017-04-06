-- ttc_clocks
--
-- Clock generation for LHC clocks
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library unisim;
use unisim.VComponents.all;

entity ttc_clocks is
	port(
		clk40_in_p: in std_logic;		
		clk40_in_n: in std_logic;
		clk_p40: in std_logic;
		clko_40: out std_logic;
		clko_80: out std_logic;
		clko_120: out std_logic;
		clko_160: out std_logic;
		clko_240: out std_logic;
		rsto_40: out std_logic;
		rsto_80: out std_logic;
		rsto_120: out std_logic;
		rsto_160: out std_logic;
		rsto_240: out std_logic;
		clko_40s: out std_logic;
		stopped: out std_logic;
		locked: out std_logic;
		rst_mmcm: in std_logic;
		rsti: in std_logic;
		clksel: in std_logic;
		psen: in std_logic;
		psval: in std_logic_vector(11 downto 0);
		psok: out std_logic
	);

end ttc_clocks;

architecture rtl of ttc_clocks is

	signal clk40_bp, clk40_bp_u, clk_fb, clk_fb_fr, clk_p40_b: std_logic;
	signal clk40_u, clk80_u, clk120_u, clk160_u, clk240_u, clk40s_u, clk40_i, clk80_i, clk120_i, clk160_i, clk240_i: std_logic;
	signal locked_i, rsto_80_r, rsto_120_r, rsto_160_r, rsto_240_r: std_logic;
	signal pscur_i: std_logic_vector(11 downto 0);
	signal psrst, psgo, psincdec, psdone, psbusy, psdiff: std_logic;
	
	attribute KEEP: string;
	
	attribute KEEP of clk40_i: signal is "TRUE";
	attribute KEEP of clk120_i: signal is "TRUE";	
	attribute KEEP of clk160_i: signal is "TRUE";	
	attribute KEEP of clk240_i: signal is "TRUE";
	
	attribute KEEP of rsto_120_r: signal is "TRUE";	
	attribute KEEP of rsto_160_r: signal is "TRUE";	
	attribute KEEP of rsto_240_r: signal is "TRUE";
	
begin

-- Input buffers

	ibuf_clk40: IBUFGDS
		port map(
			i => clk40_in_p,
			ib => clk40_in_n,
			o => clk40_bp_u
		);
		
	bufr_clk40: BUFG
		port map(
			i => clk40_bp_u,
			o => clk40_bp
		);
		
-- MMCM

	mmcm: MMCME2_ADV
		generic map(
			clkin1_period => 25.0,
			clkin2_period => 25.0,
			clkfbout_mult_f => 24.0,
			clkout1_divide => 24,
			clkout2_divide => 24,
			clkout2_phase => 45.0, -- Adjust on test
			clkout2_use_fine_ps => true,
			clkout3_divide => 12,
			clkout4_divide => 6,
			clkout5_divide => 4,
			clkout6_divide => 8
		)
		port map(
			clkin1 => clk40_bp,
			clkin2 => clk_p40,
			clkinsel => clksel,
			clkfbin => clk_fb,
			clkfbout => clk_fb,
			clkout1 => clk40_u,
			clkout2 => clk40s_u,
			clkout3 => clk80_u,
			clkout4 => clk160_u,
			clkout5 => clk240_u,
			clkout6 => clk120_u,
			rst => rst_mmcm,
			pwrdwn => '0',
			clkinstopped => stopped,
			locked => locked_i,
			daddr => "0000000",
			di => X"0000",
			dwe => '0',
			den => '0',
			dclk => '0',
			psclk => clk40_i,
			psen => psgo,
			psincdec => psincdec,
			psdone => psdone
		);
		
	locked <= locked_i;

-- Phase shift state machine
	
	psrst <= rst_mmcm or not locked_i or not psen;

	process(clk40_i)
	begin
		if rising_edge(clk40_i) then

			if psrst = '1' then
				pscur_i <= X"000";
			elsif psdone = '1' then
				if psincdec = '1' then
					pscur_i <= std_logic_vector(unsigned(pscur_i) + 1);
				else
					pscur_i <= std_logic_vector(unsigned(pscur_i) - 1);
				end if;
			end if;

			psgo <= psdiff and not (psbusy or psgo or psrst);
			psbusy <= ((psbusy and not psdone) or psgo) and not psrst;

		end if;
	end process;
	
	psincdec <= '1' when psval > pscur_i else '0';
	psdiff <= '1' when psval /= pscur_i else '0';
	psok <= not psdiff;
	
-- Buffers
	
	bufg_40: BUFG
		port map(
			i => clk40_u,
			o => clk40_i
		);
		
	clko_40 <= clk40_i;

	process(clk40_i)
	begin
		if rising_edge(clk40_i) then
			rsto_40 <= rsti or not locked_i;
		end if;
	end process;

	bufg_80: BUFG
		port map(
			i => clk80_u,
			o => clk80_i
		);
		
	clko_80 <= clk80_i;
		
	process(clk80_i)
	begin
		if rising_edge(clk80_i) then
			rsto_80_r <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
			rsto_80 <= rsto_80_r; -- Pipelining for high-fanout signal
		end if;
	end process;

	bufg_120: BUFG
		port map(
			i => clk120_u,
			o => clk120_i
		);
		
	clko_120 <= clk120_i;
		
	process(clk120_i)
	begin
		if rising_edge(clk120_i) then
			rsto_120_r <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
			rsto_120 <= rsto_120_r; -- Pipelining for high-fanout signal
		end if;
	end process;
		
	bufg_160: BUFG
		port map(
			i => clk160_u,
			o => clk160_i
		);
		
	clko_160 <= clk160_i;
		
	process(clk160_i)
	begin
		if rising_edge(clk160_i) then
			rsto_160_r <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
			rsto_160 <= rsto_160_r; -- Pipelining for high-fanout signal
		end if;
	end process;
		
	bufg_240: BUFG
		port map(
			i => clk240_u,
			o => clk240_i
		);
		
	clko_240 <= clk240_i;
		
	process(clk240_i)
	begin
		if rising_edge(clk240_i) then
			rsto_240_r <= rsti or not locked_i; -- Disaster looms if tools duplicate this signal
			rsto_240 <= rsto_240_r; -- Pipelining for high-fanout signal
		end if;
	end process;
	
	bufr_40s: BUFH
		port map(
			i => clk40s_u,
			o => clko_40s
		);

end rtl;
