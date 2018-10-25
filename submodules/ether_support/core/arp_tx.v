`timescale 1ns / 1ns
module arp_tx(
	input clk,  // timespec 6.8 ns
	// signals that trigger ARP reply
	input [10:0] arp_bus,
	// port to set MAC and IP address during initialization
	input [8:0] address_set,
	// to priority encoder in head_tx
	output arp_reply_req,
	input strobe,
	output [7:0] data_out
);

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2};  // 192.168.7.2
parameter [47:0] mac = 48'h125555000130;  // should always be overridden

wire [7:0] reply_data = arp_bus[7:0];
wire reply_write = arp_bus[8];
wire arp_reply_strobe = arp_bus[9];
wire arp_reply_ok = arp_bus[10];
wire arp_data_pull;  // forward reference
wire arp_addr_reset; // forward reference

// Step 1: squirrel away the MAC and ARP of the requester
// XXX interlock reads and writes
reg [7:0] reply_mem [0:15];
reg [3:0] reply_ix=0;
always @(posedge clk) begin
	if (reply_write) reply_mem[reply_ix] <= reply_data;
	if (reply_write | arp_data_pull) reply_ix <= reply_ix+1;
	if (arp_addr_reset) reply_ix <= 0;
end
wire [7:0] request_data=reply_mem[reply_ix];

// Local memory for our IP address.
wire [3:0] ipn;
wire [7:0] ip1;
macip_config #(.ip(ip), .mac(mac)) macip(.clk(clk),
	.address_set(address_set),
	.ipn(ipn), .ip1(ip1));

// Static template memory for pattern generator
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
	4'd05: template <= 8'h02;   // ARP protocol operation (reply)
	default: template <= 8'h00;
endcase

// XXX decide if we really want to generate Ethernet (MAC) header here
// total input packet length = 12 + 10 + 10 + 10 + padding + 4 = >46
// 0: template
// 1: local memory
// 2: requester memory
reg [1:0] mode=0;
reg [5:0] pack_cnt=0;
always @(posedge clk) case (pack_cnt[5:1])  // valid for first 32 octets
	5'd00: mode <= 2;  // start of dest MAC (them)
	5'd01: mode <= 2;
	5'd02: mode <= 2;
	5'd03: mode <= 1;  // start of source MAC (us)
	5'd04: mode <= 1;
	5'd05: mode <= 1;
	5'd06: mode <= 0;
	5'd07: mode <= 0;
	5'd08: mode <= 0;
	5'd09: mode <= 0;
	5'd10: mode <= 0;
	5'd11: mode <= 1;  // start of source MAC
	5'd12: mode <= 1;
	5'd13: mode <= 1;
	5'd14: mode <= 1;  // start of source IP
	5'd15: mode <= 1;
	5'd16: mode <= 2;  // start of dest MAC
	5'd17: mode <= 2;
	5'd18: mode <= 2;
	5'd19: mode <= 2;  // start of dest IP
	5'd20: mode <= 2;
	default: mode <= 0;
endcase

reg [7:0] data_mux;
reg strobe1=0, strobe2=0, arp_reply_req_r=0;
always @(posedge clk) begin
	strobe1 <= strobe;
	strobe2 <= strobe1;  // data_max valid according to this guy?
	pack_cnt <= strobe ? (pack_cnt+1'b1) : 6'b0;
	data_mux <= mode==2 ? request_data : mode==1 ? ip1 : template;
	arp_reply_req_r <= arp_reply_strobe & arp_reply_ok;
end
assign temp_add = pack_cnt[3:0];
assign arp_data_pull = (mode==2) & strobe1;
assign arp_addr_reset = (mode==0) | arp_reply_strobe;
assign ipn = ~pack_cnt[3:0];

assign arp_reply_req = arp_reply_req_r;
assign data_out = data_mux;

endmodule
