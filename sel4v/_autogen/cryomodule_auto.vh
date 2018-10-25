// parse_vfile  ../sel4v/cryomodule.v
// module=beam1 instance=beam gvar=cavity_n gcnt=2
// parse_vfile :../sel4v/cryomodule.v ../sel4v/beam1.v
`define AUTOMATIC_beam .phase_step(beam_array_phase_step[cavity_n]),\
	.modulo(beam_array_modulo[cavity_n]),\
	.phase_init(beam_array_phase_init[cavity_n])
// module=station instance=cavity gvar=cavity_n gcnt=2
// parse_vfile :../sel4v/cryomodule.v ../sel4v/station.v
// module=outer_prod instance=piezo_couple gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/outer_prod.v
// found output address in module outer_prod, base=k_out
// module=a_compress instance=compr gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/a_compress.v
// module=lp_pair instance=amp_lp gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/lp_pair.v
// module=cav4_elec instance=cav4_elec gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/cav4_elec.v
// module=pair_couple instance=drive_couple gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v:../submodules/rtsim/cav4_elec.v ../sel4v/pair_couple.v
// found output address in module pair_couple, base=out_coupling
// found output address in module pair_couple, base=out_phase_offset
// module=dot_prod instance=dot gvar=mode_n gcnt=3
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v:../submodules/rtsim/cav4_elec.v ../sel4v/dot_prod.v
// found output address in module dot_prod, base=k_out
// module=cav4_freq instance=freq gvar=mode_n gcnt=3
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v:../submodules/rtsim/cav4_elec.v ../sel4v/cav4_freq.v
// module=cav4_mode instance=mode gvar=mode_n gcnt=3
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v:../submodules/rtsim/cav4_elec.v ../sel4v/cav4_mode.v
// module=pair_couple instance=out_couple gvar=None gcnt=None
// module=outer_prod instance=outer_prod gvar=mode_n gcnt=3
// module=prng instance=prng gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/prng.v
// module=adc_em instance=a_cav gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/station.v ../sel4v/adc_em.v
// module=adc_em instance=a_for gvar=None gcnt=None
// module=adc_em instance=a_rfl gvar=None gcnt=None
`define AUTOMATIC_cavity .piezo_couple_k_out(cavity_array_piezo_couple_k_out[cavity_n]),\
	.piezo_couple_k_out_addr(cavity_array_piezo_couple_k_out_addr[cavity_n]),\
	.compr_sat_ctl(cavity_array_compr_sat_ctl[cavity_n]),\
	.amp_lp_bw(cavity_array_amp_lp_bw[cavity_n]),\
	.cav4_elec_phase_step(cavity_array_cav4_elec_phase_step[cavity_n]),\
	.cav4_elec_modulo(cavity_array_cav4_elec_modulo[cavity_n]),\
	.cav4_elec_drive_couple_out_coupling(cavity_array_cav4_elec_drive_couple_out_coupling[cavity_n]),\
	.cav4_elec_drive_couple_out_coupling_addr(cavity_array_cav4_elec_drive_couple_out_coupling_addr[cavity_n]),\
	.cav4_elec_drive_couple_out_phase_offset(cavity_array_cav4_elec_drive_couple_out_phase_offset[cavity_n]),\
	.cav4_elec_drive_couple_out_phase_offset_addr(cavity_array_cav4_elec_drive_couple_out_phase_offset_addr[cavity_n]),\
	.cav4_elec_dot_0_k_out(cavity_array_cav4_elec_dot_0_k_out[cavity_n]),\
	.cav4_elec_dot_1_k_out(cavity_array_cav4_elec_dot_1_k_out[cavity_n]),\
	.cav4_elec_dot_2_k_out(cavity_array_cav4_elec_dot_2_k_out[cavity_n]),\
	.cav4_elec_dot_0_k_out_addr(cavity_array_cav4_elec_dot_0_k_out_addr[cavity_n]),\
	.cav4_elec_dot_1_k_out_addr(cavity_array_cav4_elec_dot_1_k_out_addr[cavity_n]),\
	.cav4_elec_dot_2_k_out_addr(cavity_array_cav4_elec_dot_2_k_out_addr[cavity_n]),\
	.cav4_elec_freq_0_coarse_freq(cavity_array_cav4_elec_freq_0_coarse_freq[cavity_n]),\
	.cav4_elec_freq_1_coarse_freq(cavity_array_cav4_elec_freq_1_coarse_freq[cavity_n]),\
	.cav4_elec_freq_2_coarse_freq(cavity_array_cav4_elec_freq_2_coarse_freq[cavity_n]),\
	.cav4_elec_mode_0_drive_coupling(cavity_array_cav4_elec_mode_0_drive_coupling[cavity_n]),\
	.cav4_elec_mode_1_drive_coupling(cavity_array_cav4_elec_mode_1_drive_coupling[cavity_n]),\
	.cav4_elec_mode_2_drive_coupling(cavity_array_cav4_elec_mode_2_drive_coupling[cavity_n]),\
	.cav4_elec_mode_0_beam_coupling(cavity_array_cav4_elec_mode_0_beam_coupling[cavity_n]),\
	.cav4_elec_mode_1_beam_coupling(cavity_array_cav4_elec_mode_1_beam_coupling[cavity_n]),\
	.cav4_elec_mode_2_beam_coupling(cavity_array_cav4_elec_mode_2_beam_coupling[cavity_n]),\
	.cav4_elec_mode_0_bw(cavity_array_cav4_elec_mode_0_bw[cavity_n]),\
	.cav4_elec_mode_1_bw(cavity_array_cav4_elec_mode_1_bw[cavity_n]),\
	.cav4_elec_mode_2_bw(cavity_array_cav4_elec_mode_2_bw[cavity_n]),\
	.cav4_elec_mode_0_out_couple_out_coupling(cavity_array_cav4_elec_mode_0_out_couple_out_coupling[cavity_n]),\
	.cav4_elec_mode_1_out_couple_out_coupling(cavity_array_cav4_elec_mode_1_out_couple_out_coupling[cavity_n]),\
	.cav4_elec_mode_2_out_couple_out_coupling(cavity_array_cav4_elec_mode_2_out_couple_out_coupling[cavity_n]),\
	.cav4_elec_mode_0_out_couple_out_coupling_addr(cavity_array_cav4_elec_mode_0_out_couple_out_coupling_addr[cavity_n]),\
	.cav4_elec_mode_1_out_couple_out_coupling_addr(cavity_array_cav4_elec_mode_1_out_couple_out_coupling_addr[cavity_n]),\
	.cav4_elec_mode_2_out_couple_out_coupling_addr(cavity_array_cav4_elec_mode_2_out_couple_out_coupling_addr[cavity_n]),\
	.cav4_elec_mode_0_out_couple_out_phase_offset(cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset[cavity_n]),\
	.cav4_elec_mode_1_out_couple_out_phase_offset(cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset[cavity_n]),\
	.cav4_elec_mode_2_out_couple_out_phase_offset(cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset[cavity_n]),\
	.cav4_elec_mode_0_out_couple_out_phase_offset_addr(cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset_addr[cavity_n]),\
	.cav4_elec_mode_1_out_couple_out_phase_offset_addr(cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset_addr[cavity_n]),\
	.cav4_elec_mode_2_out_couple_out_phase_offset_addr(cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset_addr[cavity_n]),\
	.cav4_elec_outer_prod_0_k_out(cavity_array_cav4_elec_outer_prod_0_k_out[cavity_n]),\
	.cav4_elec_outer_prod_1_k_out(cavity_array_cav4_elec_outer_prod_1_k_out[cavity_n]),\
	.cav4_elec_outer_prod_2_k_out(cavity_array_cav4_elec_outer_prod_2_k_out[cavity_n]),\
	.cav4_elec_outer_prod_0_k_out_addr(cavity_array_cav4_elec_outer_prod_0_k_out_addr[cavity_n]),\
	.cav4_elec_outer_prod_1_k_out_addr(cavity_array_cav4_elec_outer_prod_1_k_out_addr[cavity_n]),\
	.cav4_elec_outer_prod_2_k_out_addr(cavity_array_cav4_elec_outer_prod_2_k_out_addr[cavity_n]),\
	.prng_random_run(cavity_array_prng_random_run[cavity_n]),\
	.prng_iva(cavity_array_prng_iva[cavity_n]),\
	.prng_iva_we(cavity_array_prng_iva_we[cavity_n]),\
	.prng_ivb(cavity_array_prng_ivb[cavity_n]),\
	.prng_ivb_we(cavity_array_prng_ivb_we[cavity_n]),\
	.a_cav_offset(cavity_array_a_cav_offset[cavity_n]),\
	.a_for_offset(cavity_array_a_for_offset[cavity_n]),\
	.a_rfl_offset(cavity_array_a_rfl_offset[cavity_n])
// module=tgen instance=tgen gvar=cavity_n gcnt=2
// parse_vfile :../sel4v/cryomodule.v ../sel4v/tgen.v
// found output address in module tgen, base=delay_pc_XXX
`define AUTOMATIC_tgen .bank_next(tgen_array_bank_next[cavity_n]),\
	.delay_pc_XXX(tgen_array_delay_pc_XXX[cavity_n]),\
	.delay_pc_XXX_addr(tgen_array_delay_pc_XXX_addr[cavity_n])
// module=llrf_shell instance=llrf gvar=cavity_n gcnt=2
// parse_vfile :../sel4v/cryomodule.v ../sel4v/llrf_shell.v
// module=llrf_dsp instance=dsp gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v ../sel4v/llrf_dsp.v
// module=piezo_control instance=piezo gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v:../sel4v/llrf_dsp.v ../sel4v/piezo_control.v
// found output address in module piezo_control, base=sf_consts
// found output address in module piezo_control, base=trace_en
// module=fdbk_core instance=fdbk_core gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v:../sel4v/llrf_dsp.v ../sel4v/fdbk_core.v
// module=mp_proc instance=mp_proc gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v:../sel4v/llrf_dsp.v:../sel4v/fdbk_core.v ../sel4v/mp_proc.v
// found output address in module mp_proc, base=setmp
// found output address in module mp_proc, base=coeff
// found output address in module mp_proc, base=lim
// module=lp_notch instance=lp_notch gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v:../sel4v/llrf_dsp.v ../sel4v/lp_notch.v
// module=lp1 instance=lp1a gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../sel4v/llrf_shell.v:../sel4v/llrf_dsp.v:../sel4v/lp_notch.v ../sel4v/lp1.v
// found output address in module lp1, base=kx
// found output address in module lp1, base=ky
// module=lp1 instance=lp1b gvar=None gcnt=None
`define AUTOMATIC_llrf .dsp_phase_step(llrf_array_dsp_phase_step[cavity_n]),\
	.dsp_modulo(llrf_array_dsp_modulo[cavity_n]),\
	.dsp_ctlr_ph_reset(llrf_array_dsp_ctlr_ph_reset[cavity_n]),\
	.dsp_wave_samp_per(llrf_array_dsp_wave_samp_per[cavity_n]),\
	.dsp_chan_keep(llrf_array_dsp_chan_keep[cavity_n]),\
	.dsp_wave_shift(llrf_array_dsp_wave_shift[cavity_n]),\
	.dsp_use_fiber_iq(llrf_array_dsp_use_fiber_iq[cavity_n]),\
	.dsp_tag(llrf_array_dsp_tag[cavity_n]),\
	.dsp_piezo_piezo_dc(llrf_array_dsp_piezo_piezo_dc[cavity_n]),\
	.dsp_piezo_sf_consts(llrf_array_dsp_piezo_sf_consts[cavity_n]),\
	.dsp_piezo_sf_consts_addr(llrf_array_dsp_piezo_sf_consts_addr[cavity_n]),\
	.dsp_piezo_trace_en(llrf_array_dsp_piezo_trace_en[cavity_n]),\
	.dsp_piezo_trace_en_addr(llrf_array_dsp_piezo_trace_en_addr[cavity_n]),\
	.dsp_fdbk_core_coarse_scale(llrf_array_dsp_fdbk_core_coarse_scale[cavity_n]),\
	.dsp_fdbk_core_mp_proc_sel_en(llrf_array_dsp_fdbk_core_mp_proc_sel_en[cavity_n]),\
	.dsp_fdbk_core_mp_proc_ph_offset(llrf_array_dsp_fdbk_core_mp_proc_ph_offset[cavity_n]),\
	.dsp_fdbk_core_mp_proc_sel_thresh(llrf_array_dsp_fdbk_core_mp_proc_sel_thresh[cavity_n]),\
	.dsp_fdbk_core_mp_proc_setmp(llrf_array_dsp_fdbk_core_mp_proc_setmp[cavity_n]),\
	.dsp_fdbk_core_mp_proc_coeff(llrf_array_dsp_fdbk_core_mp_proc_coeff[cavity_n]),\
	.dsp_fdbk_core_mp_proc_lim(llrf_array_dsp_fdbk_core_mp_proc_lim[cavity_n]),\
	.dsp_fdbk_core_mp_proc_setmp_addr(llrf_array_dsp_fdbk_core_mp_proc_setmp_addr[cavity_n]),\
	.dsp_fdbk_core_mp_proc_coeff_addr(llrf_array_dsp_fdbk_core_mp_proc_coeff_addr[cavity_n]),\
	.dsp_fdbk_core_mp_proc_lim_addr(llrf_array_dsp_fdbk_core_mp_proc_lim_addr[cavity_n]),\
	.dsp_lp_notch_lp1a_kx(llrf_array_dsp_lp_notch_lp1a_kx[cavity_n]),\
	.dsp_lp_notch_lp1a_kx_addr(llrf_array_dsp_lp_notch_lp1a_kx_addr[cavity_n]),\
	.dsp_lp_notch_lp1a_ky(llrf_array_dsp_lp_notch_lp1a_ky[cavity_n]),\
	.dsp_lp_notch_lp1a_ky_addr(llrf_array_dsp_lp_notch_lp1a_ky_addr[cavity_n]),\
	.dsp_lp_notch_lp1b_kx(llrf_array_dsp_lp_notch_lp1b_kx[cavity_n]),\
	.dsp_lp_notch_lp1b_kx_addr(llrf_array_dsp_lp_notch_lp1b_kx_addr[cavity_n]),\
	.dsp_lp_notch_lp1b_ky(llrf_array_dsp_lp_notch_lp1b_ky[cavity_n]),\
	.dsp_lp_notch_lp1b_ky_addr(llrf_array_dsp_lp_notch_lp1b_ky_addr[cavity_n])
// module=cav4_mech instance=cav4_mech gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v ../sel4v/cav4_mech.v
// module=outer_prod instance=noise_couple gvar=None gcnt=None
// module=resonator instance=resonator gvar=None gcnt=None
// parse_vfile :../sel4v/cryomodule.v:../submodules/rtsim/cav4_mech.v ../sel4v/resonator.v
// found output address in module resonator, base=prop_const
// module=prng instance=prng gvar=None gcnt=None
`define AUTOMATIC_cav4_mech .noise_couple_k_out(cav4_mech_noise_couple_k_out),\
	.noise_couple_k_out_addr(cav4_mech_noise_couple_k_out_addr),\
	.resonator_prop_const(cav4_mech_resonator_prop_const),\
	.resonator_prop_const_addr(cav4_mech_resonator_prop_const_addr),\
	.prng_random_run(cav4_mech_prng_random_run),\
	.prng_iva(cav4_mech_prng_iva),\
	.prng_iva_we(cav4_mech_prng_iva_we),\
	.prng_ivb(cav4_mech_prng_ivb),\
	.prng_ivb_we(cav4_mech_prng_ivb_we)
// machine-generated by newad.py
`ifdef LB_DECODE_cryomodule
`include "addr_map_cryomodule.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [13:0] lb_addr
`define AUTOMATIC_decode\
wire we_beam_0_phase_step = clk2x_write&(`ADDR_HIT_beam_0_phase_step);\
reg [11:0] beam_0_phase_step=0; always @(posedge clk2x_clk) if (we_beam_0_phase_step) beam_0_phase_step <= clk2x_data;\
wire we_beam_1_phase_step = clk2x_write&(`ADDR_HIT_beam_1_phase_step);\
reg [11:0] beam_1_phase_step=0; always @(posedge clk2x_clk) if (we_beam_1_phase_step) beam_1_phase_step <= clk2x_data;\
wire we_beam_0_modulo = clk2x_write&(`ADDR_HIT_beam_0_modulo);\
reg [11:0] beam_0_modulo=0; always @(posedge clk2x_clk) if (we_beam_0_modulo) beam_0_modulo <= clk2x_data;\
wire we_beam_1_modulo = clk2x_write&(`ADDR_HIT_beam_1_modulo);\
reg [11:0] beam_1_modulo=0; always @(posedge clk2x_clk) if (we_beam_1_modulo) beam_1_modulo <= clk2x_data;\
wire we_beam_0_phase_init = clk2x_write&(`ADDR_HIT_beam_0_phase_init);\
reg [11:0] beam_0_phase_init=0; always @(posedge clk2x_clk) if (we_beam_0_phase_init) beam_0_phase_init <= clk2x_data;\
wire we_beam_1_phase_init = clk2x_write&(`ADDR_HIT_beam_1_phase_init);\
reg [11:0] beam_1_phase_init=0; always @(posedge clk2x_clk) if (we_beam_1_phase_init) beam_1_phase_init <= clk2x_data;\
wire [9:0] cavity_0_piezo_couple_k_out_addr;\
wire [17:0] cavity_0_piezo_couple_k_out;\
wire we_cavity_0_piezo_couple_k_out = clk2x_write&(`ADDR_HIT_cavity_0_piezo_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_piezo_couple_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_piezo_couple_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_piezo_couple_k_out_addr), .doutb(cavity_0_piezo_couple_k_out));\
wire [9:0] cavity_1_piezo_couple_k_out_addr;\
wire [17:0] cavity_1_piezo_couple_k_out;\
wire we_cavity_1_piezo_couple_k_out = clk2x_write&(`ADDR_HIT_cavity_1_piezo_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_piezo_couple_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_piezo_couple_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_piezo_couple_k_out_addr), .doutb(cavity_1_piezo_couple_k_out));\
wire we_cavity_0_compr_sat_ctl = clk2x_write&(`ADDR_HIT_cavity_0_compr_sat_ctl);\
reg [15:0] cavity_0_compr_sat_ctl=0; always @(posedge clk2x_clk) if (we_cavity_0_compr_sat_ctl) cavity_0_compr_sat_ctl <= clk2x_data;\
wire we_cavity_1_compr_sat_ctl = clk2x_write&(`ADDR_HIT_cavity_1_compr_sat_ctl);\
reg [15:0] cavity_1_compr_sat_ctl=0; always @(posedge clk2x_clk) if (we_cavity_1_compr_sat_ctl) cavity_1_compr_sat_ctl <= clk2x_data;\
wire we_cavity_0_amp_lp_bw = clk2x_write&(`ADDR_HIT_cavity_0_amp_lp_bw);\
reg [17:0] cavity_0_amp_lp_bw=0; always @(posedge clk2x_clk) if (we_cavity_0_amp_lp_bw) cavity_0_amp_lp_bw <= clk2x_data;\
wire we_cavity_1_amp_lp_bw = clk2x_write&(`ADDR_HIT_cavity_1_amp_lp_bw);\
reg [17:0] cavity_1_amp_lp_bw=0; always @(posedge clk2x_clk) if (we_cavity_1_amp_lp_bw) cavity_1_amp_lp_bw <= clk2x_data;\
wire we_cavity_0_cav4_elec_phase_step = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_phase_step);\
reg [31:0] cavity_0_cav4_elec_phase_step=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_phase_step) cavity_0_cav4_elec_phase_step <= clk2x_data;\
wire we_cavity_1_cav4_elec_phase_step = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_phase_step);\
reg [31:0] cavity_1_cav4_elec_phase_step=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_phase_step) cavity_1_cav4_elec_phase_step <= clk2x_data;\
wire we_cavity_0_cav4_elec_modulo = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_modulo);\
reg [11:0] cavity_0_cav4_elec_modulo=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_modulo) cavity_0_cav4_elec_modulo <= clk2x_data;\
wire we_cavity_1_cav4_elec_modulo = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_modulo);\
reg [11:0] cavity_1_cav4_elec_modulo=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_modulo) cavity_1_cav4_elec_modulo <= clk2x_data;\
wire [0:0] cavity_0_cav4_elec_drive_couple_out_coupling_addr;\
wire [17:0] cavity_0_cav4_elec_drive_couple_out_coupling;\
wire we_cavity_0_cav4_elec_drive_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_drive_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_0_cav4_elec_drive_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_drive_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_drive_couple_out_coupling_addr), .doutb(cavity_0_cav4_elec_drive_couple_out_coupling));\
wire [0:0] cavity_1_cav4_elec_drive_couple_out_coupling_addr;\
wire [17:0] cavity_1_cav4_elec_drive_couple_out_coupling;\
wire we_cavity_1_cav4_elec_drive_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_drive_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_1_cav4_elec_drive_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_drive_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_drive_couple_out_coupling_addr), .doutb(cavity_1_cav4_elec_drive_couple_out_coupling));\
wire [0:0] cavity_0_cav4_elec_drive_couple_out_phase_offset_addr;\
wire [18:0] cavity_0_cav4_elec_drive_couple_out_phase_offset;\
wire we_cavity_0_cav4_elec_drive_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_drive_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_0_cav4_elec_drive_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_0_cav4_elec_drive_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_drive_couple_out_phase_offset_addr), .doutb(cavity_0_cav4_elec_drive_couple_out_phase_offset));\
wire [0:0] cavity_1_cav4_elec_drive_couple_out_phase_offset_addr;\
wire [18:0] cavity_1_cav4_elec_drive_couple_out_phase_offset;\
wire we_cavity_1_cav4_elec_drive_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_drive_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_1_cav4_elec_drive_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_1_cav4_elec_drive_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_drive_couple_out_phase_offset_addr), .doutb(cavity_1_cav4_elec_drive_couple_out_phase_offset));\
wire [9:0] cavity_0_cav4_elec_dot_0_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_dot_0_k_out;\
wire we_cavity_0_cav4_elec_dot_0_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_dot_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_dot_0_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_dot_0_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_dot_0_k_out_addr), .doutb(cavity_0_cav4_elec_dot_0_k_out));\
wire [9:0] cavity_1_cav4_elec_dot_0_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_dot_0_k_out;\
wire we_cavity_1_cav4_elec_dot_0_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_dot_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_dot_0_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_dot_0_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_dot_0_k_out_addr), .doutb(cavity_1_cav4_elec_dot_0_k_out));\
wire [9:0] cavity_0_cav4_elec_dot_1_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_dot_1_k_out;\
wire we_cavity_0_cav4_elec_dot_1_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_dot_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_dot_1_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_dot_1_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_dot_1_k_out_addr), .doutb(cavity_0_cav4_elec_dot_1_k_out));\
wire [9:0] cavity_1_cav4_elec_dot_1_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_dot_1_k_out;\
wire we_cavity_1_cav4_elec_dot_1_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_dot_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_dot_1_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_dot_1_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_dot_1_k_out_addr), .doutb(cavity_1_cav4_elec_dot_1_k_out));\
wire [9:0] cavity_0_cav4_elec_dot_2_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_dot_2_k_out;\
wire we_cavity_0_cav4_elec_dot_2_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_dot_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_dot_2_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_dot_2_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_dot_2_k_out_addr), .doutb(cavity_0_cav4_elec_dot_2_k_out));\
wire [9:0] cavity_1_cav4_elec_dot_2_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_dot_2_k_out;\
wire we_cavity_1_cav4_elec_dot_2_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_dot_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_dot_2_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_dot_2_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_dot_2_k_out_addr), .doutb(cavity_1_cav4_elec_dot_2_k_out));\
wire we_cavity_0_cav4_elec_freq_0_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_freq_0_coarse_freq);\
reg [27:0] cavity_0_cav4_elec_freq_0_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_freq_0_coarse_freq) cavity_0_cav4_elec_freq_0_coarse_freq <= clk2x_data;\
wire we_cavity_1_cav4_elec_freq_0_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_freq_0_coarse_freq);\
reg [27:0] cavity_1_cav4_elec_freq_0_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_freq_0_coarse_freq) cavity_1_cav4_elec_freq_0_coarse_freq <= clk2x_data;\
wire we_cavity_0_cav4_elec_freq_1_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_freq_1_coarse_freq);\
reg [27:0] cavity_0_cav4_elec_freq_1_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_freq_1_coarse_freq) cavity_0_cav4_elec_freq_1_coarse_freq <= clk2x_data;\
wire we_cavity_1_cav4_elec_freq_1_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_freq_1_coarse_freq);\
reg [27:0] cavity_1_cav4_elec_freq_1_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_freq_1_coarse_freq) cavity_1_cav4_elec_freq_1_coarse_freq <= clk2x_data;\
wire we_cavity_0_cav4_elec_freq_2_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_freq_2_coarse_freq);\
reg [27:0] cavity_0_cav4_elec_freq_2_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_freq_2_coarse_freq) cavity_0_cav4_elec_freq_2_coarse_freq <= clk2x_data;\
wire we_cavity_1_cav4_elec_freq_2_coarse_freq = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_freq_2_coarse_freq);\
reg [27:0] cavity_1_cav4_elec_freq_2_coarse_freq=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_freq_2_coarse_freq) cavity_1_cav4_elec_freq_2_coarse_freq <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_0_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_0_drive_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_0_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_0_drive_coupling) cavity_0_cav4_elec_mode_0_drive_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_0_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_0_drive_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_0_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_0_drive_coupling) cavity_1_cav4_elec_mode_0_drive_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_1_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_1_drive_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_1_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_1_drive_coupling) cavity_0_cav4_elec_mode_1_drive_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_1_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_1_drive_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_1_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_1_drive_coupling) cavity_1_cav4_elec_mode_1_drive_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_2_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_2_drive_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_2_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_2_drive_coupling) cavity_0_cav4_elec_mode_2_drive_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_2_drive_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_2_drive_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_2_drive_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_2_drive_coupling) cavity_1_cav4_elec_mode_2_drive_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_0_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_0_beam_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_0_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_0_beam_coupling) cavity_0_cav4_elec_mode_0_beam_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_0_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_0_beam_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_0_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_0_beam_coupling) cavity_1_cav4_elec_mode_0_beam_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_1_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_1_beam_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_1_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_1_beam_coupling) cavity_0_cav4_elec_mode_1_beam_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_1_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_1_beam_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_1_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_1_beam_coupling) cavity_1_cav4_elec_mode_1_beam_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_2_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_2_beam_coupling);\
reg [17:0] cavity_0_cav4_elec_mode_2_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_2_beam_coupling) cavity_0_cav4_elec_mode_2_beam_coupling <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_2_beam_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_2_beam_coupling);\
reg [17:0] cavity_1_cav4_elec_mode_2_beam_coupling=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_2_beam_coupling) cavity_1_cav4_elec_mode_2_beam_coupling <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_0_bw = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_0_bw);\
reg [17:0] cavity_0_cav4_elec_mode_0_bw=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_0_bw) cavity_0_cav4_elec_mode_0_bw <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_0_bw = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_0_bw);\
reg [17:0] cavity_1_cav4_elec_mode_0_bw=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_0_bw) cavity_1_cav4_elec_mode_0_bw <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_1_bw = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_1_bw);\
reg [17:0] cavity_0_cav4_elec_mode_1_bw=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_1_bw) cavity_0_cav4_elec_mode_1_bw <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_1_bw = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_1_bw);\
reg [17:0] cavity_1_cav4_elec_mode_1_bw=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_1_bw) cavity_1_cav4_elec_mode_1_bw <= clk2x_data;\
wire we_cavity_0_cav4_elec_mode_2_bw = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_2_bw);\
reg [17:0] cavity_0_cav4_elec_mode_2_bw=0; always @(posedge clk2x_clk) if (we_cavity_0_cav4_elec_mode_2_bw) cavity_0_cav4_elec_mode_2_bw <= clk2x_data;\
wire we_cavity_1_cav4_elec_mode_2_bw = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_2_bw);\
reg [17:0] cavity_1_cav4_elec_mode_2_bw=0; always @(posedge clk2x_clk) if (we_cavity_1_cav4_elec_mode_2_bw) cavity_1_cav4_elec_mode_2_bw <= clk2x_data;\
wire [0:0] cavity_0_cav4_elec_mode_0_out_couple_out_coupling_addr;\
wire [17:0] cavity_0_cav4_elec_mode_0_out_couple_out_coupling;\
wire we_cavity_0_cav4_elec_mode_0_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_0_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_0_cav4_elec_mode_0_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_mode_0_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_0_out_couple_out_coupling_addr), .doutb(cavity_0_cav4_elec_mode_0_out_couple_out_coupling));\
wire [0:0] cavity_1_cav4_elec_mode_0_out_couple_out_coupling_addr;\
wire [17:0] cavity_1_cav4_elec_mode_0_out_couple_out_coupling;\
wire we_cavity_1_cav4_elec_mode_0_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_0_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_1_cav4_elec_mode_0_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_mode_0_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_0_out_couple_out_coupling_addr), .doutb(cavity_1_cav4_elec_mode_0_out_couple_out_coupling));\
wire [0:0] cavity_0_cav4_elec_mode_1_out_couple_out_coupling_addr;\
wire [17:0] cavity_0_cav4_elec_mode_1_out_couple_out_coupling;\
wire we_cavity_0_cav4_elec_mode_1_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_1_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_0_cav4_elec_mode_1_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_mode_1_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_1_out_couple_out_coupling_addr), .doutb(cavity_0_cav4_elec_mode_1_out_couple_out_coupling));\
wire [0:0] cavity_1_cav4_elec_mode_1_out_couple_out_coupling_addr;\
wire [17:0] cavity_1_cav4_elec_mode_1_out_couple_out_coupling;\
wire we_cavity_1_cav4_elec_mode_1_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_1_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_1_cav4_elec_mode_1_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_mode_1_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_1_out_couple_out_coupling_addr), .doutb(cavity_1_cav4_elec_mode_1_out_couple_out_coupling));\
wire [0:0] cavity_0_cav4_elec_mode_2_out_couple_out_coupling_addr;\
wire [17:0] cavity_0_cav4_elec_mode_2_out_couple_out_coupling;\
wire we_cavity_0_cav4_elec_mode_2_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_2_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_0_cav4_elec_mode_2_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_mode_2_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_2_out_couple_out_coupling_addr), .doutb(cavity_0_cav4_elec_mode_2_out_couple_out_coupling));\
wire [0:0] cavity_1_cav4_elec_mode_2_out_couple_out_coupling_addr;\
wire [17:0] cavity_1_cav4_elec_mode_2_out_couple_out_coupling;\
wire we_cavity_1_cav4_elec_mode_2_out_couple_out_coupling = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_2_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cavity_1_cav4_elec_mode_2_out_couple_out_coupling(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_mode_2_out_couple_out_coupling),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_2_out_couple_out_coupling_addr), .doutb(cavity_1_cav4_elec_mode_2_out_couple_out_coupling));\
wire [0:0] cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset;\
wire we_cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset_addr), .doutb(cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset));\
wire [0:0] cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset;\
wire we_cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset_addr), .doutb(cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset));\
wire [0:0] cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset;\
wire we_cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset_addr), .doutb(cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset));\
wire [0:0] cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset;\
wire we_cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset_addr), .doutb(cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset));\
wire [0:0] cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset;\
wire we_cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset_addr), .doutb(cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset));\
wire [0:0] cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset_addr;\
wire [18:0] cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset;\
wire we_cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset(\
	.clka(clk2x_clk), .addra(clk2x_addr[0:0]), .dina(clk2x_data[18:0]), .wena(we_cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset_addr), .doutb(cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset));\
wire [9:0] cavity_0_cav4_elec_outer_prod_0_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_outer_prod_0_k_out;\
wire we_cavity_0_cav4_elec_outer_prod_0_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_outer_prod_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_outer_prod_0_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_outer_prod_0_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_outer_prod_0_k_out_addr), .doutb(cavity_0_cav4_elec_outer_prod_0_k_out));\
wire [9:0] cavity_1_cav4_elec_outer_prod_0_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_outer_prod_0_k_out;\
wire we_cavity_1_cav4_elec_outer_prod_0_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_outer_prod_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_outer_prod_0_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_outer_prod_0_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_outer_prod_0_k_out_addr), .doutb(cavity_1_cav4_elec_outer_prod_0_k_out));\
wire [9:0] cavity_0_cav4_elec_outer_prod_1_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_outer_prod_1_k_out;\
wire we_cavity_0_cav4_elec_outer_prod_1_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_outer_prod_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_outer_prod_1_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_outer_prod_1_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_outer_prod_1_k_out_addr), .doutb(cavity_0_cav4_elec_outer_prod_1_k_out));\
wire [9:0] cavity_1_cav4_elec_outer_prod_1_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_outer_prod_1_k_out;\
wire we_cavity_1_cav4_elec_outer_prod_1_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_outer_prod_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_outer_prod_1_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_outer_prod_1_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_outer_prod_1_k_out_addr), .doutb(cavity_1_cav4_elec_outer_prod_1_k_out));\
wire [9:0] cavity_0_cav4_elec_outer_prod_2_k_out_addr;\
wire [17:0] cavity_0_cav4_elec_outer_prod_2_k_out;\
wire we_cavity_0_cav4_elec_outer_prod_2_k_out = clk2x_write&(`ADDR_HIT_cavity_0_cav4_elec_outer_prod_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_0_cav4_elec_outer_prod_2_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_0_cav4_elec_outer_prod_2_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_0_cav4_elec_outer_prod_2_k_out_addr), .doutb(cavity_0_cav4_elec_outer_prod_2_k_out));\
wire [9:0] cavity_1_cav4_elec_outer_prod_2_k_out_addr;\
wire [17:0] cavity_1_cav4_elec_outer_prod_2_k_out;\
wire we_cavity_1_cav4_elec_outer_prod_2_k_out = clk2x_write&(`ADDR_HIT_cavity_1_cav4_elec_outer_prod_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cavity_1_cav4_elec_outer_prod_2_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cavity_1_cav4_elec_outer_prod_2_k_out),\
	.clkb(clk2x_clk), .addrb(cavity_1_cav4_elec_outer_prod_2_k_out_addr), .doutb(cavity_1_cav4_elec_outer_prod_2_k_out));\
wire we_cavity_0_prng_random_run = clk2x_write&(`ADDR_HIT_cavity_0_prng_random_run);\
reg [0:0] cavity_0_prng_random_run=0; always @(posedge clk2x_clk) if (we_cavity_0_prng_random_run) cavity_0_prng_random_run <= clk2x_data;\
wire we_cavity_1_prng_random_run = clk2x_write&(`ADDR_HIT_cavity_1_prng_random_run);\
reg [0:0] cavity_1_prng_random_run=0; always @(posedge clk2x_clk) if (we_cavity_1_prng_random_run) cavity_1_prng_random_run <= clk2x_data;\
wire we_cavity_0_prng_iva = clk2x_write&(`ADDR_HIT_cavity_0_prng_iva);\
wire cavity_0_prng_iva_we = we_cavity_0_prng_iva;\
reg [31:0] cavity_0_prng_iva=0; always @(posedge clk2x_clk) if (we_cavity_0_prng_iva) cavity_0_prng_iva <= clk2x_data;\
wire we_cavity_1_prng_iva = clk2x_write&(`ADDR_HIT_cavity_1_prng_iva);\
wire cavity_1_prng_iva_we = we_cavity_1_prng_iva;\
reg [31:0] cavity_1_prng_iva=0; always @(posedge clk2x_clk) if (we_cavity_1_prng_iva) cavity_1_prng_iva <= clk2x_data;\
wire we_cavity_0_prng_ivb = clk2x_write&(`ADDR_HIT_cavity_0_prng_ivb);\
wire cavity_0_prng_ivb_we = we_cavity_0_prng_ivb;\
reg [31:0] cavity_0_prng_ivb=0; always @(posedge clk2x_clk) if (we_cavity_0_prng_ivb) cavity_0_prng_ivb <= clk2x_data;\
wire we_cavity_1_prng_ivb = clk2x_write&(`ADDR_HIT_cavity_1_prng_ivb);\
wire cavity_1_prng_ivb_we = we_cavity_1_prng_ivb;\
reg [31:0] cavity_1_prng_ivb=0; always @(posedge clk2x_clk) if (we_cavity_1_prng_ivb) cavity_1_prng_ivb <= clk2x_data;\
wire we_cavity_0_a_cav_offset = clk2x_write&(`ADDR_HIT_cavity_0_a_cav_offset);\
reg [9:0] cavity_0_a_cav_offset=0; always @(posedge clk2x_clk) if (we_cavity_0_a_cav_offset) cavity_0_a_cav_offset <= clk2x_data;\
wire we_cavity_1_a_cav_offset = clk2x_write&(`ADDR_HIT_cavity_1_a_cav_offset);\
reg [9:0] cavity_1_a_cav_offset=0; always @(posedge clk2x_clk) if (we_cavity_1_a_cav_offset) cavity_1_a_cav_offset <= clk2x_data;\
wire we_cavity_0_a_for_offset = clk2x_write&(`ADDR_HIT_cavity_0_a_for_offset);\
reg [9:0] cavity_0_a_for_offset=0; always @(posedge clk2x_clk) if (we_cavity_0_a_for_offset) cavity_0_a_for_offset <= clk2x_data;\
wire we_cavity_1_a_for_offset = clk2x_write&(`ADDR_HIT_cavity_1_a_for_offset);\
reg [9:0] cavity_1_a_for_offset=0; always @(posedge clk2x_clk) if (we_cavity_1_a_for_offset) cavity_1_a_for_offset <= clk2x_data;\
wire we_cavity_0_a_rfl_offset = clk2x_write&(`ADDR_HIT_cavity_0_a_rfl_offset);\
reg [9:0] cavity_0_a_rfl_offset=0; always @(posedge clk2x_clk) if (we_cavity_0_a_rfl_offset) cavity_0_a_rfl_offset <= clk2x_data;\
wire we_cavity_1_a_rfl_offset = clk2x_write&(`ADDR_HIT_cavity_1_a_rfl_offset);\
reg [9:0] cavity_1_a_rfl_offset=0; always @(posedge clk2x_clk) if (we_cavity_1_a_rfl_offset) cavity_1_a_rfl_offset <= clk2x_data;\
wire we_tgen_0_bank_next = clk1x_write&(`ADDR_HIT_tgen_0_bank_next);\
reg [0:0] tgen_0_bank_next=0; always @(posedge clk1x_clk) if (we_tgen_0_bank_next) tgen_0_bank_next <= clk1x_data;\
wire we_tgen_1_bank_next = clk1x_write&(`ADDR_HIT_tgen_1_bank_next);\
reg [0:0] tgen_1_bank_next=0; always @(posedge clk1x_clk) if (we_tgen_1_bank_next) tgen_1_bank_next <= clk1x_data;\
wire [9:0] tgen_0_delay_pc_XXX_addr;\
wire [31:0] tgen_0_delay_pc_XXX;\
wire we_tgen_0_delay_pc_XXX = clk1x_write&(`ADDR_HIT_tgen_0_delay_pc_XXX);\
dpram #(.aw(10),.dw(32)) dp_tgen_0_delay_pc_XXX(\
	.clka(clk1x_clk), .addra(clk1x_addr[9:0]), .dina(clk1x_data[31:0]), .wena(we_tgen_0_delay_pc_XXX),\
	.clkb(clk1x_clk), .addrb(tgen_0_delay_pc_XXX_addr), .doutb(tgen_0_delay_pc_XXX));\
wire [9:0] tgen_1_delay_pc_XXX_addr;\
wire [31:0] tgen_1_delay_pc_XXX;\
wire we_tgen_1_delay_pc_XXX = clk1x_write&(`ADDR_HIT_tgen_1_delay_pc_XXX);\
dpram #(.aw(10),.dw(32)) dp_tgen_1_delay_pc_XXX(\
	.clka(clk1x_clk), .addra(clk1x_addr[9:0]), .dina(clk1x_data[31:0]), .wena(we_tgen_1_delay_pc_XXX),\
	.clkb(clk1x_clk), .addrb(tgen_1_delay_pc_XXX_addr), .doutb(tgen_1_delay_pc_XXX));\
wire we_llrf_0_dsp_phase_step = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_phase_step);\
reg [31:0] llrf_0_dsp_phase_step=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_phase_step) llrf_0_dsp_phase_step <= lb2_data[0];\
wire we_llrf_1_dsp_phase_step = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_phase_step);\
reg [31:0] llrf_1_dsp_phase_step=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_phase_step) llrf_1_dsp_phase_step <= lb2_data[1];\
wire we_llrf_0_dsp_modulo = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_modulo);\
reg [11:0] llrf_0_dsp_modulo=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_modulo) llrf_0_dsp_modulo <= lb2_data[0];\
wire we_llrf_1_dsp_modulo = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_modulo);\
reg [11:0] llrf_1_dsp_modulo=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_modulo) llrf_1_dsp_modulo <= lb2_data[1];\
wire we_llrf_0_dsp_ctlr_ph_reset = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_ctlr_ph_reset);\
reg [0:0] llrf_0_dsp_ctlr_ph_reset=0; always @(posedge lb2_clk) llrf_0_dsp_ctlr_ph_reset <= we_llrf_0_dsp_ctlr_ph_reset ? lb2_data[0][0:0] : 1'b0;\
wire we_llrf_1_dsp_ctlr_ph_reset = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_ctlr_ph_reset);\
reg [0:0] llrf_1_dsp_ctlr_ph_reset=0; always @(posedge lb2_clk) llrf_1_dsp_ctlr_ph_reset <= we_llrf_1_dsp_ctlr_ph_reset ? lb2_data[1][0:0] : 1'b0;\
wire we_llrf_0_dsp_wave_samp_per = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_wave_samp_per);\
reg [7:0] llrf_0_dsp_wave_samp_per=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_wave_samp_per) llrf_0_dsp_wave_samp_per <= lb2_data[0];\
wire we_llrf_1_dsp_wave_samp_per = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_wave_samp_per);\
reg [7:0] llrf_1_dsp_wave_samp_per=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_wave_samp_per) llrf_1_dsp_wave_samp_per <= lb2_data[1];\
wire we_llrf_0_dsp_chan_keep = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_chan_keep);\
reg [11:0] llrf_0_dsp_chan_keep=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_chan_keep) llrf_0_dsp_chan_keep <= lb2_data[0];\
wire we_llrf_1_dsp_chan_keep = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_chan_keep);\
reg [11:0] llrf_1_dsp_chan_keep=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_chan_keep) llrf_1_dsp_chan_keep <= lb2_data[1];\
wire we_llrf_0_dsp_wave_shift = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_wave_shift);\
reg [2:0] llrf_0_dsp_wave_shift=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_wave_shift) llrf_0_dsp_wave_shift <= lb2_data[0];\
wire we_llrf_1_dsp_wave_shift = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_wave_shift);\
reg [2:0] llrf_1_dsp_wave_shift=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_wave_shift) llrf_1_dsp_wave_shift <= lb2_data[1];\
wire we_llrf_0_dsp_use_fiber_iq = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_use_fiber_iq);\
reg [1:0] llrf_0_dsp_use_fiber_iq=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_use_fiber_iq) llrf_0_dsp_use_fiber_iq <= lb2_data[0];\
wire we_llrf_1_dsp_use_fiber_iq = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_use_fiber_iq);\
reg [1:0] llrf_1_dsp_use_fiber_iq=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_use_fiber_iq) llrf_1_dsp_use_fiber_iq <= lb2_data[1];\
wire we_llrf_0_dsp_tag = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_tag);\
reg [7:0] llrf_0_dsp_tag=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_tag) llrf_0_dsp_tag <= lb2_data[0];\
wire we_llrf_1_dsp_tag = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_tag);\
reg [7:0] llrf_1_dsp_tag=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_tag) llrf_1_dsp_tag <= lb2_data[1];\
wire we_llrf_0_dsp_piezo_piezo_dc = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_piezo_piezo_dc);\
reg [15:0] llrf_0_dsp_piezo_piezo_dc=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_piezo_piezo_dc) llrf_0_dsp_piezo_piezo_dc <= lb2_data[0];\
wire we_llrf_1_dsp_piezo_piezo_dc = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_piezo_piezo_dc);\
reg [15:0] llrf_1_dsp_piezo_piezo_dc=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_piezo_piezo_dc) llrf_1_dsp_piezo_piezo_dc <= lb2_data[1];\
wire [2:0] llrf_0_dsp_piezo_sf_consts_addr;\
wire [19:0] llrf_0_dsp_piezo_sf_consts;\
wire we_llrf_0_dsp_piezo_sf_consts = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_piezo_sf_consts);\
dpram #(.aw(3),.dw(20)) dp_llrf_0_dsp_piezo_sf_consts(\
	.clka(lb2_clk), .addra(lb2_addr[0][2:0]), .dina(lb2_data[0][19:0]), .wena(we_llrf_0_dsp_piezo_sf_consts),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_piezo_sf_consts_addr), .doutb(llrf_0_dsp_piezo_sf_consts));\
wire [2:0] llrf_1_dsp_piezo_sf_consts_addr;\
wire [19:0] llrf_1_dsp_piezo_sf_consts;\
wire we_llrf_1_dsp_piezo_sf_consts = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_piezo_sf_consts);\
dpram #(.aw(3),.dw(20)) dp_llrf_1_dsp_piezo_sf_consts(\
	.clka(lb2_clk), .addra(lb2_addr[1][2:0]), .dina(lb2_data[1][19:0]), .wena(we_llrf_1_dsp_piezo_sf_consts),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_piezo_sf_consts_addr), .doutb(llrf_1_dsp_piezo_sf_consts));\
wire [6:0] llrf_0_dsp_piezo_trace_en_addr;\
wire [0:0] llrf_0_dsp_piezo_trace_en;\
wire we_llrf_0_dsp_piezo_trace_en = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_piezo_trace_en);\
dpram #(.aw(7),.dw(1)) dp_llrf_0_dsp_piezo_trace_en(\
	.clka(lb2_clk), .addra(lb2_addr[0][6:0]), .dina(lb2_data[0][0:0]), .wena(we_llrf_0_dsp_piezo_trace_en),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_piezo_trace_en_addr), .doutb(llrf_0_dsp_piezo_trace_en));\
wire [6:0] llrf_1_dsp_piezo_trace_en_addr;\
wire [0:0] llrf_1_dsp_piezo_trace_en;\
wire we_llrf_1_dsp_piezo_trace_en = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_piezo_trace_en);\
dpram #(.aw(7),.dw(1)) dp_llrf_1_dsp_piezo_trace_en(\
	.clka(lb2_clk), .addra(lb2_addr[1][6:0]), .dina(lb2_data[1][0:0]), .wena(we_llrf_1_dsp_piezo_trace_en),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_piezo_trace_en_addr), .doutb(llrf_1_dsp_piezo_trace_en));\
wire we_llrf_0_dsp_fdbk_core_coarse_scale = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_coarse_scale);\
reg [1:0] llrf_0_dsp_fdbk_core_coarse_scale=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_fdbk_core_coarse_scale) llrf_0_dsp_fdbk_core_coarse_scale <= lb2_data[0];\
wire we_llrf_1_dsp_fdbk_core_coarse_scale = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_coarse_scale);\
reg [1:0] llrf_1_dsp_fdbk_core_coarse_scale=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_fdbk_core_coarse_scale) llrf_1_dsp_fdbk_core_coarse_scale <= lb2_data[1];\
wire we_llrf_0_dsp_fdbk_core_mp_proc_sel_en = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_sel_en);\
reg [0:0] llrf_0_dsp_fdbk_core_mp_proc_sel_en=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_fdbk_core_mp_proc_sel_en) llrf_0_dsp_fdbk_core_mp_proc_sel_en <= lb2_data[0];\
wire we_llrf_1_dsp_fdbk_core_mp_proc_sel_en = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_sel_en);\
reg [0:0] llrf_1_dsp_fdbk_core_mp_proc_sel_en=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_fdbk_core_mp_proc_sel_en) llrf_1_dsp_fdbk_core_mp_proc_sel_en <= lb2_data[1];\
wire we_llrf_0_dsp_fdbk_core_mp_proc_ph_offset = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_ph_offset);\
reg [17:0] llrf_0_dsp_fdbk_core_mp_proc_ph_offset=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_fdbk_core_mp_proc_ph_offset) llrf_0_dsp_fdbk_core_mp_proc_ph_offset <= lb2_data[0];\
wire we_llrf_1_dsp_fdbk_core_mp_proc_ph_offset = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_ph_offset);\
reg [17:0] llrf_1_dsp_fdbk_core_mp_proc_ph_offset=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_fdbk_core_mp_proc_ph_offset) llrf_1_dsp_fdbk_core_mp_proc_ph_offset <= lb2_data[1];\
wire we_llrf_0_dsp_fdbk_core_mp_proc_sel_thresh = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_sel_thresh);\
reg [17:0] llrf_0_dsp_fdbk_core_mp_proc_sel_thresh=0; always @(posedge lb2_clk) if (we_llrf_0_dsp_fdbk_core_mp_proc_sel_thresh) llrf_0_dsp_fdbk_core_mp_proc_sel_thresh <= lb2_data[0];\
wire we_llrf_1_dsp_fdbk_core_mp_proc_sel_thresh = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_sel_thresh);\
reg [17:0] llrf_1_dsp_fdbk_core_mp_proc_sel_thresh=0; always @(posedge lb2_clk) if (we_llrf_1_dsp_fdbk_core_mp_proc_sel_thresh) llrf_1_dsp_fdbk_core_mp_proc_sel_thresh <= lb2_data[1];\
wire [1:0] llrf_0_dsp_fdbk_core_mp_proc_setmp_addr;\
wire [17:0] llrf_0_dsp_fdbk_core_mp_proc_setmp;\
wire we_llrf_0_dsp_fdbk_core_mp_proc_setmp = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_setmp);\
dpram #(.aw(2),.dw(18)) dp_llrf_0_dsp_fdbk_core_mp_proc_setmp(\
	.clka(lb2_clk), .addra(lb2_addr[0][1:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_fdbk_core_mp_proc_setmp),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_fdbk_core_mp_proc_setmp_addr), .doutb(llrf_0_dsp_fdbk_core_mp_proc_setmp));\
wire [1:0] llrf_1_dsp_fdbk_core_mp_proc_setmp_addr;\
wire [17:0] llrf_1_dsp_fdbk_core_mp_proc_setmp;\
wire we_llrf_1_dsp_fdbk_core_mp_proc_setmp = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_setmp);\
dpram #(.aw(2),.dw(18)) dp_llrf_1_dsp_fdbk_core_mp_proc_setmp(\
	.clka(lb2_clk), .addra(lb2_addr[1][1:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_fdbk_core_mp_proc_setmp),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_fdbk_core_mp_proc_setmp_addr), .doutb(llrf_1_dsp_fdbk_core_mp_proc_setmp));\
wire [1:0] llrf_0_dsp_fdbk_core_mp_proc_coeff_addr;\
wire [17:0] llrf_0_dsp_fdbk_core_mp_proc_coeff;\
wire we_llrf_0_dsp_fdbk_core_mp_proc_coeff = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_coeff);\
dpram #(.aw(2),.dw(18)) dp_llrf_0_dsp_fdbk_core_mp_proc_coeff(\
	.clka(lb2_clk), .addra(lb2_addr[0][1:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_fdbk_core_mp_proc_coeff),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_fdbk_core_mp_proc_coeff_addr), .doutb(llrf_0_dsp_fdbk_core_mp_proc_coeff));\
wire [1:0] llrf_1_dsp_fdbk_core_mp_proc_coeff_addr;\
wire [17:0] llrf_1_dsp_fdbk_core_mp_proc_coeff;\
wire we_llrf_1_dsp_fdbk_core_mp_proc_coeff = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_coeff);\
dpram #(.aw(2),.dw(18)) dp_llrf_1_dsp_fdbk_core_mp_proc_coeff(\
	.clka(lb2_clk), .addra(lb2_addr[1][1:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_fdbk_core_mp_proc_coeff),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_fdbk_core_mp_proc_coeff_addr), .doutb(llrf_1_dsp_fdbk_core_mp_proc_coeff));\
wire [1:0] llrf_0_dsp_fdbk_core_mp_proc_lim_addr;\
wire [17:0] llrf_0_dsp_fdbk_core_mp_proc_lim;\
wire we_llrf_0_dsp_fdbk_core_mp_proc_lim = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_fdbk_core_mp_proc_lim);\
dpram #(.aw(2),.dw(18)) dp_llrf_0_dsp_fdbk_core_mp_proc_lim(\
	.clka(lb2_clk), .addra(lb2_addr[0][1:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_fdbk_core_mp_proc_lim),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_fdbk_core_mp_proc_lim_addr), .doutb(llrf_0_dsp_fdbk_core_mp_proc_lim));\
wire [1:0] llrf_1_dsp_fdbk_core_mp_proc_lim_addr;\
wire [17:0] llrf_1_dsp_fdbk_core_mp_proc_lim;\
wire we_llrf_1_dsp_fdbk_core_mp_proc_lim = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_fdbk_core_mp_proc_lim);\
dpram #(.aw(2),.dw(18)) dp_llrf_1_dsp_fdbk_core_mp_proc_lim(\
	.clka(lb2_clk), .addra(lb2_addr[1][1:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_fdbk_core_mp_proc_lim),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_fdbk_core_mp_proc_lim_addr), .doutb(llrf_1_dsp_fdbk_core_mp_proc_lim));\
wire [0:0] llrf_0_dsp_lp_notch_lp1a_kx_addr;\
wire [17:0] llrf_0_dsp_lp_notch_lp1a_kx;\
wire we_llrf_0_dsp_lp_notch_lp1a_kx = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_lp_notch_lp1a_kx);\
dpram #(.aw(1),.dw(18)) dp_llrf_0_dsp_lp_notch_lp1a_kx(\
	.clka(lb2_clk), .addra(lb2_addr[0][0:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_lp_notch_lp1a_kx),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_lp_notch_lp1a_kx_addr), .doutb(llrf_0_dsp_lp_notch_lp1a_kx));\
wire [0:0] llrf_1_dsp_lp_notch_lp1a_kx_addr;\
wire [17:0] llrf_1_dsp_lp_notch_lp1a_kx;\
wire we_llrf_1_dsp_lp_notch_lp1a_kx = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_lp_notch_lp1a_kx);\
dpram #(.aw(1),.dw(18)) dp_llrf_1_dsp_lp_notch_lp1a_kx(\
	.clka(lb2_clk), .addra(lb2_addr[1][0:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_lp_notch_lp1a_kx),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_lp_notch_lp1a_kx_addr), .doutb(llrf_1_dsp_lp_notch_lp1a_kx));\
wire [0:0] llrf_0_dsp_lp_notch_lp1a_ky_addr;\
wire [17:0] llrf_0_dsp_lp_notch_lp1a_ky;\
wire we_llrf_0_dsp_lp_notch_lp1a_ky = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_lp_notch_lp1a_ky);\
dpram #(.aw(1),.dw(18)) dp_llrf_0_dsp_lp_notch_lp1a_ky(\
	.clka(lb2_clk), .addra(lb2_addr[0][0:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_lp_notch_lp1a_ky),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_lp_notch_lp1a_ky_addr), .doutb(llrf_0_dsp_lp_notch_lp1a_ky));\
wire [0:0] llrf_1_dsp_lp_notch_lp1a_ky_addr;\
wire [17:0] llrf_1_dsp_lp_notch_lp1a_ky;\
wire we_llrf_1_dsp_lp_notch_lp1a_ky = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_lp_notch_lp1a_ky);\
dpram #(.aw(1),.dw(18)) dp_llrf_1_dsp_lp_notch_lp1a_ky(\
	.clka(lb2_clk), .addra(lb2_addr[1][0:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_lp_notch_lp1a_ky),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_lp_notch_lp1a_ky_addr), .doutb(llrf_1_dsp_lp_notch_lp1a_ky));\
wire [0:0] llrf_0_dsp_lp_notch_lp1b_kx_addr;\
wire [17:0] llrf_0_dsp_lp_notch_lp1b_kx;\
wire we_llrf_0_dsp_lp_notch_lp1b_kx = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_lp_notch_lp1b_kx);\
dpram #(.aw(1),.dw(18)) dp_llrf_0_dsp_lp_notch_lp1b_kx(\
	.clka(lb2_clk), .addra(lb2_addr[0][0:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_lp_notch_lp1b_kx),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_lp_notch_lp1b_kx_addr), .doutb(llrf_0_dsp_lp_notch_lp1b_kx));\
wire [0:0] llrf_1_dsp_lp_notch_lp1b_kx_addr;\
wire [17:0] llrf_1_dsp_lp_notch_lp1b_kx;\
wire we_llrf_1_dsp_lp_notch_lp1b_kx = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_lp_notch_lp1b_kx);\
dpram #(.aw(1),.dw(18)) dp_llrf_1_dsp_lp_notch_lp1b_kx(\
	.clka(lb2_clk), .addra(lb2_addr[1][0:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_lp_notch_lp1b_kx),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_lp_notch_lp1b_kx_addr), .doutb(llrf_1_dsp_lp_notch_lp1b_kx));\
wire [0:0] llrf_0_dsp_lp_notch_lp1b_ky_addr;\
wire [17:0] llrf_0_dsp_lp_notch_lp1b_ky;\
wire we_llrf_0_dsp_lp_notch_lp1b_ky = lb2_write[0]&(`ADDR_HIT_llrf_0_dsp_lp_notch_lp1b_ky);\
dpram #(.aw(1),.dw(18)) dp_llrf_0_dsp_lp_notch_lp1b_ky(\
	.clka(lb2_clk), .addra(lb2_addr[0][0:0]), .dina(lb2_data[0][17:0]), .wena(we_llrf_0_dsp_lp_notch_lp1b_ky),\
	.clkb(lb2_clk), .addrb(llrf_0_dsp_lp_notch_lp1b_ky_addr), .doutb(llrf_0_dsp_lp_notch_lp1b_ky));\
wire [0:0] llrf_1_dsp_lp_notch_lp1b_ky_addr;\
wire [17:0] llrf_1_dsp_lp_notch_lp1b_ky;\
wire we_llrf_1_dsp_lp_notch_lp1b_ky = lb2_write[1]&(`ADDR_HIT_llrf_1_dsp_lp_notch_lp1b_ky);\
dpram #(.aw(1),.dw(18)) dp_llrf_1_dsp_lp_notch_lp1b_ky(\
	.clka(lb2_clk), .addra(lb2_addr[1][0:0]), .dina(lb2_data[1][17:0]), .wena(we_llrf_1_dsp_lp_notch_lp1b_ky),\
	.clkb(lb2_clk), .addrb(llrf_1_dsp_lp_notch_lp1b_ky_addr), .doutb(llrf_1_dsp_lp_notch_lp1b_ky));\
wire [9:0] cav4_mech_noise_couple_k_out_addr;\
wire [17:0] cav4_mech_noise_couple_k_out;\
wire we_cav4_mech_noise_couple_k_out = clk2x_write&(`ADDR_HIT_cav4_mech_noise_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_mech_noise_couple_k_out(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[17:0]), .wena(we_cav4_mech_noise_couple_k_out),\
	.clkb(clk2x_clk), .addrb(cav4_mech_noise_couple_k_out_addr), .doutb(cav4_mech_noise_couple_k_out));\
wire [9:0] cav4_mech_resonator_prop_const_addr;\
wire [20:0] cav4_mech_resonator_prop_const;\
wire we_cav4_mech_resonator_prop_const = clk2x_write&(`ADDR_HIT_cav4_mech_resonator_prop_const);\
dpram #(.aw(10),.dw(21)) dp_cav4_mech_resonator_prop_const(\
	.clka(clk2x_clk), .addra(clk2x_addr[9:0]), .dina(clk2x_data[20:0]), .wena(we_cav4_mech_resonator_prop_const),\
	.clkb(clk2x_clk), .addrb(cav4_mech_resonator_prop_const_addr), .doutb(cav4_mech_resonator_prop_const));\
wire we_cav4_mech_prng_random_run = clk2x_write&(`ADDR_HIT_cav4_mech_prng_random_run);\
reg [0:0] cav4_mech_prng_random_run=0; always @(posedge clk2x_clk) if (we_cav4_mech_prng_random_run) cav4_mech_prng_random_run <= clk2x_data;\
wire we_cav4_mech_prng_iva = clk2x_write&(`ADDR_HIT_cav4_mech_prng_iva);\
wire cav4_mech_prng_iva_we = we_cav4_mech_prng_iva;\
reg [31:0] cav4_mech_prng_iva=0; always @(posedge clk2x_clk) if (we_cav4_mech_prng_iva) cav4_mech_prng_iva <= clk2x_data;\
wire we_cav4_mech_prng_ivb = clk2x_write&(`ADDR_HIT_cav4_mech_prng_ivb);\
wire cav4_mech_prng_ivb_we = we_cav4_mech_prng_ivb;\
reg [31:0] cav4_mech_prng_ivb=0; always @(posedge clk2x_clk) if (we_cav4_mech_prng_ivb) cav4_mech_prng_ivb <= clk2x_data;\
wire [31:0] mirror_out_0;wire mirror_write_0 = lb_write &(`ADDR_HIT_MIRROR);\
dpram #(.aw(`MIRROR_WIDTH),.dw(32)) mirror_0(\
	.clka(lb_clk), .addra(lb_addr[`MIRROR_WIDTH-1:0]), .dina(lb_data[31:0]), .wena(mirror_write_0),\
	.clkb(lb_clk), .addrb(lb_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_0));\

`else
`define AUTOMATIC_self input  [11:0] beam_0_phase_step,\
input  [11:0] beam_1_phase_step,\
input  [11:0] beam_0_modulo,\
input  [11:0] beam_1_modulo,\
input  [11:0] beam_0_phase_init,\
input  [11:0] beam_1_phase_init,\
input signed [17:0] cavity_0_piezo_couple_k_out,\
input signed [17:0] cavity_1_piezo_couple_k_out,\
output  [9:0] cavity_0_piezo_couple_k_out_addr,\
output  [9:0] cavity_1_piezo_couple_k_out_addr,\
input  [15:0] cavity_0_compr_sat_ctl,\
input  [15:0] cavity_1_compr_sat_ctl,\
input signed [17:0] cavity_0_amp_lp_bw,\
input signed [17:0] cavity_1_amp_lp_bw,\
input  [31:0] cavity_0_cav4_elec_phase_step,\
input  [31:0] cavity_1_cav4_elec_phase_step,\
input  [11:0] cavity_0_cav4_elec_modulo,\
input  [11:0] cavity_1_cav4_elec_modulo,\
input signed [17:0] cavity_0_cav4_elec_drive_couple_out_coupling,\
input signed [17:0] cavity_1_cav4_elec_drive_couple_out_coupling,\
output  [0:0] cavity_0_cav4_elec_drive_couple_out_coupling_addr,\
output  [0:0] cavity_1_cav4_elec_drive_couple_out_coupling_addr,\
input signed [18:0] cavity_0_cav4_elec_drive_couple_out_phase_offset,\
input signed [18:0] cavity_1_cav4_elec_drive_couple_out_phase_offset,\
output  [0:0] cavity_0_cav4_elec_drive_couple_out_phase_offset_addr,\
output  [0:0] cavity_1_cav4_elec_drive_couple_out_phase_offset_addr,\
input signed [17:0] cavity_0_cav4_elec_dot_0_k_out,\
input signed [17:0] cavity_1_cav4_elec_dot_0_k_out,\
input signed [17:0] cavity_0_cav4_elec_dot_1_k_out,\
input signed [17:0] cavity_1_cav4_elec_dot_1_k_out,\
input signed [17:0] cavity_0_cav4_elec_dot_2_k_out,\
input signed [17:0] cavity_1_cav4_elec_dot_2_k_out,\
output  [9:0] cavity_0_cav4_elec_dot_0_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_dot_0_k_out_addr,\
output  [9:0] cavity_0_cav4_elec_dot_1_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_dot_1_k_out_addr,\
output  [9:0] cavity_0_cav4_elec_dot_2_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_dot_2_k_out_addr,\
input signed [27:0] cavity_0_cav4_elec_freq_0_coarse_freq,\
input signed [27:0] cavity_1_cav4_elec_freq_0_coarse_freq,\
input signed [27:0] cavity_0_cav4_elec_freq_1_coarse_freq,\
input signed [27:0] cavity_1_cav4_elec_freq_1_coarse_freq,\
input signed [27:0] cavity_0_cav4_elec_freq_2_coarse_freq,\
input signed [27:0] cavity_1_cav4_elec_freq_2_coarse_freq,\
input signed [17:0] cavity_0_cav4_elec_mode_0_drive_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_0_drive_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_1_drive_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_1_drive_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_2_drive_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_2_drive_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_0_beam_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_0_beam_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_1_beam_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_1_beam_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_2_beam_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_2_beam_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_0_bw,\
input signed [17:0] cavity_1_cav4_elec_mode_0_bw,\
input signed [17:0] cavity_0_cav4_elec_mode_1_bw,\
input signed [17:0] cavity_1_cav4_elec_mode_1_bw,\
input signed [17:0] cavity_0_cav4_elec_mode_2_bw,\
input signed [17:0] cavity_1_cav4_elec_mode_2_bw,\
input signed [17:0] cavity_0_cav4_elec_mode_0_out_couple_out_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_0_out_couple_out_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_1_out_couple_out_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_1_out_couple_out_coupling,\
input signed [17:0] cavity_0_cav4_elec_mode_2_out_couple_out_coupling,\
input signed [17:0] cavity_1_cav4_elec_mode_2_out_couple_out_coupling,\
output  [0:0] cavity_0_cav4_elec_mode_0_out_couple_out_coupling_addr,\
output  [0:0] cavity_1_cav4_elec_mode_0_out_couple_out_coupling_addr,\
output  [0:0] cavity_0_cav4_elec_mode_1_out_couple_out_coupling_addr,\
output  [0:0] cavity_1_cav4_elec_mode_1_out_couple_out_coupling_addr,\
output  [0:0] cavity_0_cav4_elec_mode_2_out_couple_out_coupling_addr,\
output  [0:0] cavity_1_cav4_elec_mode_2_out_couple_out_coupling_addr,\
input signed [18:0] cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset,\
input signed [18:0] cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset,\
input signed [18:0] cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset,\
input signed [18:0] cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset,\
input signed [18:0] cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset,\
input signed [18:0] cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset,\
output  [0:0] cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset_addr,\
output  [0:0] cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset_addr,\
output  [0:0] cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset_addr,\
output  [0:0] cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset_addr,\
output  [0:0] cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset_addr,\
output  [0:0] cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset_addr,\
input signed [17:0] cavity_0_cav4_elec_outer_prod_0_k_out,\
input signed [17:0] cavity_1_cav4_elec_outer_prod_0_k_out,\
input signed [17:0] cavity_0_cav4_elec_outer_prod_1_k_out,\
input signed [17:0] cavity_1_cav4_elec_outer_prod_1_k_out,\
input signed [17:0] cavity_0_cav4_elec_outer_prod_2_k_out,\
input signed [17:0] cavity_1_cav4_elec_outer_prod_2_k_out,\
output  [9:0] cavity_0_cav4_elec_outer_prod_0_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_outer_prod_0_k_out_addr,\
output  [9:0] cavity_0_cav4_elec_outer_prod_1_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_outer_prod_1_k_out_addr,\
output  [9:0] cavity_0_cav4_elec_outer_prod_2_k_out_addr,\
output  [9:0] cavity_1_cav4_elec_outer_prod_2_k_out_addr,\
input  [0:0] cavity_0_prng_random_run,\
input  [0:0] cavity_1_prng_random_run,\
input  [31:0] cavity_0_prng_iva,\
input  [31:0] cavity_1_prng_iva,\
input  [0:0] cavity_0_prng_iva_we,\
input  [0:0] cavity_1_prng_iva_we,\
input  [31:0] cavity_0_prng_ivb,\
input  [31:0] cavity_1_prng_ivb,\
input  [0:0] cavity_0_prng_ivb_we,\
input  [0:0] cavity_1_prng_ivb_we,\
input signed [9:0] cavity_0_a_cav_offset,\
input signed [9:0] cavity_1_a_cav_offset,\
input signed [9:0] cavity_0_a_for_offset,\
input signed [9:0] cavity_1_a_for_offset,\
input signed [9:0] cavity_0_a_rfl_offset,\
input signed [9:0] cavity_1_a_rfl_offset,\
input  [0:0] tgen_0_bank_next,\
input  [0:0] tgen_1_bank_next,\
input  [31:0] tgen_0_delay_pc_XXX,\
input  [31:0] tgen_1_delay_pc_XXX,\
output  [9:0] tgen_0_delay_pc_XXX_addr,\
output  [9:0] tgen_1_delay_pc_XXX_addr,\
input  [31:0] llrf_0_dsp_phase_step,\
input  [31:0] llrf_1_dsp_phase_step,\
input  [11:0] llrf_0_dsp_modulo,\
input  [11:0] llrf_1_dsp_modulo,\
input  [0:0] llrf_0_dsp_ctlr_ph_reset,\
input  [0:0] llrf_1_dsp_ctlr_ph_reset,\
input  [7:0] llrf_0_dsp_wave_samp_per,\
input  [7:0] llrf_1_dsp_wave_samp_per,\
input  [11:0] llrf_0_dsp_chan_keep,\
input  [11:0] llrf_1_dsp_chan_keep,\
input  [2:0] llrf_0_dsp_wave_shift,\
input  [2:0] llrf_1_dsp_wave_shift,\
input  [1:0] llrf_0_dsp_use_fiber_iq,\
input  [1:0] llrf_1_dsp_use_fiber_iq,\
input  [7:0] llrf_0_dsp_tag,\
input  [7:0] llrf_1_dsp_tag,\
input  [15:0] llrf_0_dsp_piezo_piezo_dc,\
input  [15:0] llrf_1_dsp_piezo_piezo_dc,\
input  [19:0] llrf_0_dsp_piezo_sf_consts,\
input  [19:0] llrf_1_dsp_piezo_sf_consts,\
output  [2:0] llrf_0_dsp_piezo_sf_consts_addr,\
output  [2:0] llrf_1_dsp_piezo_sf_consts_addr,\
input  [0:0] llrf_0_dsp_piezo_trace_en,\
input  [0:0] llrf_1_dsp_piezo_trace_en,\
output  [6:0] llrf_0_dsp_piezo_trace_en_addr,\
output  [6:0] llrf_1_dsp_piezo_trace_en_addr,\
input  [1:0] llrf_0_dsp_fdbk_core_coarse_scale,\
input  [1:0] llrf_1_dsp_fdbk_core_coarse_scale,\
input  [0:0] llrf_0_dsp_fdbk_core_mp_proc_sel_en,\
input  [0:0] llrf_1_dsp_fdbk_core_mp_proc_sel_en,\
input signed [17:0] llrf_0_dsp_fdbk_core_mp_proc_ph_offset,\
input signed [17:0] llrf_1_dsp_fdbk_core_mp_proc_ph_offset,\
input signed [17:0] llrf_0_dsp_fdbk_core_mp_proc_sel_thresh,\
input signed [17:0] llrf_1_dsp_fdbk_core_mp_proc_sel_thresh,\
input signed [17:0] llrf_0_dsp_fdbk_core_mp_proc_setmp,\
input signed [17:0] llrf_1_dsp_fdbk_core_mp_proc_setmp,\
input signed [17:0] llrf_0_dsp_fdbk_core_mp_proc_coeff,\
input signed [17:0] llrf_1_dsp_fdbk_core_mp_proc_coeff,\
input signed [17:0] llrf_0_dsp_fdbk_core_mp_proc_lim,\
input signed [17:0] llrf_1_dsp_fdbk_core_mp_proc_lim,\
output  [1:0] llrf_0_dsp_fdbk_core_mp_proc_setmp_addr,\
output  [1:0] llrf_1_dsp_fdbk_core_mp_proc_setmp_addr,\
output  [1:0] llrf_0_dsp_fdbk_core_mp_proc_coeff_addr,\
output  [1:0] llrf_1_dsp_fdbk_core_mp_proc_coeff_addr,\
output  [1:0] llrf_0_dsp_fdbk_core_mp_proc_lim_addr,\
output  [1:0] llrf_1_dsp_fdbk_core_mp_proc_lim_addr,\
input signed [17:0] llrf_0_dsp_lp_notch_lp1a_kx,\
input signed [17:0] llrf_1_dsp_lp_notch_lp1a_kx,\
output  [0:0] llrf_0_dsp_lp_notch_lp1a_kx_addr,\
output  [0:0] llrf_1_dsp_lp_notch_lp1a_kx_addr,\
input signed [17:0] llrf_0_dsp_lp_notch_lp1a_ky,\
input signed [17:0] llrf_1_dsp_lp_notch_lp1a_ky,\
output  [0:0] llrf_0_dsp_lp_notch_lp1a_ky_addr,\
output  [0:0] llrf_1_dsp_lp_notch_lp1a_ky_addr,\
input signed [17:0] llrf_0_dsp_lp_notch_lp1b_kx,\
input signed [17:0] llrf_1_dsp_lp_notch_lp1b_kx,\
output  [0:0] llrf_0_dsp_lp_notch_lp1b_kx_addr,\
output  [0:0] llrf_1_dsp_lp_notch_lp1b_kx_addr,\
input signed [17:0] llrf_0_dsp_lp_notch_lp1b_ky,\
input signed [17:0] llrf_1_dsp_lp_notch_lp1b_ky,\
output  [0:0] llrf_0_dsp_lp_notch_lp1b_ky_addr,\
output  [0:0] llrf_1_dsp_lp_notch_lp1b_ky_addr,\
input signed [17:0] cav4_mech_noise_couple_k_out,\
output  [9:0] cav4_mech_noise_couple_k_out_addr,\
input  [20:0] cav4_mech_resonator_prop_const,\
output  [9:0] cav4_mech_resonator_prop_const_addr,\
input  [0:0] cav4_mech_prng_random_run,\
input  [31:0] cav4_mech_prng_iva,\
input  [0:0] cav4_mech_prng_iva_we,\
input  [31:0] cav4_mech_prng_ivb,\
input  [0:0] cav4_mech_prng_ivb_we
`define AUTOMATIC_decode
`endif
`define AUTOMATIC_map wire  [11:0] beam_array_phase_step [0:1]; assign beam_array_phase_step[0] = beam_0_phase_step;\
 assign beam_array_phase_step[1] = beam_1_phase_step;\
 wire  [11:0] beam_array_modulo [0:1]; assign beam_array_modulo[0] = beam_0_modulo;\
 assign beam_array_modulo[1] = beam_1_modulo;\
 wire  [11:0] beam_array_phase_init [0:1]; assign beam_array_phase_init[0] = beam_0_phase_init;\
 assign beam_array_phase_init[1] = beam_1_phase_init;\
 wire signed [17:0] cavity_array_piezo_couple_k_out [0:1]; assign cavity_array_piezo_couple_k_out[0] = cavity_0_piezo_couple_k_out;\
 assign cavity_array_piezo_couple_k_out[1] = cavity_1_piezo_couple_k_out;\
 wire  [9:0] cavity_array_piezo_couple_k_out_addr [0:1]; assign cavity_0_piezo_couple_k_out_addr = cavity_array_piezo_couple_k_out_addr[0];\
 assign cavity_1_piezo_couple_k_out_addr = cavity_array_piezo_couple_k_out_addr[1];\
 wire  [15:0] cavity_array_compr_sat_ctl [0:1]; assign cavity_array_compr_sat_ctl[0] = cavity_0_compr_sat_ctl;\
 assign cavity_array_compr_sat_ctl[1] = cavity_1_compr_sat_ctl;\
 wire signed [17:0] cavity_array_amp_lp_bw [0:1]; assign cavity_array_amp_lp_bw[0] = cavity_0_amp_lp_bw;\
 assign cavity_array_amp_lp_bw[1] = cavity_1_amp_lp_bw;\
 wire  [31:0] cavity_array_cav4_elec_phase_step [0:1]; assign cavity_array_cav4_elec_phase_step[0] = cavity_0_cav4_elec_phase_step;\
 assign cavity_array_cav4_elec_phase_step[1] = cavity_1_cav4_elec_phase_step;\
 wire  [11:0] cavity_array_cav4_elec_modulo [0:1]; assign cavity_array_cav4_elec_modulo[0] = cavity_0_cav4_elec_modulo;\
 assign cavity_array_cav4_elec_modulo[1] = cavity_1_cav4_elec_modulo;\
 wire signed [17:0] cavity_array_cav4_elec_drive_couple_out_coupling [0:1]; assign cavity_array_cav4_elec_drive_couple_out_coupling[0] = cavity_0_cav4_elec_drive_couple_out_coupling;\
 assign cavity_array_cav4_elec_drive_couple_out_coupling[1] = cavity_1_cav4_elec_drive_couple_out_coupling;\
 wire  [0:0] cavity_array_cav4_elec_drive_couple_out_coupling_addr [0:1]; assign cavity_0_cav4_elec_drive_couple_out_coupling_addr = cavity_array_cav4_elec_drive_couple_out_coupling_addr[0];\
 assign cavity_1_cav4_elec_drive_couple_out_coupling_addr = cavity_array_cav4_elec_drive_couple_out_coupling_addr[1];\
 wire signed [18:0] cavity_array_cav4_elec_drive_couple_out_phase_offset [0:1]; assign cavity_array_cav4_elec_drive_couple_out_phase_offset[0] = cavity_0_cav4_elec_drive_couple_out_phase_offset;\
 assign cavity_array_cav4_elec_drive_couple_out_phase_offset[1] = cavity_1_cav4_elec_drive_couple_out_phase_offset;\
 wire  [0:0] cavity_array_cav4_elec_drive_couple_out_phase_offset_addr [0:1]; assign cavity_0_cav4_elec_drive_couple_out_phase_offset_addr = cavity_array_cav4_elec_drive_couple_out_phase_offset_addr[0];\
 assign cavity_1_cav4_elec_drive_couple_out_phase_offset_addr = cavity_array_cav4_elec_drive_couple_out_phase_offset_addr[1];\
 wire signed [17:0] cavity_array_cav4_elec_dot_0_k_out [0:1]; assign cavity_array_cav4_elec_dot_0_k_out[0] = cavity_0_cav4_elec_dot_0_k_out;\
 assign cavity_array_cav4_elec_dot_0_k_out[1] = cavity_1_cav4_elec_dot_0_k_out;\
 wire signed [17:0] cavity_array_cav4_elec_dot_1_k_out [0:1]; assign cavity_array_cav4_elec_dot_1_k_out[0] = cavity_0_cav4_elec_dot_1_k_out;\
 assign cavity_array_cav4_elec_dot_1_k_out[1] = cavity_1_cav4_elec_dot_1_k_out;\
 wire signed [17:0] cavity_array_cav4_elec_dot_2_k_out [0:1]; assign cavity_array_cav4_elec_dot_2_k_out[0] = cavity_0_cav4_elec_dot_2_k_out;\
 assign cavity_array_cav4_elec_dot_2_k_out[1] = cavity_1_cav4_elec_dot_2_k_out;\
 wire  [9:0] cavity_array_cav4_elec_dot_0_k_out_addr [0:1]; assign cavity_0_cav4_elec_dot_0_k_out_addr = cavity_array_cav4_elec_dot_0_k_out_addr[0];\
 assign cavity_1_cav4_elec_dot_0_k_out_addr = cavity_array_cav4_elec_dot_0_k_out_addr[1];\
 wire  [9:0] cavity_array_cav4_elec_dot_1_k_out_addr [0:1]; assign cavity_0_cav4_elec_dot_1_k_out_addr = cavity_array_cav4_elec_dot_1_k_out_addr[0];\
 assign cavity_1_cav4_elec_dot_1_k_out_addr = cavity_array_cav4_elec_dot_1_k_out_addr[1];\
 wire  [9:0] cavity_array_cav4_elec_dot_2_k_out_addr [0:1]; assign cavity_0_cav4_elec_dot_2_k_out_addr = cavity_array_cav4_elec_dot_2_k_out_addr[0];\
 assign cavity_1_cav4_elec_dot_2_k_out_addr = cavity_array_cav4_elec_dot_2_k_out_addr[1];\
 wire signed [27:0] cavity_array_cav4_elec_freq_0_coarse_freq [0:1]; assign cavity_array_cav4_elec_freq_0_coarse_freq[0] = cavity_0_cav4_elec_freq_0_coarse_freq;\
 assign cavity_array_cav4_elec_freq_0_coarse_freq[1] = cavity_1_cav4_elec_freq_0_coarse_freq;\
 wire signed [27:0] cavity_array_cav4_elec_freq_1_coarse_freq [0:1]; assign cavity_array_cav4_elec_freq_1_coarse_freq[0] = cavity_0_cav4_elec_freq_1_coarse_freq;\
 assign cavity_array_cav4_elec_freq_1_coarse_freq[1] = cavity_1_cav4_elec_freq_1_coarse_freq;\
 wire signed [27:0] cavity_array_cav4_elec_freq_2_coarse_freq [0:1]; assign cavity_array_cav4_elec_freq_2_coarse_freq[0] = cavity_0_cav4_elec_freq_2_coarse_freq;\
 assign cavity_array_cav4_elec_freq_2_coarse_freq[1] = cavity_1_cav4_elec_freq_2_coarse_freq;\
 wire signed [17:0] cavity_array_cav4_elec_mode_0_drive_coupling [0:1]; assign cavity_array_cav4_elec_mode_0_drive_coupling[0] = cavity_0_cav4_elec_mode_0_drive_coupling;\
 assign cavity_array_cav4_elec_mode_0_drive_coupling[1] = cavity_1_cav4_elec_mode_0_drive_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_1_drive_coupling [0:1]; assign cavity_array_cav4_elec_mode_1_drive_coupling[0] = cavity_0_cav4_elec_mode_1_drive_coupling;\
 assign cavity_array_cav4_elec_mode_1_drive_coupling[1] = cavity_1_cav4_elec_mode_1_drive_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_2_drive_coupling [0:1]; assign cavity_array_cav4_elec_mode_2_drive_coupling[0] = cavity_0_cav4_elec_mode_2_drive_coupling;\
 assign cavity_array_cav4_elec_mode_2_drive_coupling[1] = cavity_1_cav4_elec_mode_2_drive_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_0_beam_coupling [0:1]; assign cavity_array_cav4_elec_mode_0_beam_coupling[0] = cavity_0_cav4_elec_mode_0_beam_coupling;\
 assign cavity_array_cav4_elec_mode_0_beam_coupling[1] = cavity_1_cav4_elec_mode_0_beam_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_1_beam_coupling [0:1]; assign cavity_array_cav4_elec_mode_1_beam_coupling[0] = cavity_0_cav4_elec_mode_1_beam_coupling;\
 assign cavity_array_cav4_elec_mode_1_beam_coupling[1] = cavity_1_cav4_elec_mode_1_beam_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_2_beam_coupling [0:1]; assign cavity_array_cav4_elec_mode_2_beam_coupling[0] = cavity_0_cav4_elec_mode_2_beam_coupling;\
 assign cavity_array_cav4_elec_mode_2_beam_coupling[1] = cavity_1_cav4_elec_mode_2_beam_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_0_bw [0:1]; assign cavity_array_cav4_elec_mode_0_bw[0] = cavity_0_cav4_elec_mode_0_bw;\
 assign cavity_array_cav4_elec_mode_0_bw[1] = cavity_1_cav4_elec_mode_0_bw;\
 wire signed [17:0] cavity_array_cav4_elec_mode_1_bw [0:1]; assign cavity_array_cav4_elec_mode_1_bw[0] = cavity_0_cav4_elec_mode_1_bw;\
 assign cavity_array_cav4_elec_mode_1_bw[1] = cavity_1_cav4_elec_mode_1_bw;\
 wire signed [17:0] cavity_array_cav4_elec_mode_2_bw [0:1]; assign cavity_array_cav4_elec_mode_2_bw[0] = cavity_0_cav4_elec_mode_2_bw;\
 assign cavity_array_cav4_elec_mode_2_bw[1] = cavity_1_cav4_elec_mode_2_bw;\
 wire signed [17:0] cavity_array_cav4_elec_mode_0_out_couple_out_coupling [0:1]; assign cavity_array_cav4_elec_mode_0_out_couple_out_coupling[0] = cavity_0_cav4_elec_mode_0_out_couple_out_coupling;\
 assign cavity_array_cav4_elec_mode_0_out_couple_out_coupling[1] = cavity_1_cav4_elec_mode_0_out_couple_out_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_1_out_couple_out_coupling [0:1]; assign cavity_array_cav4_elec_mode_1_out_couple_out_coupling[0] = cavity_0_cav4_elec_mode_1_out_couple_out_coupling;\
 assign cavity_array_cav4_elec_mode_1_out_couple_out_coupling[1] = cavity_1_cav4_elec_mode_1_out_couple_out_coupling;\
 wire signed [17:0] cavity_array_cav4_elec_mode_2_out_couple_out_coupling [0:1]; assign cavity_array_cav4_elec_mode_2_out_couple_out_coupling[0] = cavity_0_cav4_elec_mode_2_out_couple_out_coupling;\
 assign cavity_array_cav4_elec_mode_2_out_couple_out_coupling[1] = cavity_1_cav4_elec_mode_2_out_couple_out_coupling;\
 wire  [0:0] cavity_array_cav4_elec_mode_0_out_couple_out_coupling_addr [0:1]; assign cavity_0_cav4_elec_mode_0_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_0_out_couple_out_coupling_addr[0];\
 assign cavity_1_cav4_elec_mode_0_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_0_out_couple_out_coupling_addr[1];\
 wire  [0:0] cavity_array_cav4_elec_mode_1_out_couple_out_coupling_addr [0:1]; assign cavity_0_cav4_elec_mode_1_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_1_out_couple_out_coupling_addr[0];\
 assign cavity_1_cav4_elec_mode_1_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_1_out_couple_out_coupling_addr[1];\
 wire  [0:0] cavity_array_cav4_elec_mode_2_out_couple_out_coupling_addr [0:1]; assign cavity_0_cav4_elec_mode_2_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_2_out_couple_out_coupling_addr[0];\
 assign cavity_1_cav4_elec_mode_2_out_couple_out_coupling_addr = cavity_array_cav4_elec_mode_2_out_couple_out_coupling_addr[1];\
 wire signed [18:0] cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset [0:1]; assign cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset[0] = cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset;\
 assign cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset[1] = cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset;\
 wire signed [18:0] cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset [0:1]; assign cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset[0] = cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset;\
 assign cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset[1] = cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset;\
 wire signed [18:0] cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset [0:1]; assign cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset[0] = cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset;\
 assign cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset[1] = cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset;\
 wire  [0:0] cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset_addr [0:1]; assign cavity_0_cav4_elec_mode_0_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset_addr[0];\
 assign cavity_1_cav4_elec_mode_0_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_0_out_couple_out_phase_offset_addr[1];\
 wire  [0:0] cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset_addr [0:1]; assign cavity_0_cav4_elec_mode_1_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset_addr[0];\
 assign cavity_1_cav4_elec_mode_1_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_1_out_couple_out_phase_offset_addr[1];\
 wire  [0:0] cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset_addr [0:1]; assign cavity_0_cav4_elec_mode_2_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset_addr[0];\
 assign cavity_1_cav4_elec_mode_2_out_couple_out_phase_offset_addr = cavity_array_cav4_elec_mode_2_out_couple_out_phase_offset_addr[1];\
 wire signed [17:0] cavity_array_cav4_elec_outer_prod_0_k_out [0:1]; assign cavity_array_cav4_elec_outer_prod_0_k_out[0] = cavity_0_cav4_elec_outer_prod_0_k_out;\
 assign cavity_array_cav4_elec_outer_prod_0_k_out[1] = cavity_1_cav4_elec_outer_prod_0_k_out;\
 wire signed [17:0] cavity_array_cav4_elec_outer_prod_1_k_out [0:1]; assign cavity_array_cav4_elec_outer_prod_1_k_out[0] = cavity_0_cav4_elec_outer_prod_1_k_out;\
 assign cavity_array_cav4_elec_outer_prod_1_k_out[1] = cavity_1_cav4_elec_outer_prod_1_k_out;\
 wire signed [17:0] cavity_array_cav4_elec_outer_prod_2_k_out [0:1]; assign cavity_array_cav4_elec_outer_prod_2_k_out[0] = cavity_0_cav4_elec_outer_prod_2_k_out;\
 assign cavity_array_cav4_elec_outer_prod_2_k_out[1] = cavity_1_cav4_elec_outer_prod_2_k_out;\
 wire  [9:0] cavity_array_cav4_elec_outer_prod_0_k_out_addr [0:1]; assign cavity_0_cav4_elec_outer_prod_0_k_out_addr = cavity_array_cav4_elec_outer_prod_0_k_out_addr[0];\
 assign cavity_1_cav4_elec_outer_prod_0_k_out_addr = cavity_array_cav4_elec_outer_prod_0_k_out_addr[1];\
 wire  [9:0] cavity_array_cav4_elec_outer_prod_1_k_out_addr [0:1]; assign cavity_0_cav4_elec_outer_prod_1_k_out_addr = cavity_array_cav4_elec_outer_prod_1_k_out_addr[0];\
 assign cavity_1_cav4_elec_outer_prod_1_k_out_addr = cavity_array_cav4_elec_outer_prod_1_k_out_addr[1];\
 wire  [9:0] cavity_array_cav4_elec_outer_prod_2_k_out_addr [0:1]; assign cavity_0_cav4_elec_outer_prod_2_k_out_addr = cavity_array_cav4_elec_outer_prod_2_k_out_addr[0];\
 assign cavity_1_cav4_elec_outer_prod_2_k_out_addr = cavity_array_cav4_elec_outer_prod_2_k_out_addr[1];\
 wire  [0:0] cavity_array_prng_random_run [0:1]; assign cavity_array_prng_random_run[0] = cavity_0_prng_random_run;\
 assign cavity_array_prng_random_run[1] = cavity_1_prng_random_run;\
 wire  [31:0] cavity_array_prng_iva [0:1]; assign cavity_array_prng_iva[0] = cavity_0_prng_iva;\
 assign cavity_array_prng_iva[1] = cavity_1_prng_iva;\
 wire  [0:0] cavity_array_prng_iva_we [0:1]; assign cavity_array_prng_iva_we[0] = cavity_0_prng_iva_we;\
 assign cavity_array_prng_iva_we[1] = cavity_1_prng_iva_we;\
 wire  [31:0] cavity_array_prng_ivb [0:1]; assign cavity_array_prng_ivb[0] = cavity_0_prng_ivb;\
 assign cavity_array_prng_ivb[1] = cavity_1_prng_ivb;\
 wire  [0:0] cavity_array_prng_ivb_we [0:1]; assign cavity_array_prng_ivb_we[0] = cavity_0_prng_ivb_we;\
 assign cavity_array_prng_ivb_we[1] = cavity_1_prng_ivb_we;\
 wire signed [9:0] cavity_array_a_cav_offset [0:1]; assign cavity_array_a_cav_offset[0] = cavity_0_a_cav_offset;\
 assign cavity_array_a_cav_offset[1] = cavity_1_a_cav_offset;\
 wire signed [9:0] cavity_array_a_for_offset [0:1]; assign cavity_array_a_for_offset[0] = cavity_0_a_for_offset;\
 assign cavity_array_a_for_offset[1] = cavity_1_a_for_offset;\
 wire signed [9:0] cavity_array_a_rfl_offset [0:1]; assign cavity_array_a_rfl_offset[0] = cavity_0_a_rfl_offset;\
 assign cavity_array_a_rfl_offset[1] = cavity_1_a_rfl_offset;\
 wire  [0:0] tgen_array_bank_next [0:1]; assign tgen_array_bank_next[0] = tgen_0_bank_next;\
 assign tgen_array_bank_next[1] = tgen_1_bank_next;\
 wire  [31:0] tgen_array_delay_pc_XXX [0:1]; assign tgen_array_delay_pc_XXX[0] = tgen_0_delay_pc_XXX;\
 assign tgen_array_delay_pc_XXX[1] = tgen_1_delay_pc_XXX;\
 wire  [9:0] tgen_array_delay_pc_XXX_addr [0:1]; assign tgen_0_delay_pc_XXX_addr = tgen_array_delay_pc_XXX_addr[0];\
 assign tgen_1_delay_pc_XXX_addr = tgen_array_delay_pc_XXX_addr[1];\
 wire  [31:0] llrf_array_dsp_phase_step [0:1]; assign llrf_array_dsp_phase_step[0] = llrf_0_dsp_phase_step;\
 assign llrf_array_dsp_phase_step[1] = llrf_1_dsp_phase_step;\
 wire  [11:0] llrf_array_dsp_modulo [0:1]; assign llrf_array_dsp_modulo[0] = llrf_0_dsp_modulo;\
 assign llrf_array_dsp_modulo[1] = llrf_1_dsp_modulo;\
 wire  [0:0] llrf_array_dsp_ctlr_ph_reset [0:1]; assign llrf_array_dsp_ctlr_ph_reset[0] = llrf_0_dsp_ctlr_ph_reset;\
 assign llrf_array_dsp_ctlr_ph_reset[1] = llrf_1_dsp_ctlr_ph_reset;\
 wire  [7:0] llrf_array_dsp_wave_samp_per [0:1]; assign llrf_array_dsp_wave_samp_per[0] = llrf_0_dsp_wave_samp_per;\
 assign llrf_array_dsp_wave_samp_per[1] = llrf_1_dsp_wave_samp_per;\
 wire  [11:0] llrf_array_dsp_chan_keep [0:1]; assign llrf_array_dsp_chan_keep[0] = llrf_0_dsp_chan_keep;\
 assign llrf_array_dsp_chan_keep[1] = llrf_1_dsp_chan_keep;\
 wire  [2:0] llrf_array_dsp_wave_shift [0:1]; assign llrf_array_dsp_wave_shift[0] = llrf_0_dsp_wave_shift;\
 assign llrf_array_dsp_wave_shift[1] = llrf_1_dsp_wave_shift;\
 wire  [1:0] llrf_array_dsp_use_fiber_iq [0:1]; assign llrf_array_dsp_use_fiber_iq[0] = llrf_0_dsp_use_fiber_iq;\
 assign llrf_array_dsp_use_fiber_iq[1] = llrf_1_dsp_use_fiber_iq;\
 wire  [7:0] llrf_array_dsp_tag [0:1]; assign llrf_array_dsp_tag[0] = llrf_0_dsp_tag;\
 assign llrf_array_dsp_tag[1] = llrf_1_dsp_tag;\
 wire  [15:0] llrf_array_dsp_piezo_piezo_dc [0:1]; assign llrf_array_dsp_piezo_piezo_dc[0] = llrf_0_dsp_piezo_piezo_dc;\
 assign llrf_array_dsp_piezo_piezo_dc[1] = llrf_1_dsp_piezo_piezo_dc;\
 wire  [19:0] llrf_array_dsp_piezo_sf_consts [0:1]; assign llrf_array_dsp_piezo_sf_consts[0] = llrf_0_dsp_piezo_sf_consts;\
 assign llrf_array_dsp_piezo_sf_consts[1] = llrf_1_dsp_piezo_sf_consts;\
 wire  [2:0] llrf_array_dsp_piezo_sf_consts_addr [0:1]; assign llrf_0_dsp_piezo_sf_consts_addr = llrf_array_dsp_piezo_sf_consts_addr[0];\
 assign llrf_1_dsp_piezo_sf_consts_addr = llrf_array_dsp_piezo_sf_consts_addr[1];\
 wire  [0:0] llrf_array_dsp_piezo_trace_en [0:1]; assign llrf_array_dsp_piezo_trace_en[0] = llrf_0_dsp_piezo_trace_en;\
 assign llrf_array_dsp_piezo_trace_en[1] = llrf_1_dsp_piezo_trace_en;\
 wire  [6:0] llrf_array_dsp_piezo_trace_en_addr [0:1]; assign llrf_0_dsp_piezo_trace_en_addr = llrf_array_dsp_piezo_trace_en_addr[0];\
 assign llrf_1_dsp_piezo_trace_en_addr = llrf_array_dsp_piezo_trace_en_addr[1];\
 wire  [1:0] llrf_array_dsp_fdbk_core_coarse_scale [0:1]; assign llrf_array_dsp_fdbk_core_coarse_scale[0] = llrf_0_dsp_fdbk_core_coarse_scale;\
 assign llrf_array_dsp_fdbk_core_coarse_scale[1] = llrf_1_dsp_fdbk_core_coarse_scale;\
 wire  [0:0] llrf_array_dsp_fdbk_core_mp_proc_sel_en [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_sel_en[0] = llrf_0_dsp_fdbk_core_mp_proc_sel_en;\
 assign llrf_array_dsp_fdbk_core_mp_proc_sel_en[1] = llrf_1_dsp_fdbk_core_mp_proc_sel_en;\
 wire signed [17:0] llrf_array_dsp_fdbk_core_mp_proc_ph_offset [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_ph_offset[0] = llrf_0_dsp_fdbk_core_mp_proc_ph_offset;\
 assign llrf_array_dsp_fdbk_core_mp_proc_ph_offset[1] = llrf_1_dsp_fdbk_core_mp_proc_ph_offset;\
 wire signed [17:0] llrf_array_dsp_fdbk_core_mp_proc_sel_thresh [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_sel_thresh[0] = llrf_0_dsp_fdbk_core_mp_proc_sel_thresh;\
 assign llrf_array_dsp_fdbk_core_mp_proc_sel_thresh[1] = llrf_1_dsp_fdbk_core_mp_proc_sel_thresh;\
 wire signed [17:0] llrf_array_dsp_fdbk_core_mp_proc_setmp [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_setmp[0] = llrf_0_dsp_fdbk_core_mp_proc_setmp;\
 assign llrf_array_dsp_fdbk_core_mp_proc_setmp[1] = llrf_1_dsp_fdbk_core_mp_proc_setmp;\
 wire signed [17:0] llrf_array_dsp_fdbk_core_mp_proc_coeff [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_coeff[0] = llrf_0_dsp_fdbk_core_mp_proc_coeff;\
 assign llrf_array_dsp_fdbk_core_mp_proc_coeff[1] = llrf_1_dsp_fdbk_core_mp_proc_coeff;\
 wire signed [17:0] llrf_array_dsp_fdbk_core_mp_proc_lim [0:1]; assign llrf_array_dsp_fdbk_core_mp_proc_lim[0] = llrf_0_dsp_fdbk_core_mp_proc_lim;\
 assign llrf_array_dsp_fdbk_core_mp_proc_lim[1] = llrf_1_dsp_fdbk_core_mp_proc_lim;\
 wire  [1:0] llrf_array_dsp_fdbk_core_mp_proc_setmp_addr [0:1]; assign llrf_0_dsp_fdbk_core_mp_proc_setmp_addr = llrf_array_dsp_fdbk_core_mp_proc_setmp_addr[0];\
 assign llrf_1_dsp_fdbk_core_mp_proc_setmp_addr = llrf_array_dsp_fdbk_core_mp_proc_setmp_addr[1];\
 wire  [1:0] llrf_array_dsp_fdbk_core_mp_proc_coeff_addr [0:1]; assign llrf_0_dsp_fdbk_core_mp_proc_coeff_addr = llrf_array_dsp_fdbk_core_mp_proc_coeff_addr[0];\
 assign llrf_1_dsp_fdbk_core_mp_proc_coeff_addr = llrf_array_dsp_fdbk_core_mp_proc_coeff_addr[1];\
 wire  [1:0] llrf_array_dsp_fdbk_core_mp_proc_lim_addr [0:1]; assign llrf_0_dsp_fdbk_core_mp_proc_lim_addr = llrf_array_dsp_fdbk_core_mp_proc_lim_addr[0];\
 assign llrf_1_dsp_fdbk_core_mp_proc_lim_addr = llrf_array_dsp_fdbk_core_mp_proc_lim_addr[1];\
 wire signed [17:0] llrf_array_dsp_lp_notch_lp1a_kx [0:1]; assign llrf_array_dsp_lp_notch_lp1a_kx[0] = llrf_0_dsp_lp_notch_lp1a_kx;\
 assign llrf_array_dsp_lp_notch_lp1a_kx[1] = llrf_1_dsp_lp_notch_lp1a_kx;\
 wire  [0:0] llrf_array_dsp_lp_notch_lp1a_kx_addr [0:1]; assign llrf_0_dsp_lp_notch_lp1a_kx_addr = llrf_array_dsp_lp_notch_lp1a_kx_addr[0];\
 assign llrf_1_dsp_lp_notch_lp1a_kx_addr = llrf_array_dsp_lp_notch_lp1a_kx_addr[1];\
 wire signed [17:0] llrf_array_dsp_lp_notch_lp1a_ky [0:1]; assign llrf_array_dsp_lp_notch_lp1a_ky[0] = llrf_0_dsp_lp_notch_lp1a_ky;\
 assign llrf_array_dsp_lp_notch_lp1a_ky[1] = llrf_1_dsp_lp_notch_lp1a_ky;\
 wire  [0:0] llrf_array_dsp_lp_notch_lp1a_ky_addr [0:1]; assign llrf_0_dsp_lp_notch_lp1a_ky_addr = llrf_array_dsp_lp_notch_lp1a_ky_addr[0];\
 assign llrf_1_dsp_lp_notch_lp1a_ky_addr = llrf_array_dsp_lp_notch_lp1a_ky_addr[1];\
 wire signed [17:0] llrf_array_dsp_lp_notch_lp1b_kx [0:1]; assign llrf_array_dsp_lp_notch_lp1b_kx[0] = llrf_0_dsp_lp_notch_lp1b_kx;\
 assign llrf_array_dsp_lp_notch_lp1b_kx[1] = llrf_1_dsp_lp_notch_lp1b_kx;\
 wire  [0:0] llrf_array_dsp_lp_notch_lp1b_kx_addr [0:1]; assign llrf_0_dsp_lp_notch_lp1b_kx_addr = llrf_array_dsp_lp_notch_lp1b_kx_addr[0];\
 assign llrf_1_dsp_lp_notch_lp1b_kx_addr = llrf_array_dsp_lp_notch_lp1b_kx_addr[1];\
 wire signed [17:0] llrf_array_dsp_lp_notch_lp1b_ky [0:1]; assign llrf_array_dsp_lp_notch_lp1b_ky[0] = llrf_0_dsp_lp_notch_lp1b_ky;\
 assign llrf_array_dsp_lp_notch_lp1b_ky[1] = llrf_1_dsp_lp_notch_lp1b_ky;\
 wire  [0:0] llrf_array_dsp_lp_notch_lp1b_ky_addr [0:1]; assign llrf_0_dsp_lp_notch_lp1b_ky_addr = llrf_array_dsp_lp_notch_lp1b_ky_addr[0];\
 assign llrf_1_dsp_lp_notch_lp1b_ky_addr = llrf_array_dsp_lp_notch_lp1b_ky_addr[1];\

