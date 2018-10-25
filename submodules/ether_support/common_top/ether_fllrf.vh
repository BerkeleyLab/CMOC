// This .vh file is intended for inclusion in a "real" .v file,
// in particular, one that makes a few `defines to configure this
// file for a particular board.  Preprocessor variables used here:
//   SP60X
//   ML50X
//   FLLRF
//   SERDES_5T
//   SAME_CLOCKS
//   CAVITY_SIM
//   HAVE_ODDR2

	// Reference clock input
`ifdef SERDES_5T
	input   refclk_p,
	input   refclk_n,
	input   rxn0,
	input   rxp0,
	output  txn0,
	output  txp0,
	input   rxn1,
	input   rxp1,
	output  txn1,
	output  txp1,
`else
	`ifdef SP60X
		`ifdef SINGLE_100_CLK
			input SYSCLK,
		`else
			input SYSCLK_P,
			input SYSCLK_N,
		`endif
	`else
		`ifdef ML50X
			input SYSCLK_P,
			input SYSCLK_N,
		`else
			input GMII_MCLK,
			input DSP_CLK,
		`endif
	`endif
	//XXX Remove DIP SWITCH just for testing
	//input [7:0] DIP_SWITCH,

	// GMII interface
	// GMII Rx
	input GMII_RX_CLK,
	input [7:0] GMII_RXD,
	input GMII_RX_DV,
	input GMII_RX_ER,  // not used XXX that's a mistake
	// GMII Tx
	output GMII_GTX_CLK,
	input  GMII_TX_CLK,  // not used
	output [7:0] GMII_TXD,
	output GMII_TX_EN,
	output GMII_TX_ER,
	output PHY_RSTN,
`endif

`ifdef FLLRF

`ifndef SAME_CLOCKS
	output [7:0] ccnt,

	input clkn,
	input clkp,
`endif

`ifndef CAVITY_SIM
	// High speed DAC outputs
	output [13:0] dac0outp,
	output [13:0] dac0outn,
	output [13:0] dac1outp,
	output [13:0] dac1outn,
	output [13:0] dac2outp,
	output [13:0] dac2outn,

	// DAC2 shutdown control
	output dac2shtdn,

	// Microprocessor interface
	inout [15:0] ucad,
	input ucadd,
	input ucclk,
	input ucwr,

	// U89  DAC7568
	output gpdacsclk,
	output gpdacsyncn,
	output gpdacdata,
	output gpdacsclk_t,
	//output gpdacsyncn_t,
	output gpdacdata_t,

	// U81  ADS7951
	output bhadcsclk,
	output bhadcscs,
	output bhadcsdi,
	input bhadcsdo,

	// U95  ADS7951
	output gpadcsclk,
	output gpadcscs,
	output gpadcsdi,
	input gpadcsdo,

	// U137  DAC8568
	output oxodacsclk,
	output oxodacsyncn,
	output oxodacdata,
	output oxodacdata_t,
	output oxodacsclk_t,
	output oxodacsyncn_t,

	// High speed ADC inputs
	input adc5cinp,
	input adc5cinn,
	input [15:0] adc0inp,
	input [15:0] adc0inn,
	input [15:0] adc1inp,
	input [15:0] adc1inn,
	input [15:0] adc2inp,
	input [15:0] adc2inn,
	input [15:0] adc3inp,
	input [15:0] adc3inn,
	input [15:0] adc4inp,
	input [15:0] adc4inn,
	input [13:0] adc5inp,
	input [13:0] adc5inn,
	output [5:0] adcshtdn,

	// Diagnostic DAC outputs
	output [9:0] ddac0,
	output [9:0] ddac1,
	output [9:0] ddac2,
	output [9:0] ddac3,
	output ddac0mode,
	output ddac1mode,
	output ddac2mode,
	output ddac3mode,
	output ddac0siq,
	output ddac1siq,
	output ddac2siq,
	output ddac3siq,
	output ddacsleep,
	output ddacreset,

	// Miscellaneous
	input [8:0] extdatin,
	output [8:0] extdatout,
	output [1:0] ucoflags,
	input [1:0] uciflags,
	input [7:0] plcin,
	output [7:0] plcout,
	input trigin,
	output trigout,
	output trigout2,
`endif
	// LEDs, are these temporary?
	output led1,
	output led2,
	output led3,
	output led4,
	output led5,
	output led6
`else
	// Other pins used in development
	output [7:0] LED
`endif
);

// IP and MAC adresses
// Use global variables defined in top level module
parameter [31:0] ip = `MY_IP;
parameter [47:0] mac = `MY_MAC;
wire [7:0] DIP_SWITCH = ip[7:0];  // Bit select for now

`ifdef FLLRF
// map LEDs as best we can
wire [7:0] LED;
/*
assign led1=~LED[0];
assign led2=~LED[2];
assign led3=~LED[3];
assign led4=~LED[4];
assign led5=~LED[5];
assign led6=~LED[6];
*/
// LED map for testing
assign led1=~LED[0];  //blink_rx
assign led2=~LED[1];  //rx_crc_ok
assign led3=~LED[3];  //arp reply
assign led4=~LED[4];  //rx activity
assign led5=~LED[6];  //mem_gateway_underrun
assign led6=~LED[7];  //mem_gateway_fifo_full

`ifndef CAVITY_SIM
// Diagnostic DACs not yet used
assign ddac0=0;  assign ddac0mode=0;  assign ddac0siq=0;
assign ddac1=0;  assign ddac1mode=0;  assign ddac1siq=0;
assign ddac2=0;  assign ddac2mode=0;  assign ddac2siq=0;
assign ddac3=0;  assign ddac3mode=0;  assign ddac3siq=0;
assign ddacsleep=1;  assign ddacreset=1;

// Board Health ADC not supported yet
assign bhadcsclk = 0;
assign bhadcscs = 0;
assign bhadcsdi = bhadcsdo;

// General Purpose ADC not supported yet
assign gpadcsclk = 0;
assign gpadcscs = 0;
assign gpadcsdi = gpadcsdo;

// mirror some pins for rev. 0 workaround
assign gpdacsclk_t = gpdacsclk;
//assign gpdacsyncn_t = gpdacsyncn;
assign gpdacdata_t = gpdacdata;
assign oxodacdata_t = oxodacdata;
assign oxodacsclk_t = oxodacsclk;
assign oxodacsyncn_t = oxodacsyncn;

// No current use for this chip.  When there is, instantiate
// a serdacseq as is done for the oxodac signals.
assign gpdacsclk=0;
assign gpdacdata=0;
assign gpdacsyncn = 0;

// one totally unused ADC
wire [13:0] dsp_in5d;
wire adc5c;
IBUFDS adc0x(.I(adc5cinp), .IB(adc5cinn), .O(adc5c));


// Pretend to use some unused inputs
assign extdatout=extdatin^dsp_in5d[13:7]^dsp_in5d[6:0]^adc5c^trigin;
assign plcout = plcin;
assign ucoflags = uciflags;

wire intlk_in = plcin[0];
`else
wire intlk_in = 1'b1;
`endif

`ifndef SAME_CLOCKS
// ============= Clock setup =============
// Configuration of U35 (SN65LVDS125A, p. 8)
// input 1 (code 00) - 125 MHz local oscillator
// input 2 (code 10) - si571 programmable oscillator
// input 3 (code 01) - 242 MHz (nominal) reference oscillator
// input 4 (code 11) - 242 MHz (nominal) reference oscillator
//
// select local oscillator for all clock inputs
assign ccnt[1:0] = 2'b01; // output 1 (fpgaclk0 gclk H19-20)
assign ccnt[3:2] = 2'b00; // output 2 (fpgaclk1 gclk AH13-14)
assign ccnt[5:4] = 2'b00; // output 4 (gtprefclk0 refclk P4-3)
assign ccnt[7:6] = 2'b00; // output 3 (gtprefclk1 refclk Y4-3)

wire clk;
//IBUFDS clkin(.I(clkp), .IB(clkn), .O(clk));
fllrf_dsp_clockgen dsp_clkgen(
	.CLKIN1_P_IN(clkp), .CLKIN1_N_IN(clkn),
	.RST_IN(1'b0),
	.CLKOUT0_OUT(clk)
);
wire DSP_CLK=clk;
`endif

`endif

// Local bus interface ports
wire lb_clk;
wire [23:0] eth_lb_addr;
wire eth_lb_control_strobe, eth_lb_control_rd;
wire [31:0] eth_lb_data_in;
wire [31:0] eth_lb_data_out;

wire eth_clk;

`ifdef SERDES_5T
wire GMII_RX_CLK, GMII_GTX_CLK, GMII_TX_CLK;
wire [7:0] GMII_RXD, GMII_TXD;
wire GMII_RX_DV, GMII_RX_ER, GMII_TX_EN, GMII_TX_ER;

mgt_gmii_link mgt_gmii_link1(
	.refclk_p(refclk_p), .refclk_n(refclk_n),
	.rxn0(rxn0), .rxp0(rxp0), .txn0(txn0), .txp0(txp0),
	.rxn1(rxn1), .rxp1(rxp1), .txn1(txn1), .txp1(txp1),
	.GMII_RX_CLK(GMII_RX_CLK), .GMII_RXD(GMII_RXD), .GMII_RX_DV(GMII_RX_DV), .GMII_RX_ER(GMII_RX_ER),
	.GMII_GTX_CLK(eth_clk), .GMII_TX_CLK(GMII_TX_CLK),
	.GMII_TXD(GMII_TXD), .GMII_TX_EN(GMII_TX_EN), .GMII_TX_ER(GMII_TX_ER)
);

`else
assign PHY_RSTN=1;    // Can't do anything unless PHY is out of reset
`ifdef LX150T
sp60x_clocks  #(.clk2_period(10), .mult(8), .divide_out(4), .diff_input(0))
	clkgen(
		.SYSCLK(SYSCLK),
		.RST(1'b0),
		.CLK125(eth_clk)
);
`endif


`ifdef SP60X
sp60x_clocks
`ifdef SINGLE_100_CLK // 10ns period, single input
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
`else
`ifdef ML50X
ml50x_clocks clkgen(
	.CLKIN1_P_IN(SYSCLK_P), .CLKIN1_N_IN(SYSCLK_N),
	.RST_IN(1'b0),
	.CLKOUT0_OUT(eth_clk)
);
`else
`else
assign eth_clk=GMII_MCLK;
`endif
`endif
`endif

// Ethernet module: GMII to local bus interface
wire [8:0] address_set;
wire rx_crc_fault;
wire gmii_gtx_clk_;
ethergate #(.ip(ip), .mac(mac),
`ifdef SAME_CLOCKS
 .mem_gateway_pipeline(3)
`else
 .mem_gateway_pipeline(11)
`endif
) gmii_to_localbus(
	// 125MHz Reference clock
	.clk125(eth_clk),

	// GMII interface
	// GMII Rx
	.RX_CLK(GMII_RX_CLK),
	.RXD(GMII_RXD),
	.RX_DV(GMII_RX_DV),
	.RX_ER(GMII_RX_ER),
	// GMII Tx
	.GTX_CLK(gmii_gtx_clk_),
	.TXD(GMII_TXD),
	.TX_EN(GMII_TX_EN),
	.TX_ER(GMII_TX_ER),

	.address_clk(eth_clk),
	.address_set(address_set),

	// Local bus interface
	.lb_clk(lb_clk),
	.lb_addr(eth_lb_addr),
	.lb_control_strobe(eth_lb_control_strobe),
	.lb_control_rd(eth_lb_control_rd),
	.lb_data_in(eth_lb_data_in),
	.lb_data_out(eth_lb_data_out),

	//USER run-time option to set last byte of IP address
	.ethernet_leds(LED),
	.rx_crc_fault(rx_crc_fault)
);

`ifdef HAVE_ODDR2
ODDR2 GTXCLK_OUT(
	.Q(GMII_GTX_CLK),
	.C0(gmii_gtx_clk_),
	.C1(~gmii_gtx_clk_),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);
`else
assign GMII_GTX_CLK=gmii_gtx_clk_;
`endif

set_address #(.ip_net(ip), .mac(mac)) setter(.clk(eth_clk), .rst(1'b0), .last_ip_byte(DIP_SWITCH), .address_set(address_set));

// Use 125MHz clock for dsp: dsp_clk will eventually be assigned to the ring clock source
// Clock domain crossing between local bus/Ethernet and dsp clock domains provided below
wire [31:0] lb_data_out;
wire [23:0] lb_addr;
wire lb_control_rd;
wire lb_control_strobe;
wire dsp_clk;

`ifdef SAME_CLOCKS
assign dsp_clk=eth_clk;
assign lb_data_out=eth_lb_data_out;
assign lb_addr=eth_lb_addr;
assign lb_control_rd=eth_lb_control_rd;
assign lb_control_strobe=eth_lb_control_strobe;
`else
assign dsp_clk=DSP_CLK;
// Clock domain crossing ((local bus/Ethernet) --> dsp clock domains)
wire [56:0] lb_word_out_eth={eth_lb_data_out, eth_lb_addr, eth_lb_control_rd};
wire [56:0] lb_word_out_dsp;
data_xdomain #(.size(57)) x_eth2dsp(
	.clk_in(lb_clk), .gate_in(eth_lb_control_strobe), .data_in(lb_word_out_eth),
	.clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
);

assign {lb_data_out,lb_addr,lb_control_rd}=lb_word_out_dsp;
`endif

// Four modules connected to the local bus: config_romx, freq_count, dsp, and dsp_sim
// config_romx: 32-octet configuration ROM
wire [4:0] cnf_address;
wire [7:0] cnf_data;
wire cnf_strobe;
config_romx config_romx1(
	.address(cnf_address), .data(cnf_data)
);

// Frequency counters
parameter REFCNT_WIDTH=27; // production; use 12 for test benches
wire [31:0] freq_rx, freq_dsp;
freq_count #(.REFCNT_WIDTH(REFCNT_WIDTH)) fc_rx(.f_in(GMII_RX_CLK), .clk(lb_clk), .frequency(freq_rx));
freq_count #(.REFCNT_WIDTH(REFCNT_WIDTH)) fc_dsp(.f_in(lb_clk), .clk(dsp_clk), .frequency(freq_dsp));

// CRC fault counter
reg [31:0] crc_cnt_lb=0;
wire [31:0] crc_cnt_dsp;
wire crc_cnt_strobe=(rx_crc_fault==1'b1);
reg crc_cnt_strobe_d1=0;
wire crc_cnt_strobe_dsp;
always @(posedge lb_clk) begin
	if(crc_cnt_strobe) crc_cnt_lb <= crc_cnt_lb+1'b1;
	crc_cnt_strobe_d1 <= crc_cnt_strobe;
end
// Clock-domain crossing if necessary
`ifdef SAME_CLOCKS
assign crc_cnt_dsp=crc_cnt_lb;
assign crc_cnt_strobe_dsp=crc_cnt_strobe;
`else
data_xdomain #(.size(32)) crc_cnt_eth2dsp(
	.clk_in(lb_clk), .gate_in(crc_cnt_strobe_d1), .data_in(crc_cnt_lb),
	.clk_out(dsp_clk), .gate_out(crc_cnt_strobe_dsp), .data_out(crc_cnt_dsp)
);
`endif

reg [9:0] rf_config_iob=0;  // Host-writable, see below
wire [63:0] serial_out;
wire serial_sync, start_rf;
wire [23:0] dsp_address;
wire dsp_control_rd, dsp_control_strobe;

// Duplicate address decoding and pipelining also found in dsp.v
// Synthesizer will eliminate duplicate gates
reg [31:0] reg_data=0;  // pipeline all register writes through here
reg [4:0]  reg_addr=0;
reg reg_write=0;
always @ (posedge dsp_clk) if (dsp_control_strobe) begin
	reg_data <= lb_data_out;
	reg_addr <= dsp_address[5:0];
end
always @ (posedge dsp_clk) begin
	// address decoder should light up for 0x010000 through 0x01003f
	reg_write <= dsp_control_strobe & ~dsp_control_rd & (dsp_address[19:16]==4'h1);
	if (reg_write & (reg_addr==6'h02)) rf_config_iob <= reg_data;
end

wire serial_src;
`ifdef FLLRF
assign serial_src = rf_config_iob[9] ? 1'b0 : extdatin[0];  // confirmed by Massimo 2011-06-23
`else
assign serial_src = 1'b0;
`endif

wire [7:0] rx_errors;
serial_rx2 #(.serial_cnt_width(5)) serial_rx(.clk(dsp_clk),
	.bit(serial_src), .sync(serial_sync), .d(serial_out), .errors(rx_errors));

// DSP: dsp module connected to cavity simulator (dsp_sim)
// DSP module
wire [15:0] dsp_in0d, dsp_in1d, dsp_in2d, dsp_in3d, dsp_in4d;

wire serial_sel = rf_config_iob[8];
wire [31:0] serial_use = serial_sel ? serial_out[63:32] : serial_out[31:0];
wire [31:0] dsp_data_out;
wire dsp_mod_ctrl;
wire [15:0] dsp_pll_data;
wire dsp_pll_strobe;
wire [15:0] dsp_dac1_out0, dsp_dac1_out1, dsp_dac2_out0, dsp_dac2_out1;
dsp #(.invert_adc_sign(0)) dsp1(
	.clk(dsp_clk),
	.in0d(dsp_in0d), .in1d(dsp_in1d),.in2d(dsp_in2d),.in3d(dsp_in3d),.in4d(dsp_in4d),
	.delay(serial_use), .delay_strobe(serial_sync), .start_rf(start_rf),
	.control_rd(dsp_control_rd), .control_strobe(dsp_control_strobe),
	.data_in(lb_data_out), .address(dsp_address), .data_out(dsp_data_out),
	.dac1_out0(dsp_dac1_out0), .dac1_out1(dsp_dac1_out1), .dac2_out0(dsp_dac2_out0), .dac2_out1(dsp_dac2_out1),
	.mod_ctrl(dsp_mod_ctrl), .pll_data(dsp_pll_data), .pll_strobe(dsp_pll_strobe)
);
// No DDR internal to the chip, just ignore the dac*_out2 ports

// Timing module
wire trigger;
wire [31:0] timing_data_out;
timing timing_x(.clk(dsp_clk),
	.control_strobe(dsp_control_strobe), .control_rd(dsp_control_rd),
	.address(dsp_address), .data_in(lb_data_out),
	.data_out(timing_data_out),
	.intlk_in(intlk_in), .trigger(trigger),
	.start_rf(start_rf)
);

wire [31:0] sim_data_out;

// 120.8 MHz dsp_clk, enabled one cycle out of eight, each such enable toggles
// the serial DAC clock, yielding 7.55 MHz on that clock pin.
reg [15:0] dsp_pll_data_hold=0;
reg dsp_pll_strobe_hold=0;
reg [2:0] eighth=0;
wire dac_clk_ena=&eighth;
reg dac_post=0;

always @(posedge dsp_clk) begin
	eighth <= eighth+1;
	if(dsp_pll_strobe) begin
		dsp_pll_data_hold <= {~dsp_pll_data[15],dsp_pll_data[14:0]};
		dsp_pll_strobe_hold <= 1'b1;
	end
	else if(dac_clk_ena) dsp_pll_strobe_hold <= 1'b0;
end

`ifdef CAVITY_SIM
// In hardware configurations, these signals are declared above as User I/O points.
// In simulation, they are declared here but not used anywhere.
wire oxodacdata, oxodacsclk, oxodacsyncn;
`endif

// This module is designed to drive serdacseq ena with dsp_pll_strobe_hold,
// but that doesn't work at the moment.  Setting it to 1 will give erratic
// latency, but simulation shows this approach will always send the right data.
serdacseq dac7568(.clk(dsp_clk), .clkena(dac_clk_ena), .rst(1'b1), .ena(1'b1),
        .initval(32'h80000001), .chansel(12'h00f), .dataval(dsp_pll_data_hold),
        .sdata(oxodacdata), .sclk(oxodacsclk), .syncn(oxodacsyncn)
);

`ifndef CAVITY_SIM
assign sim_data_out=0;
assign trigger=trigin;  // useless until I reconfigure timing module to listen
assign trigout=dsp_mod_ctrl;
assign trigout2=dsp_mod_ctrl;
// Still could use a deeper understanding of how best to clock this mess.

dac_cells_5d dac1(.clk(dsp_clk),
        .data0(dsp_dac1_out0[15:2]), .data1(dsp_dac1_out1[15:2]),
        .dacp(dac0outp), .dacn(dac0outn));
dac_cells_5d dac2(.clk(dsp_clk),
        .data0(dsp_dac2_out0[15:2]), .data1(dsp_dac2_out1[15:2]),
        .dacp(dac1outp), .dacn(dac1outn));
dac_cells_5d dac3(.clk(dsp_clk),  // placeholder, need OBUFDS
        .data0(14'b0), .data1(14'b0),
        .dacp(dac2outp), .dacn(dac2outn));

adc_cells_5d #(.pincount(16)) adc0(.inp(adc0inp), .inn(adc0inn), .in(dsp_in0d));
adc_cells_5d #(.pincount(16)) adc1(.inp(adc1inp), .inn(adc1inn), .in(dsp_in1d));
adc_cells_5d #(.pincount(16)) adc2(.inp(adc2inp), .inn(adc2inn), .in(dsp_in2d));
adc_cells_5d #(.pincount(16)) adc3(.inp(adc3inp), .inn(adc3inn), .in(dsp_in3d));
adc_cells_5d #(.pincount(16)) adc4(.inp(adc4inp), .inn(adc4inn), .in(dsp_in4d));
adc_cells_5d #(.pincount(14)) adc5(.inp(adc5inp), .inn(adc5inn), .in(dsp_in5d));
assign adcshtdn = ~rf_config_iob[5:0];
assign dac2shtdn = ~rf_config_iob[5];

// Silly start on microprocessor interface
reg ucclk_1=0, ucclk_2=0;
reg [15:0] uc_data=0;
always @(posedge dsp_clk) begin
        ucclk_1 <= ucclk;
        ucclk_2 <= ucclk_1;
        if (ucclk_1 & ~ucclk_2 & ucwr) uc_data <= ucwr ? ucad : (uc_data+1'b1);
end
assign ucad = ucadd ? uc_data : 16'bzzzzzzzzzzzzzzzz;

`else
// Cavity module
wire sim_control_rd, sim_control_strobe;
wire [23:0] sim_address;
dsp_sim #(.invert_adc_sign(0)) dsp_sim1(
	.clk(dsp_clk),
	.in0d(dsp_in0d), .in1d(dsp_in1d),.in2d(dsp_in2d),.in3d(dsp_in3d),.in4d(dsp_in4d),
	.dac1_out(dsp_dac1_out0), .dac2_out(dsp_dac2_out0),
	.intlk_in(intlk_in), .trigger(trigger),
	.control_rd(sim_control_rd), .control_strobe(sim_control_strobe),
	.data_in(lb_data_out), .address(sim_address), .data_out(sim_data_out)
);
`endif

// Input and output multiplexers onto the local bus
// 4-bit address module select
wire [3:0] lb_module_sel=lb_addr[23:20];

// dsp and sim control strobes set when address matches
assign dsp_control_strobe=(lb_module_sel==4'b0010)& lb_control_strobe;
assign sim_control_strobe=(lb_module_sel==4'b0011)& lb_control_strobe;

// Multiplex the output of the Ethernet local bus into the different data inputs

// Read/Write control signal assigned (ignored if strobe is not set)
assign dsp_control_rd=lb_control_rd;
assign sim_control_rd=lb_control_rd;

// Local bus address
assign dsp_address=lb_addr;
assign sim_address=lb_addr;
assign cnf_address=lb_addr[4:0];

// Multiplexer selecting data output from the different modules to the Ethernet input via the local data bus
// dsp clock domain
reg [31:0] eth_dsp_data_in = 32'b0;
always @(posedge dsp_clk) case(lb_addr[23:20])
	4'b0010: eth_dsp_data_in <= dsp_data_out;
	4'b0011: eth_dsp_data_in <= sim_data_out;
	4'b0100: eth_dsp_data_in <= freq_rx;
	4'b0101: eth_dsp_data_in <= {24'b0,cnf_data};
	4'b0110: eth_dsp_data_in <= freq_dsp;
	4'b0111: eth_dsp_data_in <= serial_use;
	4'b1000: eth_dsp_data_in <= rx_errors;
	4'b1001: eth_dsp_data_in <= crc_cnt_dsp;
	4'b1010: eth_dsp_data_in <= timing_data_out;
	default: eth_dsp_data_in <= 32'hdeadbeef;
endcase

// Clock domain crossing (dsp --> (local bus/Ethernet) clock domains)
reg lb_control_strobe_d1=1'b0, lb_control_strobe_d2=1'b0, lb_control_strobe_d3=1'b0;
wire lb_control_strobe_back;
// Introduce 3 clock cycle delay to strobe to match data bus pipeline
always @(posedge dsp_clk) begin
	lb_control_strobe_d1 <= lb_control_strobe;
	lb_control_strobe_d2 <= lb_control_strobe_d1;
	lb_control_strobe_d3 <= lb_control_strobe_d2;
end

`ifdef SAME_CLOCKS
assign lb_control_strobe_back=lb_control_strobe_d3;
assign eth_lb_data_in=eth_dsp_data_in;
`else
data_xdomain #(.size(32)) x_dsp2eth(
	.clk_in(dsp_clk), .gate_in(lb_control_strobe_d3), .data_in(eth_dsp_data_in),
	.clk_out(lb_clk), .gate_out(lb_control_strobe_back), .data_out(eth_lb_data_in)
);
`endif
// nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error

endmodule
