`timescale 1ns / 1ns

`define ADDR_HIT_dut_coarse_scale 0
`define ADDR_HIT_dut_mp_proc_sel_en 0
`define ADDR_HIT_dut_mp_proc_ph_offset (lb_addr==99)
`define ADDR_HIT_dut_mp_proc_setmp 0
`define ADDR_HIT_dut_mp_proc_coeff 0
`define ADDR_HIT_dut_mp_proc_lim 0
`define ADDR_HIT_lp1_kx 0
`define ADDR_HIT_lp1_ky 0

`define LB_DECODE_fdbk_sys_tb
`include "fdbk_sys_tb_auto.vh"

module fdbk_sys_tb;

reg clk;
integer cc;
reg fail=0;
reg chirp, trace;
integer stderr=32'h8000_0002;  // Maybe icarus-specific
reg chk;
integer cmp_time=0, cmp_last_event[0:9];
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("fdbk_sys.vcd");
		$dumpvars(5,fdbk_sys_tb);
	end
	chirp = $test$plusargs("chirp");
	trace = $test$plusargs("trace");
	for (cc=0; cc < (chirp ? 9000 : 36000); cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$fwrite(stderr, "done\n");
	cmp_last_event[8] = cmp_time;
	cmp_last_event[9] = cmp_time;
	for (jx=0; jx<8; jx=jx+1) begin
		chk = cmp_last_event[jx] < cmp_last_event[jx+2] - 400;
		chk = chk & cmp_last_event[jx] > 10000;
		$display("cmp_last_event[%1d] = %5d < %5d  and > 10000  %s",
			jx, cmp_last_event[jx], cmp_last_event[jx+2] - 400,
			chk ? "   OK" : "FAULT");
		if (!chk) fail = 1;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
end

reg [2:0] state=0;
wire iq=state[0];
real cval, sval;
reg signed [17:0] cos_r=0, sin_r=0, gauss=0;
reg [7:0] rbits;
always @(posedge clk) begin
	state <= state+1;
end

// Local bus (not used for writes in this test bench)
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_write=0;
wire lb_clk = clk;  // important for clocking dprams instantiated by AUTOMATIC_decode

`AUTOMATIC_decode

wire sync1=(state==7);
wire signed [17:0] xy_sim, out_xy;
wire [11:0] cmp_event;
fdbk_core #(.use_mp_proc(1), .use_ll_prop(0)) dut // auto
	(.clk(clk),
	.sync(sync1), .iq(iq), .in_xy(xy_sim), .out_xy(out_xy),
	.cmp_event(cmp_event),
	`AUTOMATIC_dut);

wire signed [19:0] lp_out_xy_l;
lp1 lp1  // auto
	(.clk(clk), .iq(iq), .x(out_xy), .y(lp_out_xy_l),
	`AUTOMATIC_lp1);
wire signed [17:0] lp_out_xy = lp_out_xy_l[19:2];

initial if (~chirp) begin
	#1; // lose race with t=0
	// Configure low-pass filter for 1 MHz bandwidth
	// That gives 160 ns group delay, 16 clock cycles.
	dp_lp1_kx.mem[0] =  10486;  // k_X real part
	dp_lp1_kx.mem[1] =      0;  // k_X imag part
	dp_lp1_ky.mem[0] = -10486;  // k_Y real part
	dp_lp1_ky.mem[1] =      0;  // k_Y imag part
	dut_coarse_scale = 1;  // only applies to direct (non-CORDIC) path
	dut_mp_proc_ph_offset = -5500; // probably not right

	dp_dut_mp_proc_setmp.mem[0] =  29000;  // set X
	dp_dut_mp_proc_setmp.mem[1] =      0;  // set Y
	dp_dut_mp_proc_coeff.mem[0] =      0;  // coeff X I
	dp_dut_mp_proc_coeff.mem[1] =    -77;  // coeff Y I
	dp_dut_mp_proc_coeff.mem[2] =   -472;  // coeff X P
	dp_dut_mp_proc_coeff.mem[3] =   -293;  // coeff Y P
	dp_dut_mp_proc_lim.mem[0] =  22640;  // lim X hi  XXX how to derive this value?
	dp_dut_mp_proc_lim.mem[1] =      0;  // lim Y hi
	dp_dut_mp_proc_lim.mem[2] =  22640;  // lim X lo
	dp_dut_mp_proc_lim.mem[3] =      0;  // lim Y lo
	dut_mp_proc_sel_en = 1;  // Yes, we want SEL
	@(cc==  100); dp_dut_mp_proc_lim.mem[0] =  23800;  dp_dut_mp_proc_lim.mem[2] =  18000;  // lim X hi, lo
	@(cc== 7000); dp_dut_mp_proc_setmp.mem[0] =  30000;  dp_dut_mp_proc_lim.mem[0] =  28000;  // set X, lim X hi
	@(cc== 7800); dp_dut_mp_proc_coeff.mem[0] =   -456 /*-228*/;  // coeff X I
	@(cc==11000); dp_dut_mp_proc_lim.mem[1] =   1000;  dp_dut_mp_proc_lim.mem[3] =  -1000;  // lim Y hi, lo
	@(cc==11200); dp_dut_mp_proc_lim.mem[1] =   1500;  dp_dut_mp_proc_lim.mem[3] =  -1500;  // lim Y hi, lo
	@(cc==11400); dp_dut_mp_proc_lim.mem[1] =   2000;  dp_dut_mp_proc_lim.mem[3] =  -2000;  // lim Y hi, lo
	@(cc==11600); dp_dut_mp_proc_lim.mem[1] =   2500;  dp_dut_mp_proc_lim.mem[3] =  -2500;  // lim Y hi, lo
	@(cc==11800); dp_dut_mp_proc_lim.mem[1] =   3000;  dp_dut_mp_proc_lim.mem[3] =  -3000;  // lim Y hi, lo
	@(cc==12000); dp_dut_mp_proc_lim.mem[1] =   3500;  dp_dut_mp_proc_lim.mem[3] =  -3500;  // lim Y hi, lo
	@(cc==12200); dp_dut_mp_proc_lim.mem[1] =   4000;  dp_dut_mp_proc_lim.mem[3] =  -4000;  // lim Y hi, lo
	@(cc==12400); dp_dut_mp_proc_lim.mem[1] =   4500;  dp_dut_mp_proc_lim.mem[3] =  -4500;  // lim Y hi, lo
	@(cc==12600); dp_dut_mp_proc_lim.mem[1] =   5000;  dp_dut_mp_proc_lim.mem[3] =  -5000;  // lim Y hi, lo
	//@(cc==23000); dut.s0.store[1] =   1000;  // set Y
end

// Chirp simulation
reg [31:0] chirp_f = -200000000; // full scale 2147483648
reg [31:0] chirp_p = 0;
reg [2:0] think=0;
initial if (chirp) begin
	#1; // lose race with t=0
	// Configure low-pass filter for maximum 12.5 MHz bandwidth
	dp_lp1_kx.mem[0] =  130000;  // k_X real part
	dp_lp1_kx.mem[1] =       0;  // k_X imag part
	dp_lp1_ky.mem[0] = -130000;  // k_Y real part
	dp_lp1_ky.mem[1] =       0;  // k_Y imag part
	//dut.coarse_scale = 1;  // only applies to direct (non-CORDIC) path

	// stupid initialization
	dp_dut_mp_proc_setmp.mem[0] =      0;  // set X
	dp_dut_mp_proc_setmp.mem[1] =      0;  // set Y
	dp_dut_mp_proc_coeff.mem[0] =      0;  // coeff X I
	dp_dut_mp_proc_coeff.mem[1] =      0;  // coeff Y I
	dp_dut_mp_proc_coeff.mem[2] =      0;  // coeff X P
	dp_dut_mp_proc_coeff.mem[3] =      0;  // coeff Y P

	// Don't modulate amplitude (yet)
	dp_dut_mp_proc_lim.mem[0] =  22640;  dp_dut_mp_proc_lim.mem[2] =  22640;  // lim X hi, lo
	dp_dut_mp_proc_lim.mem[1] =      0;  dp_dut_mp_proc_lim.mem[3] =      0;  // lim Y hi, lo
	dut_mp_proc_sel_en = 0;  // No SEL, we're just going to chirp
	lb_addr = 0;
end
always @(posedge clk) if (chirp) begin
	think <= think + 1;
	lb_write <= 0;
	lb_data <= 18'bx;
	lb_addr <= 99;  // magic specific for this test bench, see above
	// 3000 cycles total, advance 1 in 8
	if (think==1) begin
		lb_write <= 1;  // ph_offset
		chirp_f <= chirp_f + 500000;
		chirp_p <= chirp_p + chirp_f;
		lb_data <= chirp_p[31:14];
	end
end

// this model should include time delays for ADC, filters,
// amplifier, cables, ...
// XXX disable low-pass filter temporarily
cavity3 cavity(.clk(clk), .iq(iq), .drive(lp_out_xy), .field(xy_sim));

reg signed [17:0] xy_sim_d=0, out_xy_d=0, lp_out_xy_d=0;
always @(posedge clk) begin
	out_xy_d <= out_xy;
	lp_out_xy_d <= lp_out_xy;
	xy_sim_d <= xy_sim;
end

reg signed [17:0] proc_inx, proc_iny, proc_drvx, proc_drvy, proc_pdet;
always @(posedge clk) begin
	if (dut.mp_proc.sync  ) proc_inx <= dut.mp_proc.in_mp;
	if (dut.mp_proc.stb[0]) proc_iny <= dut.mp_proc.in_mp;
	if (dut.mp_proc.stb[2]) proc_pdet <= dut.mp_proc.mp_err2;
	if (dut.mp_proc.stb[6]) proc_drvx <= dut.mp_proc.xy_drive;
	if (dut.mp_proc.stb[7]) proc_drvy <= dut.mp_proc.xy_drive;
end

always @(negedge clk) if (trace && ~iq) $display("%d %d   %d %d   %d %d   %d %d   %d   fdbk_sys_tb",
// lp_out_xy_d, lp_out_xy
	lp_out_xy_d, lp_out_xy, xy_sim_d, xy_sim, proc_inx, proc_iny, proc_drvx, proc_drvy, proc_pdet);

integer jx;

always @(posedge clk) begin
	cmp_time <= cmp_time+1;
	if (cmp_time % 500 == 0) begin
		$fwrite(stderr, ".");
		$fflush(stderr);
	end
	for (jx=0; jx<8; jx=jx+1) begin
		if (cmp_event[jx]) cmp_last_event[jx] = cmp_time;
	end
end

endmodule
