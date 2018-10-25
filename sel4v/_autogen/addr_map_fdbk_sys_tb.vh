`define LB_HI 13
`define MIRROR_WIDTH 5
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==0)
`define ADDR_HIT_dut_mp_proc_coeff (lb_addr[`LB_HI:2]==0) // fdbk_core bitwidth: 2, base_addr: 0
`define ADDR_HIT_dut_mp_proc_lim (lb_addr[`LB_HI:2]==1) // fdbk_core bitwidth: 2, base_addr: 4
`define ADDR_HIT_dut_mp_proc_setmp (lb_addr[`LB_HI:2]==2) // fdbk_core bitwidth: 2, base_addr: 8
`define ADDR_HIT_lp1_kx (lb_addr[`LB_HI:1]==6) // lp1 bitwidth: 1, base_addr: 12
`define ADDR_HIT_lp1_ky (lb_addr[`LB_HI:1]==7) // lp1 bitwidth: 1, base_addr: 14
`define ADDR_HIT_dut_coarse_scale (lb_addr[`LB_HI:0]==16) // fdbk_core bitwidth: 0, base_addr: 16
`define ADDR_HIT_dut_mp_proc_ph_offset (lb_addr[`LB_HI:0]==17) // fdbk_core bitwidth: 0, base_addr: 17
`define ADDR_HIT_dut_mp_proc_sel_en (lb_addr[`LB_HI:0]==18) // fdbk_core bitwidth: 0, base_addr: 18
`define ADDR_HIT_dut_mp_proc_sel_thresh (lb_addr[`LB_HI:0]==19) // fdbk_core bitwidth: 0, base_addr: 19
