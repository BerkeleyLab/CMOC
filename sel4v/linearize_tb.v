`timescale 1ns / 1ns

`include "addr_map_linearize_tb.vh"
`define LB_DECODE_linearize_tb
`include "linearize_tb_auto.vh"

module linearize_tb;

reg clk, fail=0;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("linearize.vcd");
		$dumpvars(5,linearize_tb);
	end
	for (cc=0; cc<555; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",fail?"FAIL":"PASS");
end

reg [1:0] qphase=0;
always @(posedge clk) qphase <= qphase+1;

reg signed [15:0] i_cart;
reg [16:0] i_angl;

always @(posedge clk) begin
	i_cart <= 16'bx;
	i_angl <= 17'bx;
	if (cc==7) begin i_cart <= 6000; i_angl <= 0; end  // I1
	if (cc==9) begin i_cart <= 8000; i_angl <= 0; end  // Q1
	if (cc==12) begin i_cart <= 6000; i_angl <= 0; end  // I2
	if (cc==14) begin i_cart <= 8000; i_angl <= 0; end  // Q2
	if (cc>30 && cc%4==3) begin i_cart <= (cc*61>32767) ? 32767 : cc*61; i_angl <= 0; end
	if (cc>30 && cc%4==0) begin i_cart <= 0; i_angl <= 0; end
end

// Local bus (not used in this test bench)
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_clk=0, lb_write=0;

`AUTOMATIC_decode

// even addresses for gain, odd addresses for phase offset
integer jx, point, opoint;
initial begin
	// bank=0
	for (jx=0; jx<32; jx=jx+1) begin
		dp_dut_curvegen_offset_rom.mem[jx+  0]=16384;  // 1 gain
		dp_dut_curvegen_offset_rom.mem[jx+ 32]=32767;  // 2 gain
		dp_dut_curvegen_offset_rom.mem[jx+ 64]=    1;  // 1 poff
		dp_dut_curvegen_offset_rom.mem[jx+ 96]=    2;  // 2 poff
		dp_dut_curvegen_slope_rom.mem[jx+  0]=0;
		dp_dut_curvegen_slope_rom.mem[jx+ 32]=0;
		dp_dut_curvegen_slope_rom.mem[jx+ 64]=0;
		dp_dut_curvegen_slope_rom.mem[jx+ 96]=0;
	end
	// bank=1
	opoint = 16384;
	for (jx=0; jx<32; jx=jx+1) begin
		point = 16384 + (jx+1)*150 + (jx+1)*(jx+1);
		dp_dut_curvegen_offset_rom.mem[jx+  0+128]=opoint;  // 1 gain
		dp_dut_curvegen_offset_rom.mem[jx+ 64+128]=    1;  // 1 poff
		dp_dut_curvegen_slope_rom.mem[jx+  0+128]=point-opoint;
		dp_dut_curvegen_slope_rom.mem[jx+ 64+128]=0;
		opoint = point;
	end
	@(cc==30);
	dut_curvegen_bank=1;
end

wire signed [15:0] o_cart;
wire [16:0] o_angl;
wire [1:0] o_qphase;
linearize dut // auto
	(.clk(clk), .i_qphase(qphase),
	.i_cart(i_cart), .i_angl(i_angl),
	.o_cart(o_cart), .o_angl(o_angl), .o_qphase(o_qphase),
	`AUTOMATIC_dut);

wire signed [15:0] d_cart;
reg_delay #(.dw(16), .len(10)) test_del(.clk(clk), .gate(1'b1),
	.din(i_cart), .dout(d_cart));

integer gain;
reg signed [47:0] c2, pred;
always @(negedge clk) if (cc>40 && cc < 550 && o_qphase==0) begin
	gain = 65536*o_cart/d_cart;
	c2 = d_cart*d_cart;
	pred = 32768+ c2*150/(4096*4096) + (c2/65536)*(c2/65536)/131072;
	//$display("%d %d %d %d", d_cart, o_cart, gain, pred);
	//$display(d_cart, gain-pred);
	if (gain-pred > 5 || gain-pred < -25) fail=1;
	if (gain-pred < -7 && d_cart > 8000) fail=1;
end

endmodule
