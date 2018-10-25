// -------------------------------------------------------------------------------
// -- Title      : Test bench for gmii_gtp interface
// -- Project    : LLRF5
// -------------------------------------------------------------------------------
// -- File Name  : gmii_gtp_tb.v
// -- Author     : Qiang Du
// -- Company    : LBNL
// -- Created    : 08-06-2014
// -- Last Update: 08-07-2014 15:20:15
// -- Standard   : Verilog
// -------------------------------------------------------------------------------
// -- Description:
// -------------------------------------------------------------------------------
// -------------------------------------------------------------------------------
// -- Copyright (c) LBNL
// -------------------------------------------------------------------------------
`timescale 1ns / 100ps
module gmii_gtp_tb;

localparam dw=8;

reg gmii_clk, clk, gtp_clk_90, gmii_rx_clk;

integer seed, jitter;
initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("gmii_gtp.vcd");
        $dumpvars(5, gmii_gtp_tb);
    end
    gmii_clk = 1'b0;
    clk = 1'b0;
    gtp_clk_90 = 1'b0;
    gmii_rx_clk = 1'b0;
    seed = 10;
    forever #4 gmii_clk = ~gmii_clk;
end

always begin
//    jitter = $dist_uniform(seed,0,1);
    #8 gtp_clk_90 = ~gtp_clk_90;
end

always #4.3 gmii_rx_clk = ~gmii_rx_clk;

initial begin
    #12;
    forever #8 clk = ~clk;
end

initial #2000 $finish();

reg [dw-1:0] tx_data=0; // tx data fram MAC
wire [dw-1:0] rx_data; // rx data to MAC
integer oc=0; // octet counter
integer f;
reg tx_enable;
always @(posedge gmii_clk) begin
    oc <= oc+1;
    f = oc%79 + (oc/178);
    tx_enable <= f > 30;
    tx_data <= (f>38) ? oc : (f==38) ? 8'hd5 : 8'h55 ;
    //tx_data <= f;
end

integer oc2=0;
wire [2*dw+3:0] d_loop; // rx data to GTP

//reg [2*dw+3:0] d_rx_f; // rx data from GTP
//always @(posedge clk) begin
//    oc2 <= oc2+1;
//    d_rx_f <= oc2;
//end

gmii_gtp #(
    .dw(dw+2)
) foo (
    .gmii_tx_clk(gmii_clk),
    .gmii_rx_clk(gmii_rx_clk),
    .gmii_txd(d_tx_2f),
    .gmii_rxd(d_rx_2f),
    .gtp_tx_clk(gtp_clk_90),
    .gtp_txd(d_loop),
    .gtp_rxd(d_loop)
);

wire operate;
wire rx_dv, rx_er;
wire [dw+1:0] d_tx_2f, d_rx_2f;

gmii_link link(
	.RX_CLK(gmii_clk), .RXD(rx_data), .RX_DV(rx_dv), .RX_ER(rx_er),
	.GTX_CLK(gmii_clk), .TXD(tx_data), .TX_EN(tx_enable), .TX_ER(1'b0),
	.an_bypass(1'b0),
	.txdata(d_tx_2f), .rx_err_los(1'b0),
	.rxdata(d_rx_2f), .operate(operate));
endmodule
