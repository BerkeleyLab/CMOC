`timescale 1ns / 1ns

module ether_gmii(
    input gmii_tx_clk,
    input gmii_rx_clk,
    input [7:0] gmii_rxd,
    input gmii_rx_dv,
    input gmii_rx_er,  // not used XXX that's a mistake
    output reg [7:0] gmii_txd,
    output reg gmii_tx_en,
    output reg gmii_tx_er,

    output [6:0] status
);

parameter [31:0] ip = {8'd128, 8'd3, 8'd128, 8'd122}; // 128.3.128.122
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter [47:0] mac = 48'h125555000128;
parameter jumbo_dw = 14;

wire [7:0] abst_in, abst_out;
wire abst_in_s, abst_out_s;

wire clk = gmii_tx_clk;   // at some point we want a ring clock instead

// Latch Rx input pins in IOB
reg [7:0] rxd=0;
reg rx_dv=0, rx_er=0;
always @(posedge gmii_rx_clk) begin
    rxd   <= gmii_rxd;
    rx_dv <= gmii_rx_dv;
    rx_er <= gmii_rx_er;
end

// FIFO from Rx clock domain to gtx clock domain
gmii_fifo rx2gtx(
    .clk_in(gmii_rx_clk), .d_in(rxd),   .strobe_in(rx_dv),
    .clk_out(clk),   .d_out(abst_in), .strobe_out(abst_in_s)
);

// Single clock domain, abstract Ethernet
wire rx_crc_ok;
wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
wire [7:0] data_tx_1;  wire [jumbo_dw-1:0] length_1;  wire req_1, ack_1, strobe_tx_1, warn_1;
wire [7:0] data_tx_2;  wire [jumbo_dw-1:0] length_2;  wire req_2, ack_2, strobe_tx_2, warn_2;
wire [7:0] data_tx_3;  wire [jumbo_dw-1:0] length_3;  wire req_3, ack_3, strobe_tx_3, warn_3;
wire [3:0] agg_leds;
aggregate #(
    .ip(ip), .mac(mac)
) agg_i (.clk(clk),
    .eth_in(abst_in),   .eth_in_s(abst_in_s),
    .eth_out(abst_out), .eth_out_s(abst_out_s),
    .rx_crc_ok(rx_crc_ok),
    .address_set(9'b0),
    .data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
    .data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
    .data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),
    .req_1(req_1), .length_1(length_1), .ack_1(ack_1), .strobe_tx_1(strobe_tx_1), .warn_1(warn_1), .data_tx_1(data_tx_1),
    .req_2(req_2), .length_2(length_2), .ack_2(ack_2), .strobe_tx_2(strobe_tx_2), .warn_2(warn_2), .data_tx_2(data_tx_2),
    .req_3(req_3), .length_3(length_3), .ack_3(ack_3), .strobe_tx_3(strobe_tx_3), .warn_3(warn_3), .data_tx_3(data_tx_3),
    .leds(agg_leds)
);

wire [23:0] control_addr;
wire control_strobe, control_rd;
wire [31:0] data_out;
reg [31:0] data_in=0;

// instantiate some test clients
// Tx only, but triggered by corresponding Rx ready
client_tx cl1tx(.clk(clk), .ack(ack_1), .strobe(strobe_tx_1), .req(req_1),
    .length(length_1), .data_out(data_tx_1), .srx(ready_1));

wire [1:0] led1;
client_rx cl1rx(.clk(clk), .ready(ready_1), .strobe(strobe_rx_1), .crc(crc_rx_1), .data_in(data_rx_1), .led(led1));

reg nomangle=0;
client_thru cl2rxtx(.clk(clk), .rx_ready(ready_2), .rx_strobe(strobe_rx_2), .rx_crc(crc_rx_2), .data_in(data_rx_2),
    .nomangle(nomangle),
    .tx_ack(ack_2), .tx_warn(warn_2), .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2));

mem_gateway cl3rxtx(.clk(clk), .rx_ready(ready_3), .rx_strobe(strobe_rx_3), .rx_crc(crc_rx_3), .packet_in(data_rx_3),
    .tx_ack(ack_3), .tx_strobe(warn_3), .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),
    .addr(control_addr), .control_strobe(control_strobe), .control_rd(control_rd),
    .data_out(data_out), .data_in(data_in));

// Stupid test rig
reg [31:0] stupidity=0; // really combinatorial
always @(*) case (control_addr[2:0])
    0: stupidity = "Hell";
    1: stupidity = "o wo";
    2: stupidity = "rld!";
    3: stupidity = 32'h0d0a0d0a;
    4: stupidity = "LBNL";
    5: stupidity = " LRD";
    6: stupidity = "&QDU";
    7: stupidity = 32'h0d0a0d0a;
endcase

wire [7:0] cnf_data;
config_romx config_romx1( .address(control_addr[4:0]), .data(cnf_data));
always @(posedge clk) data_in <= control_addr[5] ? stupidity : {24'b0,cnf_data};

// Configure the throughput-testing client from the local bus
always @(posedge clk) begin
    if (control_strobe & ~control_rd & (control_addr[7:0]==8'h7a)) nomangle <= data_out[0];
end

// Latch Tx output pins in IOB
always @(posedge clk) begin
    gmii_txd   <= abst_out;
    gmii_tx_en <= abst_out_s;
    gmii_tx_er <= 0;  // Our logic never needs this
end

assign status={agg_leds, led1, rx_crc_ok};

endmodule
