`timescale 1ns / 1ns

module larger_shell_mgt_cutewr(
    input SYSCLK_P,
    input SYSCLK_N,
    input REFCLK_P,
    input REFCLK_N,

    input RXP1,
    input RXN1,
    output TXP1,
    output TXN1,
    input SFP0_LOS,
    input SFP0_MOD0,
    output IIC_SCL_SFP,
    inout IIC_SDA_SFP,
    output SFP0_TX_DISABLE,
    output SFP0_RATE_SELECT,

    inout IIC_SCL_MAIN,
    inout IIC_SDA_MAIN,

    output [2:0] LED
);

// LED[0] arp_activity
// LED[1] rx_activity
// LED[2] tx_activity

parameter ip ={8'd128, 8'd3, 8'd129, 8'd18}; // rflab3.lbl.gov
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter mac=48'h125555000124;
parameter jumbo_dw=14;

// Stupid resets
reg gtp_reset=1, gtp_reset1=1;
always @(posedge tx_clk) begin
    gtp_reset <= gtp_reset1;
    gtp_reset1 <= 0;
end

// ============= Clock setup =============
wire clk_1x_90, clk_2x_0;
wire clk_eth; // not used

spartan6_clocks #(
    .clkin_period(8), // SYSCLK = 125MHz
    .dcm_div(5) // 125*5/5 = 125MHz
) clocks_i(
    .rst(gtp_reset),
    .sysclk_p(SYSCLK_P),
    .sysclk_n(SYSCLK_N),
    .clk_eth(clk_eth),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

// ============= Ethernet on SFP1 follows ===================
// The two clocks are sourced from gmii_link
wire rx_clk, tx_clk;

wire rxn0, rxp0, txn0, txp0; // not used
wire [9:0] txdata0, rxdata0; // not used
wire [9:0] txdata1, rxdata1;
wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
wire txstatus0, txstatus1;
wire plllkdet, resetdone;
s6_gtp_wrap s6_gtp_wrap_i(
    .txdata0(txdata0), .txstatus0(txstatus0),
    .rxdata0(rxdata0), .rxstatus0(rxstatus0),
    .txdata1(txdata1), .txstatus1(txstatus1),
    .rxdata1(rxdata1), .rxstatus1(rxstatus1),
    .tx_clk1(tx_clk), .rx_clk1(rx_clk),
    .plllkdet1(plllkdet), .resetdone1(resetdone),
    .gtp_reset_i(gtp_reset),
    .refclk_p(REFCLK_P), .refclk_n(REFCLK_N),
    .rxn0(rxn0), .rxp0(rxp0),
    .txn0(txn0), .txp0(txp0),
    .rxn1(RXN1), .rxp1(RXP1),
    .txn1(TXN1), .txp1(TXP1)
);

// bridge between serdes and internal GMII
wire [7:0] txd, rxd;
wire tx_en, tx_er, rx_dv;
wire [5:0] link_leds;
wire [15:0] lacr_rx;
wire [1:0] an_state_mon;
gmii_link glink(
	.RX_CLK(rx_clk),
	.RXD(rxd),
	.RX_DV(rx_dv),
	.GTX_CLK(tx_clk),
	.TXD(txd),
	.TX_EN(tx_en),
	.TX_ER(tx_er),
	.txdata(txdata1), .rxdata(rxdata1),
	.rx_err_los(rxstatus1[4]),
	.an_bypass(1'b1),
	.lacr_rx(lacr_rx),
	.an_state_mon(an_state_mon),
	.leds(link_leds)
);

wire [7:0] eth_status;

larger_eth #(
    .vmod_mode_count(1),
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) larger_eth_i(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    .gmii_tx_clk(tx_clk),
    .gmii_rx_clk(rx_clk),
    .gmii_rxd(rxd),
    .gmii_rx_dv(rx_dv),
    .gmii_rx_er(1'b0),
    .gmii_txd(txd),
    .gmii_tx_en(tx_en),
    .gmii_tx_er(tx_er),
    .eth_status(eth_status)
);

// ============= Housekeeping follows ===================
// SFP management ports idle for now
assign IIC_SCL_SFP = 1'b1;
assign IIC_SDA_SFP = 1'bz;
assign SFP0_TX_DISABLE = 0;
assign SFP0_RATE_SELECT = 1'b1; // full speed

reg [24:0] c1x_ecnt=0;
always @(posedge clk_1x_90) c1x_ecnt<=c1x_ecnt+1;
wire blink_c1x = c1x_ecnt[24];

reg [25:0] c2x_ecnt=0;
always @(posedge clk_2x_0) c2x_ecnt<=c2x_ecnt+1;
wire blink_c2x = c2x_ecnt[25];

//assign LED=eth_status[5:3];
assign LED=link_leds[2:0];

endmodule
