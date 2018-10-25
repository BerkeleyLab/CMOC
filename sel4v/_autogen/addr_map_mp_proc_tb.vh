`define LB_HI 13
`define MIRROR_WIDTH 4
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==0)
`define ADDR_HIT_dut_coeff (lb_addr[`LB_HI:2]==0) // mp_proc bitwidth: 2, base_addr: 0
`define ADDR_HIT_dut_lim (lb_addr[`LB_HI:2]==1) // mp_proc bitwidth: 2, base_addr: 4
`define ADDR_HIT_dut_setmp (lb_addr[`LB_HI:2]==2) // mp_proc bitwidth: 2, base_addr: 8
`define ADDR_HIT_dut_ph_offset (lb_addr[`LB_HI:0]==12) // mp_proc bitwidth: 0, base_addr: 12
`define ADDR_HIT_dut_sel_en (lb_addr[`LB_HI:0]==13) // mp_proc bitwidth: 0, base_addr: 13
`define ADDR_HIT_dut_sel_thresh (lb_addr[`LB_HI:0]==14) // mp_proc bitwidth: 0, base_addr: 14
