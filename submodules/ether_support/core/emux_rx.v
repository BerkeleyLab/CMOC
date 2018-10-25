`timescale 1ns / 1ns

module emux_rx(
	input clk,
	input      [11:0] in_c,
	output reg [11:0] out_c,
	// selected client
	output       ready,
	output       strobe,
	output       crc,
	output [7:0] data
);
parameter [15:0] port=0;
parameter jumbo_dw=14;

initial out_c=0;

wire in_crc = in_c[11];
// unused     in_c[10];
wire in_s   = in_c[9];
wire in_p   = in_c[8];
wire [7:0] in_d = in_c[7:0];


reg port_match1=0, port_match2=0, crc_reg=0;

assign ready=in_p & (in_d == port[7:0]) & port_match1;
always @(posedge clk) begin
	out_c <= in_c;
	crc_reg <= in_crc & port_match2;
	port_match1 <= (in_d == port[15:8]);
	if (in_p) port_match2 <= ready;
end

assign strobe = in_s & port_match2;
assign data = in_d;
assign crc = crc_reg;

endmodule
