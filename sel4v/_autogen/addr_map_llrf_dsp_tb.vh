`define LB_HI 13
`define ADDR_HIT_dut_piezo_trace_en (lb_addr[`LB_HI:7]==0) // llrf_dsp bitwidth: 7, base_addr: 0
`define MIRROR_WIDTH 6
`define ADDR_HIT_MIRROR (lb_addr[`LB_HI:`MIRROR_WIDTH]==2)
`define ADDR_HIT_dut_piezo_sf_consts (lb_addr[`LB_HI:3]==16) // llrf_dsp bitwidth: 3, base_addr: 128
`define ADDR_HIT_dut_fdbk_core_mp_proc_coeff (lb_addr[`LB_HI:2]==34) // llrf_dsp bitwidth: 2, base_addr: 136
`define ADDR_HIT_dut_fdbk_core_mp_proc_lim (lb_addr[`LB_HI:2]==35) // llrf_dsp bitwidth: 2, base_addr: 140
`define ADDR_HIT_dut_fdbk_core_mp_proc_setmp (lb_addr[`LB_HI:2]==36) // llrf_dsp bitwidth: 2, base_addr: 144
`define ADDR_HIT_dut_lp_notch_lp1a_kx (lb_addr[`LB_HI:1]==74) // llrf_dsp bitwidth: 1, base_addr: 148
`define ADDR_HIT_dut_lp_notch_lp1a_ky (lb_addr[`LB_HI:1]==75) // llrf_dsp bitwidth: 1, base_addr: 150
`define ADDR_HIT_dut_lp_notch_lp1b_kx (lb_addr[`LB_HI:1]==76) // llrf_dsp bitwidth: 1, base_addr: 152
`define ADDR_HIT_dut_lp_notch_lp1b_ky (lb_addr[`LB_HI:1]==77) // llrf_dsp bitwidth: 1, base_addr: 154
`define ADDR_HIT_dut_chan_keep (lb_addr[`LB_HI:0]==156) // llrf_dsp bitwidth: 0, base_addr: 156
`define ADDR_HIT_dut_ctlr_ph_reset (lb_addr[`LB_HI:0]==157) // llrf_dsp bitwidth: 0, base_addr: 157
`define ADDR_HIT_dut_fdbk_core_coarse_scale (lb_addr[`LB_HI:0]==158) // llrf_dsp bitwidth: 0, base_addr: 158
`define ADDR_HIT_dut_fdbk_core_mp_proc_ph_offset (lb_addr[`LB_HI:0]==159) // llrf_dsp bitwidth: 0, base_addr: 159
`define ADDR_HIT_dut_fdbk_core_mp_proc_sel_en (lb_addr[`LB_HI:0]==160) // llrf_dsp bitwidth: 0, base_addr: 160
`define ADDR_HIT_dut_fdbk_core_mp_proc_sel_thresh (lb_addr[`LB_HI:0]==161) // llrf_dsp bitwidth: 0, base_addr: 161
`define ADDR_HIT_dut_modulo (lb_addr[`LB_HI:0]==162) // llrf_dsp bitwidth: 0, base_addr: 162
`define ADDR_HIT_dut_phase_step (lb_addr[`LB_HI:0]==163) // llrf_dsp bitwidth: 0, base_addr: 163
`define ADDR_HIT_dut_piezo_piezo_dc (lb_addr[`LB_HI:0]==164) // llrf_dsp bitwidth: 0, base_addr: 164
`define ADDR_HIT_dut_tag (lb_addr[`LB_HI:0]==165) // llrf_dsp bitwidth: 0, base_addr: 165
`define ADDR_HIT_dut_use_fiber_iq (lb_addr[`LB_HI:0]==166) // llrf_dsp bitwidth: 0, base_addr: 166
`define ADDR_HIT_dut_wave_samp_per (lb_addr[`LB_HI:0]==167) // llrf_dsp bitwidth: 0, base_addr: 167
`define ADDR_HIT_dut_wave_shift (lb_addr[`LB_HI:0]==168) // llrf_dsp bitwidth: 0, base_addr: 168
