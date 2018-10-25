`timescale 1ns / 1ns

`define LB_DECODE_vmod1
`include "vmod1_auto.vh"

// Single cavity emulator
// Now that cav4_elec is working, this idea extends easily to multiple
// cavities sharing mechanical dynamics, but the port count balloons.
// Functionality overlaps some with cav4_elec_tb.v
// Address map imported via cav4_elec:
//    1-2     LO DDS
//    8-11    prompt forward and reflected setup
//   16-23    mode 0 cav4_mode registers
//   24-31    mode 1 cav4_mode registers
//   32-39    mode 2 cav4_mode registers
// 2048-4095  mode 0 mechanical coupling in and out
// 4096-6143  mode 1 mechanical coupling in and out
// 6144-8191  mode 3 mechanical coupling in and out
// to which we add here:
//    3-4     beam timing
//    65      amplifier bandwidth
//  129-131   ADC offsets
//    159     PRNG enable
//  160-191   PRNG A initialization
//  192-223   PRNG B initialization
// 1024-2047  resonator
// 8192-9215  piezo coupling to mechanical system
// 9216-10239 noise coupling to mechanical system

// XXX want some way to view mechanical state
// Do I want to read out a piezo current, that depends on mechanics?
// Do we want to add coarse cable drift, or are phase shifts enough?
// 11999 LUTs and 34 DSP48E1 in XC7Axx
module vmod1(
	input clk,
	input iq,
	input signed [17:0] drive,  // not counting beam
	input signed [17:0] piezo,
	// Output ADCs at 20 MHz IF
	output signed [15:0] a_field,
	output signed [15:0] a_forward,
	output signed [15:0] a_reflect,
	// Local Bus for simulator configuration
	input [31:0] lb_data,
	input [14:0] lb_addr,
	input lb_write,  // single-cycle causes a write
	// Output status
	output [7:0] clips
);
wire lb_clk;
assign lb_clk = clk;
`AUTOMATIC_decode

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
`define UNIFORM(x) ((~|(x)) | &(x))  // All 0's or all 1's

// Beam timing generator
// beam_timing output is limited to [0,phase_step].
wire [11:0] beam_timing;
beam1 beam  // auto
	(.clk(clk), .ena(iq), .reset(1'b0), .pulse(beam_timing),
	`AUTOMATIC_beam);

// Amplifier compression step
wire signed [17:0] compress_out;
a_compress compr // auto
	(.clk(clk), .iq(iq), .d_in(drive), .d_out(compress_out),
	`AUTOMATIC_compr);
reg signed [17:0] compress_out_d=0;
always @(posedge clk) compress_out_d <= compress_out;
wire signed [17:0] ampf_in = compress_out_d; // was drive

// Amplifier low-pass filter, maximum bandwidth 3.75 MHz
wire signed [17:0] amp_out1;
lp_pair #(.shift(2)) amp_lp  // auto
	(.clk(clk), .drive(ampf_in), .drive2(24'b0), .res(amp_out1), `AUTOMATIC_amp_lp);

// Configure number of modes processed
// I don't make it host-settable (at least not yet),
// because of its interaction with interp_span.
parameter n_mech_modes = 7;
parameter n_cycles = n_mech_modes * 2;
parameter interp_span = 4;  // ceil(log2(n_cycles))
parameter mode_count = 3;

// Allow tweaks to the cavity electrical eigenmode time scale
parameter mode_shift=18;

// Control how much frequency shifting is possible with mechanical displacement
parameter df_scale=0;     // see cav4_freq.v

// Create start pulses at configured interval
reg start=0;
reg [7:0] mech_cnt=0;
always @(posedge clk) begin
	mech_cnt <= mech_cnt==0 ? n_cycles-1 : mech_cnt-1;
	start <= mech_cnt == 0;
end
wire start_outer;
reg_delay #(.dw(1), .len(0)) start_outer_g(.clk(clk), .gate(1'b1), .din(start), .dout(start_outer));
wire start_eig;
reg_delay #(.dw(1), .len(1)) start_eig_g(.clk(clk), .gate(1'b1), .din(start), .dout(start_eig));

// Instantiate one cavity
wire signed [17:0] field, forward, reflect;
wire signed [17:0] cav_eig_drive, mech_x;
cav4_elec #(.mode_shift(mode_shift), .interp_span(interp_span), .df_scale(df_scale), .mode_count(mode_count)) cav4_elec // auto
	(.clk(clk),
	.iq(iq), .drive(amp_out1), .beam_timing(beam_timing),
	.field(field), .forward(forward), .reflect(reflect),
	.start(start), .mech_x(mech_x), .eig_drive(cav_eig_drive),
	`AUTOMATIC_cav4_elec
);

// Couple the piezo to mechanical drive
wire signed [17:0] piezo_eig_drive;
outer_prod piezo_couple  // auto
	(.clk(clk), .start(start_outer), .x(piezo), .result(piezo_eig_drive),
	`AUTOMATIC_piezo_couple
);

// Couple randomness to mechanical drive
wire signed [17:0] environment;  // filled in later
wire signed [17:0] noise_eig_drive;
outer_prod noise_couple  // auto
	(.clk(clk), .start(start_outer), .x(environment), .result(noise_eig_drive),
	`AUTOMATIC_noise_couple
);

// Sum these drive terms together
reg signed [18:0] local_eig_drive=0;
wire signed [19:0] sum_eig_drive = cav_eig_drive + local_eig_drive;
reg signed [17:0] eig_drive0=0, eig_drive=0;
reg edrive_clip=0;
always @(posedge clk) begin
	local_eig_drive <= piezo_eig_drive + noise_eig_drive;  // pipeline add just like cav4_elec.v
	eig_drive0 <= `SAT(sum_eig_drive,19,17);
	eig_drive <= eig_drive0;
	edrive_clip <= ~`UNIFORM(sum_eig_drive[19:17]);
end

// Instantiate the mechanical resonance computer
wire res_clip;
resonator resonator // auto
	(.clk(clk), .start(start_eig),
	.drive(eig_drive),
	.position(mech_x), .clip(res_clip),
	`AUTOMATIC_resonator
);

// Pseudorandom number subsystem
wire [31:0] rnda, rndb;
prng prng  // auto
	(.clk(clk), .rnda(rnda), .rndb(rndb),
	`AUTOMATIC_prng);

// Create a white noise term for environment
// This is a strangely-scaled CIC filter
// Each iteration adds a variance of 12, consuming 6 bits of PRNG
// Result has variance of n_cycles*12, mean of 0, possible peak n_cycles*7
// e.g. if n_cycles=14, std.dev.=12.96, peak=98, peak/rms=7.56
reg signed [11:0] noise_accum=0, noise_1=0, noise_out=0;
always @(posedge clk) begin
	noise_accum <= noise_accum + rndb[15:13] - rndb[18:16];
	if (start_eig) begin
		noise_1 <= noise_accum;
		noise_out <= noise_1-noise_accum;
	end
end
assign environment = noise_out;

// ADCs themselves
// Offsets could be allowed to drift
adc_em #(.del(1)) a_cav // auto
	(.clk(clk), .strobe(iq), .in(field),   .rnd(rnda[12: 0]), .adc(a_field), `AUTOMATIC_a_cav);
adc_em #(.del(1)) a_for // auto
	(.clk(clk), .strobe(iq), .in(forward), .rnd(rnda[25:13]), .adc(a_forward), `AUTOMATIC_a_for);
adc_em #(.del(1)) a_rfl // auto
	(.clk(clk), .strobe(iq), .in(reflect), .rnd(rndb[12: 0]), .adc(a_reflect), `AUTOMATIC_a_rfl);

// Reserve space for several possible clipping status signals
// Caller should take care of latching, reporting, and clearing.
assign clips = {6'b0, edrive_clip, res_clip};

endmodule
