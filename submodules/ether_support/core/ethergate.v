`timescale 1ns / 1ns

// This hardware design addresses the custom-FPGA to commodity-CPU boundary through Gigabit Ethernet.
// This particular version is designed to target a Xilinx Virtex-5, and configured to have one single client,
// providing an GMII to local bus interface.

module ethergate(
	// Reference clock input
	input clk125,

	// GMII interface
	// GMII Rx
	input  RX_CLK,
	input [7:0] RXD,
	input RX_DV,
	input RX_ER,
	// GMII Tx
	output GTX_CLK,
	output [7:0] TXD,
	output TX_EN,
	output TX_ER,

	// IP and MAC address setting
	input address_clk,
	input [8:0] address_set,

	// Local bus interface
	output lb_clk,
	output [23:0] lb_addr,
	output lb_control_strobe,
	output lb_control_rd,
	input [31:0] lb_data_in,
	output [31:0] lb_data_out,

	output [7:0] ethernet_leds,

	// Diagnostics
	output rx_crc_fault

);

// LED assignment legend (ethernet_leds) to report status to upper layers.
// Derived from bit assignments here and in aggregate.v, (see aggregate_leds).
//LED[0]: 125MHz for Rx data
//LED[1]: 125MHz for Tx data
//LED[2]: ARP Reply Request
//LED[3]: Rx Packet activity
//LED[4]: Tx Packet activity
//LED[5]: Rx CRC pass (sticks on after a single packet passes CRC test)
//LED[6]: Rx PLL locked
//LED[7]: unused

//IP and MAC adresses
parameter [31:0] ip = {8'd128, 8'd3, 8'd128, 8'd172};  // 128.3.128.172
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter [47:0] mac = 48'h125555000129;
parameter mem_gateway_pipeline=3;               // Read pipeline window in mem_gateway
parameter jumbo_dw = 14;
parameter address_xdomain = 0;  // cross clock domains with address_clk

wire [7:0] abst2_in, abst2_out;
wire abst2_in_s, abst2_out_s;
wire agmii_clk;

agmii2gmii agmii2gmii_bridge(
	// Reference clock input
	.clk125(clk125),

	// GMII interface
    // GMII Rx
	.RX_CLK(RX_CLK),
	.RXD(RXD),
	.RX_DV(RX_DV),
	.RX_ER(RX_ER),
	// GMII Tx
	.GTX_CLK(GTX_CLK),
	.TXD(TXD),
	.TX_EN(TX_EN),
	.TX_ER(TX_ER),

	// AGMII interface (aggregate)
    // Single clock domain for transmit and receive data
	.agmii_clk(agmii_clk),
	// AGMII Rx
	.agmii_in(abst2_out),
	.agmii_in_s(abst2_out_s),
	// AGMII Tx
	.agmii_out(abst2_in),
	.agmii_out_s(abst2_in_s)
);

// Single clock domain, abstract Ethernet
wire rx_crc_ok;
wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
wire [7:0] data_tx_1;  wire [jumbo_dw-1:0] length_1;  wire req_1, ack_1, strobe_tx_1, warn_1;
wire [7:0] data_tx_2;  wire [jumbo_dw-1:0] length_2;  wire req_2, ack_2, strobe_tx_2, warn_2;
wire [7:0] data_tx_3;  wire [jumbo_dw-1:0] length_3;  wire req_3, ack_3, strobe_tx_3, warn_3;

// 9-bit address set bus is really an 8-bit data word with a strobe.
wire [8:0] address_seta;
generate if (address_xdomain) begin: x1
	// Move address_set from a caller-provided clock to our internally generated agmii clock.
	data_xdomain #(.size(8)) address_set_x(
		.clk_in(address_clk), .gate_in(address_set[8]), .data_in(address_set[7:0]),
		.clk_out(agmii_clk), .gate_out(address_seta[8]), .data_out(address_seta[7:0])
	);
end else begin: x0
	assign address_seta = address_set;
end endgenerate

wire [3:0] aggregate_leds;
aggregate #(.ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)) a2(
	.clk(agmii_clk),  // Single clock domain for transmit and receive data
	// GMII in
	.eth_in(abst2_in),   .eth_in_s(abst2_in_s),
	// GMII out
	.eth_out(abst2_out), .eth_out_s(abst2_out_s),
	.rx_crc_ok(rx_crc_ok),
	.rx_crc_fault(rx_crc_fault),
	.address_set(address_seta),

	// Client interfaces (Use as many of these interfaces as protocols implemented in UDP payload)
	// Keep nominally compatible with ether_mc.vh
	// Client interface 1 (LED test, UDP port 1000)
	// Client interface 2 (throughput test, UDP port 2000)
	// Client interface 3 (mem_gateway, UDP port 3000)
	.data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
	.data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
	.data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),

	.req_1(req_1), .length_1(length_1), .ack_1(ack_1), .strobe_tx_1(strobe_tx_1), .warn_1(warn_1), .data_tx_1(data_tx_1),
	.req_2(req_2), .length_2(length_2), .ack_2(ack_2), .strobe_tx_2(strobe_tx_2), .warn_2(warn_2), .data_tx_2(data_tx_2),
	.req_3(req_3), .length_3(length_3), .ack_3(ack_3), .strobe_tx_3(strobe_tx_3), .warn_3(warn_3), .data_tx_3(data_tx_3),

	// Export aggregate_leds for status monitoring
	.leds(aggregate_leds));

// Tx only, but triggered by corresponding Rx ready
client_tx cl1tx(.clk(GTX_CLK), .ack(ack_1), .strobe(strobe_tx_1), .req(req_1),
	.length(length_1), .data_out(data_tx_1), .srx(ready_1));

// Rx only, controls two LEDs
wire [1:0] led1;
client_rx cl1rx(.clk(GTX_CLK), .ready(ready_1), .strobe(strobe_rx_1), .crc(crc_rx_1), .data_in(data_rx_1), .led(led1));

// Throughput test client
reg nomangle=0;
client_thru cl2rxtx(.clk(GTX_CLK), .rx_ready(ready_2), .rx_strobe(strobe_rx_2), .rx_crc(crc_rx_2), .data_in(data_rx_2),
	.nomangle(nomangle),
	.tx_ack(ack_2), .tx_warn(warn_2), .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2));

// Client mem_gateway: Bridge between the client interface with aggregate, and a local bus
// The local bus is the protocol implemented in the UDP packet
wire mem_gateway_fifo_full, mem_gateway_underrun;
mem_gateway #(.read_pipe_len(mem_gateway_pipeline)) sfp_cl1(.clk(GTX_CLK),
	// Client interface connected to aggregate
	.rx_ready(ready_3), .rx_strobe(strobe_rx_3), .rx_crc(crc_rx_3), .packet_in(data_rx_3),
	.tx_ack(ack_3), .tx_strobe(warn_3), .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),

	// Local bus
	.addr(lb_addr), .control_strobe(lb_control_strobe), .control_rd(lb_control_rd),
	.data_out(lb_data_out), .data_in(lb_data_in),
	.fifo_full(mem_gateway_fifo_full), .underrun(mem_gateway_underrun));

// Diagnostic LEDs
// Mem_gateway diagnostics
wire full_fifo_led, underrun_led;
activity full_act(.clk(GTX_CLK), .trigger(mem_gateway_fifo_full), .led(full_fifo_led));
activity underrun_act(.clk(GTX_CLK), .trigger(mem_gateway_underrun), .led(underrun_led));

// CRC fault activity
wire rx_crc_fault_led;
activity crc_fault_act(.clk(GTX_CLK), .trigger(rx_crc_fault), .led(rx_crc_fault_led));

// Simple blinkers to show clocks exist
reg [24:0] cnt_rx=0, cnt_tx=0;
always @(posedge RX_CLK) cnt_rx <= cnt_rx+1'b1;  // 125MHz reference clock
always @(posedge GTX_CLK) cnt_tx<=cnt_tx+1'b1;  // 125MHz for parallel Rx data (generated by the PLL)
reg rx_crc_ok_once=1'b0;
always @(posedge GTX_CLK) if(rx_crc_ok) rx_crc_ok_once <= 1'b1;
wire blink_rx=cnt_rx[24];
wire blink_tx=cnt_tx[24];

// LEDs to report monitoring status to upper layers
// wire rx_locked=0;
// rx_locked,rx_crc_ok
//assign ethernet_leds={led1,aggregate_leds,blink_tx,blink_rx};
//assign ethernet_leds={rx_crc_ok_once, rx_crc_ok, aggregate_leds,blink_tx,blink_rx};
assign ethernet_leds={full_fifo_led, underrun_led, aggregate_leds, rx_crc_fault_led, blink_rx};
// Provide clock for local bus registered data in upper layers
assign lb_clk = GTX_CLK;

endmodule
