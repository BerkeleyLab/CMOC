`define LB_HI 14
`define ADDR_HIT_afilter_siso_dot_k_out (lb_addr[`LB_HI:10]==0) // afilter_siso bitwidth: 10, base_addr: 0
`define ADDR_HIT_afilter_siso_outer_prod_k_out (lb_addr[`LB_HI:10]==1) // afilter_siso bitwidth: 10, base_addr: 1024
`define ADDR_HIT_afilter_siso_resonator_prop_const (lb_addr[`LB_HI:10]==2) // afilter_siso bitwidth: 10, base_addr: 2048
