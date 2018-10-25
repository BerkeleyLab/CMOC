// -------------------------------------------------------------------------------
// -- Title      : larger as an Ethernet client
// -- project    : CMOC
// -------------------------------------------------------------------------------
// -- File Name  : larger_eth.v
// -- Author     : Qiang Du
// -- Company    : LBNL
// -- Created    : 09-05-2014
// -- Last Update: 10-07-2014 13:33:28
// -- Standard   : Verilog
// -------------------------------------------------------------------------------
// -- Description:
// -------------------------------------------------------------------------------
// -------------------------------------------------------------------------------
// -- Copyright (c) LBNL
// -------------------------------------------------------------------------------
`timescale 1ns / 1ns

module larger_eth (
    input clk1x,
    input clk2x,
    input gmii_tx_clk,
    input gmii_rx_clk,
    input [7:0] gmii_rxd,
    input gmii_rx_dv,
    input gmii_rx_er,  // not used XXX that's a mistake
    output [7:0] gmii_txd,
    output gmii_tx_en,
    output gmii_tx_er,
    // Ethernet configuration port
    input eth_cfg_clk,
    input [9:0] eth_cfg_set,
    output [7:0] eth_status
);

parameter ip ={8'd192, 8'd168, 8'd7, 8'd4};
parameter mac=48'h112233445566;
parameter jumbo_dw=14;
parameter vmod_mode_count=3;
parameter cavity_count=2;

wire lb_clk;
wire eth_lb_control_strobe, eth_lb_control_rd;
wire [23:0] eth_lb_addr;
wire [31:0] eth_lb_data_out;
wire [31:0] eth_lb_data_in;

wire rx_crc_fault;

ethergate #(
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw),
    .address_xdomain(1),
    .mem_gateway_pipeline(3)
) ethergate_i (
    .clk125(gmii_tx_clk),
    .RX_CLK(gmii_rx_clk),
    .RXD(gmii_rxd),
    .RX_DV(gmii_rx_dv),
    .RX_ER(gmii_rx_er),
    // GMII Tx
    .TXD(gmii_txd),
    .TX_EN(gmii_tx_en),
    .TX_ER(gmii_tx_er),

    // IP and MAC address setting
    // It's a bug that there's no enable bit
    .address_clk(eth_cfg_clk),
    .address_set(eth_cfg_set[8:0]),

    // Local bus interface
    .lb_clk(lb_clk),
    .lb_addr(eth_lb_addr),
    .lb_control_strobe(eth_lb_control_strobe),
    .lb_control_rd(eth_lb_control_rd),
    .lb_data_in(eth_lb_data_in),
    .lb_data_out(eth_lb_data_out),

    //USER run-time option to set last byte of IP address
    .ethernet_leds(eth_status),
    .rx_crc_fault(rx_crc_fault)
);

wire lb_write = eth_lb_control_strobe & ~eth_lb_control_rd;
wire lb_read  = eth_lb_control_strobe &  eth_lb_control_rd;
cryomodule #(
    .cavity_count(cavity_count),
    .mode_count(vmod_mode_count)
) cryomodule(
    .clk1x(clk1x),
    .clk2x(clk2x),
    // Local Bus drives both simulator and controller
    // Simulator is in the upper 16K, controller in the lower 16K words.
    .lb_clk(lb_clk),
    .lb_data(eth_lb_data_out),
    .lb_addr(eth_lb_addr[16:0]),
    .lb_write(lb_write),  // single-cycle causes a write // XXX write or strobe?
    .lb_read(lb_read),
    .lb_out(eth_lb_data_in)
);

endmodule
