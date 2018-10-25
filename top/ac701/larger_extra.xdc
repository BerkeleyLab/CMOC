# report_clock_interaction -delay_type min_max -significant_digits 3 -name timing_3

# Seperate different clock domains
# http://www.xilinx.com/support/answers/44651.htm
set_clock_groups -asynchronous \
-group [get_clocks pll_clk*] \
-group [get_clocks mmcm_clk*] \
-group [get_clocks clk_1x_int] \

set_clock_groups -asynchronous \
-group [get_clocks pll_clk*] \
-group [get_clocks clk_2x_int]

# PHY_RX_CLK and pll_clk* clocks are asynchronous too
set_false_path -from [get_clocks PHY_RX_CLK] -to [get_clocks pll_clk*]
