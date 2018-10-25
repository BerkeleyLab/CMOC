// -------------------------------------------------------------------------------
// -- Title      : ICMP transmit module
// -- Project    : LBNL PSPEPS
// -------------------------------------------------------------------------------
// -- File Name  : icmp_tx.v
// -- Author     : Qiang Du
// -- Company    : LBNL
// -- Created    : 08-25-2014
// -- Last Update: 09-05-2014 11:46:08
// -- Standard   : Verilog
// -------------------------------------------------------------------------------
// -- Description:
// -------------------------------------------------------------------------------
// 1. Swap source ip and dest ip
// 2. change message type from 0x08 (request) -> 0x00 (reply)
// 3. Transmit the new frame with the same source quench and data field.
// -------------------------------------------------------------------------------
// -- Copyright (c) LBNL
// -------------------------------------------------------------------------------

`timescale 1ns / 1ns

module icmp_tx (
    input clk,
    input [10:0] icmp_bus,
    // port to set IP address during initialization
    input [8:0] address_set,
    // to priority encoder in head_tx
    output reply_req,
    input strobe,
    output [7:0] data_out
);

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2};  // 192.168.7.2
parameter [47:0] mac = 48'h12555500012f;  // should always be overridden

wire [7:0] reply_data = icmp_bus[7:0];
wire reply_write = icmp_bus[8]; // enable storing data from rx packet
wire reply_strobe = icmp_bus[9];
wire reply_ok = icmp_bus[10];
wire icmp_data_pull;  // forward reference
wire icmp_addr_reset; // forward reference

// Step 1: store requester's mac(6) + ip(4) + checksum(2) + quench(4) + load(32) + crc(4)
reg [7:0] reply_mem [0:127];
reg [6:0] reply_ix=0;
always @(posedge clk) begin
    if (reply_write & ~strobe) reply_mem[reply_ix] <= reply_data;
    if ((reply_write & ~strobe) | (strobe & icmp_data_pull)) reply_ix <= reply_ix+1;
    if (icmp_addr_reset) reply_ix <= 0;
end

wire [7:0] request_data=reply_mem[reply_ix];
// Local memory for our IP address.
wire [3:0] ipn;
wire [7:0] ip1;
// assign ipn = ~pack_cnt[3:0]; // good for mac
// assign ipn = ~pack_cnt[3:0] - 2; // good for ip
wire [3:0] ipn_off = pack_cnt>25 ? 4'd14 : 0;
assign ipn = ~pack_cnt[3:0] + ipn_off;
macip_config #(
    .ip(ip), .mac(mac)
) macip(
    .clk(clk),
    .address_set(address_set),
    .ipn(ipn),
    .ip1(ip1)
);


// Template memory.
reg [7:0] template=0;
always @(posedge clk) case (pack_cnt[6:0])
	6'd12: template <= 8'h08;  // Ether type
	6'd13: template <= 8'h00;
	// Start of IP header
	6'd14: template <= 8'h45;  // Vers/IHL
	6'd15: template <= 8'h00;  // TOS
	6'd20: template <= 8'h00;  // Flags/Fragment
	6'd21: template <= 8'h00;
	6'd23: template <= 8'h01;  // Proto (ICMP)
	6'd24: template <= 8'h00;  // IP checksum
	6'd25: template <= 8'h00;  // IP checksum
	6'd34: template <= 8'h00;  // ICMP echo reply
	6'd35: template <= 8'h00;  // ICMP code
	default: template <= 8'h00;
endcase

// 0: template
// 1: local memory
// 2: requester memory
reg [1:0] mode=0;
always @(posedge clk) case (pack_cnt[6:1])  // valid for first 128 octets
	5'd00, 5'd01, 5'd02: mode <= 2;  // dest MAC (them)
	5'd03, 5'd04, 5'd05: mode <= 1;  // source MAC (us)
	5'd06: mode <= 0;  // Ether type
	5'd07: mode <= 0;  // IP header Ver/IHL
	5'd08: mode <= 2;  // Length
	5'd09: mode <= 2;  // Identification
	5'd10: mode <= 2;  // Flags/fragment
        5'd11: case (pack_cnt[6:0])
            7'd22: mode <= 2;  // TTL
            7'd23: mode <= 0;  // ICMP Protocol
        endcase
	5'd12: mode <= 2;  // IP checksum
	5'd13: mode <= 1;  // start of us IP
	5'd14: mode <= 1;
	5'd15: mode <= 2;  // start of them IP
	5'd16: mode <= 2;
        5'd17: mode <= 0;  // ICMP header (echo reply)
	default: mode <= 2;
endcase

// packet counter
reg [6:0] pack_cnt=0;
reg [7:0] data_mux;
reg strobe1=0, strobe2=0, reply_req_r=0;
always @(posedge clk) begin
	strobe1 <= strobe;
	strobe2 <= strobe1;  // data_max valid according to this guy?
	pack_cnt <= strobe ? (pack_cnt+1'b1) : 6'b0;
	data_mux <= mode==2 ? request_data : mode==1 ? ip1 : template;
	reply_req_r <= reply_strobe & reply_ok;
end
assign icmp_data_pull = (mode==2) & strobe1;
// XXX need to reset icmp_addr after icmp_data_pull finishes.
assign icmp_addr_reset = reply_strobe | (~strobe & strobe1);
assign reply_req = reply_req_r;
assign data_out = data_mux;
endmodule
