// Verilog `include this from other files that
// do or don't `define SESQUI, and define the module name.

// This is supposed to synthesize to and make timing on the XC7K160T, as used
// on the BMB7 and QF2_pre (a.k.a. BMB7-1.5).

// Most of what's here is chip- and board-specific clock setup,
// and then instantiates larger_eth and the gmii_to_rgmii bridge.

// This version now includes conditional code to support
// two variations (BMB-7 and QF2-pre).

`ifdef SESQUI
    input   sys_clk_p,
    input   sys_clk_n,
    input   kintex_data_in_p,
    input   kintex_data_in_n,
    output  kintex_data_out_p,
    output  kintex_data_out_n,
    output  kintex_done,
`else
    input       EXT_CLK, // 50MHz from s6
    inout [18:0] bus_bmb7_U7,
`endif

    // QSFP management pins
`ifndef SESQUI
    input       K7_QSFP_SCL,
    input       K7_QSFP_SDA,

    // QSFP1, bank 116
    input       K7_QSFP1_PRSNTL,
    input       K7_QSFP1_INTL,
    output      K7_QSFP1_RESETL,
    output      K7_QSFP1_MODSEL,
    output      K7_QSFP1_LPMODE,
`endif

    input       K7_MGTREFCLK0_P,
    input       K7_MGTREFCLK0_N,
    input       K7_MGTREFCLK1_P,
    input       K7_MGTREFCLK1_N,
    input       K7_QSFP1_RX0_P,
    input       K7_QSFP1_RX0_N,
    output      K7_QSFP1_TX0_P,
    output      K7_QSFP1_TX0_N,
    // input       K7_QSFP1_RX1_P,
    // input       K7_QSFP1_RX1_N,
    // output      K7_QSFP1_TX1_P,
    // output      K7_QSFP1_TX1_N,
    // input       K7_QSFP1_RX2_P,
    // input       K7_QSFP1_RX2_N,
    // output      K7_QSFP1_TX2_P,
    // output      K7_QSFP1_TX2_N,
    // input       K7_QSFP1_RX3_P,
    // input       K7_QSFP1_RX3_N,
    // output      K7_QSFP1_TX3_P,
    // output      K7_QSFP1_TX3_N,

`ifndef SESQUI
    // QSFP2, bank 115
    input       K7_QSFP2_PRSNTL,
    input       K7_QSFP2_INTL,
    output      K7_QSFP2_RESETL,
    output      K7_QSFP2_MODSEL,
    output      K7_QSFP2_LPMODE,
`endif

    input       K7_MGTREFCLK2_P,
    input       K7_MGTREFCLK2_N,
    input       K7_MGTREFCLK3_P,
    input       K7_MGTREFCLK3_N,
    // input       K7_QSFP2_RX0_P,
    // input       K7_QSFP2_RX0_N,
    // output      K7_QSFP2_TX0_P,
    // output      K7_QSFP2_TX0_N,
    // input       K7_QSFP2_RX1_P,
    // input       K7_QSFP2_RX1_N,
    // output      K7_QSFP2_TX1_P,
    // output      K7_QSFP2_TX1_N,
    // input       K7_QSFP2_RX2_P,
    // input       K7_QSFP2_RX2_N,
    // output      K7_QSFP2_TX2_P,
    // output      K7_QSFP2_TX2_N,
    // input       K7_QSFP2_RX3_P,
    // input       K7_QSFP2_RX3_N,
    // output      K7_QSFP2_TX3_P,
    // output      K7_QSFP2_TX3_N,

    output      K7_GTX_REF_CTRL,

`ifdef SESQUI
    output [1:0] LEDS
`else
    output [5:0] LEDS
`endif
);

//parameter ip ={8'd128, 8'd3, 8'd130, 8'd38};
parameter ip ={8'd192, 8'd168, 8'd1, 8'd173};
parameter mac = 48'h00105ad155b2;
parameter jumbo_dw=14;

// Debugging hooks on the fiber link
wire [5:0] link_leds;
wire [15:0] lacr_stat;

// QSFP management: no reset, no i2c
`ifndef SESQUI
assign K7_QSFP1_RESETL = 1'b1;
assign K7_QSFP1_MODSEL = 1'b1;
assign K7_QSFP1_LPMODE = 1'b0;
assign K7_QSFP2_RESETL = 1'b1;
assign K7_QSFP2_MODSEL = 1'b1;
assign K7_QSFP2_LPMODE = 1'b0;
wire sfp_prsnt  = ~K7_QSFP1_PRSNTL;
`endif

// selection of QSFP
`ifdef SESQUI
// on QF2-pre, REFCLK0 comes from D6/D5 from Y4 (SIT9122)
wire gtrefclk_p = K7_MGTREFCLK0_P;
wire gtrefclk_n = K7_MGTREFCLK0_N;
`else
// on BMB7, REFCLK3 is now coming from K6/K5 from the jitter cleaner
wire gtrefclk_p = K7_MGTREFCLK3_P;
wire gtrefclk_n = K7_MGTREFCLK3_N;
`endif
wire sfp_tx_n;  assign K7_QSFP1_TX0_N = sfp_tx_n;
wire sfp_tx_p;  assign K7_QSFP1_TX0_P = sfp_tx_p;
wire sfp_rx_n   = K7_QSFP1_RX0_N;
wire sfp_rx_p   = K7_QSFP1_RX0_P;
// Enable Y4(SIT9122) for GTX_REF_CLK
assign K7_GTX_REF_CTRL = 1'b1;

`ifdef SESQUI
assign kintex_done = 1'b1;
wire EXT_CLK;
`ifdef SIMULATE
assign EXT_CLK = sys_clk_p;
`else
IBUFDS #(.DIFF_TERM("TRUE")) kintex_ck(.O(EXT_CLK), .I(sys_clk_p),         .IB(sys_clk_n));
`endif
`endif

//////////////////////////////////////////////////////////////////////////////
// Clock ip
wire drp_clk, clk_1x_90, clk_2x_0;
`ifndef SIMULATE
clk_wiz_0 clk_i (
    .clk_in(EXT_CLK),                   // input clk_in
    .clk_100(drp_clk),                  // output clk_100
    .clk_200(),                         // output clk_200
    .clk_75_90(clk_1x_90),
    .clk_150(clk_2x_0),
    .reset(1'b0),                       // input reset
    .locked()                           // output locked
);
`endif

// More clocks and ... stuff
wire eth_cfg_clk;
wire [9:0] eth_cfg_set;
`ifdef SESQUI
// Assume QF2LINK
wire bmb7_U7_clkout;
wire bmb7_U7_clk4xout;
wire [7:0] port_50006_word_k7tos6;
wire [7:0] port_50006_word_s6tok7;
wire port_50006_tx_available,port_50006_tx_complete;
wire port_50006_rx_available,port_50006_rx_complete;
wire port_50006_word_read;
wire s6_to_k7_clk_out;
wire bmb7_clk, bmb7_clk_4x;
(* mark_debug = "true" *) wire async_reset;
bmb7_comm_clks bmb7_comm_clks(
	.clk_in(EXT_CLK),
	.clk_1x(bmb7_clk),
	.clk_4x(bmb7_clk_4x),
	.async_reset(async_reset)
);

wire kintex_data_in, kintex_data_out;
`ifdef SIMULATE
assign kintex_data_in = kintex_data_in_p;
assign kintex_data_out_p = kintex_data_out;
assign kintex_data_out_n = ~kintex_data_out;
`else
IBUFDS #(.DIFF_TERM("TRUE")) kintex_rx(.O(kintex_data_in),  .I(kintex_data_in_p),  .IB(kintex_data_in_n));
OBUFDS                       kintex_tx(.I(kintex_data_out), .O(kintex_data_out_p), .OB(kintex_data_out_n));
`endif
wire [7:0] port_50006_word_s6tok7_x;
wire port_50006_rx_available_x, port_50006_rx_complete_x;
`ifndef SIMULATE
qf2_core #(.CHANNEL_3_ENABLE(1'b1), .CHANNEL_4_ENABLE(1'b1), .CHANNEL_4_LOOPBACK(1'b1)) foo(
	.async_reset(async_reset), .clk(bmb7_clk), .clk_4x(bmb7_clk_4x),
	// 50 Mb/s hardware link with Spartan
	.data_in(kintex_data_in), .data_out(kintex_data_out),
	// Virtual LED control, ask about smaple rate
	// I guess changes cause messages that will use link bandwidth
	.led_lpc_r(1'b0), .led_lpc_g(1'b0), .led_lpc_b(1'b0),
	.led_hpc_r(1'b0), .led_hpc_g(1'b0), .led_hpc_b(1'b0),
	// Channel 1 interface (port 50004)
	.channel_1_inbound_read(1'b0), .channel_1_outbound_data(8'b0),
	.channel_1_outbound_frame_end(1'b0), .channel_1_outbound_write(1'b0),
	// Channel 2 interface (port 50005)
	.channel_2_inbound_read(1'b0), .channel_2_outbound_data(8'b0),
	.channel_2_outbound_frame_end(1'b0), .channel_2_outbound_write(1'b0),
	// Channel 3 interface (port 50006)
	// inbound means Spartan to Kintex
	.channel_3_inbound_data      (port_50006_word_s6tok7_x),  // qf2_core output
	.channel_3_inbound_available (port_50006_rx_available_x),
	.channel_3_inbound_frame_end (port_50006_rx_complete_x),
	.channel_3_inbound_read      (1'b1),  // our endpoint is always ready
	// outbound means Kintex to Spartan
	.channel_3_outbound_data      (port_50006_word_k7tos6),  // qf2_core input
	.channel_3_outbound_available (port_50006_word_read),
	.channel_3_outbound_frame_end (port_50006_tx_complete),
	.channel_3_outbound_write     (port_50006_tx_available),
	// Channel 4 interface (port 50007)
	.channel_4_inbound_read(1'b0), .channel_4_outbound_data(8'b0),
	.channel_4_outbound_frame_end(1'b0), .channel_4_outbound_write(1'b0),
	// Multicast
	.multicast_inbound_read(1'b0), .multicast_outbound_data(8'b0),
	.multicast_outbound_frame_end(1'b0), .multicast_outbound_write(1'b0)
);
`endif
assign bmb7_U7_clkout = bmb7_clk;
assign bmb7_U7_clk4xout = bmb7_clk_4x;
assign s6_to_k7_clk_out = EXT_CLK;

// Vivado 2017.1 seems OK, but 2016.1 is definitely not trustable
// `define TRUST_VIVADO
`ifdef TRUST_VIVADO
assign port_50006_word_s6tok7  = port_50006_word_s6tok7_x;
assign port_50006_rx_available = port_50006_rx_available_x;
assign port_50006_rx_complete  = port_50006_rx_complete_x;
`else
// Stupid bug workaround for VHDL to Verilog handoff in Vivado 2016.1?
reg [7:0] port_50006_word_s6tok7_r=0;
reg port_50006_rx_available_r=0, port_50006_rx_complete_r=0;
always @(posedge bmb7_clk) begin
	port_50006_word_s6tok7_r  <= port_50006_word_s6tok7_x;
	port_50006_rx_available_r <= port_50006_rx_available_x;
	port_50006_rx_complete_r  <= port_50006_rx_complete_x;
end
assign port_50006_word_s6tok7  = port_50006_word_s6tok7_r;
assign port_50006_rx_available = port_50006_rx_available_r;
assign port_50006_rx_complete  = port_50006_rx_complete_r;
`endif

// Debugging/management setup
wire [3:0] freq_count_in = {gmii_tx_clk, gmii_rx_clk, clk_2x_0, clk_1x_90};
wire an_bypass;  // autonegotiation bypass
management_top manage(
	// link ports
	.bmb7_clk(bmb7_clk),
	.port_50006_word_k7tos6(port_50006_word_k7tos6),
	.port_50006_word_s6tok7(port_50006_word_s6tok7),
	.port_50006_tx_available(port_50006_tx_available),
	.port_50006_tx_complete(port_50006_tx_complete),
	.port_50006_rx_available(port_50006_rx_available),
	.port_50006_rx_complete(port_50006_rx_complete),
	.port_50006_word_read(port_50006_word_read),
	// Ethernet configuration port
	.eth_cfg_clk(eth_cfg_clk),
	.eth_cfg_set(eth_cfg_set),
	// Link status and debug
	.an_bypass(an_bypass),
	.link_leds(link_leds),
	.lacr_stat(lacr_stat),
	// monitor/debug I/O
	.freq_count_in(freq_count_in)
);
`else
assign eth_cfg_clk = 0;
assign eth_cfg_set = 0;
`endif  // SESQUI


//////////////////////////////////////////////////////////////////////////////
wire gmii_tx_clk, gmii_rx_clk;
wire [6:0] mac_status;
wire gt_rx_resetdone, gt_tx_resetdone;
wire gt_rxfsm_resetdone, gt_txfsm_resetdone;
wire gt_cpll_locked;

//`define GTREFCLK_Q1
k7_gtx_larger_eth #(
	.ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) mac_qsfp1_0 (
	// physical pins
	.gtrefclk_p(gtrefclk_p),
	.gtrefclk_n(gtrefclk_n),
	.sfp_tx_p(sfp_tx_p),
	.sfp_tx_n(sfp_tx_n),
	.sfp_rx_p(sfp_rx_p),
	.sfp_rx_n(sfp_rx_n),
	.clk_1x_90(clk_1x_90), // 75MHz
	.clk_2x_0(clk_2x_0), // 150MHz
	// Ethernet configuration port
	.eth_cfg_clk(eth_cfg_clk),
	.eth_cfg_set(eth_cfg_set),
	// Link status and debug
	.an_bypass(an_bypass),
	.link_leds(link_leds),
	.lacr_stat(lacr_stat),
	// controls
	.soft_reset(1'b0),
	.reset(1'b0),
	.drp_clk(drp_clk),
	.gt_txfsm_resetdone(gt_txfsm_resetdone),
	.gt_rxfsm_resetdone(gt_rxfsm_resetdone),
	.gt_tx_resetdone(gt_tx_resetdone),
	.gt_rx_resetdone(gt_rx_resetdone),
	.gt_pll_locked(gt_cpll_locked),
	.mac_status(mac_status),
	.gmii_tx_clk(gmii_tx_clk),
	.gmii_rx_clk(gmii_rx_clk)
);

// LED[0] blink_clk_1x
// LED[1] blink_clk_2x
// LED[2] rx_activity
// LED[3] tx_activity

// clock counters
reg [25:0] gmii_tx_clk_cnt=0, gmii_rx_clk_cnt=0;
always @(posedge gmii_tx_clk) gmii_tx_clk_cnt <= gmii_tx_clk_cnt + 1'b1;
always @(posedge gmii_rx_clk) gmii_rx_clk_cnt <= gmii_rx_clk_cnt + 1'b1;

`ifdef SESQUI
// Not useful, just covering equivalent dependencies
assign LEDS=~{gmii_tx_clk_cnt[24] ^ mac_status[0], gmii_rx_clk_cnt[24] ^ (|mac_status[6:4])};
`else
assign LEDS=~{mac_status[6:4], gmii_tx_clk_cnt[24], mac_status[0], gmii_rx_clk_cnt[24]};
`endif

endmodule
