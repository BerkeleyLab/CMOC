`timescale 1ns / 1ns

// Combines two single (complex) pole filters into something that
// can be configured to give a notch plus low-pass.  See lp_notch.m.

`include "lp_notch_auto.vh"

module lp_notch(
	input clk,  // timespec 6.66 ns
	input iq,
	input signed [17:0] x,
	output signed [19:0] y,
	`AUTOMATIC_self
);

`AUTOMATIC_decode

wire signed [19:0] y1;
lp1 lp1a // auto
	(.clk(clk), .iq(iq),
	.x(x), .y(y1), `AUTOMATIC_lp1a);

wire signed [19:0] y2;
lp1 lp1b // auto
	(.clk(clk), .iq(iq),
	.x(x), .y(y2), `AUTOMATIC_lp1b);

assign y = y1+y2;  // XXX saturate me!

endmodule
