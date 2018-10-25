// This .vh file is intended for inclusion in a "real" .v file,
// in particular, one that makes a few `defines to configure this
// file for a particular board.  Preprocessor variables used here:
//   SP60X
//   ML50X
//   AV5T
//   N_LED
//   HAVE_ODDR2

`ifdef SP60X
    `ifdef SINGLE_100_CLK
        input SYSCLK,
    `else
        input SYSCLK_P,
        input SYSCLK_N,
    `endif
`else
    `ifdef ML50X
        input SYSCLK_P,
        input SYSCLK_N,
    `else
        input GMII_MCLK,
    `endif
`endif
	input GMII_RX_CLK,
	input [7:0] GMII_RXD,
	input GMII_RX_DV,
	input GMII_RX_ER,  // not used XXX that's a mistake
	output GMII_GTX_CLK,
	input  GMII_TX_CLK,  // not used
	output reg [7:0] GMII_TXD,
	output reg GMII_TX_EN,
	output reg GMII_TX_ER,
	output PHY_RSTN,
`ifdef SPI_TEST
	// Basic 4-wire to microcontroller, plus "interrupt"
	input UC_CLK,
	input UC_CS,
	input UC_MOSI,
	output UC_MISO,
	output UC_LOOK,
	// 4-wire to e.g., Winbond W25X16
	output BOOT_CS,
	output BOOT_MOSI,
	input  BOOT_MISO,
	output BOOT_CCLK,
`endif
`ifdef AV5T
	output MPD09,
	output MPD11,
	output MPD13,
	output MPD15,
	output MPA5,
	output CEn,
`endif
	output [`N_LED-1:0] LED
);
// LED assignment derived from bit assignments here,
// in aggregate.v, and in client_rx.v.
//   LED[0] D7: Rx CRC OK (sticks on after a single packet passes CRC test)
//   LED[1] D8: 3.7 Hz clock-present blinker
//   LED[2] D1: brightness controlled by UDP port 1000, payload byte 1
//   LED[3] D2: brightness controlled by UDP port 1000, payload byte 2
//   LED[4] D3: ARP packet rejected
//   LED[5] D4: ARP packet accepted
//   LED[6] D5: Rx packet activity
//   LED[7] D6: Tx packet activity

parameter [31:0] ip = `MY_IP;
parameter [47:0] mac = `MY_MAC;
parameter jumbo_dw = 14;

wire [7:0] abst_in, abst_out;
wire abst_in_s, abst_out_s;
wire [2:0] debug;

assign PHY_RSTN=1;    // Can't do anything unless PHY is out of reset

wire clk125;
`ifdef SP60X
sp60x_clocks
    `ifdef SINGLE_100_CLK // 10ns period, single input
        #(.clk2_period(10), .mult(8), .divide_out(4), .diff_input(0))
        clkgen(
                   .SYSCLK(SYSCLK),
    `else
        clkgen(
                   .SYSCLK_P(SYSCLK_P), .SYSCLK_N(SYSCLK_N),
    `endif
	.RST(1'b0),
	.CLK125(clk125)
);
`else
`ifdef ML50X
ml50x_clocks clkgen(
	.CLKIN1_P_IN(SYSCLK_P), .CLKIN1_N_IN(SYSCLK_N),
	.RST_IN(1'b0),
	.CLKOUT0_OUT(clk125)
);
`else
assign clk125=GMII_MCLK;
`endif
`endif

`ifdef HAVE_ODDR2
ODDR2 GTXCLK_OUT(
	.Q(GMII_GTX_CLK),
	.C0(clk125),
	.C1(~clk125),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);
`else
assign GMII_GTX_CLK=clk125;
`endif

wire gtx_clk=clk125;
wire clk=clk125;   // at some point we want a ring clock instead

// Simple blinker to show clock exists
reg [24:0] ecnt=0;
always @(posedge clk) ecnt<=ecnt+1;
wire blink=ecnt[24];

// Latch Rx input pins in IOB
reg [7:0] rxd=0;
reg rx_dv=0, rx_er=0;
always @(posedge GMII_RX_CLK) begin
	rxd   <= GMII_RXD;
	rx_dv <= GMII_RX_DV;
	rx_er <= GMII_RX_ER;
end

// FIFO from Rx clock domain to ring clock domain
gmii_fifo rx2ring(
	.clk_in(GMII_RX_CLK), .d_in(rxd),   .strobe_in(rx_dv),
	.clk_out(clk),   .d_out(abst_in), .strobe_out(abst_in_s)
);

// Single clock domain, abstract Ethernet
wire [8:0] address_set;
wire rx_crc_ok=1;  // incomplete
wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
wire [7:0] data_tx_1;  wire [jumbo_dw-1:0] length_1;  wire req_1, ack_1, strobe_tx_1, warn_1;
wire [7:0] data_tx_2;  wire [jumbo_dw-1:0] length_2;  wire req_2, ack_2, strobe_tx_2, warn_2;
wire [7:0] data_tx_3;  wire [jumbo_dw-1:0] length_3;  wire req_3, ack_3, strobe_tx_3, warn_3;
wire [3:0] leds;
`ifdef SPI_TEST
wire [7:0] data_rx_4;  wire [1:0] ready_4;  wire strobe_rx_4, crc_rx_4;
wire [7:0] data_tx_4;  wire [jumbo_dw-1:0] length_4;  wire [1:0] req_4;  wire ack_4, strobe_tx_4, warn_4;
aggregate2
`else
assign address_set=9'b0;
aggregate
`endif
 #(.ip(ip), .mac(mac)) a(.clk(clk),
	.eth_in(abst_in),   .eth_in_s(abst_in_s),
	.eth_out(abst_out), .eth_out_s(abst_out_s),
	.address_set(address_set),

	.data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
	.data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
	.data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),
`ifdef SPI_TEST
	.data_rx_4(data_rx_4), .ready_4(ready_4), .strobe_rx_4(strobe_rx_4), .crc_rx_4(crc_rx_4),
`endif

	.req_1(req_1), .length_1(length_1), .ack_1(ack_1), .strobe_tx_1(strobe_tx_1), .warn_1(warn_1), .data_tx_1(data_tx_1),
	.req_2(req_2), .length_2(length_2), .ack_2(ack_2), .strobe_tx_2(strobe_tx_2), .warn_2(warn_2), .data_tx_2(data_tx_2),
	.req_3(req_3), .length_3(length_3), .ack_3(ack_3), .strobe_tx_3(strobe_tx_3), .warn_3(warn_3), .data_tx_3(data_tx_3),
`ifdef SPI_TEST
	.req_4(req_4), .length_4(length_4), .ack_4(ack_4), .strobe_tx_4(strobe_tx_4), .warn_4(warn_4), .data_tx_4(data_tx_4),
`endif
	.debug(debug), .leds(leds));

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

`define THRU_CLIENT
`ifdef THRU_CLIENT
reg nomangle=0;
client_thru cl2rxtx(.clk(clk), .rx_ready(ready_2), .rx_strobe(strobe_rx_2), .rx_crc(crc_rx_2), .data_in(data_rx_2),
	.nomangle(nomangle),
	.tx_ack(ack_2), .tx_warn(warn_2), .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2));
`endif

mem_gateway cl3rxtx(.clk(clk), .rx_ready(ready_3), .rx_strobe(strobe_rx_3), .rx_crc(crc_rx_3), .packet_in(data_rx_3),
	.tx_ack(ack_3), .tx_strobe(warn_3), .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),
	.addr(control_addr), .control_strobe(control_strobe), .control_rd(control_rd),
	.data_out(data_out), .data_in(data_in));

`ifdef SPI_TEST
wire [15:0] status_in=16'h1234;
scaffold scaffold(.clk(clk),
	.rx_ready(ready_4), .rx_strobe(strobe_rx_4), .rx_data(data_rx_4),
	.tx_ack(ack_4), .tx_warn(warn_4), .tx_req(req_4), .tx_len(length_4), .tx_data(data_tx_4),
	.uc_clk(UC_CLK), .uc_cs(UC_CS), .uc_mosi(UC_MOSI), .uc_miso(UC_MISO), .uc_look_at_me(UC_LOOK),
	.flash_clk(BOOT_CCLK), .flash_cs(BOOT_CS), .flash_mosi(BOOT_MOSI), .flash_miso(BOOT_MISO),
	.status_in(status_in), .address_set(address_set)
	);
`endif

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

// FIFO from ring clock domain to tx clock domain
wire [7:0] txd;
wire tx_en;
gmii_fifo ring2tx(
	.clk_in(clk),      .d_in(abst_out), .strobe_in(abst_out_s),
	.clk_out(gtx_clk), .d_out(txd), .strobe_out(tx_en)
);

// Latch Tx output pins in IOB
always @(posedge gtx_clk) begin
	GMII_TXD   <= txd;
	GMII_TX_EN <= tx_en;
	GMII_TX_ER <= 0;  // Our logic never needs this
end

assign LED={leds,led1,blink,rx_crc_ok};  // save rx_crc_ok for later

`ifdef AV5T
// Debugging signals
assign MPD09=1'b0; //clk
assign MPD11=1'b0; //debug[0]
assign MPD13=debug[1];
assign MPD15=debug[2];
assign MPA5=0;
assign CEn=0;
`endif

endmodule
