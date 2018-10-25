`timescale 1ns / 1ns

module tail_tx #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	// chain from all the clients
	input [9:0] in_c,
	// info sent to head
	output reg [jumbo_dw-1:0] payload_len,
	// additional information needed to assemble Ethernet packet
	output start_header,
	output reg x_data,
	output [7:0] payload
);
	// Also need some flag and structure for selecting ARP replies?
wire       in_m = in_c[9];
wire       in_p = in_c[8];
wire [7:0] in_d = in_c[7:0];
initial payload_len=0;

// in_p is asserted for the second octet of incoming port number.
// this is followed by the high and low octet of the transmitted
// packet length.
reg in_l1=0, in_l2=0;
initial x_data=0;
always @(posedge clk) begin
	in_l1 <= in_p;
	in_l2 <= in_l1;
	if (in_l1) payload_len[jumbo_dw-1:8] <= in_d;
	if (in_l2) payload_len[ 7:0] <= in_d;
	x_data <= in_m;
end

assign start_header=in_p;
assign payload=in_d;
endmodule
