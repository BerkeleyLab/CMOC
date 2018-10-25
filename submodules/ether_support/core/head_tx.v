`timescale 1ns / 1ns

module head_tx #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	// chain to all the clients
	output [9:0] out_c,
	// input to arbiter
	input [15:0] tx_request,
	// from tail_tx
	input [jumbo_dw-1:0] payload_len,
	// Make UDP source port available to Ethernet packet assembly
	input port_bsel,
	output [7:0] port_byte,
	output arp_mode,
	output icmp_mode
);

reg [3:0] client_sel=0;
wire port_hi;

// 16 ports of 16-bits each, split into octets
// For the whole system to work right, the port_rom contents
// have to be consistent with the wiring of tx_request and
// the port parameters to those modules.
// port_rom module should be machine generated.
port_rom pr(.addr({client_sel,port_hi}),.data(port_byte));

// 16-to-4 priority encoder
wire [3:0] which;
wire hit;
pri_en16 pe(.inp(tx_request), .which(which), .hit(hit));

// head-end state
reg h_idle=1, h_port1=0, h_port2=0, h_len1=0, h_len2=0, h_head=0, h_data=0, h_gap=0;
reg [5:0] head_cnt=0;
reg [jumbo_dw:0] data_cnt=0;
reg [6:0] gap_cnt=0;
assign port_hi = (h_head|h_data)?port_bsel:h_port2;
always @(posedge clk) begin
	if (h_idle & hit) begin
		h_idle <= 0; h_port1 <= 1; client_sel <= which;
	end
	if (h_port1) begin
		h_port1 <= 0; h_port2 <= 1;
	end
	if (h_port2) begin
		h_port2 <= 0; h_len1 <= 1;
	end
	if (h_len1) begin
		h_len1 <= 0; h_len2 <= 1;
	end
	if (h_len2) begin
		h_len2 <= 0; h_head <= 1;
	end
	if (h_head & head_cnt==1) begin
		h_head <= 0; h_data <= 1;
	end
	if (h_data & data_cnt==1) begin
		h_data <= 0; h_gap <= 1;
	end
	if (h_gap & gap_cnt==1) begin
		h_gap <= 0; h_idle <= 1;
	end

	// length of h_head state has to exactly match the header processing
	// phase in assemble_eth, so the data arrives at the end of the header
	head_cnt <= h_head ? (head_cnt-1) : 48;
	data_cnt <= h_data ? (data_cnt-1) : payload_len;
	gap_cnt <= h_gap ? (gap_cnt-1) : 13;
end
// The length of h_gap (set by gap_cnt logic) needs to accommodate at least
//   8-byte Preamble (actually not, overlaps IP header checksum calculation)
//   2-byte UDP checksum fake (if ever added)
//   4-byte Ethernet CRC
//  12-byte standard minimum IFG
// The gap_cnt programming above is set to give exactly 96 ns between GMII
// strobes.  Feel free to increase gap_cnt to give the host computer a break.

// The only data sent down out_c from here is the port selection.
// Send 18 as the default payload length, in case someone *cough*ARP*cough*
// doesn't override it.
wire port_tx = h_port1 | h_port2;
wire out_p = h_port2;
wire out_m = h_data;  // per-client multiplexer control
reg [8:0] out_c_r=0;  // well, most of out_c
always @(posedge clk) begin
	out_c_r <= {out_p, port_tx ? port_byte : h_len2 ? 8'd18 : 8'b0};
end
assign out_c = {out_m, out_c_r};
assign arp_mode=(client_sel==7);
assign icmp_mode=(client_sel==6);

endmodule
