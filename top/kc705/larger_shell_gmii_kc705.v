`timescale 1ns / 1ns

module larger_shell_gmii_kc705(
    input SYSCLK_P,
    input SYSCLK_N,

    input CPU_RESET,
    // GMII
    output [7:0] PHY_TXD,
    output PHY_TXCTL_TXEN,
    output PHY_TXER,
    output PHY_TXC_GTXCLK,
    input PHY_TXCLK, // not used

    input [7:0] PHY_RXD,
    input PHY_RXER,
    input PHY_RXCTL_RXDV,
    input PHY_RXCLK,
    output PHY_RESET_B,

    output [7:0] GPIO_LED
);

parameter ip ={8'd128, 8'd3, 8'd130, 8'd38};
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
//parameter mac=48'h125555000125;
parameter mac=48'h112233445577;
parameter jumbo_dw=14;

wire clk_1x_90, clk_2x_0, clk_eth, clk_eth_90, pll_locked;

series7_clocks clocks(
    .rst(CPU_RESET),
    .sysclk_p(SYSCLK_P),
    .sysclk_n(SYSCLK_N),
	.pll_lock(pll_locked),
    .clk_eth(clk_eth),
    .clk_eth_90(clk_eth_90),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

// GMII_GTK_CLK output pin is what actually drives the PHY for Tx
`ifdef SIMULATE
assign PHY_TXC_GTXCLK = clk_eth;
`else
ODDR GTXCLK_OUT(
    .Q(PHY_TXC_GTXCLK),
    .C(clk_eth),
    .CE(1'b1),
    .D1(1'b1),
    .D2(1'b0),
    .R(1'b0),
    .S(1'b0)
);
`endif

wire gmii_rx_clk, gmii_rx_dv, gmii_rx_er;
wire gmii_tx_en, gmii_tx_er;
wire [7:0] gmii_rxd, gmii_txd;
wire [7:0] eth_status;

larger_eth #(
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) larger_eth_i(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    .gmii_tx_clk(clk_eth),
    .gmii_rx_clk(PHY_RXCLK),
    .gmii_rxd(PHY_RXD),
    .gmii_rx_dv(PHY_RXCTL_RXDV),
    .gmii_rx_er(PHY_RXER),
    .gmii_txd(PHY_TXD),
    .gmii_tx_en(PHY_TXCTL_TXEN),
    .gmii_tx_er(PHY_TXER),
    .eth_status(eth_status)
);

// PHY reset
// the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
// this is derived using the 125MHz available and a 6 bit counter
reg [23:0] phy_rst_cnt = 0;
always @(posedge clk_eth) begin
	if (CPU_RESET) phy_rst_cnt <= 0;
	else phy_rst_cnt <= (&phy_rst_cnt) ? 24'hffffff : phy_rst_cnt + 1'b1;
end

reg [24:0] c1x_ecnt=0;
always @(posedge clk_1x_90) c1x_ecnt<=c1x_ecnt+1;
wire blink_c1x = c1x_ecnt[24];

reg [25:0] c2x_ecnt=0;
always @(posedge clk_2x_0) c2x_ecnt<=c2x_ecnt+1;
wire blink_c2x = c2x_ecnt[25];

assign PHY_RESET_B = phy_rst_cnt[23];
assign GPIO_LED={eth_status[5:0], blink_c2x, blink_c1x};
//assign GPIO_LED={eth_status[5:3], eth_status[0]};

endmodule
