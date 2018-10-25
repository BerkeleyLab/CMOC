`timescale 1ns / 1ns
module head_rx(
	input clk,
	input [7:0] eth_octet,
	input eth_strobe,
	// chain to all the clients
	output [11:0] out_c,
	// info for arp_tx
	output [10:0] arp_bus,
        // info for icmp tx
        output [10:0] icmp_bus,
	// connection to shared memory
	output [4:0] shmem_a,
	output [7:0] shmem_d,
	output shmem_wen,
	input shmem_idle,
	output shmem_bank,
	// port to set IP address during initialization
	input [8:0] address_set,
	// Start of packet flag -- grist for an activity LED
	output packet_start,
	// CRC OK status -- wire to LED?
	output crc_ok,
	output crc_fault,
	output debug
);

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2};  // 192.168.7.2
parameter [47:0] mac = 48'h125555000134;

reg h_idle=1, h_preamble=0, h_data=0, h_drop=0;
wire drop_packet=0;
always @(posedge clk) begin
	if (h_idle & eth_strobe) begin
		h_idle <= 0;
		if (eth_octet==8'h55) h_preamble <= 1;
		else h_drop <= 1;
	end
	if (h_preamble & eth_strobe & (eth_octet==8'hd5)) begin
		h_preamble <= 0; h_data <= 1;
	end else if (h_preamble & eth_strobe & (eth_octet!=8'h55)) begin
		h_preamble <= 0; h_drop <= 1;
	end
	if (h_data & ~eth_strobe) begin
		h_data <= 0; h_idle <= 1;
	end
	if (h_data & drop_packet) begin   // dangerous, probably shouldn't use
		h_data <= 0; h_drop <=1;
	end
	if (h_drop & ~eth_strobe) begin
		h_drop <= 0; h_idle <= 1;
	end
end

reg h_data1=0, data_first=0;
reg [7:0] data1=0;
always @(posedge clk) begin
	h_data1 <= h_data;
	data_first <= h_data & ~h_data1;
	data1 <= eth_strobe ? eth_octet : 8'b0;
end

`ifdef FUTURE_FEATURE
reg [10:0] pack_cnt=0;
always @(posedge clk) begin
	pack_cnt <= h_data ? pack_cnt+1'b1 : 11'b0;
end
`endif

wire crc_zero;
crc8e_guts crc(.clk(clk), .gate(h_data1), .first(data_first),
	.d_in(data1), .zero(crc_zero));

reg crc_zero_f=0, crc_report=0;
wire h_data_start=h_data1 & ~h_data;
reg crc_fault_r=0;
always @(posedge clk) begin
	if (h_data_start) crc_zero_f <= crc_zero;
	crc_fault_r <= h_data_start&~crc_zero;
	crc_report <= h_data1 & ~h_data;
end

// CRC propagates to clients in the data word flagged by out_c.
// This output is available to also light an LED.
assign crc_ok = crc_zero_f;

// ============
// == UDP/IP ==
// ============
udpip_rx #(.ip(ip), .mac(mac)) udp(.clk(clk),
	.data(data1), .h_data(h_data1),
	.crc_strobe(crc_report), .crc_ok(crc_zero_f),
	.address_set(address_set),
	.out_c(out_c),
	.shmem_a(shmem_a), .shmem_d(shmem_d), .shmem_wen(shmem_wen),
	.shmem_idle(shmem_idle), .shmem_bank(shmem_bank)
);

// =========
// == ARP ==
// =========
arp_rx #(.ip(ip), .mac(mac)) arp(.clk(clk),
	.data(data1), .h_data(h_data1),
	.crc_strobe(crc_report), .crc_ok(crc_zero_f),
	.address_set(address_set),
	.arp_bus(arp_bus)
);

// ============
// == ICMP/IP ==
// ============
icmp_rx #(
    .ip(ip),
    .mac(mac)
) icmp (
    .clk(clk),
    .data(data1),
    .h_data(h_data1),
    .crc_strobe(crc_report), .crc_ok(crc_zero_f),
    .address_set(address_set),
    .icmp_bus(icmp_bus)
);
assign crc_fault=crc_fault_r;
assign packet_start=data_first;
assign debug=eth_strobe;

endmodule
