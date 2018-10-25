`timescale 1ns / 1ns
// Larry Doolittle, LBNL, November 2015
// Four cycles, 21 ns
module lin_curves(
	input clk,
	input [1:0] qphase,
	input [15:0] mag,
	// Host-settable simple control
	input [0:0] bank,  // external
	// Host-settable ROM
	input signed [15:0] offset_rom,  // external
	input signed [10:0] slope_rom,  // external
	output [7:0] offset_rom_addr,  // external address for offset_rom
	output [7:0] slope_rom_addr,  // external address for slope_rom
	// Final output
	output signed [15:0] curve
);

parameter extra_delay=0;

// Start right up
// 1 + 2 + 5 = 8
assign offset_rom_addr = {bank, qphase, mag[15:11]};
assign slope_rom_addr = {bank, qphase, mag[15:11]};

// First cycle
wire [15:0] mag1;
reg_delay #(.dw(16), .len(1+extra_delay)) match1(.clk(clk), .gate(1'b1),
	.din(mag), .dout(mag1));  //  phase match to response from roms
wire [15:0] offset_rom1;
reg_delay #(.dw(16), .len(0+extra_delay)) match2(.clk(clk), .gate(1'b1),
	.din(offset_rom), .dout(offset_rom1));
wire [10:0] slope_rom1;
reg_delay #(.dw(11), .len(0+extra_delay)) match3(.clk(clk), .gate(1'b1),
	.din(slope_rom), .dout(slope_rom1));

// Second cycle
reg signed [27:0] prod=0, prod1=0;
reg signed [15:0] offs1=0, offs2=0;
always @(posedge clk) begin
	prod <= $signed({1'b0,mag1[10:0]}) * slope_rom1;
	prod1 <= prod;
	offs1 <= offset_rom1;
	offs2 <= offs1;
end

// Third cycle
reg signed [15:0] sum = 0;
always @(posedge clk) begin
	sum <= offs2 + $signed(prod1[26:11]);
end

assign curve = sum;

endmodule
