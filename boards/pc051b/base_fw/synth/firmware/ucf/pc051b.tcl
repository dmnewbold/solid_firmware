
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Ethernet RefClk (125MHz)
create_clock -period 8.000 -name eth_refclk [get_ports eth_clk_p]

# Ethernet monitor clock hack (62.5MHz)
create_clock -period 16.000 -name clk_dc [get_pins infra/eth/dc_buf/O]

# System synchronous clock (40MHz nominal)
create_clock -period 25.000 -name clk40 [get_ports clk_p]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks eth_refclk] -group [get_clocks -include_generated_clocks [get_clocks -filter {name =~ infra/eth/phy/*/RXOUTCLK}]] -group [get_clocks -include_generated_clocks [get_clocks -filter {name =~ infra/eth/phy/*/TXOUTCLK}]]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks clk40]

# Area constraints
create_pblock infra
resize_pblock [get_pblocks infra] -add {CLOCKREGION_X1Y4:CLOCKREGION_X1Y4}

set_property PACKAGE_PIN F6 [get_ports eth_clk_p]
set_property PACKAGE_PIN E6 [get_ports eth_clk_n]

set_property LOC GTPE2_CHANNEL_X0Y4 [get_cells -hier -filter {name=~infra/eth/*/gtpe2_i}]
set_property LOC GTPE2_CHANNEL_X0Y6 [get_cells -hier -filter {name=~*/mgt_ds/*/gtpe2_i}]
set_property LOC GTPE2_CHANNEL_X0Y7 [get_cells -hier -filter {name=~*/mgt_us/*/gtpe2_i}]

proc false_path {patt clk} {
    set p [get_ports -quiet $patt -filter {direction != out}]
    if {[llength $p] != 0} {
        set_input_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != out}]
        set_false_path -from [get_ports $patt -filter {direction != out}]
    }
    set p [get_ports -quiet $patt -filter {direction != in}]
    if {[llength $p] != 0} {
       	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	    set_false_path -to [get_ports $patt -filter {direction != in}]
	}
}

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {leds[*]}]
set_property PACKAGE_PIN W22 [get_ports {leds[0]}]
set_property PACKAGE_PIN U22 [get_ports {leds[1]}]
false_path {leds[*]} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property PACKAGE_PIN W20 [get_ports led]
false_path led eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {addr[*]}]
set_property PACKAGE_PIN AA20 [get_ports {addr[0]}]
set_property PACKAGE_PIN Y21 [get_ports {addr[1]}]
set_property PACKAGE_PIN AB21 [get_ports {addr[2]}]
set_property PACKAGE_PIN U20 [get_ports {addr[3]}]
set_property PACKAGE_PIN AA21 [get_ports {addr[4]}]
set_property PACKAGE_PIN Y22 [get_ports {addr[5]}]
set_property PACKAGE_PIN AB22 [get_ports {addr[6]}]
set_property PACKAGE_PIN V20 [get_ports {addr[7]}]
false_path {addr[*]} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {sel[*]}]
set_property PACKAGE_PIN U18 [get_ports {sel[0]}]
set_property PACKAGE_PIN R18 [get_ports {sel[1]}]
set_property PACKAGE_PIN T18 [get_ports {sel[2]}]
set_property PACKAGE_PIN P16 [get_ports {sel[3]}]
set_property PACKAGE_PIN R17 [get_ports {sel[4]}]
false_path {sel[*]} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {i2c_*}]
set_property PACKAGE_PIN AA18 [get_ports {i2c_scl}]
set_property PACKAGE_PIN U17 [get_ports {i2c_sda_i}]
set_property PACKAGE_PIN AB18 [get_ports {i2c_sda_o}]
false_path {i2c_*} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {spi_*}] 
set_property PACKAGE_PIN T21 [get_ports {spi_sclk}]
set_property PACKAGE_PIN U21 [get_ports {spi_mosi}]
set_property PACKAGE_PIN P19 [get_ports {spi_miso}]
set_property PACKAGE_PIN R19 [get_ports {spi_csn}]
false_path {spi_*} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports {clkgen_*}]
set_property PACKAGE_PIN V18 [get_ports {clkgen_rstn}]
set_property PACKAGE_PIN V19 [get_ports {clkgen_lol}]
false_path {clkgen_*} eth_refclk

# Bank 13, 2V5
set_property IOSTANDARD LVDS_25 [get_ports {clk_*}]
set_property DIFF_TERM TRUE [get_ports {clk_*}]
set_property PACKAGE_PIN W11 [get_ports {clk_p}]
set_property PACKAGE_PIN W12 [get_ports {clk_n}]

# Bank 15, 2V5
set_property IOSTANDARD LVCMOS25 [get_ports {sync_in trig_in}]
set_property PACKAGE_PIN J16 [get_ports {sync_in}]
set_property PACKAGE_PIN M17 [get_ports {trig_in}]
false_path {sync_in trig_in} eth_refclk

# Bank 14, 3V3
set_property IOSTANDARD LVCMOS33 [get_ports trig_out]
set_property PACKAGE_PIN Y19 [get_ports {trig_out}]
false_path {trig_out} eth_refclk

# Bank 13,15,16, 2V5 / 14, 3V3 (bits 61, 63)
set_property IOSTANDARD LVDS_25 [get_ports {adc_d_*}]
set_property DIFF_TERM TRUE [get_ports {adc_d_*}]
set_property DIFF_TERM FALSE [get_ports {adc_d_*[61] adc_d_*[63]}]
set_property PACKAGE_PIN W14 [get_ports {adc_d_p[0]}]
set_property PACKAGE_PIN Y14 [get_ports {adc_d_n[0]}]
set_property PACKAGE_PIN AA13 [get_ports {adc_d_p[1]}]
set_property PACKAGE_PIN AB13 [get_ports {adc_d_n[1]}]
set_property PACKAGE_PIN Y13 [get_ports {adc_d_p[2]}]
set_property PACKAGE_PIN AA14 [get_ports {adc_d_n[2]}]
set_property PACKAGE_PIN Y11 [get_ports {adc_d_p[3]}]
set_property PACKAGE_PIN Y12 [get_ports {adc_d_n[3]}]
set_property PACKAGE_PIN AA10 [get_ports {adc_d_p[4]}]
set_property PACKAGE_PIN AA11 [get_ports {adc_d_n[4]}]
set_property PACKAGE_PIN E22 [get_ports {adc_d_p[5]}]
set_property PACKAGE_PIN D22 [get_ports {adc_d_n[5]}]
set_property PACKAGE_PIN B20 [get_ports {adc_d_p[6]}]
set_property PACKAGE_PIN A20 [get_ports {adc_d_n[6]}]
set_property PACKAGE_PIN G21 [get_ports {adc_d_p[7]}]
set_property PACKAGE_PIN G22 [get_ports {adc_d_n[7]}]
set_property PACKAGE_PIN D20 [get_ports {adc_d_p[8]}]
set_property PACKAGE_PIN C20 [get_ports {adc_d_n[8]}]
set_property PACKAGE_PIN E21 [get_ports {adc_d_p[9]}]
set_property PACKAGE_PIN D21 [get_ports {adc_d_n[9]}]
set_property PACKAGE_PIN A18 [get_ports {adc_d_p[10]}]
set_property PACKAGE_PIN A19 [get_ports {adc_d_n[10]}]
set_property PACKAGE_PIN F18 [get_ports {adc_d_p[11]}]
set_property PACKAGE_PIN E18 [get_ports {adc_d_n[11]}]
set_property PACKAGE_PIN F19 [get_ports {adc_d_p[12]}]
set_property PACKAGE_PIN F20 [get_ports {adc_d_n[12]}]
set_property PACKAGE_PIN C22 [get_ports {adc_d_p[13]}]
set_property PACKAGE_PIN B22 [get_ports {adc_d_n[13]}]
set_property PACKAGE_PIN A15 [get_ports {adc_d_p[14]}]
set_property PACKAGE_PIN A16 [get_ports {adc_d_n[14]}]
set_property PACKAGE_PIN B21 [get_ports {adc_d_p[15]}]
set_property PACKAGE_PIN A21 [get_ports {adc_d_n[15]}]
set_property PACKAGE_PIN B15 [get_ports {adc_d_p[16]}]
set_property PACKAGE_PIN B16 [get_ports {adc_d_n[16]}]
set_property PACKAGE_PIN C18 [get_ports {adc_d_p[17]}]
set_property PACKAGE_PIN C19 [get_ports {adc_d_n[17]}]
set_property PACKAGE_PIN B17 [get_ports {adc_d_p[18]}]
set_property PACKAGE_PIN B18 [get_ports {adc_d_n[18]}]
set_property PACKAGE_PIN E19 [get_ports {adc_d_p[19]}]
set_property PACKAGE_PIN D19 [get_ports {adc_d_n[19]}]
set_property PACKAGE_PIN A13 [get_ports {adc_d_p[20]}]
set_property PACKAGE_PIN A14 [get_ports {adc_d_n[20]}]
set_property PACKAGE_PIN C14 [get_ports {adc_d_p[21]}]
set_property PACKAGE_PIN C15 [get_ports {adc_d_n[21]}]
set_property PACKAGE_PIN E16 [get_ports {adc_d_p[22]}]
set_property PACKAGE_PIN D16 [get_ports {adc_d_n[22]}]
set_property PACKAGE_PIN D17 [get_ports {adc_d_p[23]}]
set_property PACKAGE_PIN C17 [get_ports {adc_d_n[23]}]
set_property PACKAGE_PIN C13 [get_ports {adc_d_p[24]}]
set_property PACKAGE_PIN B13 [get_ports {adc_d_n[24]}]
set_property PACKAGE_PIN F13 [get_ports {adc_d_p[25]}]
set_property PACKAGE_PIN F14 [get_ports {adc_d_n[25]}]
set_property PACKAGE_PIN D14 [get_ports {adc_d_p[26]}]
set_property PACKAGE_PIN D15 [get_ports {adc_d_n[26]}]
set_property PACKAGE_PIN E13 [get_ports {adc_d_p[27]}]
set_property PACKAGE_PIN E14 [get_ports {adc_d_n[27]}]
set_property PACKAGE_PIN F16 [get_ports {adc_d_p[28]}]
set_property PACKAGE_PIN E17 [get_ports {adc_d_n[28]}]
set_property PACKAGE_PIN T16 [get_ports {adc_d_p[29]}]
set_property PACKAGE_PIN U16 [get_ports {adc_d_n[29]}]
set_property PACKAGE_PIN U15 [get_ports {adc_d_p[30]}]
set_property PACKAGE_PIN V15 [get_ports {adc_d_n[30]}]
set_property PACKAGE_PIN V10 [get_ports {adc_d_p[31]}]
set_property PACKAGE_PIN W10 [get_ports {adc_d_n[31]}]
set_property PACKAGE_PIN W15 [get_ports {adc_d_p[32]}]
set_property PACKAGE_PIN W16 [get_ports {adc_d_n[32]}]
set_property PACKAGE_PIN T14 [get_ports {adc_d_p[33]}]
set_property PACKAGE_PIN T15 [get_ports {adc_d_n[33]}]
set_property PACKAGE_PIN Y16 [get_ports {adc_d_p[34]}]
set_property PACKAGE_PIN AA16 [get_ports {adc_d_n[34]}]
set_property PACKAGE_PIN AA15 [get_ports {adc_d_p[35]}]
set_property PACKAGE_PIN AB15 [get_ports {adc_d_n[35]}]
set_property PACKAGE_PIN AB16 [get_ports {adc_d_p[36]}]
set_property PACKAGE_PIN AB17 [get_ports {adc_d_n[36]}]
set_property PACKAGE_PIN V13 [get_ports {adc_d_p[37]}]
set_property PACKAGE_PIN V14 [get_ports {adc_d_n[37]}]
set_property PACKAGE_PIN L14 [get_ports {adc_d_p[38]}]
set_property PACKAGE_PIN L15 [get_ports {adc_d_n[38]}]
set_property PACKAGE_PIN M15 [get_ports {adc_d_p[39]}]
set_property PACKAGE_PIN M16 [get_ports {adc_d_n[39]}]
set_property PACKAGE_PIN K17 [get_ports {adc_d_p[40]}]
set_property PACKAGE_PIN J17 [get_ports {adc_d_n[40]}]
set_property PACKAGE_PIN J15 [get_ports {adc_d_p[41]}]
set_property PACKAGE_PIN H15 [get_ports {adc_d_n[41]}]
set_property PACKAGE_PIN H17 [get_ports {adc_d_p[42]}]
set_property PACKAGE_PIN H18 [get_ports {adc_d_n[42]}]
set_property PACKAGE_PIN G17 [get_ports {adc_d_p[43]}]
set_property PACKAGE_PIN G18 [get_ports {adc_d_n[43]}]
set_property PACKAGE_PIN N22 [get_ports {adc_d_p[44]}]
set_property PACKAGE_PIN M22 [get_ports {adc_d_n[44]}]
set_property PACKAGE_PIN G15 [get_ports {adc_d_p[45]}]
set_property PACKAGE_PIN G16 [get_ports {adc_d_n[45]}]
set_property PACKAGE_PIN M13 [get_ports {adc_d_p[46]}]
set_property PACKAGE_PIN L13 [get_ports {adc_d_n[46]}]
set_property PACKAGE_PIN H13 [get_ports {adc_d_p[47]}]
set_property PACKAGE_PIN G13 [get_ports {adc_d_n[47]}]
set_property PACKAGE_PIN N20 [get_ports {adc_d_p[48]}]
set_property PACKAGE_PIN M20 [get_ports {adc_d_n[48]}]
set_property PACKAGE_PIN M18 [get_ports {adc_d_p[49]}]
set_property PACKAGE_PIN L18 [get_ports {adc_d_n[49]}]
set_property PACKAGE_PIN M21 [get_ports {adc_d_p[50]}]
set_property PACKAGE_PIN L21 [get_ports {adc_d_n[50]}]
set_property PACKAGE_PIN N18 [get_ports {adc_d_p[51]}]
set_property PACKAGE_PIN N19 [get_ports {adc_d_n[51]}]
set_property PACKAGE_PIN J19 [get_ports {adc_d_p[52]}]
set_property PACKAGE_PIN H19 [get_ports {adc_d_n[52]}]
set_property PACKAGE_PIN J14 [get_ports {adc_d_p[53]}]
set_property PACKAGE_PIN H14 [get_ports {adc_d_n[53]}]
set_property PACKAGE_PIN L19 [get_ports {adc_d_p[54]}]
set_property PACKAGE_PIN L20 [get_ports {adc_d_n[54]}]
set_property PACKAGE_PIN J20 [get_ports {adc_d_p[55]}]
set_property PACKAGE_PIN J21 [get_ports {adc_d_n[55]}]
set_property PACKAGE_PIN K18 [get_ports {adc_d_p[56]}]
set_property PACKAGE_PIN K19 [get_ports {adc_d_n[56]}]
set_property PACKAGE_PIN K13 [get_ports {adc_d_p[57]}]
set_property PACKAGE_PIN K14 [get_ports {adc_d_n[57]}]
set_property PACKAGE_PIN J22 [get_ports {adc_d_p[58]}]
set_property PACKAGE_PIN H22 [get_ports {adc_d_n[58]}]
set_property PACKAGE_PIN L16 [get_ports {adc_d_p[59]}]
set_property PACKAGE_PIN K16 [get_ports {adc_d_n[59]}]
set_property PACKAGE_PIN H20 [get_ports {adc_d_p[60]}]
set_property PACKAGE_PIN G20 [get_ports {adc_d_n[60]}]
set_property PACKAGE_PIN AA19 [get_ports {adc_d_p[61]}]
set_property PACKAGE_PIN AB20 [get_ports {adc_d_n[61]}]
set_property PACKAGE_PIN K21 [get_ports {adc_d_p[62]}]
set_property PACKAGE_PIN K22 [get_ports {adc_d_n[62]}]
set_property PACKAGE_PIN V17 [get_ports {adc_d_p[63]}]
set_property PACKAGE_PIN W17 [get_ports {adc_d_n[63]}]
false_path {adc_d_*} eth_refclk
