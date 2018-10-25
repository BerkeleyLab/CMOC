`timescale 1ns / 1ns

module client_txu #(
	parameter tck_mask=1023,  // production; use 3 for test benches
	parameter REFCNT_WIDTH=27, // production; use 12 for test benches
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	// network port as shown in tx_flow.eps
	input clk,
	input ack,
	input strobe,  // actually warn
	output req,
	output [jumbo_dw-1:0] length,
	output [7:0] data_out,

	input [7:0] if_config,

	input rx_clk,  // measures frequency of this clock
	input tx_clk,  // measures frequency of this clock
	input gr_clk,  // measures frequency of this clock

	// Faceplate Ethernet pins
	output GBE_FP_MDC,
	inout  GBE_FP_MDIO,

	// Auxiliary Ethernet pins
	output GBE_AX_MDC,
	inout  GBE_AX_MDIO,

	// SFP 0 pins
	output SFP0_MOD1,
	inout  SFP0_MOD2,

	// SFP 1 pins
	output SFP1_MOD1,
	inout  SFP1_MOD2,

	input [31:0] other   // should include LASR
);

reg [jumbo_dw-1:0] cnt_d = 0;
wire [jumbo_dw-1:0] next_cnt_d = strobe ? cnt_d + 1 : 0;
always @(posedge clk) cnt_d <= next_cnt_d;

// 32-octet configuration ROM
wire [7:0] cnf_data;
config_romx conf(.address(next_cnt_d[4:0]), .data(cnf_data));
reg [7:0] conf_d=0;
always @(posedge clk) conf_d <= cnf_data;

// Frequency counters
wire [31:0] freq_rx, freq_tx, freq_gr;
wire fs;
freq_count2 #(.REFCNT_WIDTH(REFCNT_WIDTH)) fc_rx(.f_in(rx_clk), .clk(clk), .frequency(freq_rx));
freq_count2 #(.REFCNT_WIDTH(REFCNT_WIDTH)) fc_tx(.f_in(tx_clk), .clk(clk), .frequency(freq_tx));
freq_count2 #(.REFCNT_WIDTH(REFCNT_WIDTH)) fc_gr(.f_in(gr_clk), .clk(clk), .frequency(freq_gr), .strobe(fs));

// Network byte order == big-endian
reg [127:0] freq_sr=0;
wire ps = cnt_d[jumbo_dw-1:4]==2; // packet strobe
always @(posedge clk) if (fs | ps)
	freq_sr <= fs ? {freq_rx, freq_tx, freq_gr, other} : {freq_sr[119:0], 8'b0};
wire [7:0] freq_d = freq_sr[127:120];

// Gigabit Ethernet (GBE) serial ports
wire [15:0] mii1_data, mii2_data;
wire  [4:0] mii1_addr, mii2_addr;
wire      mii1_strobe, mii2_strobe;
mii mii_fp(.clk(clk), .MDC(GBE_FP_MDC), .MDIO(GBE_FP_MDIO),
	.strobe(mii1_strobe), .data(mii1_data), .addr(mii1_addr));
mii mii_ax(.clk(clk), .MDC(GBE_AX_MDC), .MDIO(GBE_AX_MDIO),
	.strobe(mii2_strobe), .data(mii2_data), .addr(mii2_addr));

// SFP Digital Diagnostics Transceiver Controllers
wire [7:0] sfp0_pc, sfp1_pc;
wire [8:0] sfp0_result, sfp1_result;
wire sfp0_strobe, sfp1_strobe, sfp_sync;
sfp_ddmi #(.tck_mask(tck_mask)) sfp0_i(
	.clk(clk), .SCL(SFP0_MOD1), .SDA(SFP0_MOD2), .sync(sfp_sync),
	.alt_add(if_config[6:4]),
	.pc_out(sfp0_pc), .result_out(sfp0_result), .strobe_out(sfp0_strobe));
sfp_ddmi #(.tck_mask(tck_mask)) sfp1_i(
	.clk(clk), .SCL(SFP1_MOD1), .SDA(SFP1_MOD2),
	.alt_add(if_config[6:4]),
	.pc_out(sfp1_pc), .result_out(sfp1_result), .strobe_out(sfp1_strobe));

// Somewhat cheesy multiplexer of the four above serial readouts
wire [1:0] link_sel=if_config[1:0]; // XXX not very efficient
reg [7:0] link_a=0, link_d=0;
reg link_s=0;
always @(posedge clk) case (link_sel)
	2'b00: begin link_a<=mii1_addr;  link_d<=mii1_data;     link_s<=mii1_strobe; end
	2'b01: begin link_a<=mii2_addr;  link_d<=mii2_data;     link_s<=mii2_strobe; end
	2'b10: begin link_a<=sfp0_pc; link_d<=sfp0_result[8:1]; link_s<=sfp0_strobe; end
	2'b11: begin link_a<=sfp1_pc; link_d<=sfp1_result[8:1]; link_s<=sfp1_strobe; end
endcase

// Save results in dual-port RAM
wire [7:0] ram_d;
wire dpram_save;
wire dpram_wen = link_s & dpram_save;
dpram #(.aw(8), .dw(8)) ram1(.clka(clk), .clkb(clk),
	.addra(link_a), .dina(link_d), .wena(dpram_wen),
	.addrb(cnt_d[7:0]-8'd64), .doutb(ram_d));

parameter [2:0]
  ST_WAIT=0,
  ST_SER0=1,
  ST_SER1=2,
  ST_TX0=3,
  ST_TX1=4;
reg [2:0] st=ST_WAIT;
assign dpram_save= (st==ST_SER1);
reg req_r=0;
always @(posedge clk) case(st)
	ST_WAIT: begin
		if (fs) st <= ST_SER0;
	end
	ST_SER0: begin
		if (link_s & (link_a==0)) st <= ST_SER1;
	end
	ST_SER1: begin
		if (link_s & (link_a==0)) st <= ST_TX0;
	end
	ST_TX0: begin
		req_r <= 1;
		if (ack) begin
			req_r <= 0;
			st <= ST_TX1;
		end
	end
	ST_TX1: if (cnt_d == 14'd320) st <= ST_WAIT;
endcase

// Final datapath multiplexer
reg [7:0] d_out = 0;
always @(posedge clk) case (cnt_d[jumbo_dw-1:4])
	0: d_out <= conf_d;
	1: d_out <= conf_d;
	2: d_out <= freq_d;
	3: d_out <= 0;
	default: d_out <= ram_d;
endcase

assign req = req_r;
assign length = 320;
assign data_out = strobe ? d_out : 8'h00;

endmodule
