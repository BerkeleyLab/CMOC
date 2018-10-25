`timescale 1ns / 1ns
module arp_rx(
	// input data
	input clk,           // timespec 6.8 ns
	input [7:0] data,
	input h_data,
	input crc_strobe,    // follows end of h_data by a clock cycle
	input crc_ok,
	// port to set IP address during initialization
	input [8:0] address_set,
	// signals to trigger ARP reply
	output [10:0] arp_bus
);

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2};  // 192.168.7.2
parameter [47:0] mac = 48'h125555000131;  // not really used

// Static template memory for pattern matcher
reg [7:0] template=0;
wire [3:0] temp_add;
always @(posedge clk) case(temp_add)
	// template starts at 12th byte of Ethernet packet,
	// after the two (totally ignored) MAC addresses.
	4'd12: template <= 8'h08;
	4'd13: template <= 8'h06;
	4'd14: template <= 8'h00;   // ARP Ethernet hardware, octet 1
	4'd15: template <= 8'h01;   // ARP Ethernet hardware, octet 2
	4'd00: template <= 8'h08;   // ARP Protocol IP
	4'd01: template <= 8'h00;   // ARP Protocol IP
	4'd02: template <= 8'h06;   // ARP protocol address length
	4'd03: template <= 8'h04;   // ARP protocol address length
	4'd04: template <= 8'h00;   // ARP protocol operation
	4'd05: template <= 8'h01;   // ARP protocol operation (request)
	default: template <= 8'h00;
endcase

// After the above accounted-for 12+10 octets, always save the next
//   6 octets (sender MAC)
//   4 octets (sender IP)
// Ignore the next 6 octets, placeholder for our MAC
//   only generate a response if the following 4 octets match our
//   IP address
// That response will mirror the packet received, with local and
//   remote MAC+IP interchanged, and 1==request changed to 2==reply.

// Local memory for our IP address.
wire [3:0] ipn;
wire [7:0] ip1;
macip_config #(.ip(ip), .mac(mac)) macip(.clk(clk),
	.address_set(address_set),
	.ipn(ipn), .ip1(ip1));

// total input packet length = 12 + 10 + 10 + 10 + padding + 4 = >46
// 0: ignore
// 1: ignore, send to output
// 2: must match template
// 3: must match IP
reg [1:0] mode=0;
reg [6:0] pack_cnt=0;
always @(posedge clk) case (pack_cnt[5:1])  // valid for first 64 octets
	5'd00: mode <= 0;
	5'd01: mode <= 0;
	5'd02: mode <= 0;
	5'd03: mode <= 0;
	5'd04: mode <= 0;
	5'd05: mode <= 0;
	5'd06: mode <= 2;
	5'd07: mode <= 2;
	5'd08: mode <= 2;
	5'd09: mode <= 2;
	5'd10: mode <= 2;
	5'd11: mode <= 1;
	5'd12: mode <= 1;
	5'd13: mode <= 1;
	5'd14: mode <= 1;
	5'd15: mode <= 1;
	5'd16: mode <= 0;
	5'd17: mode <= 0;
	5'd18: mode <= 0;
	5'd19: mode <= 3;
	5'd20: mode <= 3;
	default: mode <= 0;
endcase

reg h_data1=0, keep=0, reply_write_r=0, deserves_response=0;
reg arp_reply_strobe_r=0, arp_reply_ok_r=0;
reg [7:0] data1=0, data2=0;
always @(posedge clk) begin
	pack_cnt <= h_data ? (pack_cnt+1'b1) : 7'b0;
	h_data1 <= h_data;
	data1 <= data;
	data2 <= data1;
	if (h_data & !h_data1) keep <= 1;
	if (h_data1 & (mode==2) & (data1!=template)) keep <= 0;
	if (h_data1 & (mode==3) & (data1!=ip1)) keep <= 0;
	reply_write_r <= h_data & (mode==1) & keep;
	if (reply_write_r) deserves_response <= 1;
	if (arp_reply_strobe_r) deserves_response <= 0;
	arp_reply_strobe_r <= crc_strobe & deserves_response;
	arp_reply_ok_r <= keep & crc_ok;
end

assign ipn = {2'b0,pack_cnt[1],~pack_cnt[0]};
assign temp_add = pack_cnt[3:0];

// Keep this synchronized with arp_tx.v
assign arp_bus = {arp_reply_ok_r, arp_reply_strobe_r, reply_write_r, data2};

endmodule
