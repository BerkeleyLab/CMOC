`timescale 1ns / 1ns


module crc8_test(
	input clk,  // timespec 6.0 ns
	input gate,
	input first,  // set this during the first clock cycle of a new block of data
	input [7:0] d_in,
	output reg [7:0] d_out,
	output reg zero
);

wire z0;
wire [7:0] d0;
reg [7:0] d_il=0;
always @(posedge clk) if (gate) begin
	d_il <= d_in;
	d_out <= d0;
	zero <= z0;
end

crc8_guts #(.wid(32), .init(32'hffffffff)) crc(.clk(clk), .gate(gate),
	.first(first), .d_in(d_il),
	.d_out(d0), .zero(z0));

endmodule
