	input        refclk_p,
	input        refclk_n,
	input        rxn0,
	input        rxp0,
	output       txn0,
	output       txp0,
	input        rxn1,
	input        rxp1,
	output       txn1,
	output       txp1,

	// SFP 0 pins
	input        SFP0_LOS,
	input        SFP0_MOD0,
	output       SFP0_MOD1,
	inout        SFP0_MOD2,
	output       SFP0_TX_DISABLE,
	output       SFP0_RATE_SELECT,

	// SFP 1 pins
	input        SFP1_LOS,
	input        SFP1_MOD0,
	output       SFP1_MOD1,
	inout        SFP1_MOD2,
	output       SFP1_TX_DISABLE,
	output       SFP1_RATE_SELECT,
	// IIC master
	inout        IIC_SCL_MAIN,
	inout        IIC_SDA_MAIN,
`ifdef FLLRF
	output [7:0] ccnt,
`endif
`ifdef SP6
	// XXX unnecessary
	input        SYSCLK_P,
	input        SYSCLK_N,
	output [3:0] LED
`else
	output [5:0] DEBUGO,
	output [7:0] LED
`endif
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

   parameter [31:0] ip2 = {8'd131,8'd243,8'd168,8'd81};  // 131.243.168.81
   parameter [47:0] mac2 = 48'h125555000139;
   parameter jumbo_dw = 14;

// ============= Clock setup =============
// Configuration of U35 (SN65LVDS125A, p. 8)
// input 1 (code 00) - 125 MHz local oscillator
// input 2 (code 01) - si571 programmable oscillator
// input 3 (code 10) - 242 MHz (nominal) reference oscillator
// input 4 (code 11) - 242 MHz (nominal) reference oscillator
//
// select local oscillator for all clock inputs
`ifdef FLLRF
assign ccnt[1:0] = 2'b00; // output 1 (fpgaclk0 gclk H19-20)
assign ccnt[3:2] = 2'b00; // output 2 (fpgaclk1 gclk AH13-14)
assign ccnt[5:4] = 2'b00; // output 4 (gtprefclk0 refclk P4-3)
assign ccnt[7:6] = 2'b00; // output 3 (gtprefclk1 refclk Y4-3)
`endif

// ============= Ethernet on SFP0 follows ===================

// The two clocks are sourced from gmii_link
wire rx_clk, tx_clk;

// Stupid resets
reg gtp_reset=1, gtp_reset1=1;
always @(posedge tx_clk) begin
	gtp_reset <= gtp_reset1;
	gtp_reset1 <= 0;
end

wire [9:0] txdata0, rxdata0;
wire [9:0] txdata1, rxdata1;
wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
wire txstatus0, txstatus1;
`ifdef SP6
   // XXX unnecessary
   wire              clk125;

   sp60x_clocks clkgen(
		       .SYSCLK_P(SYSCLK_P), .SYSCLK_N(SYSCLK_N),
		       .RST(1'b0),
		       .CLK125(clk125)
		       );

   wire              plllkdet, resetdone;
   s6_gtp_wrap s6_gtp_wrap_i(
			     .txdata0(txdata0), .txstatus0(txstatus0),
			     .rxdata0(rxdata0), .rxstatus0(rxstatus0),
			     .txdata1(txdata1), .txstatus1(txstatus1),
			     .rxdata1(rxdata1), .rxstatus1(rxstatus1),
 `ifdef GTP1 // for CUTE-WR and SPEC
			     .tx_clk1(tx_clk), .rx_clk1(rx_clk),
			     .plllkdet1(plllkdet), .resetdone1(resetdone),
 `else
			     .tx_clk(tx_clk), .rx_clk(rx_clk),
			     .plllkdet(plllkdet), .resetdone(resetdone),
 `endif
			     .gtp_reset_i(gtp_reset),
			     .refclk_p(refclk_p), .refclk_n(refclk_n),
			     .rxn0(rxn0), .rxp0(rxp0),
			     .txn0(txn0), .txp0(txp0),
	                     .rxn1(rxn1), .rxp1(rxp1),
	                     .txn1(txn1), .txp1(txp1)
			     );
`else
   // Virtex-5 MGT wrapper on top of wrapper on ...
   `ifdef VIRTEX5
        gtp_wrap2 gtp_wrap_i(
            .txdata0(txdata0), .txstatus0(txstatus0),
            .rxdata0(rxdata0), .rxstatus0(rxstatus0),
            .txdata1(txdata1), .txstatus1(txstatus1),
            .rxdata1(rxdata1), .rxstatus1(rxstatus1),
            .tx_clk(tx_clk), .rx_clk(rx_clk), .gtp_reset(gtp_reset),
            .refclk_p(refclk_p), .refclk_n(refclk_n),
            .rxn0(rxn0), .rxp0(rxp0),
            .txn0(txn0), .txp0(txp0),
            .rxn1(rxn1), .rxp1(rxp1),
            .txn1(txn1), .txp1(txp1)
        );
    `endif // !`ifdef VIRTEX5
`endif // !`ifdef SP6

wire [2:0] debug;

// bridge between serdes and internal GMII
// watch the clock domains!
wire [7:0] abst2_in, abst2_out, rxd;
wire abst2_in_s, abst2_out_s, rx_dv;
reg rd=0;  // Running Disparity, see below
wire [5:0] link_leds;
wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
wire [1:0] an_state_mon;
reg an_bypass=1;  // settable by software
gmii_link glink(
	.RX_CLK(rx_clk),
	.RXD(rxd),
	.RX_DV(rx_dv),
	.GTX_CLK(tx_clk),
	.TXD(abst2_out),
	.TX_EN(abst2_out_s),
	.TX_ER(1'b0),
`ifdef GTP1
	.txdata(txdata1), .rxdata(rxdata1),
	.rx_err_los(rxstatus1[4]),
`else
	.txdata(txdata0), .rxdata(rxdata0),
	.rx_err_los(rxstatus0[4]),
`endif
	.an_bypass(an_bypass),
	.lacr_rx(lacr_rx),
	.an_state_mon(an_state_mon),
	.leds(link_leds)
);

// local disparity calculation
// Even though we use the 8b/10b encoder of the Xilinx serdes, we can't
// use its disparity calculator directly: UG196 p. 101, "This running
// disparity [TXCHARDISP] is calculated several cycles after the TXDATA
// is clocked into the FPGA TX interface, so it cannot be used to decide
// the next value to send, as required in some protocols."  It would be
// really nice to measure the delay and cross-check the two calculators.
// Final answer is to switch to TBI (10-bit interface).

//XXX Do we want to route rd into 8b10b encoder through gmii_ink??
//wire rd_out;
//enc_8b10b enc(.datain(txdata0), .dispin(rd), .dispout(rd_out));
//always @(posedge tx_clk) rd <= rd_out & ~gtp_reset;

// FIFO from Rx clock domain to Tx clock domain
gmii_fifo rx2tx(
	.clk_in(rx_clk), .d_in(rxd),   .strobe_in(rx_dv),
	.clk_out(tx_clk),   .d_out(abst2_in), .strobe_out(abst2_in_s)
);

// Single clock domain, abstract Ethernet
wire rx_crc_ok2;
wire [7:0] data_rx2_1;  wire ready2_1, strobe_rx2_1, crc_rx2_1;
wire [7:0] data_rx2_2;  wire ready2_2, strobe_rx2_2, crc_rx2_2;
wire [7:0] data_rx2_3;  wire ready2_3, strobe_rx2_3, crc_rx2_3;
wire [7:0] data_tx2_1;  wire [jumbo_dw-1:0] length2_1;  wire req2_1, ack2_1, warn2_1, strobe_tx2_1;
wire [7:0] data_tx2_2;  wire [jumbo_dw-1:0] length2_2;  wire req2_2, ack2_2, warn2_2, strobe_tx2_2;
wire [7:0] data_tx2_3;  wire [jumbo_dw-1:0] length2_3;  wire req2_3, ack2_3, warn2_3, strobe_tx2_3;
wire [3:0] abst2_leds;
aggregate #(.ip(ip2), .mac(mac2))
   a2(.clk(tx_clk),
      .eth_in(abst2_in),   .eth_in_s(abst2_in_s),
      .eth_out(abst2_out), .eth_out_s(abst2_out_s),
      .rx_crc_ok(rx_crc_ok2),
      .address_set(9'b0),
      .data_rx_1(data_rx2_1), .ready_1(ready2_1), .strobe_rx_1(strobe_rx2_1), .crc_rx_1(crc_rx2_1),
      .data_rx_2(data_rx2_2), .ready_2(ready2_2), .strobe_rx_2(strobe_rx2_2), .crc_rx_2(crc_rx2_2),
      .data_rx_3(data_rx2_3), .ready_3(ready2_3), .strobe_rx_3(strobe_rx2_3), .crc_rx_3(crc_rx2_3),
      .req_1(req2_1), .length_1(length2_1), .ack_1(ack2_1), .warn_1(warn2_1), .strobe_tx_1(strobe_tx2_1), .data_tx_1(data_tx2_1),
      .req_2(req2_2), .length_2(length2_2), .ack_2(ack2_2), .warn_2(warn2_2), .strobe_tx_2(strobe_tx2_2), .data_tx_2(data_tx2_2),
      .req_3(req2_3), .length_3(length2_3), .ack_3(ack2_3), .warn_3(warn2_3), .strobe_tx_3(strobe_tx2_3), .data_tx_3(data_tx2_3),
      .debug(debug), .leds(abst2_leds)
      );

wire [23:0] control2_addr;
wire control2_strobe, control2_rd;
wire [31:0] data2_out;
reg [31:0] data2_in=0;

// instantiate some test clients
// Tx only, but triggered by corresponding Rx ready
client_tx cl1tx(.clk(tx_clk), .ack(ack2_1), .strobe(strobe_tx2_1), .req(req2_1),
	.length(length2_1), .data_out(data_tx2_1), .srx(ready2_1));

wire [1:0] led1;
client_rx cl1rx(.clk(tx_clk), .ready(ready2_1), .strobe(strobe_rx2_1), .crc(crc_rx2_1), .data_in(data_rx2_1), .led(led1));

client_thru cl2rxtx(.clk(tx_clk), .rx_ready(ready2_2), .rx_strobe(strobe_rx2_2), .rx_crc(crc_rx2_2), .data_in(data_rx2_2),
	.nomangle(1'b0),
	.tx_ack(ack2_2), .tx_warn(warn2_2), .tx_req(req2_2), .tx_len(length2_2), .data_out(data_tx2_2));

mem_gateway sfp_cl3(.clk(tx_clk), .rx_ready(ready2_3), .rx_strobe(strobe_rx2_3),
	.rx_crc(crc_rx2_3), .packet_in(data_rx2_3),
	.tx_ack(ack2_3), .tx_strobe(warn2_3), .tx_req(req2_3), .tx_len(length2_3), .packet_out(data_tx2_3),
	.addr(control2_addr), .control_strobe(control2_strobe), .control_rd(control2_rd),
	.data_out(data2_out), .data_in(data2_in));

// Stupid test rig, clock domain matches aggregate
always @(posedge tx_clk) case (control2_addr[2:0])
	0: data2_in <= "Hell";
	1: data2_in <= "o wo";
	2: data2_in <= "rld!";
	3: data2_in <= 32'h0d0a0d0a;
endcase

// ============= Housekeeping follows ===================

// Simple blinker to show clock exists
reg [24:0] ecnt=0;
always @(posedge rx_clk) ecnt<=ecnt+1;
wire blink=ecnt[24];

// SFP management ports idle for now
assign SFP0_MOD1 = 1'b1;
assign SFP0_MOD2 = 1'bz;
assign SFP0_TX_DISABLE = 0;
assign SFP0_RATE_SELECT = 1'b1; // full speed

assign LED={led1,abst2_leds,blink,rx_crc_ok2};  // save rx_crc_ok for later

assign SFP1_MOD1 = 1'b1;
assign SFP1_MOD2 = 1'bz;
assign SFP1_TX_DISABLE = 1;
assign SFP1_RATE_SELECT = 1'b1; // full speed

//assign IIC_SCL_MAIN = 1'bz;
//assign IIC_SDA_MAIN = 1'bz;
`ifndef SP6
   assign DEBUGO={2'b0,debug,rx_clk};
`endif

endmodule
