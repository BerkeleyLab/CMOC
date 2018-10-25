
# clock constraints
create_clock -period 8.0 [get_ports PHY_RX_CLK]
set_max_delay -from [get_clocks PHY_RX_CLK] -to [get_clocks pll_clk_0] 4.2

# PHY
set_property -dict {PACKAGE_PIN V18 IOSTANDARD HSTL_I_18} [get_ports PHY_RESET_B]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD HSTL_I_18} [get_ports PHY_TX_CLK]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD HSTL_I_18} [get_ports PHY_RX_CLK]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD HSTL_I_18} [get_ports PHY_TX_CTRL]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD HSTL_I_18} [get_ports PHY_RX_CTRL]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD HSTL_I_18} [get_ports {PHY_TXD[3]}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD HSTL_I_18} [get_ports {PHY_TXD[2]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD HSTL_I_18} [get_ports {PHY_TXD[1]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD HSTL_I_18} [get_ports {PHY_TXD[0]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD HSTL_I_18} [get_ports {PHY_RXD[3]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD HSTL_I_18} [get_ports {PHY_RXD[2]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD HSTL_I_18} [get_ports {PHY_RXD[1]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD HSTL_I_18} [get_ports {PHY_RXD[0]}]

set_property internal_vref {0.90} [get_iobanks -of_objects [get_package_pins U17]]
