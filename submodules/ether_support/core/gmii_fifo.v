`timescale 1ns / 1ns

module gmii_fifo(
	input clk_in,
	input [7:0] d_in,
	input strobe_in,
	input clk_out,
	output [7:0] d_out,
	output strobe_out
);

wire fifo_empty;
reg fifo_read0=0;
reg strobe_in0=0, strobe_in1=0, strobe_in2=0, strobe_in3=0, strobe_in4=0, fifo_read=0;
reg [7:0] fifo_input=0;

wire fifo_read_test;

assign fifo_read_test = fifo_read & ~fifo_empty;

always @(posedge clk_in) begin
	strobe_in0 <= strobe_in;
	strobe_in1 <= strobe_in0;
	strobe_in2 <= strobe_in1;
	strobe_in3 <= strobe_in2;
	fifo_input <= strobe_in ? d_in : 8'b0;
end

always @(posedge clk_out) begin
	strobe_in4 <= strobe_in3;
	if (strobe_in4) fifo_read <= 1;
	if (fifo_read0 & fifo_empty) fifo_read <= 0;
	fifo_read0 <= fifo_read;
end

wire [7:0] fifo_out;

fifo2 #(.dw(8), .aw(4)) fifo_rx(
	.rd_clk(clk_out), .wr_clk(clk_in), .rst(1'b1),
	.din(fifo_input), .we(strobe_in0),
	.dout(fifo_out), .re(fifo_read_test),
	/* .full(), .wr_level(), .rd_level() */
	.empty(fifo_empty));

assign d_out = fifo_out[7:0];
assign strobe_out = fifo_read0 & fifo_read;

endmodule
