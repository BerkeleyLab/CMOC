# 125-MHz SFP_MGT_CLK0
create_clock -name mgtref_clk -period 8.0 [get_ports SFP_MGT_CLK0_P]

#GTREFCLK constraint
#create_clock -name gtp_wrap_i_gtrefclk0 -period 8.0 [get_pins -hier -filter {name=~ *gtp_wrap_i/gtwizard_i/*GTREFCLK0_IN}]

# DRP clock constraint
create_clock -name drp_clk -period 10.0 [get_pins -hier -filter {name=~clkgen/clk_100}]

# User Clock Constraints, 62.5MHz
#create_clock -name gtp_tx_clk -period 16.0 [get_pins -hier -filter {name =~ *gtp_wrap_i/tx_clk}]
#create_clock -name gtp_rx_clk -period 16.0 [get_pins -hier -filter {name =~ *gtp_wrap_i/rx_clk}]

# Physical location constraints
## GTP reference clock
set_property PACKAGE_PIN AB13 [get_ports SFP_MGT_CLK0_N]
set_property PACKAGE_PIN AA13 [get_ports SFP_MGT_CLK0_P]

## GTP Mapping
#XXX may be able to read from board_part.xml by get_board_part_pins, see UG835
set_property PACKAGE_PIN AC10 [get_ports SFP_TX_P]
set_property PACKAGE_PIN AD10 [get_ports SFP_TX_N]
set_property PACKAGE_PIN AC12 [get_ports SFP_RX_P]
set_property PACKAGE_PIN AD12 [get_ports SFP_RX_N]

set_property -dict "PACKAGE_PIN R18 IOSTANDARD LVCMOS33" [get_ports SFP_TX_DISABLE]
set_property -dict "PACKAGE_PIN R23 IOSTANDARD LVCMOS33" [get_ports SFP_LOS]

## SFP_MGT_CLK_SEL0/1
set_property -dict "PACKAGE_PIN B26 IOSTANDARD LVCMOS25" [get_ports SFP_MGT_CLK_SEL0]
set_property -dict "PACKAGE_PIN C24 IOSTANDARD LVCMOS25" [get_ports SFP_MGT_CLK_SEL1]

# set placement for gt0_gtp_wrapper_i/GTPE2_CHANNEL
#INST  "gtp_wrap_i/gtwizard_i/gt0_gtwizard_i/gtpe2_i" PACKAGE_PIN = GTPE2_CHANNEL_X0Y0;
#set_property PACKAGE_PIN GTPE2_CHANNEL_X0Y0 [get_cells gtp_wrap_i/gtwizard_i/gt0_gtwizard_i/gtpe2_i]
#set_property PACKAGE_PIN GTPE2_CHANNEL_X0Y0 [get_cells -hier {*gtpe2_i}]
