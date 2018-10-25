
# clock constraints
# 200 MHz system clock
create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]
#create_clock -period 5.0 [get_ports SYSCLK_N]

# 200 MHz Clock input
set_property -dict "PACKAGE_PIN R3 IOSTANDARD DIFF_SSTL15" [get_ports SYSCLK_P]
set_property -dict "PACKAGE_PIN P3 IOSTANDARD DIFF_SSTL15" [get_ports SYSCLK_N]
set_property -dict "PACKAGE_PIN U4 IOSTANDARD SSTL15" [get_ports GLBL_RST]

set_property -dict "PACKAGE_PIN M26 IOSTANDARD LVCMOS33" [get_ports {GPIO_LED[0]}]
set_property -dict "PACKAGE_PIN T24 IOSTANDARD LVCMOS33" [get_ports {GPIO_LED[1]}]
set_property -dict "PACKAGE_PIN T25 IOSTANDARD LVCMOS33" [get_ports {GPIO_LED[2]}]
set_property -dict "PACKAGE_PIN R26 IOSTANDARD LVCMOS33" [get_ports {GPIO_LED[3]}]
