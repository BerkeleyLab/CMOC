`timescale 1ns / 1ns

// Magnitude and phase processor for a self-excited loop

// This module has "all the time in the world", see sel4.tex
// Inputs and outputs repeat every eight cycles.
// Keeping out_sync aligned with sync gives a nice transition
// between loopback testing of fdbk_core and the full configuration.
//          in_mp            out_xy  out_ph
// 0  sync  cav_m  .
// 1  .     cav_p  .
// 2  .     .      .
// 3  .     .      .
// 4  .     .      .
// 5  .     .      .
// 6  .     .      .
// 7  .     .      .
// 8  sync  cav_m  out_sync  drv_x  (gain_p)
// 9  .     cav_p  .         drv_y   drv_p
// 10 .     .      .         set_x  (gain_p)
// 11 .     .      .         0       set_p
// 12 .     .      .         gain_x (gain_p)
// 13 .     .      .         0       gain_p
// 14 .     .      .         0      (gain_p)
// 15 .     .      .         0      (gain_p)
//
// where the parenthesized (gain_p) outputs are filler, not used.

// Larry Doolittle, LBNL, 2014

// drv_p = (sel_en ? in_mp : 0) + ph_offset
// set_p and gain_p

module mp_proc(
	input clk,
	input sync,
	// Input from cordic_mux
	input signed [17:0] in_mp,
	// Host-writable simple controls
	input [0:0] sel_en,  // external
	input signed [17:0] ph_offset,  // external
	input signed [17:0] sel_thresh,  // external
	// Host-settable channel-multiplexed controls
	input signed [17:0] setmp,  // external
	input signed [17:0] coeff,  // external
	input signed [17:0] lim,  // external
	output [1:0] setmp_addr,  // external address for setmp
	output [1:0] coeff_addr,  // external address for coeff
	output [1:0] lim_addr,  // external address for lim
	// Final output, back to cordic_mux
	output out_sync,
	output signed [17:0] out_xy,
	output signed [18:0] out_ph,
	output [11:0] cmp_event
//  cmp_event[0]   |mag err| > 0.2%
//  cmp_event[1]   |pha err| > 0.11 deg
//  cmp_event[2]   |mag err| > 0.1%
//  cmp_event[3]   |pha err| > 0.06 deg
//  cmp_event[4]   |mag err| > 0.05%
//  cmp_event[5]   |pha err| > 0.03 deg
//  cmp_event[6]   |mag err| > 0.024%
//  cmp_event[7]   |pha err| > 0.014 deg
//  cmp_event[8]   X drive >= lim_X_hi
//  cmp_event[9]   Y drive >= lim_Y_hi
//  cmp_event[10]  X drive < lim_X_lo
//  cmp_event[11]  Y drive < lim_Y_lo
);

// critical timing setup
// Addressing of controls for dprams
// can obviously optimize to save a few LUTs
reg [2:0] state=0, state1=0, state2=0, state3=0, state4=0, state5=0, state6=0;
always @(posedge clk) begin
	state <= sync ? 7 : state+1;  // check reset value
	state1 <= state;
	state2 <= state1;
	state3 <= state2;
	state4 <= state3;
	state5 <= state4;
	state6 <= state5;
end
assign setmp_addr = {1'b0, ~state[0]};
assign coeff_addr = {~state2[1],state2[0]};
assign   lim_addr = {state6[2],state4[0]};

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg [7:0] stb=0;
always @(posedge clk) stb <= {stb[6:0],sync};

// Programmable threshold for when it's OK to turn on SEL.
// At low amplitude, the phase is unusable.
// Include hysteresis so it can't chatter.
reg sel_thresh_good=0, sel_thresh_bad=0, sel_amp_ok=0;
always @(posedge clk) begin
	sel_thresh_good <= in_mp > sel_thresh;
	sel_thresh_bad  <= in_mp < (sel_thresh >>> 1);
	if (stb[0]) begin
		if (sel_thresh_good) sel_amp_ok <= 1;
		if (sel_thresh_bad)  sel_amp_ok <= 0;
	end
end

// Subtract setpoint, add offset
reg signed [17:0] mp_err=0, phout=0;
// drv_p only valid during sync cycles
wire signed [17:0] drv_p = (sel_en&sel_amp_ok) ? in_mp + ph_offset : 0; // XXX can't change phase unless SEL?
always @(posedge clk) begin
	mp_err <= in_mp - setmp;  // XXX saturate magnitude only?
	phout <= stb[0] ? drv_p : setmp;
end
wire signed [17:0] mp_err2;
pdetect2 #(.w(18)) pdetect(.clk(clk), .ang_in(mp_err), .strobe_in(stb[1]),
	// Feature: don't allow phase history to be built up if amplitude is small
	.reset(~sel_amp_ok),
	.ang_out(mp_err2));

// Match pipeline
wire signed [17:0] out_ph_w;
reg_delay #(.dw(18), .len(7)) pipe_match(.clk(clk), .gate(1'b1),
	.din(phout), .dout(out_ph_w));
assign out_ph = {out_ph_w,1'b0};  // Hmmmm....

wire pi_sync;  // not used
wire signed [17:0] xy_drive;
wire [3:0] clipped;
xy_pi_clip pi(.clk(clk), .in_xy(mp_err2), .sync(stb[1]),
	.out_xy(xy_drive), .o_sync(pi_sync), .coeff(coeff), .lim(lim), .clipped(clipped)
);

// terrible waste of a multiplier
reg signed [35:0] set1=0;
always @(posedge clk) begin
	set1 <= setmp * 96667;  // 2^17*2/(1.646760258)^2
end
wire signed [17:0] set1s = set1[34:17];

reg signed [17:0] xy_drive_final=0;
always @(posedge clk) begin
	xy_drive_final <= stb[6]|stb[7] ? xy_drive : stb[0] ? set1s : 0;
end
assign out_xy = xy_drive_final;
assign out_sync = sync;

// Lock-detection, not part of main pipeline
// First take absolute value of error.  OK that -1 is treated the same as 0.
// Recirculate so we get multiple comparison chances later.
wire [16:0] mp_err2_abs = mp_err2[17] ? ~mp_err2[16:0] : mp_err2[16:0];
reg [16:0] mp_err3=0, mp_err4;
always @(posedge clk) begin
	mp_err3 <= ~(stb[1]|stb[2]) ? mp_err4 : mp_err2_abs;
	mp_err4 <= mp_err3;
end

// Set up the thresholds for comparison
reg [16:0] thresh1=0, thresh2=0;
reg over_thresh=0;
localparam thresh_shift1 = 9;
always @(posedge clk) begin
	// When thresh_shift1 = 9, thresholds at 0.2%, 0.1%, 0.05%, and 0.024%
	// in amplitude, and 0.002 radian, .. 0.00024 radian in phase,
	// equivalent to 0.11 degree, .. 0.014 degree.  Note that 20861 is
	// one radian, expressed as 17-bit fraction of a revolution.
	thresh1 <= stb[1] ? (setmp >>> thresh_shift1): stb[2] ? (20861 >>> thresh_shift1) : thresh2 >> 1;
	thresh2 <= thresh1;
	over_thresh <= mp_err3 > thresh1;
end

// Spit out oever-threshold events;
// someone else will have to latch these, and reset on slow capture.
wire [7:0] over_event = {8{over_thresh}} & {stb[2:0], stb[7:3]};
assign cmp_event = {clipped, over_event};

// Other things to add here?
//  SEL operation frequency counter
// sqrt(prod(1+0.5.^[0:20].^2))

// drive (the whole point of the main data path)
//     six cycles computation from in_mp to out_xy
// setpoint
//   X   R_set/1.64676^2 = R_set*0.737512254/2
//   Y   0
//   th  th_set
// gain
//   X   scalar gain
//   Y   0
//   th  ph_offset?
// unused

endmodule
