## MGT Mapping from BMB7_1_r42.pdf
set_property -dict "PACKAGE_PIN B12 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP_SDA}]
set_property -dict "PACKAGE_PIN B14 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP_SCL}]
# QSFP1 116
set_property PACKAGE_PIN F2 [get_ports {K7_QSFP1_TX3_P}]
set_property PACKAGE_PIN F1 [get_ports {K7_QSFP1_TX3_N}]
set_property PACKAGE_PIN D2 [get_ports {K7_QSFP1_TX2_P}]
set_property PACKAGE_PIN D1 [get_ports {K7_QSFP1_TX2_N}]
set_property PACKAGE_PIN B2 [get_ports {K7_QSFP1_TX0_P}]
set_property PACKAGE_PIN B1 [get_ports {K7_QSFP1_TX0_N}]
set_property PACKAGE_PIN A4 [get_ports {K7_QSFP1_TX1_P}]
set_property PACKAGE_PIN A3 [get_ports {K7_QSFP1_TX1_N}]
set_property PACKAGE_PIN G4 [get_ports {K7_QSFP1_RX3_P}]
set_property PACKAGE_PIN G3 [get_ports {K7_QSFP1_RX3_N}]
set_property PACKAGE_PIN E4 [get_ports {K7_QSFP1_RX2_P}]
set_property PACKAGE_PIN E3 [get_ports {K7_QSFP1_RX2_N}]
set_property PACKAGE_PIN C4 [get_ports {K7_QSFP1_RX0_P}]
set_property PACKAGE_PIN C3 [get_ports {K7_QSFP1_RX0_N}]
set_property PACKAGE_PIN B6 [get_ports {K7_QSFP1_RX1_P}]
set_property PACKAGE_PIN B5 [get_ports {K7_QSFP1_RX1_N}]

set_property PACKAGE_PIN D6 [get_ports {K7_MGTREFCLK0_P}]
set_property PACKAGE_PIN D5 [get_ports {K7_MGTREFCLK0_N}]
set_property PACKAGE_PIN F6 [get_ports {K7_MGTREFCLK1_P}]
set_property PACKAGE_PIN F5 [get_ports {K7_MGTREFCLK1_N}]
create_clock -period 3.200 -name K7_MGTREFCLK0_P -waveform {0.000 1.600} [get_ports K7_MGTREFCLK0_P]
#create_clock -period 8.000 -name K7_MGTREFCLK0_P -waveform {0.000 4.000} [get_ports K7_MGTREFCLK0_P]

set_property -dict "PACKAGE_PIN  C9 IOSTANDARD LVCMOS33" [get_ports {K7_GTX_REF_CTRL}]
set_property -dict "PACKAGE_PIN B11 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP1_INTL}]
set_property -dict "PACKAGE_PIN A14 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP1_MODSEL}]
set_property -dict "PACKAGE_PIN B15 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP1_PRSNTL}]
set_property -dict "PACKAGE_PIN A15 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP1_LPMODE}]
set_property -dict "PACKAGE_PIN A12 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP1_RESETL}]

# QSFP2 115
set_property PACKAGE_PIN P2 [get_ports {K7_QSFP2_TX3_P}]
set_property PACKAGE_PIN P1 [get_ports {K7_QSFP2_TX3_N}]
set_property PACKAGE_PIN M2 [get_ports {K7_QSFP2_TX2_P}]
set_property PACKAGE_PIN M1 [get_ports {K7_QSFP2_TX2_N}]
set_property PACKAGE_PIN K2 [get_ports {K7_QSFP2_TX0_P}]
set_property PACKAGE_PIN K1 [get_ports {K7_QSFP2_TX0_N}]
set_property PACKAGE_PIN H2 [get_ports {K7_QSFP2_TX1_P}]
set_property PACKAGE_PIN H1 [get_ports {K7_QSFP2_TX1_N}]
set_property PACKAGE_PIN R4 [get_ports {K7_QSFP2_RX3_P}]
set_property PACKAGE_PIN R3 [get_ports {K7_QSFP2_RX3_N}]
set_property PACKAGE_PIN N4 [get_ports {K7_QSFP2_RX2_P}]
set_property PACKAGE_PIN N3 [get_ports {K7_QSFP2_RX2_N}]
set_property PACKAGE_PIN L4 [get_ports {K7_QSFP2_RX0_P}]
set_property PACKAGE_PIN L3 [get_ports {K7_QSFP2_RX0_N}]
set_property PACKAGE_PIN J4 [get_ports {K7_QSFP2_RX1_P}]
set_property PACKAGE_PIN J3 [get_ports {K7_QSFP2_RX1_N}]

set_property PACKAGE_PIN H6 [get_ports {K7_MGTREFCLK2_P}]
set_property PACKAGE_PIN H5 [get_ports {K7_MGTREFCLK2_N}]
set_property PACKAGE_PIN K6 [get_ports {K7_MGTREFCLK3_P}]
set_property PACKAGE_PIN K5 [get_ports {K7_MGTREFCLK3_N}]
create_clock -period 8.000 -name K7_MGTREFCLK3_P -waveform {0.000 4.000} [get_ports K7_MGTREFCLK3_P]

set_property -dict "PACKAGE_PIN B9  IOSTANDARD LVCMOS33" [get_ports {K7_QSFP2_INTL}]
set_property -dict "PACKAGE_PIN A8  IOSTANDARD LVCMOS33" [get_ports {K7_QSFP2_MODSEL}]
set_property -dict "PACKAGE_PIN B10 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP2_PRSNTL}]
set_property -dict "PACKAGE_PIN A10 IOSTANDARD LVCMOS33" [get_ports {K7_QSFP2_LPMODE}]
set_property -dict "PACKAGE_PIN A9  IOSTANDARD LVCMOS33" [get_ports {K7_QSFP2_RESETL}]

