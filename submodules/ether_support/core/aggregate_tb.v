`timescale 1ns / 1ns

module aggregate_tb;

// packets available to simulate (when configured without LINUX_TUN)
// reply.dat   captured from hardware (mode6) as output of our tx code
// udp2.dat    undocumented origin, but proven valid
// word.dat    captured from Andrea's Mac via PHY and FPGA

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;

parameter max_data_len=1024;
//parameter data_len=64;   // value for udp2.dat
//parameter data_len=80;   // value for reply.dat
//parameter data_len=255;  // value for word.dat
//parameter data_len=455;  // value for long.dat
parameter jumbo_dw = 14;

reg [7:0] pack_mem [0:max_data_len-1];

reg clk;
integer cc;
reg [127:0] packet_file;
integer data_len;
initial begin
	`ifndef LINUX_TUN
	if (!$value$plusargs("packet_file=%s", packet_file)) packet_file="udp2.dat";
	$readmemh(packet_file,pack_mem);
	`endif
	if (!$value$plusargs("data_len=%d", data_len))  data_len= 64;
	if ($test$plusargs("vcd")) begin
		$dumpfile("aggregate.vcd");
		$dumpvars(5,aggregate_tb);
	end
	for (cc=0;
`ifdef LINUX_TUN
  1
`else
  cc<1800
`endif
	; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
end

reg [7:0] eth_in=0, eth_in_=0;
reg eth_in_s=0, eth_in_s_=0;
wire [7:0] eth_out;
wire eth_out_s;

`ifdef LINUX_TUN
always @(posedge clk) begin
	if (cc > 4) $tap_io(eth_out, eth_out_s, eth_in_, eth_in_s_);
	eth_in <= eth_in_;
	eth_in_s <= eth_in_s_;
end
`else
reg eth_out_s1=0, ok_to_print=1;
integer ci;
always @(posedge clk) begin
	ci = cc % (data_len+150);
	if ((ci>=100) & (ci<(100+data_len))) begin
		eth_in <= pack_mem[ci-100];
		eth_in_s <= 1;
	end else begin
		eth_in <= 8'hxx;
		eth_in_s <= 0;
	end

	eth_out_s1 <= eth_out_s;
	if (eth_out_s1 & ~eth_out_s) ok_to_print <= 0;
	if (eth_out_s & ok_to_print) $display("octet %x",eth_out);
end
`endif

wire [8:0] address_set;
wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
wire [7:0] data_tx_1;  wire [jumbo_dw-1:0] length_1;  wire req_1, ack_1, strobe_tx_1, warn_1;
wire [7:0] data_tx_2;  wire [jumbo_dw-1:0] length_2;  wire req_2, ack_2, strobe_tx_2, warn_2;
wire [7:0] data_tx_3;  wire [jumbo_dw-1:0] length_3;  wire req_3, ack_3, strobe_tx_3, warn_3;
wire [3:0] leds;
aggregate #(.ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)) a(.clk(clk),
	.eth_in(eth_in), .eth_in_s(eth_in_s),
	.eth_out(eth_out), .eth_out_s(eth_out_s),
	.address_set(address_set),

	.data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
	.data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
	.data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),

	.req_1(req_1), .length_1(length_1), .ack_1(ack_1), .strobe_tx_1(strobe_tx_1), .warn_1(warn_1), .data_tx_1(data_tx_1),
	.req_2(req_2), .length_2(length_2), .ack_2(ack_2), .strobe_tx_2(strobe_tx_2), .warn_2(warn_2), .data_tx_2(data_tx_2),
	.req_3(req_3), .length_3(length_3), .ack_3(ack_3), .strobe_tx_3(strobe_tx_3), .warn_3(warn_3), .data_tx_3(data_tx_3),

	.leds(leds));

wire [23:0] control_addr;
wire control_strobe, control_rd;
wire [31:0] data_out;
//`define CROSS_DOMAIN
`ifdef CROSS_DOMAIN
   wire [31:0] data_in;
`else
   reg [31:0] data_in;
`endif

// instantiate some test clients
// Tx only, but triggered by corresponding Rx ready
client_tx #(.jumbo_dw(jumbo_dw)) cl1tx(.clk(clk), .ack(ack_1), .strobe(strobe_tx_1), .req(req_1),
	.length(length_1), .data_out(data_tx_1), .srx(ready_1));

wire [1:0] led1;
client_rx #(.jumbo_dw(jumbo_dw)) cl1rx(.clk(clk), .ready(ready_1), .strobe(strobe_rx_1), .crc(crc_rx_1), .data_in(data_rx_1), .led(led1));

`define THRU_CLIENT
`ifdef THRU_CLIENT
client_thru cl2rxtx(.clk(clk), .rx_ready(ready_2), .rx_strobe(strobe_rx_2), .rx_crc(crc_rx_2), .data_in(data_rx_2),
	.nomangle(1'b0),
	.tx_ack(ack_2), .tx_warn(warn_2), .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2));
`endif

mem_gateway
`ifdef CROSS_DOMAIN
#(.read_pipe_len(11))
`else
#(.read_pipe_len(3))
`endif
  cl3rxtx(.clk(clk), .rx_ready(ready_3), .rx_strobe(strobe_rx_3), .rx_crc(crc_rx_3), .packet_in(data_rx_3),
	.tx_ack(ack_3), .tx_strobe(warn_3), .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),
	.addr(control_addr), .control_strobe(control_strobe), .control_rd(control_rd),
	.data_out(data_out), .data_in(data_in));


`ifdef CROSS_DOMAIN
   reg dsp_clk=0;

   always begin
      dsp_clk=0; #5;
      dsp_clk=1; #5;
   end

   // Clock domain crossing ((local bus/Ethernet) --> dsp clock domains)
   wire [56:0] lb_word_out_eth={data_out, control_addr, control_rd};
   wire [56:0] lb_word_out_dsp;
   wire [31:0] lb_data;
   wire [23:0] lb_addr;
   wire        lb_control_rd;
   wire        lb_control_strobe;

   // gate_in must be & ~control2_rd
   // mem_gateway generate control_strobe at every R/W cycle
   // So just delay lb_control_strobe for a certian time. see below
   data_xdomain #(.size(57))
   x_eth2dsp(.clk_in(clk), .gate_in(control_strobe), .data_in(lb_word_out_eth),
	     .clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
	     );

   assign {lb_data,lb_addr,lb_control_rd}=lb_word_out_dsp;

   // Clock domain crossing (dsp --> (local bus/Ethernet) clock domains)
   reg  lb_control_strobe_d1=1'b0, lb_control_strobe_d2=1'b0, lb_control_strobe_d3=1'b0;
   wire lb_control_strobe_back;
   // dsp clock domain
   reg [31:0]  lb_data_in;

   // Introduce 3 clock cycle delay to strobe to match data bus pipeline
   always @(posedge dsp_clk) begin
      lb_control_strobe_d1 <= lb_control_strobe;
      lb_control_strobe_d2 <= lb_control_strobe_d1;
      lb_control_strobe_d3 <= lb_control_strobe_d2;
   end

   // Multiplexer selecting data output from the different modules to the Ethernet input via the local data bus
   always @(posedge dsp_clk)
	case(lb_addr[23:20])
	  0: lb_data_in <= "Hell";
	  1: lb_data_in <= "o wo";
	  2: lb_data_in <= "rld!";
	  3: lb_data_in <= "(::)";
	  default: lb_data_in <= 32'hdeadbeef;
	endcase // case (lb_addr[23:20])


   data_xdomain #(.size(32))
   x_dsp2eth(.clk_in(dsp_clk), .gate_in(lb_control_strobe), .data_in(lb_data_in),
	     .clk_out(clk), .gate_out(lb_control_strobe_back), .data_out(data_in)
	     );
   // nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error
`else
// Stupid test rig
always @(posedge clk) case (control_addr[2:0])
	0: data_in <= "Hell";
	1: data_in <= "o wo";
	2: data_in <= "rld!";
	3: data_in <= 32'h0d0a0d0a;
endcase
`endif //  `ifdef CROSS_DOMAIN

`ifdef LINUX_TUN
// try pushing a different MAC and IP into the block

parameter [31:0] new_ip = {8'd192, 8'd168, 8'd7, 8'd3};  // 192.168.7.3

wire [7:0] last_byte=8'd4;  // Overwrite last byte
parameter [47:0] new_mac = 48'h12555533312e;  // fictitious
reg set_address_rst_r=0, set_address_rst1=0;
always @(posedge clk) begin
	set_address_rst_r <= set_address_rst1;
	set_address_rst1 <= 1;
end

wire set_address_rst=~set_address_rst_r;

set_address #(.ip_net(new_ip), .mac(new_mac)) set_address( .clk(clk),
	.rst(set_address_rst), .last_ip_byte(last_byte),
	.address_set(address_set)
);

/*
integer start_cnt=0;
always @(posedge clk) begin
	start_cnt <= start_cnt+1;
	case (start_cnt)
	  1: address_set <= 9'h104;
	  2: address_set <= 9'h107;
	  3: address_set <= 9'h1a8;
	  4: address_set <= 9'h1c0;
	  5: address_set <= 9'h1bc;
	  6: address_set <= 9'h19a;
	  7: address_set <= 9'h178;
	  8: address_set <= 9'h156;
	  9: address_set <= 9'h134;
	 10: address_set <= 9'h112;
	default: address_set <= 0;
	endcase
end
*/
`else
assign address_set=0;
`endif

endmodule
