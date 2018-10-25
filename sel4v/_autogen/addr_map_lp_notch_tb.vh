`define LB_HI 13
`define MIRROR_WIDTH 4
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==0)
`define ADDR_HIT_dut_lp1a_kx (lb_addr[`LB_HI:1]==0) // lp_notch bitwidth: 1, base_addr: 0
`define ADDR_HIT_dut_lp1a_ky (lb_addr[`LB_HI:1]==1) // lp_notch bitwidth: 1, base_addr: 2
`define ADDR_HIT_dut_lp1b_kx (lb_addr[`LB_HI:1]==2) // lp_notch bitwidth: 1, base_addr: 4
`define ADDR_HIT_dut_lp1b_ky (lb_addr[`LB_HI:1]==3) // lp_notch bitwidth: 1, base_addr: 6
