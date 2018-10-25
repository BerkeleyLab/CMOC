`timescale 1ns / 1ns

module agmii2gmii(
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

	// AGMII interface (aggregate)
	// Single clock domain for transmit and receive data
	output agmii_clk,  // timespec 7.2 ns
    // AGMII Rx
    input [7:0] agmii_in,
    input agmii_in_s,
    // AGMII Tx
    output [7:0] agmii_out,
    output agmii_out_s
);

// Latch Rx input pins in IOB
reg [7:0] rxd=0;
reg rx_dv=0, rx_er=0;
always @(posedge RX_CLK) begin
    rxd   <= RXD;
    rx_dv <= RX_DV;
    rx_er <= RX_ER;
end

assign agmii_clk=clk125;

// FIFO from Rx clock domain to Tx clock domain
gmii_fifo rx2tx(
    .clk_in(RX_CLK), .d_in(rxd), .strobe_in(rx_dv),
    .clk_out(agmii_clk), .d_out(agmii_out), .strobe_out(agmii_out_s)
);

assign GTX_CLK = agmii_clk;
assign TXD=agmii_in;
assign TX_EN=agmii_in_s;
assign TX_ER=1'b0;

endmodule
