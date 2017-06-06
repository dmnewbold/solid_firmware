-- sc_trig_ro_block
--
-- Header data to ROC for each readout
-- Sends data at block start
--
-- Dave Newbold, August 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.top_decl.all;

entity sc_trig_ro_block is
	port(
		clk40: in std_logic;
		rst40: in std_logic;
		trig_en: in std_logic;
		sctr: in std_logic_vector(47 downto 0);
		mark: in std_logic;
		keep: in std_logic_vector(N_CHAN - 1 downto 0);
		veto: in std_logic_vector(N_CHAN - 1 downto 0);
		tctr: out std_logic_vector(27 downto 0);
		ro_q: out std_logic_vector(31 downto 0);
		ro_valid: out std_logic;
		ro_blkend: out std_logic;
		ro_go: in std_logic;
		ro_ctr: in std_logic_vector(7 downto 0);
		rveto: in std_logic
	);

end sc_trig_ro_block;

architecture rtl of sc_trig_ro_block is

	constant OFFSET: integer := (NZS_BLKS + ZS_BLKS) * 2 ** BLK_RADIX;
	signal tctr_i: unsigned(27 downto 0);
	signal go, blkend: std_logic;
	signal chen, keep_c: std_logic_vector(63 downto 0);

begin
	
-- Trigger counter

	process(clk40)
	begin
		if rising_edge(clk40) then
			if trig_en = '0' then
				tctr_i <= (others => '0');
			elsif mark = '1' and or_reduce(keep) = '1' then
				tctr_i <= tctr_i + 1;
			end if;
		end if;
	end process;
	
	tctr <= std_logic_vector(tctr_i);
	
-- Block data to ROC
	
	chen <= (63 downto N_CHAN => '0') & (keep and not veto); -- Assumption on 64 channels max here...
	keep_c <= (63 downto N_CHAN => '0') & keep; 

	go <= (go or (ro_go and or_reduce(keep) and not rveto)) and not blkend and trig_en when rising_edge(clk40);
	blkend <= '1' when ro_ctr = X"06" else '0';
	ro_valid <= go;
	ro_blkend <= blkend;
	
	with ro_ctr select ro_q <=
		X"0" & std_logic_vector(tctr_i) when X"00", -- Type 0
		std_logic_vector(unsigned(sctr(31 downto 1) & '0') - OFFSET) when X"01", -- Hack so that counter is taken at start-of-block
		X"0000" & std_logic_vector(sctr(47 downto 32)) when X"02",
		chen(31 downto 0) when X"03", -- Corresponds to CH_WORD = 3 in sc_roc
		chen(63 downto 32) when X"04",
		keep_c(31 downto 0) when X"05",
		keep_c(63 downto 32) when others;

end rtl;
