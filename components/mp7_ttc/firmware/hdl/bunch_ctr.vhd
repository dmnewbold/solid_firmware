-- bunch_ctr
--
-- General-purpose bunch counter, locked to BC0 signal
--
-- Free-running with period dictated by LHC_BUNCH_COUNT until a bc0 input
-- arrives - then it will lock to that and subsequently raise 'err' if bc0
-- does not arrive in the right place.
--
-- CLOCK_RATIO is the ratio between clk and clk40.
-- CLK_DIV is the division of the clock for bctr
--   The divider count is available on pctr
--   NB: CLK_DIV should be a factor of CLOCK_RATIO
-- OFFSET is useful for making an 'early' counter required for ram address
--   lines, etc. It's specified in terms of clock cycles, not BX.
-- LOCK_CTR controls lock / error check mode of counter
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity bunch_ctr is
	generic(
		CLOCK_RATIO: positive := 1;
		CLK_DIV: positive := 1;
		CTR_WIDTH: positive := 12;
		OCTR_WIDTH: positive := 12;
		LHC_BUNCH_COUNT: positive;
		OFFSET: natural := 0;
		BC0_BX: natural := 0;
		LOCK_CTR: boolean := true
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		clr: in std_logic;
		bc0: in std_logic; -- clk40 domain
		oc0: in std_logic := '0';
		bctr: out std_logic_vector(CTR_WIDTH - 1 downto 0);
		pctr: out std_logic_vector(2 downto 0);
		bmax: out std_logic;
		octr: out std_logic_vector(OCTR_WIDTH - 1 downto 0);
		lock: out std_logic
	);

begin

	assert 2 ** CTR_WIDTH > LHC_BUNCH_COUNT * CLOCK_RATIO / CLK_DIV
		report "Not enough bits in bunch counter"
		severity failure;

	assert CLK_DIV < 9
		report "Division ratio too high"
		severity failure;
		
end bunch_ctr;

architecture rtl of bunch_ctr is

	constant SCYC: integer := ((BC0_BX * CLOCK_RATIO) + OFFSET + 2) mod (LHC_BUNCH_COUNT * CLOCK_RATIO);
	constant OFF: integer := SCYC / CLK_DIV;
	constant P_OFF: integer := SCYC mod CLK_DIV;

	signal bctr_i: unsigned(CTR_WIDTH - 1 downto 0) := (others => '0');
	signal pctr_i: unsigned(2 downto 0) := (others => '0');
	signal lock_i, lock_lost: std_logic := '0';
	signal bc0_d, bc0_dd, sync, sync_d, bmax_i, pmax_i, err_i: std_logic;
	signal octr_i: unsigned(OCTR_WIDTH - 1 downto 0);
	
begin

	process(clk)
	begin
		if rising_edge(clk) then

			bc0_d <= bc0; -- CDC (related clocks)
			bc0_dd <= bc0_d;
			sync_d <= sync;
			
			if rst = '1' or clr = '1' then
				bctr_i <= (others => '0');
				pctr_i <= (others => '0');
				lock_i <= '0';
				lock_lost <= '0';
			elsif sync = '1' and LOCK_CTR and lock_i = '0' and lock_lost = '0' then
				bctr_i <= to_unsigned(OFF, CTR_WIDTH);
				pctr_i <= to_unsigned(P_OFF, pctr_i'length);
				lock_i <= '1';
			else
				if sync_d = '1' and lock_i = '1' and (bctr_i /= to_unsigned(OFF, CTR_WIDTH) or pctr_i /= to_unsigned(P_OFF, pctr_i'length)) then
					lock_i <= '0';
					lock_lost <= '1';
				end if;
				if pmax_i = '1' then
					pctr_i <= "000";
					if bmax_i = '1' then
						bctr_i <= (others => '0');
					else
						bctr_i <= bctr_i + 1;
					end if;
				else
					pctr_i <= pctr_i + 1;
				end if;
			end if;
		end if;
	end process;
	
	sync <= '1' when bc0_d = '1' and bc0_dd = '0' else '0';
	pmax_i <= '1' when pctr_i = to_unsigned(CLK_DIV - 1, 3) else '0';
	bmax_i <= '1' when bctr_i = to_unsigned(LHC_BUNCH_COUNT * CLOCK_RATIO / CLK_DIV - 1, CTR_WIDTH) else '0';
	
	process(clk)
	begin
		if rising_edge(clk) then
			if oc0 = '1' or rst = '1' or clr = '1' then
				octr_i <= to_unsigned(0, octr_i'length);
			elsif bmax_i = '1' and pmax_i = '1' then
				octr_i <= octr_i + 1;
			end if;
		end if;
	end process;

	bctr <= std_logic_vector(bctr_i);
	pctr <= std_logic_vector(pctr_i);
	octr <= std_logic_vector(octr_i);
	lock <= lock_i;	
	bmax <= bmax_i and pmax_i;
	
end rtl;
