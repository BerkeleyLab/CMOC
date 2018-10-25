`timescale 1ns / 1ns
module assemble_eth #(
	parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2},  // 192.168.7.2
	parameter [47:0] mac = 48'h125555000133,
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	// info supplied by head_tx
	output port_bsel,
	input [7:0] port_byte,
	input arp_mode,
	input icmp_mode,
	// info supplied by tail_tx
	input [jumbo_dw-1:0] payload_len,
	input start_header,
	input x_data,
	input [7:0] payload,

	// output to PHY
	output [7:0] eth_octet,
	output eth_strobe,

	// connection to RAM that holds remote machine's MAC and IP
	output [4:0] shmem_a,
	input [7:0] shmem_d,
	input shmem_bank,
	output shmem_idle,

	// port to set IP address during initialization
	input [8:0] address_set,

	// connection to arp_tx module
	output arp_reply_strobe,
	input [7:0] arp_data,
	output icmp_reply_strobe,
	input [7:0] icmp_data,

	output debug
);

// header (and pseudo header) octets for a UDP packet:
//  4 x source IP address
//  4 x dest IP address (dynamic)
//     (latter 8 octets used to solve causality in the IP header calculator)
// -- start of Ethernet header
//  6 x destination MAC
//  6 x source MAC
//  2 x proto  [08 00]
// -- start of IP header
//  2 x Vers/IHL/TOS  [45 10]
//  2 x total length (dynamic, payload length + 20 IP header + 8 UDP header + 2 trailer)
//  2 x Identification  [00 00]
//  2 x Flags/Fragment offset  [00 00]
//  2 x TTL/Proto  [20 11] (consider setting the DF (don't fragment) flag)
//  2 x header checksum (dynamic)
//  4 x source IP address
//  4 x dest IP address
// -- start of UDP header
//  2 x UDP source port
//  2 x UDP dest port
//  2 x length (dynamic, payload length + 8 header + 2 trailer)
//  2 x dummy checksum, or zero for no checksum
// ---
// 50 total, 32 non-dynamic, followed by UDP data

// octets for an ICMP reply packet:
// --start of Ethernet Header
//  6 x destination MAC (them)
//  6 x source MAC (us)
//  2 x proto  [08 00]
// -- start of IP header
//  2 x Vers/IHL/TOS  [45 00]
//  2 x total length (dynamic, payload length + 20 IP header + 8 ICMP header)
//  2 x Identification  [00 00]
//  2 x Flags/Fragment offset  [00 00]
//  2 x TTL/Proto  [40 01]
//  2 x header checksum (dynamic)
//  4 x source IP address
//  4 x dest IP address
// -- start of ICMP header
//  2 x ICMP Type + code [00 00]
//  2 x ICMP checksum
//  4 x Quench
//  ---
// 50 total, followed by ICMP data

// octets for an ARP reply packet:
// -- start of Ethernet header
//  6 x destination MAC (them)
//  6 x source MAC (us)
//  2 x proto  [08 06]
// -- start of ARP content
//  2 x hardware type  [00 01]
//  2 x protocol  [08 00]
//  2 x addrlen  [06 04]
//  2 x operation  [00 02]
//  6 x reply source MAC (us)
//  4 x reply source IP (us)
//  6 x reply dest MAC (them)
//  4 x reply dest IP (them)
//  ---
//  50 total with pseudo-header, 42 real, followed by at least
//    18 octets padding to minimum Ethernet packet length


// Ethernet minimum packet length is 64 octets, including its header and
// 4-byte CRC, but not the preamble.  Subtracting CRC, 14 byte Ethernet
// header, 20 byte IP header, and 8 byte UDP header, that leaves 18 byte
// minimum UDP payload size.  Or 16 bytes, if this module adds a 2 byte
// UDP checksum workaround trailer.

reg [5:0] head_cnt=0;
reg [3:0] shmem_cnt=0;
reg m_header=0;
reg x_data1=0, x_data2=0, x_data3=0, x_data4=0;  // pipeline
reg shmem_adv=0;

always @(posedge clk) begin
	x_data1 <= x_data;
	x_data2 <= x_data1;
	x_data3 <= x_data2;
	x_data4 <= x_data3;
	if (start_header | x_data2) m_header <= start_header;
	head_cnt <= (start_header|m_header) ? head_cnt+1'b1 : 6'b0;
	shmem_cnt <= (head_cnt==0) ? 4'd6 : (head_cnt == 7) ? 4'b0 : (shmem_cnt+shmem_adv);
end
// Ping-pong host config with atomic update; head_rx is the master,
// only changes shmem_bank when I say it's OK with shmem_idle.
assign shmem_a = {shmem_bank,shmem_cnt};
assign shmem_idle = ~m_header;  // could refine this a little

always @(*) case(head_cnt)
	6'd4, 6'd5, 6'd6, 6'd7,  // IP (chksum)
	6'd8, 6'd9, 6'd10, 6'd11, 6'd12, 6'd13,  // MAC
	6'd38, 6'd39, 6'd40, 6'd41,  // IP
	6'd44, 6'd45:  // UDP
		shmem_adv=1;
	default:
		shmem_adv=0;
endcase

// Local memory for our IP address.
wire [3:0] ipn;
wire [7:0] ip1;
macip_config #(.ip(ip), .mac(mac)) macip(.clk(clk),
	.address_set(address_set),
	.ipn(ipn), .ip1(ip1));

reg [1:0] src_sel=0;
// src_sel=0   them MAC,IP
// src_sel=1   us MAC,IP
// src_sel=2   template
// src_sel=3   port number
always @(posedge clk) case(head_cnt[5:1])
	// first four words are pseudo-header for IP checksum
	5'd0, 5'd1:       src_sel<=1;   // Source IP
	5'd2, 5'd3:       src_sel<=0;   // Dest IP
	// actual Ethernet packet start
	5'd4, 5'd5, 5'd6: src_sel<=0;   // Dest MAC
	5'd7, 5'd8, 5'd9: src_sel<=1;   // Source MAC
	5'd10, 5'd11, 5'd12, 5'd13, 5'd14,
	5'd15, 5'd16:     src_sel<=2;   // Proto, IP header, checksum
	5'd17, 5'd18:     src_sel<=1;   // Source IP
	5'd19, 5'd20:     src_sel<=0;   // Dest IP
	5'd21:            src_sel<=3;   // Source port
	5'd22:            src_sel<=0;   // Dest port
	5'd23, 5'd24:     src_sel<=2;   // Length (overwritten), checksum
	default:          src_sel<=2;   // garbage
endcase

//assign ipn = 4 + ~head_cnt[3:0];  // good for Source IP,  head_cnt  0-3
//assign ipn = 8 + ~head_cnt[3:0];  // good for Source MAC, head_cnt 14-19
//assign ipn = 6 + ~head_cnt[3:0];  // good for Source IP,  head_cnt 34-39
wire [3:0] ipn_off = 4 + {1'b0,|head_cnt[4:3],head_cnt[5],1'b0};
assign ipn = ipn_off + ~head_cnt[3:0];

reg [7:0] template=0;
always @(posedge clk) case(head_cnt[3:0])
	// Alias from head_cnt=20
	6'd04: template <= 8'h08;  // Proto
	6'd05: template <= 8'h00;
	// Start of IP header
	6'd06: template <= 8'h45;  // Vers/IHL
	6'd07: template <= 8'h10;  // TOS
	6'd08: template <= 8'h00;  // Total length (overwritten by total, below)
	6'd09: template <= 8'h00;
	6'd10: template <= 8'h00;  // Identification
	6'd11: template <= 8'h00;
	6'd12: template <= 8'h00;  // Flags/Fragment
	6'd13: template <= 8'h00;
	6'd14: template <= 8'h20;  // TTL
	6'd15: template <= 8'h11;  // Proto (UDP)
	// Alias from head_count=48
	6'd00: template <= 8'h00;  // datagram checksum
	6'd01: template <= 8'h00;
	default: template <= 8'h00;
endcase

// Multiplex payload, template ROM, source UDP port.
// src_sel=0   them MAC,IP
// src_sel=1   us MAC,IP
// src_sel=2   template
// src_sel=3   port number
reg [7:0] data1=0;
// src_sel and each data source should be one cycle pipelined from head_cnt
always @(posedge clk) begin
	data1 <= x_data ? payload : src_sel[1] ?
		(src_sel[0] ? port_byte : template) :
		(src_sel[0] ? ip1 : shmem_d);
end

assign port_bsel = ~head_cnt[0];  // control addressing of port ROM in head_tx

// Stuff lengths in there too
//   head_cnt[5:1]==8   IP total packet length = payload_len + 30
//   head_cnt[5:1]==18  UDP datagram length = payload_len + 10
reg mux_2=0, mux_3=0;
reg [jumbo_dw-1:0] total=0;
reg [7:0] data2=0;
wire [7:0] total_byte = head_cnt[0] ? total[7:0] : {5'b0,total[jumbo_dw-1:8]};
always @(posedge clk) begin
	mux_2 <= (head_cnt[5:1]==(8+4)) | (head_cnt[5:1]==(19+4));
	mux_3 <= mux_2;
	total <= payload_len + ((head_cnt[5]) ? 11'd8 : 11'd28 );
	data2 <= mux_3 ? total_byte : data1;
end

wire [7:0] data2x = icmp_mode ? icmp_data : data2;
// ICMP length comes from rx at mux_4
reg [15:0] icmp_len=0;
reg icmp_reply_strobe1=0, icmp_reply_strobe2=0, icmp_reply_strobe3=0;
reg mux_4=0, m_icmp=0;
reg [6:0] pack_cnt=0;
reg [15:0] icmp_len_total=0;
always @(posedge clk) begin
    mux_4 <= mux_3 & ~head_cnt[5];
    if (mux_4) icmp_len <= {icmp_len[7:0], data2x};
    // 8 + 1(delay) + 14(ether head) = 23, 28 + 1(delay) = 29
    icmp_len_total <= icmp_len + (pack_cnt>28 ? 5'd23 : 5'd29);
    if (start_header | &pack_cnt) m_icmp <= start_header;
    pack_cnt <= (start_header|m_icmp) ? (pack_cnt + 1'b1) : 6'b0;
    icmp_reply_strobe1 <= icmp_reply_strobe;
    icmp_reply_strobe2 <= icmp_reply_strobe1;
    icmp_reply_strobe3 <= icmp_reply_strobe2;
end
assign icmp_reply_strobe = icmp_mode & (pack_cnt>8) & (pack_cnt<=icmp_len_total);

// Next step in the octet processing pipeline is to compute
// and insert the IP header checksum.
// Input data is data2x, output data is data3.
// XXX also add UDP checksum fake trailer (will require adding another
// two bytes to the length computation above)
reg [7:0] out_chksum=0, out_chksum1=0, data3=0;
reg out_chksum_carry=0;
reg out_chksum_gate=0, out_chksum_sel=0, out_chksum_zero=0;
always @(posedge clk) begin
	out_chksum_gate <= (head_cnt[5:1]>0) & (head_cnt[5:1]<5) |
		(head_cnt[5:1]>(7+4)) & (head_cnt[5:1]<(13+4));
	out_chksum_sel  <= head_cnt[5:1]==(13+4);
	out_chksum_zero <= head_cnt==0;  // +4 ??
        // use RX IP chksum for ICMP
        data3 <= (out_chksum_sel & ~icmp_mode) ? ~(out_chksum1+out_chksum_carry) : data2x;
	if (out_chksum_gate|out_chksum_zero|out_chksum_sel) begin
		{out_chksum_carry, out_chksum} <=
			(out_chksum_zero?8'b0:out_chksum1) +
			(out_chksum_gate?data2x:8'b0) + out_chksum_carry;
		out_chksum1 <= out_chksum;
	end
end

reg ars_up=0, ars_dn=0, arp_reply_strobe_r=0;
always @(posedge clk) begin
	ars_up <= (head_cnt[5:2]==4'b0010);
	ars_dn <= (head_cnt[5:1]==5'b11010) | ~m_header;
	arp_reply_strobe_r <= arp_mode & ~ars_dn & (ars_up | arp_reply_strobe_r);
end

// assign arp_reply_strobe = arp_mode & (head_cnt>9) & (head_cnt<52);
assign arp_reply_strobe = arp_reply_strobe_r;
wire [7:0] data3x = arp_reply_strobe ? arp_data : data3;

reg [7:0] data4=0;
reg first_crc=0, gate_crc=0;
wire [7:0] crc_out;
reg [2:0] crc_cnt=0;
reg out_crc_sel=0, out_crc_sel1=0;

crc8e_guts #(.wid(32)) crc(.clk(clk), .gate(gate_crc),
	.first(first_crc), .d_in(out_crc_sel ? ~crc_out : data3x),
	.d_out(crc_out), .zero());

wire icmp_reply_strobe_up = ~icmp_reply_strobe & icmp_reply_strobe1;
wire x_data1_up = ~x_data1 & x_data2;
always @(posedge clk) begin
	first_crc <= head_cnt==11;
	gate_crc <= head_cnt==11 ? 1'b1 : (crc_cnt==4 ? 1'b0 : gate_crc);
	//crc_cnt <= ((~x_data1 & x_data2) | ((crc_cnt>0) & (crc_cnt<4))) ? crc_cnt+1 : 3'b0;
        crc_cnt <= ((icmp_mode ? icmp_reply_strobe_up : x_data1_up)
             | ((crc_cnt>0) & (crc_cnt<4))) ? crc_cnt+1 : 3'b0;
	out_crc_sel <= crc_cnt!=0;
	out_crc_sel1 <= out_crc_sel;
	data4 <= out_crc_sel ? crc_out : (m_header & (head_cnt<11)) ? 8'h55 : (m_header & (head_cnt==11)) ? 8'hd5 : data3x;
end

assign eth_octet=data4;
assign eth_strobe=(head_cnt>4)| ((icmp_mode ? icmp_reply_strobe3 : x_data4) | out_crc_sel1); //high 4 more cycles
//assign eth_strobe=(head_cnt>4)| (x_data4 | out_crc_sel1); //high 4 more cycles
assign debug=eth_strobe;

endmodule
