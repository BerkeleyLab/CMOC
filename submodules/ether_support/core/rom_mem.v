`timescale 1ns / 1ns

module rom_mem(
	input [2:0] addr,
	output reg [31:0] data
);

always @(*) case(addr)
   3'b001: data = "Hell";
   3'b010: data = "o wo";
   3'b011: data = "rld!";
   default: data = 32'hdeadbeef;
endcase
endmodule
