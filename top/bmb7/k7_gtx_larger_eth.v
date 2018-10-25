module k7_gtx_larger_eth #(
	parameter ip ={8'd192, 8'd168, 8'd1, 8'd12},
	parameter mac = 48'h00105ad155b3,  // scraped from a 3C905B
	parameter jumbo_dw=14
) (
	// physical pins
	input gtrefclk_p,
	input gtrefclk_n,
	output sfp_tx_p,
	output sfp_tx_n,
	input sfp_rx_p,
	input sfp_rx_n,
	input clk_1x_90,
	input clk_2x_0,
	// Ethernet configuration port
	input eth_cfg_clk,
	input [9:0] eth_cfg_set,
	// Link status and debug
	input an_bypass,
	output [5:0] link_leds,
	output [15:0] lacr_stat,
	// controls
	input soft_reset,
	input reset,
	input drp_clk,
	output gt_txfsm_resetdone,
	output gt_rxfsm_resetdone,
	output gt_tx_resetdone,
	output gt_rx_resetdone,
	output gt_pll_locked,
	output [6:0] mac_status,
	output gmii_tx_clk,
	output gmii_rx_clk
);

// Reset generation
// UG482 Fig 2-14
wire gt_cpll_locked;
reg [7:0] reset_wait = 0;
wire gtx_reset;
reg gtx_pll_reset = 1'b0;
reg gtx_pll_reset_done = 1'b0;
// UG476, figure 2-16
always @(posedge drp_clk) begin
	reset_wait <= reset_wait + 1;
	gtx_pll_reset <= reset_wait == 60 ? 1'b1 : 0;
	if (reset_wait == 120) gtx_pll_reset_done <= gt_cpll_locked;
end
assign gtx_reset = reset & gtx_pll_reset_done;

//////////////////////////////////////////////////////////////////////////////
// PSPES
wire gtx_rxusrclk, gtx_txusrclk;
wire [19:0] gt_txdata_20b, gt_rxdata_20b;
wire [9:0] tx_data_tbi, rx_data_tbi;
wire usr_tx_clk_rdy, usr_rx_clk_rdy;

gtx_wrap gtx_wrap_i(
    .soft_reset(soft_reset),
    .gtrefclk_p(gtrefclk_p),
    .gtrefclk_n(gtrefclk_n),
    .drpclk_in(drp_clk),
    .gt_txdata_in(gt_txdata_20b),
    .gt_rxdata_out(gt_rxdata_20b),
    .gt_txreset(gtx_reset),
    .gt_rxreset(gtx_reset),
    .gt_cpllreset(gtx_pll_reset),
    .gt_txusrrdy_in(usr_tx_clk_rdy),
    .gt_rxusrrdy_in(usr_rx_clk_rdy),
    .gt_rxn_in(sfp_rx_n),
    .gt_rxp_in(sfp_rx_p),
    .gt_txn_out(sfp_tx_n),
    .gt_txp_out(sfp_tx_p),
    .gt_rxresetdone(gt_rx_resetdone),
    .gt_txresetdone(gt_tx_resetdone),
    .gt_rxfsm_resetdone_out(gt_rxfsm_resetdone),
    .gt_txfsm_resetdone_out(gt_txfsm_resetdone),
    .gt_txusrclk_out(gtx_txusrclk),
    .gt_rxusrclk_out(gtx_rxusrclk),
    .gt_cpll_locked(gt_pll_locked)
);

// Uses 4 BUFG + 2 MMCM primitives
wire gtx_txusrclk_90;
gtp_usrclk gtp_usrclk_i1 (
    .gtp_clk(gtx_txusrclk),
    .gtp_clk_90(gtx_txusrclk_90),
    .gmii_clk(gmii_tx_clk),
    .pll_lock(usr_tx_clk_rdy)
);

wire gtx_rxusrclk_90;
gtp_usrclk gtp_usrclk_i2(
    .gtp_clk(gtx_rxusrclk),
    .gtp_clk_90(gtx_rxusrclk_90),
    .gmii_clk(gmii_rx_clk),
    .pll_lock(usr_rx_clk_rdy)
);

gmii_gtp gmii_gtp_i (
    .gmii_tx_clk(gmii_tx_clk),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_txd(tx_data_tbi),
    .gmii_rxd(rx_data_tbi),
    .gtp_tx_clk(gtx_txusrclk_90),
    .gtp_txd(gt_txdata_20b),
    .gtp_rxd(gt_rxdata_20b)
);

//////////////////////////////////////////////////////////////////////////////
// LBL PSPEPS
// bridge between serdes and internal GMII
// watch the clock domains!
wire [7:0] gmii_rxd, gmii_txd;
wire gmii_rx_dv, gmii_rx_er, gmii_tx_en, gmii_tx_er;

wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
assign lacr_stat = lacr_rx;
wire [1:0] an_state_mon;
gmii_link glink(
	.RX_CLK(gmii_rx_clk),
	.RXD(gmii_rxd),
	.RX_DV(gmii_rx_dv),
	.RX_ER(gmii_rx_er),
	.GTX_CLK(gmii_tx_clk),
	.TXD(gmii_txd),
	.TX_EN(gmii_tx_en),
	.TX_ER(gmii_tx_er),
	.txdata(tx_data_tbi),
	.rxdata(rx_data_tbi),
	.rx_err_los(1'b0),
	.an_bypass(an_bypass),
	.lacr_rx(lacr_rx),
	.an_state_mon(an_state_mon),
	.leds(link_leds)
);

wire [7:0] eth_status;
larger_eth #(
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) larger_eth_i(
    .clk1x(clk_1x_90), // 75MHz
    .clk2x(clk_2x_0), // 150MHz
    .gmii_tx_clk(gmii_tx_clk), // 125MHz
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rxd(gmii_rxd),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er),
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er),
    // IP and MAC address setting
    .eth_cfg_clk(eth_cfg_clk),
    .eth_cfg_set(eth_cfg_set),
    .eth_status(eth_status)
);
assign mac_status = {eth_status[4:2],eth_status[6:5],eth_status[0]};

endmodule
