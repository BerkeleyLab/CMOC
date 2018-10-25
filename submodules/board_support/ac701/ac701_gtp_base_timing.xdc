#board: xilinx.com:artix7:ac701:1.0
# clock constraints
# 125-MHz SFP_MGT_CLK0
create_clock -period 8.0 [get_ports SFP_MGT_CLK0_N]

#GTREFCLK constraint
create_clock -name gtp_wrap_i_gtrefclk0 -period 8.0 [get_pins -hier -filter {name=~ *gtp_wrap_i/gtwizard_i/*GTREFCLK0_IN}]

# DRP clock constraint
create_clock -name ref_clk_100 -period 10.0 [get_pins -hier -filter {name=~clkgen/clk_100}]

# User Clock Constraints, 62.5MHz
create_clock -name gtp_tx_clk -period 16.0 [get_pins -hier -filter {name =~gtp_wrap_i/tx_clk}]
create_clock -name gtp_rx_clk -period 16.0 [get_pins -hier -filter {name =~gtp_wrap_i/rx_clk}]

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

## 200 MHz Clock input
set_property -dict "PACKAGE_PIN R3 IOSTANDARD DIFF_SSTL15" [get_ports SYSCLK_P]
set_property -dict "PACKAGE_PIN P3 IOSTANDARD DIFF_SSTL15" [get_ports SYSCLK_N]
set_property -dict "PACKAGE_PIN U4 IOSTANDARD SSTL15" [get_ports GLBL_RST]

# Platform-independent constriants. Requires Vivado 2014.2
# See actuall Pins of current_board_part:
# get_property LOC [get_board_part_pins -of [get_board_part_interfaces LED*]]
set_property "PACKAGE_PIN [get_property LOC [get_board_part_pins LED*[0]]]" [get_ports {GPIO_LED[0]}]
set_property "PACKAGE_PIN [get_property LOC [get_board_part_pins LED*[1]]]" [get_ports {GPIO_LED[1]}]
set_property "PACKAGE_PIN [get_property LOC [get_board_part_pins LED*[2]]]" [get_ports {GPIO_LED[2]}]
set_property "PACKAGE_PIN [get_property LOC [get_board_part_pins LED*[3]]]" [get_ports {GPIO_LED[3]}]
set_property "IOSTANDARD [get_property IOSTANDARD [get_board_part_pins LED*[0]]]" [get_ports {GPIO_LED[0]}]
set_property "IOSTANDARD [get_property IOSTANDARD [get_board_part_pins LED*[1]]]" [get_ports {GPIO_LED[1]}]
set_property "IOSTANDARD [get_property IOSTANDARD [get_board_part_pins LED*[2]]]" [get_ports {GPIO_LED[2]}]
set_property "IOSTANDARD [get_property IOSTANDARD [get_board_part_pins LED*[3]]]" [get_ports {GPIO_LED[3]}]

# set placement for gt0_gtp_wrapper_i/GTPE2_CHANNEL
#INST  "gtp_wrap_i/gtwizard_i/gt0_gtwizard_i/gtpe2_i" PACKAGE_PIN = GTPE2_CHANNEL_X0Y0;
set_property PACKAGE_PIN GTPE2_CHANNEL_X0Y0 [get_cells gtp_wrap_i/gtwizard_i/gt0_gtwizard_i/gtpe2_i]
