create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]

set_clock_groups -asynchronous \
-group [get_clocks pll_clk*] \
-group [get_clocks mmcm_clk*] \
-group [get_clocks clk_1x_int] \

set_clock_groups -asynchronous \
-group [get_clocks pll_clk*] \
-group [get_clocks clk_2x_int]

# PHY_RX_CLK and pll_clk* clocks are asynchronous too
set_false_path -from [get_clocks phy_rxclk] -to [get_clocks pll_clk*]