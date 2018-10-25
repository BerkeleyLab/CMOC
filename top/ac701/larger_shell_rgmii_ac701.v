`timescale 1ns / 1ns

// This is supposed to synthesize to and make timing on the XC7A200T, as used
// on the AC701.

// Most of what's here is chip- and board-specific clock setup,
// and then instantiates larger_eth and the gmii_to_rgmii bridge.

module larger_shell_rgmii_ac701(
    input SYSCLK_P,
    input SYSCLK_N,

    input GLBL_RST,
    output [3:0] PHY_TXD,
    output PHY_TX_CTRL,
    output PHY_TX_CLK,
    input [3:0] PHY_RXD,
    input PHY_RX_CTRL,
    input PHY_RX_CLK,
    output PHY_RESET_B,

    output [3:0] GPIO_LED
);

// LED[0] blink_clk_1x
// LED[1] blink_clk_2x
// LED[2] rx_activity
// LED[3] tx_activity

parameter ip ={8'd128, 8'd3, 8'd128, 8'd122};
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter mac=48'h125555000123;
parameter jumbo_dw=14;

wire clk_1x_90, clk_2x_0, clk_eth, clk_eth_90;

parameter clk2x_div = 7;  // relative to 1200 MHz (on-board oscillator * 6)
series7_clocks #(.mmcm_div0(clk2x_div*2), .mmcm_div1(clk2x_div)) clocks(
    .rst(GLBL_RST),
    .sysclk_p(SYSCLK_P),
    .sysclk_n(SYSCLK_N),
    .clk_eth(clk_eth),
    .clk_eth_90(clk_eth_90),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

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
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rxd(gmii_rxd),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er),
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er),
    .eth_status(eth_status)
);

gmii_to_rgmii gmii_to_rgmii_i(
    .rgmii_txd(PHY_TXD),
    .rgmii_tx_ctl(PHY_TX_CTRL),
    .rgmii_tx_clk(PHY_TX_CLK),
    .rgmii_rxd(PHY_RXD),
    .rgmii_rx_ctl(PHY_RX_CTRL),
    .rgmii_rx_clk(PHY_RX_CLK),

    .gmii_tx_clk(clk_eth),
    .gmii_tx_clk90(clk_eth_90),
    .gmii_txd(gmii_txd),
    .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er),
    .gmii_rxd(gmii_rxd),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_rx_dv(gmii_rx_dv),
    .gmii_rx_er(gmii_rx_er)
);

// PHY reset
// the phy reset output (active low) needs to be held for at least 10x25MHZ cycles
// this is derived using the 125MHz available and a 6 bit counter
reg phy_resetn_int;
reg [5:0] phy_reset_count;

always @(posedge clk_eth)
begin
    if (GLBL_RST) begin
        phy_resetn_int <= 0;
        phy_reset_count <= 0;
    end
    else begin
        if (!(&phy_reset_count)) begin
            phy_reset_count <= phy_reset_count + 1'b1;
        end
        else begin
            phy_resetn_int <= 1'b1;
        end
    end
end

reg [24:0] c1x_ecnt=0;
always @(posedge clk_1x_90) c1x_ecnt<=c1x_ecnt+1;
wire blink_c1x = c1x_ecnt[24];

reg [25:0] c2x_ecnt=0;
always @(posedge clk_2x_0) c2x_ecnt<=c2x_ecnt+1;
wire blink_c2x = c2x_ecnt[25];

assign PHY_RESET_B = phy_resetn_int;
assign GPIO_LED={eth_status[5:4], blink_c2x, blink_c1x};
//assign GPIO_LED={eth_status[5:3], eth_status[0]};

endmodule
