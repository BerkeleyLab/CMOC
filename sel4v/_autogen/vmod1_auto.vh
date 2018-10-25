// parse_vfile  ../submodules/rtsim/vmod1.v
// module=beam1 instance=beam gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/beam1.v
`define AUTOMATIC_beam .phase_step(beam_phase_step),\
	.modulo(beam_modulo),\
	.phase_init(beam_phase_init)
// module=a_compress instance=compr gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/a_compress.v
`define AUTOMATIC_compr .sat_ctl(compr_sat_ctl)
// module=lp_pair instance=amp_lp gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/lp_pair.v
`define AUTOMATIC_amp_lp .bw(amp_lp_bw)
// module=cav4_elec instance=cav4_elec gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/cav4_elec.v
// module=pair_couple instance=drive_couple gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v:../submodules/rtsim/cav4_elec.v ../submodules/rtsim/pair_couple.v
// found output address in module pair_couple, base=out_coupling
// found output address in module pair_couple, base=out_phase_offset
// module=dot_prod instance=dot gvar=mode_n gcnt=3
// parse_vfile :../submodules/rtsim/vmod1.v:../submodules/rtsim/cav4_elec.v ../submodules/rtsim/dot_prod.v
// found output address in module dot_prod, base=k_out
// module=cav4_freq instance=freq gvar=mode_n gcnt=3
// parse_vfile :../submodules/rtsim/vmod1.v:../submodules/rtsim/cav4_elec.v ../submodules/rtsim/cav4_freq.v
// module=cav4_mode instance=mode gvar=mode_n gcnt=3
// parse_vfile :../submodules/rtsim/vmod1.v:../submodules/rtsim/cav4_elec.v ../submodules/rtsim/cav4_mode.v
// module=pair_couple instance=out_couple gvar=None gcnt=None
// module=outer_prod instance=outer_prod gvar=mode_n gcnt=3
// parse_vfile :../submodules/rtsim/vmod1.v:../submodules/rtsim/cav4_elec.v ../submodules/rtsim/outer_prod.v
// found output address in module outer_prod, base=k_out
`define AUTOMATIC_cav4_elec .phase_step(cav4_elec_phase_step),\
	.modulo(cav4_elec_modulo),\
	.drive_couple_out_coupling(cav4_elec_drive_couple_out_coupling),\
	.drive_couple_out_coupling_addr(cav4_elec_drive_couple_out_coupling_addr),\
	.drive_couple_out_phase_offset(cav4_elec_drive_couple_out_phase_offset),\
	.drive_couple_out_phase_offset_addr(cav4_elec_drive_couple_out_phase_offset_addr),\
	.dot_0_k_out(cav4_elec_dot_0_k_out),\
	.dot_1_k_out(cav4_elec_dot_1_k_out),\
	.dot_2_k_out(cav4_elec_dot_2_k_out),\
	.dot_0_k_out_addr(cav4_elec_dot_0_k_out_addr),\
	.dot_1_k_out_addr(cav4_elec_dot_1_k_out_addr),\
	.dot_2_k_out_addr(cav4_elec_dot_2_k_out_addr),\
	.freq_0_coarse_freq(cav4_elec_freq_0_coarse_freq),\
	.freq_1_coarse_freq(cav4_elec_freq_1_coarse_freq),\
	.freq_2_coarse_freq(cav4_elec_freq_2_coarse_freq),\
	.mode_0_drive_coupling(cav4_elec_mode_0_drive_coupling),\
	.mode_1_drive_coupling(cav4_elec_mode_1_drive_coupling),\
	.mode_2_drive_coupling(cav4_elec_mode_2_drive_coupling),\
	.mode_0_beam_coupling(cav4_elec_mode_0_beam_coupling),\
	.mode_1_beam_coupling(cav4_elec_mode_1_beam_coupling),\
	.mode_2_beam_coupling(cav4_elec_mode_2_beam_coupling),\
	.mode_0_bw(cav4_elec_mode_0_bw),\
	.mode_1_bw(cav4_elec_mode_1_bw),\
	.mode_2_bw(cav4_elec_mode_2_bw),\
	.mode_0_out_couple_out_coupling(cav4_elec_mode_0_out_couple_out_coupling),\
	.mode_1_out_couple_out_coupling(cav4_elec_mode_1_out_couple_out_coupling),\
	.mode_2_out_couple_out_coupling(cav4_elec_mode_2_out_couple_out_coupling),\
	.mode_0_out_couple_out_coupling_addr(cav4_elec_mode_0_out_couple_out_coupling_addr),\
	.mode_1_out_couple_out_coupling_addr(cav4_elec_mode_1_out_couple_out_coupling_addr),\
	.mode_2_out_couple_out_coupling_addr(cav4_elec_mode_2_out_couple_out_coupling_addr),\
	.mode_0_out_couple_out_phase_offset(cav4_elec_mode_0_out_couple_out_phase_offset),\
	.mode_1_out_couple_out_phase_offset(cav4_elec_mode_1_out_couple_out_phase_offset),\
	.mode_2_out_couple_out_phase_offset(cav4_elec_mode_2_out_couple_out_phase_offset),\
	.mode_0_out_couple_out_phase_offset_addr(cav4_elec_mode_0_out_couple_out_phase_offset_addr),\
	.mode_1_out_couple_out_phase_offset_addr(cav4_elec_mode_1_out_couple_out_phase_offset_addr),\
	.mode_2_out_couple_out_phase_offset_addr(cav4_elec_mode_2_out_couple_out_phase_offset_addr),\
	.outer_prod_0_k_out(cav4_elec_outer_prod_0_k_out),\
	.outer_prod_1_k_out(cav4_elec_outer_prod_1_k_out),\
	.outer_prod_2_k_out(cav4_elec_outer_prod_2_k_out),\
	.outer_prod_0_k_out_addr(cav4_elec_outer_prod_0_k_out_addr),\
	.outer_prod_1_k_out_addr(cav4_elec_outer_prod_1_k_out_addr),\
	.outer_prod_2_k_out_addr(cav4_elec_outer_prod_2_k_out_addr)
// module=outer_prod instance=piezo_couple gvar=None gcnt=None
`define AUTOMATIC_piezo_couple .k_out(piezo_couple_k_out),\
	.k_out_addr(piezo_couple_k_out_addr)
// module=outer_prod instance=noise_couple gvar=None gcnt=None
`define AUTOMATIC_noise_couple .k_out(noise_couple_k_out),\
	.k_out_addr(noise_couple_k_out_addr)
// module=resonator instance=resonator gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/resonator.v
// found output address in module resonator, base=prop_const
`define AUTOMATIC_resonator .prop_const(resonator_prop_const),\
	.prop_const_addr(resonator_prop_const_addr)
// module=prng instance=prng gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/prng.v
`define AUTOMATIC_prng .random_run(prng_random_run),\
	.iva(prng_iva),\
	.iva_we(prng_iva_we),\
	.ivb(prng_ivb),\
	.ivb_we(prng_ivb_we)
// module=adc_em instance=a_cav gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/vmod1.v ../submodules/rtsim/adc_em.v
`define AUTOMATIC_a_cav .offset(a_cav_offset)
// module=adc_em instance=a_for gvar=None gcnt=None
`define AUTOMATIC_a_for .offset(a_for_offset)
// module=adc_em instance=a_rfl gvar=None gcnt=None
`define AUTOMATIC_a_rfl .offset(a_rfl_offset)
// machine-generated by newad.py
`ifdef LB_DECODE_vmod1
`include "addr_map_vmod1.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [13:0] lb_addr
`define AUTOMATIC_decode\
wire we_beam_phase_step = lb_write&(`ADDR_HIT_beam_phase_step);\
reg [11:0] beam_phase_step=0; always @(posedge lb_clk) if (we_beam_phase_step) beam_phase_step <= lb_data;\
wire we_beam_modulo = lb_write&(`ADDR_HIT_beam_modulo);\
reg [11:0] beam_modulo=0; always @(posedge lb_clk) if (we_beam_modulo) beam_modulo <= lb_data;\
wire we_beam_phase_init = lb_write&(`ADDR_HIT_beam_phase_init);\
reg [11:0] beam_phase_init=0; always @(posedge lb_clk) if (we_beam_phase_init) beam_phase_init <= lb_data;\
wire we_compr_sat_ctl = lb_write&(`ADDR_HIT_compr_sat_ctl);\
reg [15:0] compr_sat_ctl=0; always @(posedge lb_clk) if (we_compr_sat_ctl) compr_sat_ctl <= lb_data;\
wire we_amp_lp_bw = lb_write&(`ADDR_HIT_amp_lp_bw);\
reg [17:0] amp_lp_bw=0; always @(posedge lb_clk) if (we_amp_lp_bw) amp_lp_bw <= lb_data;\
wire we_cav4_elec_phase_step = lb_write&(`ADDR_HIT_cav4_elec_phase_step);\
reg [31:0] cav4_elec_phase_step=0; always @(posedge lb_clk) if (we_cav4_elec_phase_step) cav4_elec_phase_step <= lb_data;\
wire we_cav4_elec_modulo = lb_write&(`ADDR_HIT_cav4_elec_modulo);\
reg [11:0] cav4_elec_modulo=0; always @(posedge lb_clk) if (we_cav4_elec_modulo) cav4_elec_modulo <= lb_data;\
wire [0:0] cav4_elec_drive_couple_out_coupling_addr;\
wire [17:0] cav4_elec_drive_couple_out_coupling;\
wire we_cav4_elec_drive_couple_out_coupling = lb_write&(`ADDR_HIT_cav4_elec_drive_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cav4_elec_drive_couple_out_coupling(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_drive_couple_out_coupling),\
	.clkb(lb_clk), .addrb(cav4_elec_drive_couple_out_coupling_addr), .doutb(cav4_elec_drive_couple_out_coupling));\
wire [0:0] cav4_elec_drive_couple_out_phase_offset_addr;\
wire [18:0] cav4_elec_drive_couple_out_phase_offset;\
wire we_cav4_elec_drive_couple_out_phase_offset = lb_write&(`ADDR_HIT_cav4_elec_drive_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cav4_elec_drive_couple_out_phase_offset(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[18:0]), .wena(we_cav4_elec_drive_couple_out_phase_offset),\
	.clkb(lb_clk), .addrb(cav4_elec_drive_couple_out_phase_offset_addr), .doutb(cav4_elec_drive_couple_out_phase_offset));\
wire [9:0] cav4_elec_dot_0_k_out_addr;\
wire [17:0] cav4_elec_dot_0_k_out;\
wire we_cav4_elec_dot_0_k_out = lb_write&(`ADDR_HIT_cav4_elec_dot_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_dot_0_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_dot_0_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_dot_0_k_out_addr), .doutb(cav4_elec_dot_0_k_out));\
wire [9:0] cav4_elec_dot_1_k_out_addr;\
wire [17:0] cav4_elec_dot_1_k_out;\
wire we_cav4_elec_dot_1_k_out = lb_write&(`ADDR_HIT_cav4_elec_dot_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_dot_1_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_dot_1_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_dot_1_k_out_addr), .doutb(cav4_elec_dot_1_k_out));\
wire [9:0] cav4_elec_dot_2_k_out_addr;\
wire [17:0] cav4_elec_dot_2_k_out;\
wire we_cav4_elec_dot_2_k_out = lb_write&(`ADDR_HIT_cav4_elec_dot_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_dot_2_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_dot_2_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_dot_2_k_out_addr), .doutb(cav4_elec_dot_2_k_out));\
wire we_cav4_elec_freq_0_coarse_freq = lb_write&(`ADDR_HIT_cav4_elec_freq_0_coarse_freq);\
reg [27:0] cav4_elec_freq_0_coarse_freq=0; always @(posedge lb_clk) if (we_cav4_elec_freq_0_coarse_freq) cav4_elec_freq_0_coarse_freq <= lb_data;\
wire we_cav4_elec_freq_1_coarse_freq = lb_write&(`ADDR_HIT_cav4_elec_freq_1_coarse_freq);\
reg [27:0] cav4_elec_freq_1_coarse_freq=0; always @(posedge lb_clk) if (we_cav4_elec_freq_1_coarse_freq) cav4_elec_freq_1_coarse_freq <= lb_data;\
wire we_cav4_elec_freq_2_coarse_freq = lb_write&(`ADDR_HIT_cav4_elec_freq_2_coarse_freq);\
reg [27:0] cav4_elec_freq_2_coarse_freq=0; always @(posedge lb_clk) if (we_cav4_elec_freq_2_coarse_freq) cav4_elec_freq_2_coarse_freq <= lb_data;\
wire we_cav4_elec_mode_0_drive_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_0_drive_coupling);\
reg [17:0] cav4_elec_mode_0_drive_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_0_drive_coupling) cav4_elec_mode_0_drive_coupling <= lb_data;\
wire we_cav4_elec_mode_1_drive_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_1_drive_coupling);\
reg [17:0] cav4_elec_mode_1_drive_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_1_drive_coupling) cav4_elec_mode_1_drive_coupling <= lb_data;\
wire we_cav4_elec_mode_2_drive_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_2_drive_coupling);\
reg [17:0] cav4_elec_mode_2_drive_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_2_drive_coupling) cav4_elec_mode_2_drive_coupling <= lb_data;\
wire we_cav4_elec_mode_0_beam_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_0_beam_coupling);\
reg [17:0] cav4_elec_mode_0_beam_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_0_beam_coupling) cav4_elec_mode_0_beam_coupling <= lb_data;\
wire we_cav4_elec_mode_1_beam_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_1_beam_coupling);\
reg [17:0] cav4_elec_mode_1_beam_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_1_beam_coupling) cav4_elec_mode_1_beam_coupling <= lb_data;\
wire we_cav4_elec_mode_2_beam_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_2_beam_coupling);\
reg [17:0] cav4_elec_mode_2_beam_coupling=0; always @(posedge lb_clk) if (we_cav4_elec_mode_2_beam_coupling) cav4_elec_mode_2_beam_coupling <= lb_data;\
wire we_cav4_elec_mode_0_bw = lb_write&(`ADDR_HIT_cav4_elec_mode_0_bw);\
reg [17:0] cav4_elec_mode_0_bw=0; always @(posedge lb_clk) if (we_cav4_elec_mode_0_bw) cav4_elec_mode_0_bw <= lb_data;\
wire we_cav4_elec_mode_1_bw = lb_write&(`ADDR_HIT_cav4_elec_mode_1_bw);\
reg [17:0] cav4_elec_mode_1_bw=0; always @(posedge lb_clk) if (we_cav4_elec_mode_1_bw) cav4_elec_mode_1_bw <= lb_data;\
wire we_cav4_elec_mode_2_bw = lb_write&(`ADDR_HIT_cav4_elec_mode_2_bw);\
reg [17:0] cav4_elec_mode_2_bw=0; always @(posedge lb_clk) if (we_cav4_elec_mode_2_bw) cav4_elec_mode_2_bw <= lb_data;\
wire [0:0] cav4_elec_mode_0_out_couple_out_coupling_addr;\
wire [17:0] cav4_elec_mode_0_out_couple_out_coupling;\
wire we_cav4_elec_mode_0_out_couple_out_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_0_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cav4_elec_mode_0_out_couple_out_coupling(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_mode_0_out_couple_out_coupling),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_0_out_couple_out_coupling_addr), .doutb(cav4_elec_mode_0_out_couple_out_coupling));\
wire [0:0] cav4_elec_mode_1_out_couple_out_coupling_addr;\
wire [17:0] cav4_elec_mode_1_out_couple_out_coupling;\
wire we_cav4_elec_mode_1_out_couple_out_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_1_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cav4_elec_mode_1_out_couple_out_coupling(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_mode_1_out_couple_out_coupling),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_1_out_couple_out_coupling_addr), .doutb(cav4_elec_mode_1_out_couple_out_coupling));\
wire [0:0] cav4_elec_mode_2_out_couple_out_coupling_addr;\
wire [17:0] cav4_elec_mode_2_out_couple_out_coupling;\
wire we_cav4_elec_mode_2_out_couple_out_coupling = lb_write&(`ADDR_HIT_cav4_elec_mode_2_out_couple_out_coupling);\
dpram #(.aw(1),.dw(18)) dp_cav4_elec_mode_2_out_couple_out_coupling(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_mode_2_out_couple_out_coupling),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_2_out_couple_out_coupling_addr), .doutb(cav4_elec_mode_2_out_couple_out_coupling));\
wire [0:0] cav4_elec_mode_0_out_couple_out_phase_offset_addr;\
wire [18:0] cav4_elec_mode_0_out_couple_out_phase_offset;\
wire we_cav4_elec_mode_0_out_couple_out_phase_offset = lb_write&(`ADDR_HIT_cav4_elec_mode_0_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cav4_elec_mode_0_out_couple_out_phase_offset(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[18:0]), .wena(we_cav4_elec_mode_0_out_couple_out_phase_offset),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_0_out_couple_out_phase_offset_addr), .doutb(cav4_elec_mode_0_out_couple_out_phase_offset));\
wire [0:0] cav4_elec_mode_1_out_couple_out_phase_offset_addr;\
wire [18:0] cav4_elec_mode_1_out_couple_out_phase_offset;\
wire we_cav4_elec_mode_1_out_couple_out_phase_offset = lb_write&(`ADDR_HIT_cav4_elec_mode_1_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cav4_elec_mode_1_out_couple_out_phase_offset(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[18:0]), .wena(we_cav4_elec_mode_1_out_couple_out_phase_offset),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_1_out_couple_out_phase_offset_addr), .doutb(cav4_elec_mode_1_out_couple_out_phase_offset));\
wire [0:0] cav4_elec_mode_2_out_couple_out_phase_offset_addr;\
wire [18:0] cav4_elec_mode_2_out_couple_out_phase_offset;\
wire we_cav4_elec_mode_2_out_couple_out_phase_offset = lb_write&(`ADDR_HIT_cav4_elec_mode_2_out_couple_out_phase_offset);\
dpram #(.aw(1),.dw(19)) dp_cav4_elec_mode_2_out_couple_out_phase_offset(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[18:0]), .wena(we_cav4_elec_mode_2_out_couple_out_phase_offset),\
	.clkb(lb_clk), .addrb(cav4_elec_mode_2_out_couple_out_phase_offset_addr), .doutb(cav4_elec_mode_2_out_couple_out_phase_offset));\
wire [9:0] cav4_elec_outer_prod_0_k_out_addr;\
wire [17:0] cav4_elec_outer_prod_0_k_out;\
wire we_cav4_elec_outer_prod_0_k_out = lb_write&(`ADDR_HIT_cav4_elec_outer_prod_0_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_outer_prod_0_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_outer_prod_0_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_outer_prod_0_k_out_addr), .doutb(cav4_elec_outer_prod_0_k_out));\
wire [9:0] cav4_elec_outer_prod_1_k_out_addr;\
wire [17:0] cav4_elec_outer_prod_1_k_out;\
wire we_cav4_elec_outer_prod_1_k_out = lb_write&(`ADDR_HIT_cav4_elec_outer_prod_1_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_outer_prod_1_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_outer_prod_1_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_outer_prod_1_k_out_addr), .doutb(cav4_elec_outer_prod_1_k_out));\
wire [9:0] cav4_elec_outer_prod_2_k_out_addr;\
wire [17:0] cav4_elec_outer_prod_2_k_out;\
wire we_cav4_elec_outer_prod_2_k_out = lb_write&(`ADDR_HIT_cav4_elec_outer_prod_2_k_out);\
dpram #(.aw(10),.dw(18)) dp_cav4_elec_outer_prod_2_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_cav4_elec_outer_prod_2_k_out),\
	.clkb(lb_clk), .addrb(cav4_elec_outer_prod_2_k_out_addr), .doutb(cav4_elec_outer_prod_2_k_out));\
wire [9:0] piezo_couple_k_out_addr;\
wire [17:0] piezo_couple_k_out;\
wire we_piezo_couple_k_out = lb_write&(`ADDR_HIT_piezo_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_piezo_couple_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_piezo_couple_k_out),\
	.clkb(lb_clk), .addrb(piezo_couple_k_out_addr), .doutb(piezo_couple_k_out));\
wire [9:0] noise_couple_k_out_addr;\
wire [17:0] noise_couple_k_out;\
wire we_noise_couple_k_out = lb_write&(`ADDR_HIT_noise_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_noise_couple_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_noise_couple_k_out),\
	.clkb(lb_clk), .addrb(noise_couple_k_out_addr), .doutb(noise_couple_k_out));\
wire [9:0] resonator_prop_const_addr;\
wire [20:0] resonator_prop_const;\
wire we_resonator_prop_const = lb_write&(`ADDR_HIT_resonator_prop_const);\
dpram #(.aw(10),.dw(21)) dp_resonator_prop_const(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[20:0]), .wena(we_resonator_prop_const),\
	.clkb(lb_clk), .addrb(resonator_prop_const_addr), .doutb(resonator_prop_const));\
wire we_prng_random_run = lb_write&(`ADDR_HIT_prng_random_run);\
reg [0:0] prng_random_run=0; always @(posedge lb_clk) if (we_prng_random_run) prng_random_run <= lb_data;\
wire we_prng_iva = lb_write&(`ADDR_HIT_prng_iva);\
wire prng_iva_we = we_prng_iva;\
reg [31:0] prng_iva=0; always @(posedge lb_clk) if (we_prng_iva) prng_iva <= lb_data;\
wire we_prng_ivb = lb_write&(`ADDR_HIT_prng_ivb);\
wire prng_ivb_we = we_prng_ivb;\
reg [31:0] prng_ivb=0; always @(posedge lb_clk) if (we_prng_ivb) prng_ivb <= lb_data;\
wire we_a_cav_offset = lb_write&(`ADDR_HIT_a_cav_offset);\
reg [9:0] a_cav_offset=0; always @(posedge lb_clk) if (we_a_cav_offset) a_cav_offset <= lb_data;\
wire we_a_for_offset = lb_write&(`ADDR_HIT_a_for_offset);\
reg [9:0] a_for_offset=0; always @(posedge lb_clk) if (we_a_for_offset) a_for_offset <= lb_data;\
wire we_a_rfl_offset = lb_write&(`ADDR_HIT_a_rfl_offset);\
reg [9:0] a_rfl_offset=0; always @(posedge lb_clk) if (we_a_rfl_offset) a_rfl_offset <= lb_data;\
wire [31:0] mirror_out_0;wire mirror_write_0 = lb_write &(`ADDR_HIT_MIRROR);\
dpram #(.aw(`MIRROR_WIDTH),.dw(32)) mirror_0(\
	.clka(lb_clk), .addra(lb_addr[`MIRROR_WIDTH-1:0]), .dina(lb_data[31:0]), .wena(mirror_write_0),\
	.clkb(lb_clk), .addrb(lb_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_0));\

`else
`define AUTOMATIC_self input  [11:0] beam_phase_step,\
input  [11:0] beam_modulo,\
input  [11:0] beam_phase_init,\
input  [15:0] compr_sat_ctl,\
input signed [17:0] amp_lp_bw,\
input  [31:0] cav4_elec_phase_step,\
input  [11:0] cav4_elec_modulo,\
input signed [17:0] cav4_elec_drive_couple_out_coupling,\
output  [0:0] cav4_elec_drive_couple_out_coupling_addr,\
input signed [18:0] cav4_elec_drive_couple_out_phase_offset,\
output  [0:0] cav4_elec_drive_couple_out_phase_offset_addr,\
input signed [17:0] cav4_elec_dot_0_k_out,\
input signed [17:0] cav4_elec_dot_1_k_out,\
input signed [17:0] cav4_elec_dot_2_k_out,\
output  [9:0] cav4_elec_dot_0_k_out_addr,\
output  [9:0] cav4_elec_dot_1_k_out_addr,\
output  [9:0] cav4_elec_dot_2_k_out_addr,\
input signed [27:0] cav4_elec_freq_0_coarse_freq,\
input signed [27:0] cav4_elec_freq_1_coarse_freq,\
input signed [27:0] cav4_elec_freq_2_coarse_freq,\
input signed [17:0] cav4_elec_mode_0_drive_coupling,\
input signed [17:0] cav4_elec_mode_1_drive_coupling,\
input signed [17:0] cav4_elec_mode_2_drive_coupling,\
input signed [17:0] cav4_elec_mode_0_beam_coupling,\
input signed [17:0] cav4_elec_mode_1_beam_coupling,\
input signed [17:0] cav4_elec_mode_2_beam_coupling,\
input signed [17:0] cav4_elec_mode_0_bw,\
input signed [17:0] cav4_elec_mode_1_bw,\
input signed [17:0] cav4_elec_mode_2_bw,\
input signed [17:0] cav4_elec_mode_0_out_couple_out_coupling,\
input signed [17:0] cav4_elec_mode_1_out_couple_out_coupling,\
input signed [17:0] cav4_elec_mode_2_out_couple_out_coupling,\
output  [0:0] cav4_elec_mode_0_out_couple_out_coupling_addr,\
output  [0:0] cav4_elec_mode_1_out_couple_out_coupling_addr,\
output  [0:0] cav4_elec_mode_2_out_couple_out_coupling_addr,\
input signed [18:0] cav4_elec_mode_0_out_couple_out_phase_offset,\
input signed [18:0] cav4_elec_mode_1_out_couple_out_phase_offset,\
input signed [18:0] cav4_elec_mode_2_out_couple_out_phase_offset,\
output  [0:0] cav4_elec_mode_0_out_couple_out_phase_offset_addr,\
output  [0:0] cav4_elec_mode_1_out_couple_out_phase_offset_addr,\
output  [0:0] cav4_elec_mode_2_out_couple_out_phase_offset_addr,\
input signed [17:0] cav4_elec_outer_prod_0_k_out,\
input signed [17:0] cav4_elec_outer_prod_1_k_out,\
input signed [17:0] cav4_elec_outer_prod_2_k_out,\
output  [9:0] cav4_elec_outer_prod_0_k_out_addr,\
output  [9:0] cav4_elec_outer_prod_1_k_out_addr,\
output  [9:0] cav4_elec_outer_prod_2_k_out_addr,\
input signed [17:0] piezo_couple_k_out,\
output  [9:0] piezo_couple_k_out_addr,\
input signed [17:0] noise_couple_k_out,\
output  [9:0] noise_couple_k_out_addr,\
input  [20:0] resonator_prop_const,\
output  [9:0] resonator_prop_const_addr,\
input  [0:0] prng_random_run,\
input  [31:0] prng_iva,\
input  [0:0] prng_iva_we,\
input  [31:0] prng_ivb,\
input  [0:0] prng_ivb_we,\
input signed [9:0] a_cav_offset,\
input signed [9:0] a_for_offset,\
input signed [9:0] a_rfl_offset
`define AUTOMATIC_decode
`endif
