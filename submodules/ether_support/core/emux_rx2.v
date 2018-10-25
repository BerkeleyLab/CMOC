`timescale 1ns / 1ns

module emux_rx2(
	input clk,
	input      [11:0] in_c,
	output reg [11:0] out_c,
	// selected client
	output [1:0] ready,
	output       strobe,
	output       crc,
	output [7:0] data
);
parameter [15:0] port1=0;
parameter [15:0] port2=0;
parameter jumbo_dw = 14;

initial out_c=0;

wire in_crc = in_c[11];
// unused     in_c[10];
wire in_s   = in_c[9];
wire in_p   = in_c[8];
wire [7:0] in_d = in_c[7:0];

reg port1_match1=0, port1_match2=0;
reg port2_match1=0, port2_match2=0;
wire port_match2 = port1_match2 | port2_match2;
reg crc_reg=0;

assign ready[0]=in_p & (in_d == port1[7:0]) & port1_match1;
assign ready[1]=in_p & (in_d == port2[7:0]) & port2_match1;
always @(posedge clk) begin
	out_c <= in_c;
	crc_reg <= in_crc & port_match2;
	port1_match1 <= (in_d == port1[15:8]);
	port2_match1 <= (in_d == port2[15:8]);
	if (in_p) port1_match2 <= ready[0];
	if (in_p) port2_match2 <= ready[1];
end

assign strobe = in_s & port_match2;
assign data = in_d;
assign crc = crc_reg;

endmodule
