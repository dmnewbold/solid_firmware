-- sc_trig_link_pipe
--
-- Data path logic for trigger links
--
-- Dave Newbold, October 2017

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

entity sc_trig_link_pipe is
	port(
		en: in std_logic;
		clk125: in std_logic;
		rxd: in std_logic_vector(15 downto 0);
		rxk: in std_logic_vector(1 downto 0);
		link_good: in std_logic;
		txd: out std_logic_vector(15 downto 0);
		txk: out std_logic_vector(1 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		sctr: in std_logic_vector(15 downto 0);
		d: in std_logic_vector(15 downto 0);
		dv: in std_logic;
		q: out std_logic_vector(15 downto 0);
		qv: out std_logic;
		ack: in std_logic;
		stat_rx: out std_logic_vector(4 downto 0);
		stat_tx: out std_logic_vector(1 downto 0);
		my_id: in std_logic_vector(7 downto 0);
		remote_id: out std_logic_vector(7 downto 0);
		data_good: out std_logic
	);

end sc_trig_link_pipe;

architecture rtl of sc_trig_link_pipe is
	
	signal txd_idle: std_logic_vector(15 downto 0);
	signal txk_idle: std_logic_vector(1 downto 0);
	signal rx_valid, tx_f_valid: std_logic;
	signal di_rx, do_rx, di_tx, do_tx: std_logic_vector(31 downto 0);
	signal v, ren_rx, ren_tx, wen_tx, empty_rx, full_rx, empty_tx, full_tx: std_logic;
	signal f: std_logic_vector(15 downto 0);
	signal up, fail, cause: std_logic;
	signal cctr: unsigned(8 downto 0);

begin

-- Input FIFO

	rx_valid <= '1' when rxk = "00" and link_good = '1' else '0';
	di_rx <= X"0000" & rxd;
	
	rx_fifo: FIFO18E1
		generic map(
			DATA_WIDTH => 18,
			FIRST_WORD_FALL_THROUGH => true
		)
		port map(
			di => di_rx,
			dip => "0000",
			do => do_rx,
			empty => empty_rx,
			full => full_rx,
			rdclk => clk40,
			rden => ren_rx,
			regce => '1',
			rst => rst40,
			rstreg => '0',
			wrclk => clk125,
			wren => rx_valid
		);

	q <= do_rx(15 downto 0);
	qv <= up and not empty_rx;
	stat_rx <= full_rx & empty_rx;
	ren_rx <= ack or not up;
	
-- Data checker: rx

	process(clk40)
	begin
		if rising_edge(clk40) then
			if rst40 = '1' or en = '0' or link_good = '0' then -- CDC, en is on clk_ipb, but ~static level
				up <= '0';
				fail <= '0';
				cause <= '0';
			elsif do_rx(3 downto 0) = X"f" then
				if up = '0' then 
					if fail = '0' and do_rx(15 downto 8) = sctr(15 downto 8) then
						up <= '1';
						cctr <= (others => '0');
					end if;
				else
					if do_rx(15 downto 8) /= sctr(15 downto 8) then
						up <= '0';
						fail <= '1';
					else
						cctr <= (others => '0');
					end if;
				end if;
			else
				if and_reduce(std_logic_vector(cctr)) = '1' then -- Timeout between block markers
					up <= '0';
					fail <= '1';
					cause <= '1';
				else
					cctr <= cctr + 1;
				end if;
			end if;
		end if;
	end process;
		
	data_good <= up;
	stat_rx(2) <= up;
	stat_rx(3) <= fail;
	stat_rx(4) <= cause;

-- Trigger forwarding and hop count

	process(clk125)
	begin
		if rising_edge(clk125) then
			f <= rxd(15 downto 8) & std_logic_vector(unsigned(rxd(7 downto 4)) - 1) & rxd(3 downto 0);
			if rx_valid = '1' and rxd(7 downto 4) /= "0001" and up = '1' then
				v <= '1';
			else
				v <= '0';
			end if;
		end if;
	end process;

-- Output FIFO

	di_tx <= X"0000" & d when or_reduce(sctr(7 downto 0)) = '1' else X"0000" & sctr(15 downto 8) & X"1f";

	tx_fifo: FIFO18E1
		generic map(
			DATA_WIDTH => 18,
			FIRST_WORD_FALL_THROUGH => true
		)
		port map(
			di => di_tx,
			dip => "0000",
			do => do_tx,
			empty => empty_tx,
			full => full_tx,
			rdclk => clk125,
			rden => ren_tx,
			regce => '1',
			rst => rst40,
			rstreg => '0',
			wrclk => clk40,
			wren => wen_tx
		);

	stat_rx <= full_tx & empty_tx;
	ren_tx <= not empty_tx and not v;
	wen_tx <= dv or not or_reduce(sctr(7 downto 0));
	
-- Link output select

	process(f, do_tx, my_id, v, empty_tx)
	begin
		if v = '1' then
			txd <= f;
			txk <= "00";
		elsif empty_tx = '0' then
			txd <= do_tx(15 downto 0);
			txk <= "00";
		else
			txd <= X"bc" & my_id;
			txk <= "10";
		end if;
	end process;

-- Remote link ID

	remote_id <= rxd(7 downto 0) when rising_edge(clk125) and rxk = "10" and link_good = '1';

end rtl;
