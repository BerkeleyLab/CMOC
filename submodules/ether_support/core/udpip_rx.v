`timescale 1ns / 1ns
module udpip_rx #(
	parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2},  // 192.168.7.2
	parameter [47:0] mac = 48'h12555500012b,  // not really used
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	// input data
	input clk,   // timespec 6.8 ns
	input [7:0] data,
	input h_data,
	input crc_strobe,    // follows end of h_data by a clock cycle
	input crc_ok,
	// port to set IP address during initialization
	input [8:0] address_set,
	// chain to all the clients
	output [11:0] out_c,
	// connection to shared memory
	output [4:0] shmem_a,
	output [7:0] shmem_d,
	output shmem_wen,
	input shmem_idle,
	output reg shmem_bank
);

// Local memory for our IP address.
wire [3:0] ipn;
wire [7:0] ip1;
macip_config #(.ip(ip), .mac(mac)) macip(.clk(clk),
	.address_set(address_set),
	.ipn(ipn), .ip1(ip1));

reg [jumbo_dw-1:0] pack_cnt=0;
always @(posedge clk) begin
	pack_cnt <= h_data ? pack_cnt+1 : 0;
end
assign ipn = 2 + ~pack_cnt[3:0];

// Template memory.
reg [7:0] template=0;
always @(posedge clk) case (pack_cnt[5:0])
	6'd12: template <= 8'h08;  // Proto
	6'd13: template <= 8'h00;
	// Start of IP header
	6'd14: template <= 8'h45;  // Vers/IHL
	6'd15: template <= 8'h10;
	6'd20: template <= 8'h00;  // Flags/Fragment
	6'd21: template <= 8'h00;
	6'd22: template <= 8'h20;  // TTL
	6'd23: template <= 8'h11;  // Proto (UDP)
	default: template <= 8'h55;
endcase

// Select which of the above octets need to match to be
// considered a UDP packet
reg udp_req=0;
always @(posedge clk) case(pack_cnt[5:0])
	// No compelling reason to check MAC address in this context
	// Byte 14 (Vers/IHL) is weird; proper to demand length of 5
	//     since we don't handle IP options.
	// Byte 20 (flags/fragment) is a problem: DF flag (0x40) is OK, MF
	//     flag and fragment (0xbf) are not.  Special case below.
	// Bytes 30-33 are our IP address
	6'd12, 6'd13, 6'd14, 6'd20, 6'd21, 6'd23:
		udp_req <= 1;
	default:
		udp_req <= 0;
endcase

// Packet matching is pretty simple at this point
// Previous code explicitly checked for 0x00 and 0xff, so we could
// in parallel look for e.g., broadcast and actual MAC address.
reg t_match=0, pack_cnt_low=0, udp_req1=0, udp_match=0, mask_df_bit=0;
reg p_match_time=0, p_fail=0; // IP memory match
wire [7:0] df_mask={1'b1, ~mask_df_bit, 6'h3f};
reg [7:0] data1=0;
reg chksum_fail=0, ip_l_error=0;
reg multicast_mac=0;
// https://en.wikipedia.org/wiki/MAC_address#Address_details
always @(posedge clk) begin
	data1 <= h_data ? data : 8'b0;  // add 1 byte for CRC test XXX avoid?
	pack_cnt_low <= pack_cnt[jumbo_dw-1:6]==0;
	udp_req1 <= udp_req & pack_cnt_low;
	mask_df_bit <= pack_cnt==20;
	p_match_time <= (pack_cnt[jumbo_dw-1:1]==15) | (pack_cnt[jumbo_dw-1:1]==16);
	t_match <= ((data1&df_mask) == template) & (pack_cnt[7:6]==0);
	p_fail  <=  (data1 != ip1) & p_match_time & ~multicast_mac;
	if (h_data & (pack_cnt==1)) multicast_mac <= data1[0];  // low-order bit of first MAC octet
	if (h_data & (pack_cnt==0)) udp_match <= 1;
	if (~h_data | (~t_match & udp_req1) | p_fail | chksum_fail | ip_l_error) udp_match <= 0;
end

// UDP Datagram length
// XXX check if consistent with IP packet length and Ethernet frame length
// reg [15:0] pack_length= 16'hffff;
reg [7:0] data2=0;
reg [jumbo_dw-1:0] pack_cnt2=8, ip_length_m20=0;
reg pack_strobe=0, pack_cnt2_op=0;
reg pack_cnt_39=0, pack_cnt_40=0, pack_cnt_41=0;
always @(posedge clk) begin
	data2 <= data1;  // XXX am I the only subsection to want this?
	pack_cnt_39 <= (pack_cnt==38) & udp_match;
	pack_cnt_40 <= pack_cnt_39;
	pack_cnt_41 <= pack_cnt_40;
	if (pack_cnt_39 | pack_cnt_40 | pack_cnt2==8) pack_cnt2_op <= pack_cnt_39 | pack_cnt_40; // XXX ugly
	if (pack_cnt2_op) pack_cnt2 <= pack_cnt_40 ? {data2,data1} : (pack_cnt2-1);
	ip_l_error <= pack_cnt_41 & (pack_cnt2!=ip_length_m20);
	pack_strobe <= (pack_cnt2>8);
	// if (pack_cnt==1) pack_length <= 16'hffff;
	// if (pack_cnt_39) pack_length[15:8] <= data1;
	// if (pack_cnt_40) pack_length[7:0] <= data1;
	// pack_strobe <= (pack_cnt>33) & (pack_cnt<(34+pack_length));
end

//check consistency IP - UDP length
reg pack_cnt_17=0;
always @(posedge clk) begin
	pack_cnt_17 <= pack_cnt==17;
	if (pack_cnt_17) ip_length_m20 <= {data2,data1}-20;  // IP packet length (no Ethernet header(14), no CRC(4))
end

// Select which of the above octets are written to the shared memory
reg shmem_sel=0;
initial shmem_bank=0;
always @(posedge clk) case(pack_cnt[5:0])
	6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd11, // MAC
	6'd26, 6'd27, 6'd28, 6'd29, // IP
	6'd34, 6'd35: // UDP port
		shmem_sel <= 1;
	default:
		shmem_sel <= 0;
endcase
reg [3:0] shmem_ar=0;
reg shmem_change=0;
reg shmem_busy=0;  // our status, vs. shmem_idle which is assemble_eth's
reg shmem_busy1=0;
always @(posedge clk) begin
	shmem_busy <= h_data & (pack_cnt < 40);
	shmem_busy1 <= shmem_busy;
	if (shmem_sel | (h_data & (pack_cnt==0))) shmem_ar <= shmem_sel ? shmem_ar+1 : 0;
	if (~shmem_busy & shmem_busy1 & udp_match) shmem_change <= 1;  // falling edge
	if (shmem_change & shmem_idle & ~shmem_busy) begin
		shmem_bank <= ~shmem_bank;
		shmem_change <= 0;
	end
end
assign shmem_a = {~shmem_bank,shmem_ar};
assign shmem_d = data1;
assign shmem_wen = shmem_sel;

// Next step in the octet processing pipeline is to compute
// the IP header checksum.

// Corrupt IP header checksum sets h_drop to 1 => drops the packet
// before anything is sent to clients

reg [7:0] out_chksum=0, out_chksum1=0;
reg out_chksum_carry=0, out_chksum_all_ones=0;
reg out_chksum_gate=0, out_chksum_zero=0;
always @(posedge clk) begin
	out_chksum_gate <= ((pack_cnt[jumbo_dw-1:1]>=7) & (pack_cnt[jumbo_dw-1:1]<17));
	out_chksum_zero <= pack_cnt==0;
	if (out_chksum_gate | out_chksum_zero) begin
		{out_chksum_carry, out_chksum} <=
			(out_chksum_zero?0:out_chksum1) +
			(out_chksum_gate?data1:0) + out_chksum_carry;
		out_chksum1 <= out_chksum;
		out_chksum_all_ones <= &out_chksum;
	end
	chksum_fail <= (pack_cnt==35) & (~out_chksum_all_ones | ~(&out_chksum));
end

// start the Rx chain
reg out_l=0, out_s=0, out_p=0;
always @(posedge clk) begin
	out_l   <= udp_match & (pack_cnt[jumbo_dw-1:1]==19);            // datagram length
	out_s   <= udp_match & pack_strobe & h_data;            // data
	out_p   <= udp_match & (pack_cnt==37) & h_data;         // destination port
end

// CRC comes after datagram, so its mask bit is left to 1
// XXX put crc_ok in here somehow
assign out_c = {crc_strobe, out_l, out_s, out_p, data1};

endmodule
