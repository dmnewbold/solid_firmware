-- sc_roc
--
-- Readout controller and buffer
--
-- Dave Newbold, July 2016

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

use work.ipbus.all;
use work.ipbus_decode_sc_roc.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;

entity sc_roc is
	port(
		clk: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(7 downto 0);
		clk40: in std_logic;
		rst40: in std_logic;
		d_trig: in std_logic_vector(31 downto 0);
		blkend_trig: in std_logic;
		we_trig: in std_logic;
		veto_trig: out std_logic;
		chan: out std_logic_vector(7 downto 0);
		d: in std_logic_vector(31 downto 0);
		blkend: in std_logic;
		empty: in std_logic;
		ren: out std_logic
	);

end sc_roc;

architecture rtl of sc_roc is

	constant CH_WORD: integer := 3;
	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl: ipb_reg_v(0 downto 0);
	signal stat: ipb_reg_v(1 downto 0);
	signal ctrl_en, ctrl_en_auto, ctrl_occ_freeze, ctrl_occ_clr: std_logic;
	signal rsti: std_logic;
	signal hfifo_d, hfifo_q, fifo_d, fifo_q: std_logic_vector(35 downto 0);
	signal hfifo_wen, hfifo_full, hfifo_empty, hfifo_ren, hfifo_valid: std_logic;
	signal fifo_wen, fifo_full, fifo_empty, fifo_ren, fifo_valid: std_logic;
	signal rctr, evtlen, evtlen_r, ectr: unsigned(15 downto 0);
	signal dctr: unsigned(31 downto 0);
	signal cyc, brcyc, evtdone, rsrc, err: std_logic;
	signal rdata: std_logic_vector(31 downto 0);
	signal chan_i: unsigned(7 downto 0);
	signal ttype: unsigned(3 downto 0);
	signal q_trig: std_logic_vector(31 downto 0);
	signal mask: std_logic_vector(63 downto 0);
	signal tfifo_full, tfifo_empty, tfifo_ren, tfifo_blkend, tfifo_warn: std_logic;
	type state_t is (ST_IDLE, ST_TRIG, ST_DERAND, ST_WLEN, ST_ERR);
	signal state: state_t;
	signal m, chandone, nextchan, first, ren_i, cherr, occ_rst: std_logic;

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
      sel => ipbus_sel_sc_roc(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );
    
-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	ctrl_en <= ctrl(0)(0);
	ctrl_en_auto <= ctrl(0)(1);
	ctrl_occ_freeze <= ctrl(0)(2);
	ctrl_occ_clr <= ctrl(0)(3);
	
	rsti <= not ctrl_en;
		
	stat(0) <= X"0000" & "00" & cherr & err & tfifo_blkend & tfifo_warn & tfifo_full & tfifo_empty &
		'0' & hfifo_valid & hfifo_full & hfifo_empty & '0' & fifo_valid & fifo_full & fifo_empty;
	stat(1) <= std_logic_vector(dctr);
		
-- Buffer read side

	cyc <= ipbw(N_SLV_BUF).ipb_strobe and not ipbw(N_SLV_BUF).ipb_write;
	brcyc <= ((cyc and not ipbw(N_SLV_BUF).ipb_addr(0)) or (ctrl_en_auto and or_reduce(std_logic_vector(rctr)))) and not fifo_empty;
	ipbr(N_SLV_BUF).ipb_rdata <= rdata when ipbw(N_SLV_BUF).ipb_addr(0) = '0' else X"0000" & std_logic_vector(rctr);
	ipbr(N_SLV_BUF).ipb_ack <= cyc and not (fifo_empty and not ipbw(N_SLV_BUF).ipb_addr(0));
	ipbr(N_SLV_BUF).ipb_err <= cyc and (fifo_empty and not ipbw(N_SLV_BUF).ipb_addr(0));
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rsti = '1' then
				rctr <= (others => '0');
				dctr <= (others => '0');
			elsif brcyc = '1' then
				if hfifo_wen = '1' then
					rctr <= rctr + evtlen;
					dctr <= dctr + evtlen;
				else
					rctr <= rctr - 1;
				end if;
			elsif hfifo_wen = '1' then
				rctr <= rctr + evtlen + 1;
				dctr <= dctr + evtlen + 1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rsti = '1' then
				rsrc <= '0';
			elsif brcyc = '1' then
				if rsrc = '0' then
					rsrc <= '1';
					evtlen_r <= unsigned(hfifo_q(15 downto 0));
					ectr <= to_unsigned(1, ectr'length);
				else
					ectr <= ectr + 1;
					if ectr = evtlen_r then
						rsrc <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	rdata <= hfifo_q(31 downto 0) when rsrc = '0' else fifo_q(31 downto 0);

-- Header buffer

	hbuf: entity work.big_fifo_36
		generic map(
			N_FIFO => 1
		)
		port map(
			clk => clk,
			rst => rsti,
			d => hfifo_d,
			wen => hfifo_wen,
			full => hfifo_full,
			empty => hfifo_empty,
			ctr => open,
			ren => hfifo_ren,
			q => hfifo_q,
			valid => hfifo_valid
		);
		
	hfifo_ren <= brcyc and not rsrc;
	hfifo_wen <= '1' when state = ST_WLEN else '0';
	hfifo_d <= X"0AA" & board_id & std_logic_vector(evtlen);
	
-- Data buffer

	dbuf: entity work.big_fifo_36
		generic map(
			N_FIFO => 2 ** FIFO_RADIX
		)
		port map(
			clk => clk,
			rst => rsti,
			d => fifo_d,
			wen => fifo_wen,
			full => fifo_full,
			empty => fifo_empty,
			ctr => open,
			ren => fifo_ren,
			q => fifo_q,
			valid => fifo_valid
		);
		
	fifo_ren <= brcyc and rsrc;
	fifo_wen <= tfifo_ren or ren_i;
	fifo_d(35 downto 32) <= X"0";
	fifo_d(31 downto 0) <= d when state = ST_DERAND else q_trig;
	
-- Trigger buffer

	tbuf: entity work.sc_derand
		port map(
			clk_w => clk40,
			rst_w => rst40,
			d => d_trig,
			d_blkend => blkend_trig,
			wen => we_trig,
			clk_r => clk,
			q => q_trig,
			q_blkend => tfifo_blkend,
			empty => tfifo_empty,
			ren => tfifo_ren,
			warn => tfifo_warn,
			full => tfifo_full
		);

	tfifo_ren <= '1' when state = ST_TRIG and tfifo_empty = '0' and fifo_full = '0' else '0';
	veto_trig <= tfifo_warn;
	
-- State machine

	process(clk)
	begin
		if rising_edge(clk) then
			if rsti = '1' then
				state <= ST_IDLE;
			else		
				case state is
				
				when ST_IDLE => -- Starting state
					if tfifo_empty = '0' then
						state <= ST_TRIG;
					end if;

				when ST_TRIG => -- Move trigger data
					if tfifo_blkend = '1' and fifo_full = '0' then
						if ttype /= X"0" or or_reduce(mask) = '0' then
							state <= ST_WLEN;
						else
							state <= ST_DERAND;
						end if;
					end if;
				
				when ST_DERAND => -- Move event data
					if cherr = '1' then
						state <= ST_ERR;
					elsif evtdone = '1' and fifo_full = '0' then
						state <= ST_WLEN;
					end if;
					
				when ST_WLEN => -- Write the header 
					if hfifo_full = '1' or tfifo_full = '1' then
						state <= ST_ERR;
					else
						state <= ST_IDLE;
					end if;
					
				when ST_ERR => -- Stuck
				
				end case;
			end if;
		end if;
	end process;
	
	err <= '1' when state = ST_ERR else '0';
	
	m <= mask(to_integer(chan_i));
	chandone <= blkend or not m;
	evtdone <= '1' when (chan_i = N_CHAN - 1 and chandone = '1' and state = ST_DERAND) or
		((ttype /= X"0" or or_reduce(mask) = '0') and tfifo_blkend = '1' and state = ST_TRIG) else '0';
	nextchan <= '1' when state = ST_DERAND and chandone = '1' and fifo_full = '0' and evtdone = '0' else '0';
	
	process(clk)
	begin
		if rising_edge(clk) then
			if state = ST_IDLE then
				chan_i <= (others => '0');
				evtlen <= (others => '0');
			else
				if fifo_wen = '1' then
					evtlen <= evtlen + 1;
				end if;
				if nextchan = '1' then
					chan_i <= chan_i + 1; 
				end if;
				if nextchan = '1' or state = ST_TRIG then
					first <= '1';
				else
					first <= '0';
				end if;
				if state = ST_TRIG then
					if evtlen = to_unsigned(0, 16) then
						ttype <= unsigned(q_trig(31 downto 28));
					elsif evtlen = to_unsigned(CH_WORD, 16) then
						mask(31 downto 0) <= q_trig;
					elsif evtlen = to_unsigned(CH_WORD + 1, 16) then
						mask(63 downto 32) <= q_trig;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	ren_i <= '1' when state = ST_DERAND and m = '1' and fifo_full = '0' and empty = '0' else '0';
	cherr <= '1' when state = ST_DERAND and first = '1' and empty = '1' else '0';
	
	ren <= ren_i;
	chan <= std_logic_vector(chan_i);
	
-- Occupancy histogram

	occ_rst <= ctrl_occ_clr or rsti;

	occ: entity work.occ_histo_unscaled
		generic map(
			BINS_RADIX => 3,
			OCC_WIDTH => 11 + FIFO_RADIX
		)
		port map(
			clk => clk,
			rst => rsti,
			ipb_in => ipbw(N_SLV_OCC),
			ipb_out => ipbr(N_SLV_OCC),
			clk_s => clk,
			rst_s => occ_rst,
			occ => std_logic_vector(rctr(10 + FIFO_RADIX downto 0)),
			freeze => ctrl_occ_freeze
		);
			
end rtl;
