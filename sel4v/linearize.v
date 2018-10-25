`timescale 1ns / 1ns
// Larry Doolittle, LBNL, November 2015

// Fails the "don't modify the data stream when all host-settable registers
// are zero" paradigm.  All gains will be zero in that case.

// 9 cycles pipeline delay.  Could try to shorten that by a couple.
// First make sure this one synthesizes OK at 190 MHz.

// Input span on i_cart must exclude negative full-scale.
// That's consistent with a programmable clip feature on the PI state-machine
// that feeds this module.

`include "linearize_auto.vh"

module linearize(
	input clk,
	input [1:0] i_qphase,
	input signed [15:0] i_cart,  // I1 I2 Q1 Q2 I1 ...
	input [16:0] i_angl,         // A1 A2 -- -- A1 ...
	output signed [15:0] o_cart,
	output [16:0] o_angl,
	output [1:0] o_qphase,
	`AUTOMATIC_self
);

parameter interleave = 2;
parameter cheat = 0;  // can probably set to 1 or 2 to reduce latency

reg [31:0] square = 0;
reg [15:0] square1 = 0;
wire [15:0] square2;
reg [15:0] mag = 0;
wire [15:0] magd;
reg_delay #(.dw(16), .len(interleave)) square_del(.clk(clk), .gate(1'b1),
	.din(square1), .dout(square2));
reg_delay #(.dw(16), .len(interleave-1)) mag_del(.clk(clk), .gate(1'b1),
	.din(mag), .dout(magd));
always @(posedge clk) begin
	square <= i_cart * i_cart;
	square1 <= square[29:14];  // not normally safe to drop both msb;
	// see note above about i_cart span
	mag <= i_qphase[1] ? magd : square1 + square2;
end

// output curve is multiplexed as G1 G2 O1 O2 G1 ...
// (gains and phase offsets)
wire signed [15:0] curve;
lin_curves curvegen // auto
	(.clk(clk), .qphase(i_qphase), .mag(mag), .curve(curve),
	`AUTOMATIC_curvegen);
wire signed [15:0] curve1, curve2;
reg_delay #(.dw(16), .len(interleave)) curve_del1(.clk(clk), .gate(1'b1),
	.din(curve), .dout(curve1));
reg_delay #(.dw(16), .len(interleave)) curve_del2(.clk(clk), .gate(1'b1),
	.din(curve1), .dout(curve2));
wire signed [15:0] gain = i_qphase[1] ? curve1 : curve2;
wire signed [15:0] poff = i_qphase[1] ? curve  : curve1;
reg signed [15:0] gain1=0;
//always @(posedge clk) gain1 <= gain;

wire signed [15:0] cart1;
reg_delay #(.dw(16), .len(11 - 4*cheat)) del_cart(.clk(clk), .gate(1'b1),
	.din(i_cart), .dout(cart1));
wire [16:0] angl1;
reg_delay #(.dw(17), .len(11 - 4*cheat)) del_angl(.clk(clk), .gate(1'b1),
	.din(i_angl), .dout(angl1));

reg signed [31:0] prod = 0;
reg [15:0] sum = 0;
//reg [1:0] qphase1 = 0, qphase2 = 0;
always @(posedge clk) begin
	prod <= cart1 * gain;
	sum <= angl1 + poff;
	//qphase1 <= qphase;
	//qphase2 <= qphase1;
end
assign o_cart = prod[30:15];
assign o_angl = sum;
assign o_qphase = i_qphase;

endmodule
