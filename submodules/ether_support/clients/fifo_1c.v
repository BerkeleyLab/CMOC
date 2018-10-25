`timescale 1ns / 1ns

// Simplified FIFO that works in a single clock domain
module fifo_1c(clk, din, we, dout, re, full, empty);

parameter dw=16;
parameter aw=8;

input clk, we, re;
input  [dw-1:0] din;
output [dw-1:0] dout;
output reg full, empty;

// Logic for read and write pointers -- very simple
reg  [aw:0] wp=0, rp=0;
wire [aw:0] wp_next = wp + 1'b1;
wire [aw:0] rp_next = rp + 1'b1;
always @(posedge clk) if (we) wp <= wp_next;
always @(posedge clk) if (re) rp <= rp_next;

// Instantiate actual memory
dpram #(.aw(aw), .dw(dw)) mem(
	.clkb(clk), .addrb(rp[aw-1:0]), .doutb(dout),
	.clka(clk), .addra(wp[aw-1:0]), .dina(din), .wena(we));

// Now compute the harder part, the status flags
wire [aw:0] block = {1'b1, {aw{1'b0}}};
always @(posedge clk) begin
	empty <= (wp == rp) | (re & (wp == rp_next));
	full <= (wp == (rp ^ block)) | (we & (wp_next == (rp ^ block)));
end

endmodule
