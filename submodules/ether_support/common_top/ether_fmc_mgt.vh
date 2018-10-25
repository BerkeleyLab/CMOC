// -------------------------------------------------------------------------------
// Filename    : ether_fmc_mgt.vh
// Description : Template file fmc-adc demo based on S6 GTP motherboards including
//               SP605, CUTE-WR and SPEC.
// Author      : Qiang Du
// Maintainer  :
// -------------------------------------------------------------------------------
// Created     : Wed Apr 25 18:30:31 2012 (-0700)
// Version     : 1.0

// Code:

`ifndef ETH_IP
`define ETH_IP {8'd131,8'd243,8'd168,8'd80} // 131.243.168.80
`define ETH_MAC 48'h12555500013b
`endif

// tested 13 on SP605 and 12 onSPEC:
`ifndef READ_PIP_LEN
`define READ_PIP_LEN 13
`endif

`timescale 1ns / 1ps

module ether_fmc_mgt(
                 // FMC-ADC related
                 input            trig_in, // External trigger, not used yet
                 output           trig_out, // output trigger, not used yet
                 input            DSP_CLK,
                 input [13:0]     ADCA, // AD9258 Channel A
                 input [13:0]     ADCB, // AD9258 Channel B
                 input            ADC_COA, // AD9258 Channel A data clock
                 input            ADC_COB, // AD9258 Channel B data clock, not used
                 output           ADC_CSB, // AD9258 Chip select (active low)
                 output           ADC_PDWN, // AD9258 Power down
                 output           ADC_SCLK, // AD9258 SPI Clock Pin
                 inout            ADC_SDIO, // AD9258 SPI Data Pin
                 input            ADC_SYNC, // AD9258 Sync pin
                 output [13:0]    DACA, // DAC5672 channel A
                 output [13:0]    DACB, // DAC5672 channel B
                 output           DAC_SLEEP, // DAC5672 enable (active low)
                 output           SPI_SPARE_CS, // D1 on FMC
                 output           SPI_7794_CS,
                 output           SPI_DIN,
                 input            SPI_DOUT,
                 output           SPI_SCLK,
                 input            DSP_CLK2,

                 // Stupid non-general-purpose FPGA pins
                 input            refclk_p,
                 input            refclk_n,
                 input            rxn0,
                 input            rxp0,
                 output           txn0,
                 output           txp0,
                 input            rxn1,
                 input            rxp1,
                 output           txn1,
                 output           txp1,
                 // IIC master
                 inout            IIC_SCL_MAIN,
                 inout            IIC_SDA_MAIN,
                 // SFP 0 pins
                 input            SFP0_LOS,
                 input            SFP0_MOD0,
                 output           SFP0_MOD1,
                 inout            SFP0_MOD2,
                 output           SFP0_TX_DISABLE,
                 output           SFP0_RATE_SELECT,
                 // SFP 1 pins
                 input            SFP1_LOS,
                 input            SFP1_MOD0,
                 output           SFP1_MOD1,
                 inout            SFP1_MOD2,
                 output           SFP1_TX_DISABLE,
                 output           SFP1_RATE_SELECT,
                 // FPGA clock
                 input            SYSCLK_P,
                 input            SYSCLK_N,
                 output [3:0]     LED
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

   sp60x_clocks clkgen(
                       .SYSCLK_P(SYSCLK_P), .SYSCLK_N(SYSCLK_N),
                       .RST(1'b0),
                       .CLK125(eth_clk)
                       );

   IBUFG dspclk_i(.O(fmc_clk), .I(DSP_CLK));

   IBUFG dcoa_i(.O(dcoa_clk), .I(ADC_COA));

   assign dsp_clk = dcoa_clk;

   // ADC interleave mode DDR mux:
   adc_cells adc_cells_i(
                               .clk(dsp_clk),
                               .mux_data_in(ADCA),
                               .adc0(adc_ddra),
                               .adc1(adc_ddrb)
                               );

   assign adc_da = fmc_adc_ddr ? adc_ddra : ADCA;
   assign adc_db = fmc_adc_ddr ? adc_ddrb : ADCB;

   // DAC DDR mux:

   dac_cells dac1(.clk(dsp_clk), .data0(fmc_dac1_out0[15:2]), .data1(fmc_dac1_out1[15:2]), .dac(DACA));
   dac_cells dac2(.clk(dsp_clk), .data0(fmc_dac2_out0[15:2]), .data1(fmc_dac2_out1[15:2]), .dac(DACB));


   // ============= Ethernet on SFP0 follows ===================

   // The two clocks are sourced from gmii_link
   wire rx_clk, tx_clk;

   // Stupid resets
   reg gtp_reset=1, gtp_reset1=1;
   always @(posedge tx_clk) begin
      gtp_reset <= gtp_reset1;
      gtp_reset1 <= 0;
   end

   // Spartan-6 MGT wrapper on top of wrapper on s6_gtpwizard_tile
   wire [9:0] txdata0, rxdata0;
   wire [9:0] txdata1, rxdata1;
   wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
   wire       txstatus0, txstatus1;
   wire       plllkdet, plllkdet1;
   wire       resetdone, resetdone1;

   s6_gtp_wrap s6_gtp_wrap_i(
                             .txdata0(txdata0), .txstatus0(txstatus0),
                             .rxdata0(rxdata0), .rxstatus0(rxstatus0),
                             .txdata1(txdata1), .txstatus1(txstatus1),
                             .rxdata1(rxdata1), .rxstatus1(rxstatus1),
`ifdef GTP1
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

   wire [2:0] debug;

   // bridge between serdes and internal GMII
   // watch the clock domains!
   wire [7:0] abst2_in, abst2_out, rxd;
   wire       abst2_in_s, abst2_out_s, rx_dv;
   reg       rd=0;  // Running Disparity, see below
   reg       rd_hack=0, rd_hack0=0;  // Software-writable
   always @(posedge tx_clk) rd_hack <= rd_hack0;

   wire [5:0] gmii_link_leds;
   wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
   wire [1:0]  an_state_mon;
   reg        an_bypass=1;  // settable by software
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
`else
                .txdata(txdata0), .rxdata(rxdata0),
`endif
                .rx_err_los(rxstatus0[4]),
                .an_bypass(an_bypass),
                .lacr_rx(lacr_rx),
                .an_state_mon(an_state_mon),
                .leds(gmii_link_leds)
                );
   // FIFO from Rx clock domain to Tx clock domain
   gmii_fifo rx2tx(
                .clk_in(rx_clk), .d_in(rxd),   .strobe_in(rx_dv),
                .clk_out(tx_clk),   .d_out(abst2_in), .strobe_out(abst2_in_s)
                );

   // Single clock domain, abstract Ethernet
   wire        rx_crc_fault2;
   wire [7:0]  data_rx2_1;  wire ready2_1, strobe_rx2_1, crc_rx2_1;
   wire [7:0]  data_rx2_2;  wire ready2_2, strobe_rx2_2, crc_rx2_2;
   wire [7:0]  data_rx2_3;  wire ready2_3, strobe_rx2_3, crc_rx2_3;
   wire [7:0]  data_tx2_1;  wire [jumbo_dw-1:0] length2_1;  wire req2_1, ack2_1, warn2_1, strobe_tx2_1;
   wire [7:0]  data_tx2_2;  wire [jumbo_dw-1:0] length2_2;  wire req2_2, ack2_2, warn2_2, strobe_tx2_2;
   wire [7:0]  data_tx2_3;  wire [jumbo_dw-1:0] length2_3;  wire req2_3, ack2_3, warn2_3, strobe_tx2_3;
   wire [3:0]  abst2_leds;
   aggregate #(.ip(ip), .mac(mac))
   a2(
      .clk(tx_clk),
      .eth_in(abst2_in),   .eth_in_s(abst2_in_s),
      .eth_out(abst2_out), .eth_out_s(abst2_out_s),
      .rx_crc_fault(rx_crc_fault2),
      .address_set(9'b0),
      .data_rx_1(data_rx2_1), .ready_1(ready2_1), .strobe_rx_1(strobe_rx2_1), .crc_rx_1(crc_rx2_1),
      .data_rx_2(data_rx2_2), .ready_2(ready2_2), .strobe_rx_2(strobe_rx2_2), .crc_rx_2(crc_rx2_2),
      .data_rx_3(data_rx2_3), .ready_3(ready2_3), .strobe_rx_3(strobe_rx2_3), .crc_rx_3(crc_rx2_3),
      .req_1(req2_1), .length_1(length2_1), .ack_1(ack2_1), .warn_1(warn2_1), .strobe_tx_1(strobe_tx2_1), .data_tx_1(data_tx2_1),
      .req_2(req2_2), .length_2(length2_2), .ack_2(ack2_2), .warn_2(warn2_2), .strobe_tx_2(strobe_tx2_2), .data_tx_2(data_tx2_2),
      .req_3(req2_3), .length_3(length2_3), .ack_3(ack2_3), .warn_3(warn2_3), .strobe_tx_3(strobe_tx2_3), .data_tx_3(data_tx2_3),
        .debug(debug), .leds(abst2_leds)
      );

   reg nomangle=0;
   client_thru cl2rxtx(
                .clk(tx_clk), .rx_ready(ready2_2), .rx_strobe(strobe_rx2_2),
                .rx_crc(crc_rx2_2), .data_in(data_rx2_2),
                .nomangle(nomangle),
                .tx_ack(ack2_2), .tx_warn(warn2_2),
                .tx_req(req2_2), .tx_len(length2_2), .data_out(data_tx2_2)
                );


   wire gtx_clk=eth_clk;

   wire [23:0] control_addr;
   wire        control_strobe, control_rd;
   wire [31:0] data_out;
   wire [31:0] data_in;
   wire        led_fifofull, led_underrun;

   mem_gateway
     #(.read_pipe_len(`READ_PIP_LEN))
   cl3rxtx1 (.clk(tx_clk),
             .rx_ready(ready2_3), .rx_strobe(strobe_rx2_3),
             .rx_crc(crc_rx2_3), .packet_in(data_rx2_3),
             .tx_ack(ack2_3), .tx_strobe(warn2_3),
             .tx_req(req2_3), .tx_len(length2_3), .packet_out(data_tx2_3),
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
   x_eth2dsp(.clk_in(tx_clk), .gate_in(control_strobe), .data_in(lb_word_out_eth),
             .clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
             );
   assign {lb_data,lb_addr,lb_control_rd}=lb_word_out_dsp;

   wire [31:0] fmc_data_out;

   // FMC ADC module follows
   wire [7:0]        cross_time;

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

                     .tx_clk(tx_clk),
                     .tx_req(req2_1),
                     .tx_length(length2_1),
                     .eth_strobe(strobe_tx2_1),
                     .eth_out(data_tx2_1),

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
   freq_count #(.REFCNT_WIDTH(27)) fc_dsp(.f_in(dsp_clk), .clk(tx_clk), .frequency(freq_dsp));

   // CRC fault counter
   reg [31:0]  crc_cnt_lb=0;
   wire [31:0] crc_cnt_dsp;
   wire        crc_cnt_strobe=(rx_crc_fault2==1'b1);
   reg               crc_cnt_strobe_d1=0;
   wire        crc_cnt_strobe_dsp;
   always @(posedge tx_clk) begin
      if(crc_cnt_strobe) crc_cnt_lb <= crc_cnt_lb+1'b1;
      crc_cnt_strobe_d1 <= crc_cnt_strobe;
   end

   // Clock-domain crossing if necessary
   data_xdomain #(.size(32))
   crc_cnt_eth2dsp(.clk_in(tx_clk), .gate_in(crc_cnt_strobe_d1), .data_in(crc_cnt_lb),
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
             .clk_out(tx_clk), .gate_out(lb_control_strobe_back), .data_out(data_in)
             );
   // nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error

   assign LED={led_fifofull, abst2_leds[0],fmc_blink,blink};

   // ============= Housekeeping follows ===================

   // Simple blinker to show clock exists
   reg [24:0]  ecnt=0;
   always @(posedge tx_clk) ecnt<=ecnt+1;
   wire        blink=ecnt[24];

   // Simple blinker to show clock exists
   reg [24:0]  fmc_clk_cnt=0;
   always @(posedge dsp_clk) fmc_clk_cnt<=fmc_clk_cnt+1;
   wire        fmc_blink=fmc_clk_cnt[24];
   assign SFP0_MOD1 = 1'b1;
   assign SFP0_MOD2 = 1'bz;
   assign SFP0_TX_DISABLE = 0;
   assign SFP0_RATE_SELECT = 1'b1; // full speed
   assign SFP1_MOD1 = 1'b1;
   assign SFP1_MOD2 = 1'bz;
   assign SFP1_TX_DISABLE = 0;
   assign SFP1_RATE_SELECT = 1'b1; // full speed

endmodule
//
// ether_fmc_sp605.v ends here
