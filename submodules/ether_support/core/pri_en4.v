`timescale 1ns / 1ns

module pri_en4(
	input [3:0] inp,
	output [1:0] which,
	output hit
);

assign hit = |inp;
reg [1:0] w;
always @(*) case (inp)
	4'b0000: w = 0;
	4'b0001: w = 0;
	4'b0010: w = 1;
	4'b0011: w = 1;
	4'b0100: w = 2;
	4'b0101: w = 2;
	4'b0110: w = 2;
	4'b0111: w = 2;
	4'b1000: w = 3;
	4'b1001: w = 3;
	4'b1010: w = 3;
	4'b1011: w = 3;
	4'b1100: w = 3;
	4'b1101: w = 3;
	4'b1110: w = 3;
	4'b1111: w = 3;
endcase
assign which=w;

endmodule
