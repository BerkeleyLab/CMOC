`timescale 1ns / 1ns

// Nominally 26 logic cells in a traditional Spartan3/Virtex2 FPGA.
// Maybe as few as 16 in a Virtex5 and higher.
module emux_tx2(
	clk,
	in_c,
	out_c,
	// selected client
	data,  // client data
	c_l,  // client length
	c_s,  // client strobe
	c_w,  // client warning (1 cycle advanced from strobe)
	c_a   // client ack
);
parameter [15:0] port1=0;
parameter [15:0] port2=0;
parameter jumbo_dw=14;
	input clk;
	input      [9:0] in_c;
	output reg [9:0] out_c;
	// selected client
	input [7:0]  data;  // client data
	input [jumbo_dw-1:0] c_l;  // client length
	output       c_s;  // client strobe
	output       c_w;  // client warning (1 cycle advanced from strobe)
        output       c_a;  // client ack
initial out_c=0;

wire       in_m = in_c[9];
wire       in_p = in_c[8];
wire [7:0] in_d = in_c[7:0];

// in_p is asserted for the second octet of incoming port number.
// this is followed by the high and low octet of the transmitted
// packet length.
reg in_l1=0, in_l2=0, d_sel=0;
reg port1_match1=0, port1_match2=0;
reg port2_match1=0, port2_match2=0;
wire port_match2 = port1_match2 | port2_match2;
always @(posedge clk) begin
	in_l1 <= in_p;
	in_l2 <= in_l1;
	d_sel <= in_m & port_match2;
end

wire [7:0] mux_d = ((in_l1 | in_l2) & port_match2) ?
	(in_l2 ? c_l[7:0] : {5'b0,c_l[jumbo_dw-1:8]} ) :
	(d_sel ? data : in_d );

always @(posedge clk) begin
	// network byte order: msb first
	port1_match1 <= (in_d == port1[15:8]);
	port2_match1 <= (in_d == port2[15:8]);
	if (in_p) port1_match2 <= (in_d == port1[7:0]) & port1_match1;
	if (in_p) port2_match2 <= (in_d == port2[7:0]) & port2_match1;
	out_c <= {in_m, in_p, mux_d};
end

assign c_w = in_m & port_match2;
assign c_s = d_sel;
assign c_a = in_l1 & port_match2;

endmodule
