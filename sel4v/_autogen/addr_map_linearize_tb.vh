`define LB_HI 13
`define ADDR_HIT_dut_curvegen_offset_rom (lb_addr[`LB_HI:8]==0) // linearize bitwidth: 8, base_addr: 0
`define ADDR_HIT_dut_curvegen_slope_rom (lb_addr[`LB_HI:8]==1) // linearize bitwidth: 8, base_addr: 256
`define MIRROR_WIDTH 1
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==256)
`define ADDR_HIT_dut_curvegen_bank (lb_addr[`LB_HI:0]==512) // linearize bitwidth: 0, base_addr: 512
