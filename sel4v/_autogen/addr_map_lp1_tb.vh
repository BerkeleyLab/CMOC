`define LB_HI 13
`define MIRROR_WIDTH 3
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==0)
`define ADDR_HIT_dut_kx (lb_addr[`LB_HI:1]==0) // lp1 bitwidth: 1, base_addr: 0
`define ADDR_HIT_dut_ky (lb_addr[`LB_HI:1]==1) // lp1 bitwidth: 1, base_addr: 2
