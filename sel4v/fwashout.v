`timescale 1ns / 1ns

// Name: Washout (DC-reject) filter
//% track input allows freezing DC offset
module fwashout(clk, rst, track,
	a_data, a_gate, a_trig,
	o_data, o_gate, o_trig,
	time_err
);

parameter a_dw = 16;
parameter o_dw = 16;
parameter cut = 4;

input clk;  // timespec 8.0 ns
input rst;
input track;
input signed [a_dw-1:0] a_data;  input a_gate, a_trig;
output signed [o_dw-1:0] o_data;  output o_gate, o_trig;
output time_err;

reg signed [a_dw+cut-1:0] dc=0;
reg signed [a_dw+cut-0:0] sub=0;
always @(posedge clk) begin
	if (rst|track) dc <= rst ? 0 : (dc - (dc>>>cut)+a_data);
	sub <= (a_data<<<cut)-dc+2;
end

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
wire signed [a_dw+cut-1:0] clipped=`SAT(sub,a_dw+cut,a_dw+cut-1);
assign o_data = clipped[a_dw+cut-1:cut];

// Intended for raw ADC inputs.
// Could go back and make this module handle other data patterns

assign o_gate=1'b1;
assign o_trig=a_trig;
assign time_err=~a_gate;

endmodule
