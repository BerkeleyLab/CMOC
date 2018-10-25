`define LB_HI 14
`define ADDR_HIT_dot_k_out (lb_addr[`LB_HI:10]==0) // dot_prod bitwidth: 10, base_addr: 0
`define ADDR_HIT_outer_prod_k_out (lb_addr[`LB_HI:10]==1) // outer_prod bitwidth: 10, base_addr: 1024
`define ADDR_HIT_resonator_prop_const (lb_addr[`LB_HI:10]==2) // resonator bitwidth: 10, base_addr: 2048
