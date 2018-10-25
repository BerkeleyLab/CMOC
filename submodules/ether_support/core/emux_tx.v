`timescale 1ns / 1ns

// Nominally 26 logic cells in a traditional Spartan3/Virtex2 FPGA.
// Maybe as few as 16 in a Virtex5 and higher.
module emux_tx #(
	parameter [15:0] port=0,
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	input      [9:0] in_c,
	output reg [9:0] out_c,
	// selected client
	input [7:0]  data,  // client data
	input [jumbo_dw-1:0] c_l,  // client length
	output       c_s,  // client strobe
	output       c_w,  // client warning (1 cycle advanced from strobe)
	output       c_a   // client ack
);

initial out_c=0;

wire       in_m = in_c[9];
wire       in_p = in_c[8];
wire [7:0] in_d = in_c[7:0];

// in_p is asserted for the second octet of incoming port number.
// this is followed by the high and low octet of the transmitted
// packet length.
reg in_l1=0, in_l2=0, d_sel=0;
reg port_match1=0, port_match2=0;
always @(posedge clk) begin
	in_l1 <= in_p;
	in_l2 <= in_l1;
	d_sel <= in_m & port_match2;
end

wire [7:0] mux_d = ((in_l1 | in_l2) & port_match2) ?
	(in_l2 ? c_l[7:0] : {{(16-jumbo_dw){1'b0}},c_l[jumbo_dw-1:8]} ) :
	(d_sel ? data : in_d );

always @(posedge clk) begin
	// network byte order: msb first
	port_match1 <= (in_d == port[15:8]);
	if (in_p) port_match2 <= (in_d == port[7:0]) & port_match1;
	out_c <= {in_m, in_p, mux_d};
end

assign c_w = in_m & port_match2;
assign c_s = d_sel;
assign c_a = in_l1 & port_match2;

endmodule
