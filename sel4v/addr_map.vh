// generation code 1
`define LB_HI 14   // there's probably a better place for this

// fdbk_sys_tb
`define ADDR_HIT_dut_mp_proc_sel_thresh 0

// mp_proc_tb
`define ADDR_HIT_dut_sel_thresh 0

`define ADDR_HIT_lp1a_kx lb_addr[`LB_HI:1]==0  // address base 0, length 2
`define ADDR_HIT_lp1a_ky lb_addr[`LB_HI:1]==1  // address base 2, length 2
`define ADDR_HIT_lp1b_kx lb_addr[`LB_HI:1]==2  // address base 4, length 2
`define ADDR_HIT_lp1b_ky lb_addr[`LB_HI:1]==3  // address base 6, length 2
// automatically added 2014-08-19
`define ADDR_HIT_stupid lb_addr[`LB_HI:0]==9  // address base 9, length 1

// used when building fdbk_core_tb
`define ADDR_HIT_mp_proc_coeff lb_addr[`LB_HI:2]==3  // address base 12, length 4
`define ADDR_HIT_mp_proc_ph_offset lb_addr[`LB_HI:0]==8  // address base 8, length 1
`define ADDR_HIT_mp_proc_sel_en lb_addr[`LB_HI:0]==10  // address base 10, length 1
`define ADDR_HIT_mp_proc_sel_thresh lb_addr[`LB_HI:0]==11  // address base 11, length 1
`define ADDR_HIT_mp_proc_setmp lb_addr[`LB_HI:2]==4  // address base 16, length 4
`define ADDR_HIT_mp_proc_lim lb_addr[`LB_HI:2]==5  // address base 20, length 4

// used when building llrf_dsp_tb
`define ADDR_HIT_piezo_piezo_dc 0
`define ADDR_HIT_fdbk_core_coarse_scale 0
`define ADDR_HIT_fdbk_core_mp_proc_sel_en 0
`define ADDR_HIT_fdbk_core_mp_proc_sel_thresh 0
`define ADDR_HIT_fdbk_core_mp_proc_ph_offset 0
`define ADDR_HIT_fdbk_core_mp_proc_setmp 0
`define ADDR_HIT_fdbk_core_mp_proc_coeff 0
`define ADDR_HIT_fdbk_core_mp_proc_lim 0
`define ADDR_HIT_lp_notch_lp1a_kx 0
`define ADDR_HIT_lp_notch_lp1a_ky 0
`define ADDR_HIT_lp_notch_lp1b_kx 0
`define ADDR_HIT_lp_notch_lp1b_ky 0
`define ADDR_HIT_dut_tag 0

// used when building llrf_shell_tb
// First 16 addresses are reserved for fgen
`define ADDR_HIT_dsp_phase_step (lb_addr[`LB_HI:0]==35)  // base 35, length 1
`define ADDR_HIT_dsp_modulo (lb_addr[`LB_HI:0]==36)  // base 36, length 1
`define ADDR_HIT_dsp_wave_samp_per (lb_addr[`LB_HI:0]==37)  // base 37, length 1
`define ADDR_HIT_dsp_chan_keep (lb_addr[`LB_HI:0]==38)  // base 38, length 1
`define ADDR_HIT_dsp_wave_shift (lb_addr[`LB_HI:0]==39)  // base 39, length 1
`define ADDR_HIT_dsp_piezo_piezo_dc (lb_addr[`LB_HI:0]==40) //base 40, length 1
`define ADDR_HIT_dsp_fdbk_core_coarse_scale (lb_addr[`LB_HI:0]==41) //base 41, length 1
`define ADDR_HIT_dsp_fdbk_core_mp_proc_ph_offset (lb_addr[`LB_HI:0]==42)  // base 42, length 1
`define ADDR_HIT_dsp_fdbk_core_mp_proc_sel_en (lb_addr[`LB_HI:0]==43)  // base 43, length 1
`define ADDR_HIT_dsp_fdbk_core_mp_proc_sel_thresh (lb_addr[`LB_HI:0]==65)  // base 65, length 1
`define ADDR_HIT_dsp_fdbk_core_mp_proc_coeff (lb_addr[`LB_HI:2]==11)  // base 44, length 4
`define ADDR_HIT_dsp_fdbk_core_mp_proc_setmp (lb_addr[`LB_HI:2]==12)  // base 48, length 4
`define ADDR_HIT_dsp_fdbk_core_mp_proc_lim (lb_addr[`LB_HI:2]==13)  // base 52, length 4
`define ADDR_HIT_dsp_lp_notch_lp1a_kx (lb_addr[`LB_HI:1]==28)  // base 56, length 2
`define ADDR_HIT_dsp_lp_notch_lp1a_ky (lb_addr[`LB_HI:1]==29)  // base 58, length 2
`define ADDR_HIT_dsp_lp_notch_lp1b_kx (lb_addr[`LB_HI:1]==30)  // base 60, length 2
`define ADDR_HIT_dsp_lp_notch_lp1b_ky (lb_addr[`LB_HI:1]==31)  // base 62, length 2
`define ADDR_HIT_dsp_tag (lb_addr[`LB_HI:0]==66)  // base 66, length 1

// used when building vmod1
`define ADDR_HIT_cav4_elec_phase_step (lb_addr[`LB_HI:0]==1)
`define ADDR_HIT_cav4_elec_modulo (lb_addr[`LB_HI:0]==2)
`define ADDR_HIT_cav4_elec_beam_real (lb_addr[`LB_HI:0]==3)
`define ADDR_HIT_cav4_elec_beam_imag (lb_addr[`LB_HI:0]==4)
`define ADDR_HIT_amp_lp_bw (lb_addr[`LB_HI:0]==5)
`define ADDR_HIT_beam_phase_step (lb_addr[`LB_HI:0]==6)
`define ADDR_HIT_beam_modulo (lb_addr[`LB_HI:0]==7)
`define ADDR_HIT_cav4_elec_drive_couple_out_coupling (lb_addr[`LB_HI:1]==4)  // base 8, length 2
`define ADDR_HIT_cav4_elec_drive_couple_out_phase_offset (lb_addr[`LB_HI:1]==5)  // base 10, length 2
`define ADDR_HIT_cav4_elec_mode_0_beam_coupling (lb_addr[`LB_HI:0]==16+0)
`define ADDR_HIT_cav4_elec_mode_1_beam_coupling (lb_addr[`LB_HI:0]==24+0)
`define ADDR_HIT_cav4_elec_mode_2_beam_coupling (lb_addr[`LB_HI:0]==32+0)
`define ADDR_HIT_cav4_elec_freq_0_coarse_freq (lb_addr[`LB_HI:0]==16+1)
`define ADDR_HIT_cav4_elec_freq_1_coarse_freq (lb_addr[`LB_HI:0]==24+1)
`define ADDR_HIT_cav4_elec_freq_2_coarse_freq (lb_addr[`LB_HI:0]==32+1)
`define ADDR_HIT_cav4_elec_mode_0_drive_coupling (lb_addr[`LB_HI:0]==16+2)
`define ADDR_HIT_cav4_elec_mode_1_drive_coupling (lb_addr[`LB_HI:0]==24+2)
`define ADDR_HIT_cav4_elec_mode_2_drive_coupling (lb_addr[`LB_HI:0]==32+2)
`define ADDR_HIT_cav4_elec_mode_0_bw (lb_addr[`LB_HI:0]==16+3)
`define ADDR_HIT_cav4_elec_mode_1_bw (lb_addr[`LB_HI:0]==24+3)
`define ADDR_HIT_cav4_elec_mode_2_bw (lb_addr[`LB_HI:0]==32+3)
`define ADDR_HIT_cav4_elec_mode_0_out_couple_out_coupling (lb_addr[`LB_HI:1]==8+2)  // base 20, length 2
`define ADDR_HIT_cav4_elec_mode_1_out_couple_out_coupling (lb_addr[`LB_HI:1]==12+2)  // base 28, length 2
`define ADDR_HIT_cav4_elec_mode_2_out_couple_out_coupling (lb_addr[`LB_HI:1]==16+2)  // base 36, length 2
`define ADDR_HIT_cav4_elec_mode_0_out_couple_out_phase_offset (lb_addr[`LB_HI:1]==8+3)  // base 22, length 2
`define ADDR_HIT_cav4_elec_mode_1_out_couple_out_phase_offset (lb_addr[`LB_HI:1]==12+3)  // base 30, length 2
`define ADDR_HIT_cav4_elec_mode_2_out_couple_out_phase_offset (lb_addr[`LB_HI:1]==16+3)  // base 38, length 2
`define ADDR_HIT_a_cav_offset (lb_addr[`LB_HI:0]==49)
`define ADDR_HIT_a_for_offset (lb_addr[`LB_HI:0]==50)
`define ADDR_HIT_a_rfl_offset (lb_addr[`LB_HI:0]==51)
`define ADDR_HIT_prng_random_run (lb_addr[`LB_HI:0]==52)
`define ADDR_HIT_prng_iva (lb_addr[`LB_HI:0]==53)
`define ADDR_HIT_prng_ivb (lb_addr[`LB_HI:0]==54)
`define ADDR_HIT_compr_sat_ctl (lb_addr[`LB_HI:0]==55)
`define ADDR_HIT_resonator_prop_const (lb_addr[`LB_HI:10]==1)
`define ADDR_HIT_cav4_elec_dot_0_k_out (lb_addr[`LB_HI:10]==2)
`define ADDR_HIT_cav4_elec_outer_prod_0_k_out (lb_addr[`LB_HI:10]==3)
`define ADDR_HIT_cav4_elec_dot_1_k_out (lb_addr[`LB_HI:10]==4)
`define ADDR_HIT_cav4_elec_outer_prod_1_k_out (lb_addr[`LB_HI:10]==5)
`define ADDR_HIT_cav4_elec_dot_2_k_out (lb_addr[`LB_HI:10]==6)
`define ADDR_HIT_cav4_elec_outer_prod_2_k_out (lb_addr[`LB_HI:10]==7)
`define ADDR_HIT_piezo_couple_k_out (lb_addr[`LB_HI:10]==8)
`define ADDR_HIT_noise_couple_k_out (lb_addr[`LB_HI:10]==9)
