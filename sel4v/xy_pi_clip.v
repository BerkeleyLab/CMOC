`timescale 1ns / 1ns

// Proportional-Integral gain for multiplexed X-Y data stream,
// with programmable clip levels.  Timing plan shown below.

// Spartan-6: 159 LUTs, 1 DSP48A1
//  (not counting ~36 LUTs needed to generate coeff and lim)
// XXX this is the critical timing path, streamline and/or pipeline some more
// XXX proportional and integral gain terms need very different scaling?

// Serious pipelining internally.
// At any one point, the data flow sequence is:
//   X integral     high-side clip (new data from multiplier summed with previous X integral term)
//   Y integral     high-side clip (new data from multiplier summed with previous Y integral term)
//   X proportional high-side clip (new data from multiplier summed with previous X integral term)
//   Y proportional high-side clip (new data from multiplier summed with previous Y integral term)
//   X integral      low-side clip (recirculated data from high-side clip)
//   Y integral      low-side clip (recirculated data from high-side clip)
//   X proportional  low-side clip (recirculated data from high-side clip)
//   Y proportional  low-side clip (recirculated data from high-side clip)

//        in_xy  coeff   lim
//  sync  xerr
//  .     yerr   x_int
//  .     .      y_int
//  .     .      x_prop
//  .     .      y_prop
//  .     .      .       x_hi
//  .     .      .       y_hi
//  .     .      .       x_hi
//  sync  .      .       y_hi
//  .     .      .       x_lo
//  .     .      .       y_lo
//  .     .      .       x_lo
//  .     .      .       y_lo
//  .     .      .       .      o_sync  out_x
//  .     .      .       .      .       out_y
module xy_pi_clip(
	input clk,  // timespec 6.8 ns
	input sync,  // high for the first of the xy pair
	input signed [17:0] in_xy,
	output signed [17:0] out_xy,
	output o_sync,
	// 8-way muxed configuration
	input signed [17:0] coeff,
	input signed [17:0] lim,
	// Output clipped, four bits are vs. {x_hi, y_hi, x_lo, y_lo}
	output [3:0] clipped
);

// sync comes in one out of every eight cycles
// build a one-hot encoding of the various phases out of a simple shift register
reg [14:0] stb=0;
always @(posedge clk) stb <= {stb[13:0],sync};

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

wire signed [17:0] in_xy1;
reg_delay #(.dw(18), .len(2)) pi_match(.clk(clk), .gate(1'b1),
	.din(in_xy), .dout(in_xy1));

reg signed [35:0] mr=0;
reg signed [41:0] mr_scale=0;
reg signed [29:0] mr_sat=0;
reg signed [30:0] lim1=0;
reg signed [30:0] accum1=0, accum2=0, accum3=0, accum4=0, accum5=0, accum6=0;
reg signed [17:0] val=0;
reg clip_recirc=0, p_term=0, p_term1=0, p_term2=0, lim_hi=0, cmp=0;
wire sat1 = cmp ^ lim_hi;
wire signed [18:0] accum1_upper = accum1[30:12];
always @(posedge clk) begin
	clip_recirc <= stb[6]|stb[7]|stb[0]|stb[1];
	p_term <= stb[2]|stb[3]|stb[6]|stb[7];
	p_term1 <= p_term;
	p_term2 <= p_term1;
	lim_hi <= stb[6]|stb[7]|stb[8]|stb[9];
	val <= (sync|stb[0]) ? in_xy : in_xy1;  // outputs on stb 0, 1, 2, 3
	mr <= coeff * val;  // outputs on stb 1, 2, 3, 4
	mr_scale <= p_term ? (mr <<< 6) : mr;  // this step determines K_P vs. K_I scaling
	mr_sat <= `SAT(mr_scale,41,29);  // outputs on stb 3, 4, 5, 6
	accum1 <= clip_recirc ? accum4 : (mr_sat + (p_term2 ? accum6 : accum4));
	accum2 <= accum1;
	cmp <= accum1_upper < lim;
	lim1 <= {lim[17],lim,12'b0};
	accum3 <= sat1 ? lim1 : accum2;
	accum4 <= accum3;
	accum5 <= accum4;
	accum6 <= accum5;
end

wire signed [17:0] out_show = accum3[29:12];
wire signed [18:0] acc_show = accum1[30:12];  // debug only, match cmp expression
assign out_xy = (stb[4]|stb[5]) ? out_show : 0;
assign o_sync = stb[4];
assign clipped = {4{sat1}} & {stb[14]|stb[12], stb[13]|stb[11], stb[10]|stb[8], stb[9]|stb[7]};

endmodule
