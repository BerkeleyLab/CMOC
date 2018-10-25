`define LB_HI 23
`define ADDR_HIT_cavity_0_piezo_couple_k_out (clk2x_addr[`LB_HI:10]==8192) // station bitwidth: 10, base_addr: 8388608
`define ADDR_HIT_cavity_1_piezo_couple_k_out (clk2x_addr[`LB_HI:10]==8193) // station bitwidth: 10, base_addr: 8389632
`define MIRROR_WIDTH 5
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==262208)
`define ADDR_HIT_adc_mmcm (lb_addr[`LB_HI:0]==8390656) // main_test bitwidth: 0, base_addr: 8390656
`define ADDR_HIT_beam_0_modulo (clk2x_addr[`LB_HI:0]==8390657) // beam1 bitwidth: 0, base_addr: 8390657
`define ADDR_HIT_beam_0_phase_init (clk2x_addr[`LB_HI:0]==8390658) // beam1 bitwidth: 0, base_addr: 8390658
`define ADDR_HIT_beam_0_phase_step (clk2x_addr[`LB_HI:0]==8390659) // beam1 bitwidth: 0, base_addr: 8390659
`define ADDR_HIT_beam_1_modulo (clk2x_addr[`LB_HI:0]==8390660) // beam1 bitwidth: 0, base_addr: 8390660
`define ADDR_HIT_beam_1_phase_init (clk2x_addr[`LB_HI:0]==8390661) // beam1 bitwidth: 0, base_addr: 8390661
`define ADDR_HIT_beam_1_phase_step (clk2x_addr[`LB_HI:0]==8390662) // beam1 bitwidth: 0, base_addr: 8390662
`define ADDR_HIT_cavity_0_cav4_elec_freq_0_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390663) // station bitwidth: 0, base_addr: 8390663
`define ADDR_HIT_cavity_0_cav4_elec_freq_0_signed_large_port (clk2x_addr[`LB_HI:0]==8390664) // station bitwidth: 0, base_addr: 8390664
`define ADDR_HIT_cavity_0_cav4_elec_freq_0_single_cycle (clk2x_addr[`LB_HI:0]==8390665) // station bitwidth: 0, base_addr: 8390665
`define ADDR_HIT_cavity_0_cav4_elec_freq_1_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390666) // station bitwidth: 0, base_addr: 8390666
`define ADDR_HIT_cavity_0_cav4_elec_freq_1_signed_large_port (clk2x_addr[`LB_HI:0]==8390667) // station bitwidth: 0, base_addr: 8390667
`define ADDR_HIT_cavity_0_cav4_elec_freq_1_single_cycle (clk2x_addr[`LB_HI:0]==8390668) // station bitwidth: 0, base_addr: 8390668
`define ADDR_HIT_cavity_0_cav4_elec_freq_2_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390669) // station bitwidth: 0, base_addr: 8390669
`define ADDR_HIT_cavity_0_cav4_elec_freq_2_signed_large_port (clk2x_addr[`LB_HI:0]==8390670) // station bitwidth: 0, base_addr: 8390670
`define ADDR_HIT_cavity_0_cav4_elec_freq_2_single_cycle (clk2x_addr[`LB_HI:0]==8390671) // station bitwidth: 0, base_addr: 8390671
`define ADDR_HIT_cavity_0_cav4_elec_modulo (clk2x_addr[`LB_HI:0]==8390672) // station bitwidth: 0, base_addr: 8390672
`define ADDR_HIT_cavity_0_cav4_elec_phase_step (clk2x_addr[`LB_HI:0]==8390673) // station bitwidth: 0, base_addr: 8390673
`define ADDR_HIT_cavity_0_cav4_elec_trace_reset_we (clk2x_addr[`LB_HI:0]==8390674) // station bitwidth: 0, base_addr: 8390674
`define ADDR_HIT_cavity_1_cav4_elec_freq_0_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390675) // station bitwidth: 0, base_addr: 8390675
`define ADDR_HIT_cavity_1_cav4_elec_freq_0_signed_large_port (clk2x_addr[`LB_HI:0]==8390676) // station bitwidth: 0, base_addr: 8390676
`define ADDR_HIT_cavity_1_cav4_elec_freq_0_single_cycle (clk2x_addr[`LB_HI:0]==8390677) // station bitwidth: 0, base_addr: 8390677
`define ADDR_HIT_cavity_1_cav4_elec_freq_1_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390678) // station bitwidth: 0, base_addr: 8390678
`define ADDR_HIT_cavity_1_cav4_elec_freq_1_signed_large_port (clk2x_addr[`LB_HI:0]==8390679) // station bitwidth: 0, base_addr: 8390679
`define ADDR_HIT_cavity_1_cav4_elec_freq_1_single_cycle (clk2x_addr[`LB_HI:0]==8390680) // station bitwidth: 0, base_addr: 8390680
`define ADDR_HIT_cavity_1_cav4_elec_freq_2_add_write_enable_test (clk2x_addr[`LB_HI:0]==8390681) // station bitwidth: 0, base_addr: 8390681
`define ADDR_HIT_cavity_1_cav4_elec_freq_2_signed_large_port (clk2x_addr[`LB_HI:0]==8390682) // station bitwidth: 0, base_addr: 8390682
`define ADDR_HIT_cavity_1_cav4_elec_freq_2_single_cycle (clk2x_addr[`LB_HI:0]==8390683) // station bitwidth: 0, base_addr: 8390683
`define ADDR_HIT_cavity_1_cav4_elec_modulo (clk2x_addr[`LB_HI:0]==8390684) // station bitwidth: 0, base_addr: 8390684
`define ADDR_HIT_cavity_1_cav4_elec_phase_step (clk2x_addr[`LB_HI:0]==8390685) // station bitwidth: 0, base_addr: 8390685
`define ADDR_HIT_cavity_1_cav4_elec_trace_reset_we (clk2x_addr[`LB_HI:0]==8390686) // station bitwidth: 0, base_addr: 8390686
