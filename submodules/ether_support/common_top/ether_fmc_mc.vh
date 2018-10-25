// -------------------------------------------------------------------------------
// Filename    : ether_fmc_mc.vh
// Description : Template file for ether_fmc instaniation based on gmii
// Author      : Qiang Du
// Maintainer  :
// -------------------------------------------------------------------------------
// Created     : Tue Jun 26 10:47:55 2012 (-0700)

// Change Log  :
// 26-Jun-2012    Qiang Du
//    Initial version.
// -------------------------------------------------------------------------------

// Code:

`ifndef ETH_IP
`define ETH_IP {8'd131,8'd243,8'd168,8'd80} // 131.243.168.80
`define ETH_MAC 48'h12555500013a
`endif

`ifndef READ_PIP_LEN
`define READ_PIP_LEN 13
`endif

// SP60X has 4 user LEDs
`ifndef N_LED
`define N_LED 4
`endif

`timescale 1ns / 1ps

module ether_fmc_mc(
                      // FMC-ADC related
                      input               trig_in, // External trigger input @ J44 P1
                      output              trig_out, // output trigger signal @ J44 P2
                      input               DSP_CLK,
                      input [13:0]        ADCA, // AD9258 Channel A
                      input [13:0]        ADCB, // AD9258 Channel B
                      input               ADC_COA, // AD9258 Channel A data clock
                      input               ADC_COB, // AD9258 Channel B data clock, not used
                      input               DSP_CLK2, // DSP clock directly from fmc-adc board, not used
                      output              ADC_CSB, // AD9258 Chip select (active low)
                      output              ADC_PDWN, // AD9258 Power down
                      output              ADC_SCLK, // AD9258 SPI Clock Pin
                      inout               ADC_SDIO, // AD9258 SPI Data Pin
                      input               ADC_SYNC, // AD9258 Sync pin
                      output [13:0]       DACA, // DAC5672 channel A
                      output [13:0]       DACB, // DAC5672 channel B
                      output              DAC_SLEEP, // DAC5672 enable (active low)
                      output              SPI_SPARE_CS, // D1 on FMC
                      output              SPI_7794_CS,
                      output              SPI_DIN,
                      input               SPI_DOUT,
                      output              SPI_SCLK,

`ifdef SIM_ETHER_FMC
                      // GMII related:
                      input               GMII_MCLK,
`else
                      // Faceplate Ethernet pins
                      output              PHY_MDC, // not used
                      inout               PHY_MDIO, // not used
                      input               SYSCLK_P,
                      input               SYSCLK_N,
                      input               SYSCLK,
`endif
                      input               GMII_RX_CLK,
                      input [7:0]         GMII_RXD,
                      input               GMII_RX_DV,
                      input               GMII_RX_ER, // not used XXX that's a mistake
                      output              GMII_GTX_CLK,
                      input               GMII_TX_CLK, // not used
                      output reg [7:0]    GMII_TXD,
                      output reg          GMII_TX_EN,
                      output reg          GMII_TX_ER,
                      output              PHY_RSTN,
                      output [`N_LED-1:0] LED
                      );

   parameter [31:0] ip  = `ETH_IP;
   parameter [47:0] mac = `ETH_MAC;
   parameter jumbo_dw = 14;

   reg [3:0] power_conf_iob=4'b0000;// Start all off (except for FP Eth, see below)

   // ============= Clock setup =============
   wire        eth_clk; // 125MHz generated from 200MHz osc, for copper GMII
   wire        fmc_clk; // from fmc-adc external clock
   wire        dsp_clk; // from AD9258 outputed data clock
   wire        dcoa_clk;
   wire [13:0] adc_da, adc_db;
   wire        fmc_adc_ddr;
   wire [13:0] adc_ddra, adc_ddrb;
   wire [15:0] fmc_dac1_out0, fmc_dac1_out1, fmc_dac2_out0, fmc_dac2_out1;

`ifdef SIM_ETHER_FMC
   assign eth_clk = GMII_MCLK;
   assign GMII_GTX_CLK = eth_clk;
   assign fmc_clk = DSP_CLK;
   assign dcoa_clk = ADC_COA;
   assign adc_da = ADCA;
   assign adc_db = ADCB;
   assign dsp_clk = dcoa_clk;
`else
   sp60x_clocks
 `ifdef 100MHZ_CLK_SINGLE // 10ns period, single input
        #(.clk2_period(10), .mult(8), .divide_out(4), .diff_input(0))
          clkgen(
		       .SYSCLK(SYSCLK),
 `else
	  clkgen(
		       .SYSCLK_P(SYSCLK_P), .SYSCLK_N(SYSCLK_N),
 `endif
		       .RST(1'b0),
		       .CLK125(eth_clk)
		       );
   ODDR2 GTXCLK_OUT(
		    .Q(GMII_GTX_CLK),
		    .C0(eth_clk),
		    .C1(~eth_clk),
		    .CE(1'b1),
		    .D0(1'b1),
		    .D1(1'b0),
		    .R(1'b0),
		    .S(1'b0)
		    );

   IBUFG dspclk_i(.O(fmc_clk), .I(DSP_CLK));

   IBUFG dcoa_i(.O(dcoa_clk), .I(ADC_COA));

   assign dsp_clk = dcoa_clk;

   // ADC interleave mode DDR mux:
   adc_cells adc_cells_i(.clk(dsp_clk), .mux_data_in(ADCA), .adc0(adc_ddra), .adc1(adc_ddrb));

   assign adc_da = fmc_adc_ddr ? adc_ddra : ADCA;
   assign adc_db = fmc_adc_ddr ? adc_ddrb : ADCB;

   // DAC DDR mux:

   dac_cells #(.width(14)) dac1(.clk(dsp_clk), .data0(fmc_dac1_out0[15:2]), .data1(fmc_dac1_out1[15:2]), .dac(DACA));
   dac_cells #(.width(14)) dac2(.clk(dsp_clk), .data0(fmc_dac2_out0[15:2]), .data1(fmc_dac2_out1[15:2]), .dac(DACB));
`endif // !`ifdef SIM_ETHER_FMC

   // ============= Faceplate GMII Ethernet follows ===================
   wire gtx_clk=eth_clk;
   wire fp_clk=eth_clk;   // at some point we want a ring clock instead

   // Latch Rx input pins in IOB
   reg [7:0] rx1d=0;
   reg        rx1_dv=0, rx1_er=0;
   always @(posedge GMII_RX_CLK) begin
      rx1d   <= GMII_RXD;
      rx1_dv <= GMII_RX_DV;
      rx1_er <= GMII_RX_ER;
   end
   // FIFO from Rx clock domain to ring clock domain
   wire [7:0] abst1_in, abst1_out;
   wire       abst1_in_s, abst1_out_s;
   gmii_fifo rx2ring(
		     .clk_in(GMII_RX_CLK), .d_in(rx1d),  .strobe_in(rx1_dv),
		     .clk_out(fp_clk),    .d_out(abst1_in), .strobe_out(abst1_in_s)
		     );

   // Single clock domain, abstract Ethernet
   wire       rx_crc_fault;
   wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
   wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
   wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
   wire [7:0] data_tx_1;  wire [jumbo_dw-1:0] length_1;  wire req_1, ack_1, warn_1, strobe_tx_1;
   wire [7:0] data_tx_2;  wire [jumbo_dw-1:0] length_2;  wire req_2, ack_2, warn_2, strobe_tx_2;
   wire [7:0] data_tx_3;  wire [jumbo_dw-1:0] length_3;  wire req_3, ack_3, warn_3, strobe_tx_3;
   wire [3:0] abst1_leds;
   aggregate #(.ip(ip), .mac(mac))
   a1(
      .clk(fp_clk),
      .eth_in(abst1_in),   .eth_in_s(abst1_in_s),
      .eth_out(abst1_out), .eth_out_s(abst1_out_s),
      .rx_crc_fault(rx_crc_fault),
      .address_set(9'b0),
      .data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
      .data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
      .data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),
      .req_1(req_1), .length_1(length_1), .ack_1(ack_1), .warn_1(warn_1), .strobe_tx_1(strobe_tx_1), .data_tx_1(data_tx_1),
      .req_2(req_2), .length_2(length_2), .ack_2(ack_2), .warn_2(warn_2), .strobe_tx_2(strobe_tx_2), .data_tx_2(data_tx_2),
      .req_3(req_3), .length_3(length_3), .ack_3(ack_3), .warn_3(warn_3), .strobe_tx_3(strobe_tx_3), .data_tx_3(data_tx_3),
      .leds(abst1_leds)
      );

   reg nomangle=0;
   client_thru cl2rxtx1 (
			 .clk(fp_clk),
			 .rx_ready(ready_2), .rx_strobe(strobe_rx_2),
			 .rx_crc(crc_rx_2), .data_in(data_rx_2),
			 .nomangle(nomangle),
			 .tx_ack(ack_2), .tx_warn(warn_2),
			 .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2)
			 );

   wire [23:0] control_addr;
   wire        control_strobe, control_rd;
   wire [31:0] data_out;
   wire [31:0] data_in;
   wire        led_fifofull, led_underrun;

   mem_gateway
     #(.read_pipe_len(`READ_PIP_LEN))
   cl3rxtx1 (.clk(fp_clk),
	     .rx_ready(ready_3), .rx_strobe(strobe_rx_3),
	     .rx_crc(crc_rx_3), .packet_in(data_rx_3),
	     .tx_ack(ack_3), .tx_strobe(warn_3),
	     .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),
	     .addr(control_addr),
	     .control_strobe(control_strobe), .control_rd(control_rd),
	     .fifo_full(led_fifofull), .underrun(led_underrun),
	     .data_out(data_out), .data_in(data_in)
	     );

   // ============= Ether - local bus interfaces =============
   // Clock domain crossing between local bus/Ethernet and dsp clock domains provided below
   // Local bus address
   wire [31:0] lb_data;
   wire [23:0] lb_addr;
   wire        lb_control_rd;
   wire        lb_control_strobe;
   wire [56:0] lb_word_out_eth={data_out, control_addr, control_rd};
   wire [56:0] lb_word_out_dsp;

   // Clock domain crossing ((local bus/Ethernet) --> dsp clock domains)
   data_xdomain #(.size(57))
   x_eth2dsp(.clk_in(eth_clk), .gate_in(control_strobe), .data_in(lb_word_out_eth),
	     .clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
	     );
   assign {lb_data,lb_addr,lb_control_rd}=lb_word_out_dsp;

   wire [31:0] fmc_data_out;

   // FMC ADC module follows
   wire [7:0] cross_time;

   fmc_adc fmc_adc_i(
		     .clk(dsp_clk),
		     .adc1({adc_da,2'b0}), .adc2({adc_db,2'b0}),
		     .trig_in(trig_in), .trig_out(trig_out),
		     .cross_time(cross_time),

		     .lb_data(lb_data),
		     .lb_addr(lb_addr[19:0]),
		     .lb_strobe(lb_control_strobe),
		     .lb_read(lb_control_rd),
		     .lb_data_out(fmc_data_out),

		     .tx_clk(eth_clk),
		     .tx_req(req_1),
		     .tx_length(length_1),
		     .eth_strobe(strobe_tx_1),
		     .eth_out(data_tx_1),

		     .adc_ddr(fmc_adc_ddr),
		     .adc_csb(ADC_CSB),
		     .adc_pdwn(ADC_PDWN),
		     .adc_sclk(ADC_SCLK),
		     .adc_sdio(ADC_SDIO),
		     .adc_sync(ADC_SYNC),

	         .dac1_out0(fmc_dac1_out0),
	         .dac1_out1(fmc_dac1_out1),
	         .dac2_out0(fmc_dac2_out0),
		     .dac2_out1(fmc_dac2_out1),
		     .dac_sleep(DAC_SLEEP),

		     .spi_spare_cs(SPI_SPARE_CS),
		     .spi_7794_cs(SPI_7794_CS),
		     .spi_din(SPI_DIN),
		     .spi_dout(SPI_DOUT),
		     .spi_sclk(SPI_SCLK)
		     );

   // Four modules connected to the local bus: config_romx, freq_count, fmc_adc, and dsp_sim
   // config_romx: 32-octet configuration ROM
   wire [4:0]  cnf_address;
   wire [7:0]  cnf_data;
   wire        cnf_strobe;
   config_romx config_romx1( .address(cnf_address), .data(cnf_data));

   // Frequency counters, refresh rate: 125MHz/2^27 = 0.931 Hz
   wire [31:0] freq_rx, freq_dsp;
   freq_count #(.REFCNT_WIDTH(27)) fc_dsp(.f_in(dsp_clk), .clk(eth_clk), .frequency(freq_dsp));

   // CRC fault counter
   reg [31:0]  crc_cnt_lb=0;
   wire [31:0] crc_cnt_dsp;
   wire        crc_cnt_strobe=(rx_crc_fault==1'b1);
   reg         crc_cnt_strobe_d1=0;
   wire        crc_cnt_strobe_dsp;
   always @(posedge eth_clk) begin
      if(crc_cnt_strobe) crc_cnt_lb <= crc_cnt_lb+1'b1;
      crc_cnt_strobe_d1 <= crc_cnt_strobe;
   end

   // Clock-domain crossing if necessary
   data_xdomain #(.size(32))
   crc_cnt_eth2dsp(.clk_in(eth_clk), .gate_in(crc_cnt_strobe_d1), .data_in(crc_cnt_lb),
		   .clk_out(dsp_clk), .gate_out(crc_cnt_strobe_dsp), .data_out(crc_cnt_dsp)
		   );

   // Host writable registers
   reg [9:0] fmc_config_iob=0;
   wire      dsp_control_rd, dsp_control_strobe;

   assign dsp_control_strobe=(lb_addr[23:20]==4'b0001)&lb_control_strobe;

   reg [31:0]  reg_data=0;  // pipeline all register writes through here
   reg [4:0]   reg_addr=0;
   reg         reg_write=0;
   always @ (posedge dsp_clk) if (dsp_control_strobe) begin
      reg_data <= lb_data;
      reg_addr <= lb_addr[5:0];
   end
   always @ (posedge dsp_clk) begin
      // address decoder should light up for 0x010000 through 0x01003f
      reg_write <= dsp_control_strobe & ~lb_control_rd & (lb_addr[19:16]==4'h1);
      if (reg_write & (reg_addr==6'h02)) fmc_config_iob <= reg_data;
   end

   // Clock domain crossing (dsp --> (local bus/Ethernet) clock domains)
   reg         lb_control_strobe_d1=1'b0, lb_control_strobe_d2=1'b0, lb_control_strobe_d3=1'b0;
   wire        lb_control_strobe_back;
   // dsp clock domain
   reg [31:0]  lb_data_in;

   // Introduce 3 clock cycle delay to strobe to match data bus pipeline
   always @(posedge dsp_clk) begin
      lb_control_strobe_d1 <= lb_control_strobe;
      lb_control_strobe_d2 <= lb_control_strobe_d1;
      lb_control_strobe_d3 <= lb_control_strobe_d2;
   end

   // Multiplexer selecting data output from the different modules to the Ethernet input via the local data bus
   always @(posedge dsp_clk) if (lb_control_rd)
	case(lb_addr[23:20])
          1: lb_data_in <= fmc_config_iob; // not used yet
	  2: lb_data_in <= {24'b0,cnf_data};
	  3: lb_data_in <= freq_dsp;
	  4: lb_data_in <= crc_cnt_dsp;
	  5: lb_data_in <= "Hell";
	  6: lb_data_in <= "o wo";
	  7: lb_data_in <= "rld!";
	  8: lb_data_in <= fmc_data_out;
	  default: lb_data_in <= 32'hdeadbeaf;
	endcase // case (lb_addr[23:20])

   data_xdomain #(.size(32))
   x_dsp2eth(.clk_in(dsp_clk), .gate_in(lb_control_strobe_d3), .data_in(lb_data_in),
	     .clk_out(eth_clk), .gate_out(lb_control_strobe_back), .data_out(data_in)
	     );
   // nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error

   assign LED={led_fifofull, abst1_leds,fmc_blink,blink};

   // FIFO from ring clock domain to tx clock domain
   wire [7:0] txd;
   wire       tx_en;
   gmii_fifo ring2tx(
		     .clk_in(fp_clk), .d_in(abst1_out), .strobe_in(abst1_out_s),
		     .clk_out(gtx_clk), .d_out(txd), .strobe_out(tx_en)
		     );

   // Latch Tx output pins in IOB
   always @(posedge gtx_clk) begin
      GMII_TXD   <= txd;
      GMII_TX_EN <= tx_en;
      GMII_TX_ER <= 0;  // Our logic never needs this
   end

   // ============= Housekeeping follows ===================

   // Simple blinker to show clock exists
   reg [24:0]  ecnt=0;
   always @(posedge fp_clk) ecnt<=ecnt+1;
   wire        blink=ecnt[24];

   // Simple blinker to show clock exists
   reg [24:0]  fmc_clk_cnt=0;
   always @(posedge dsp_clk) fmc_clk_cnt<=fmc_clk_cnt+1;
   wire        fmc_blink=fmc_clk_cnt[24];


   assign PHY_RSTN=1;    // Can't do anything unless PHY is out of reset

endmodule
//
// ether_fmc_mc.vh ends here
