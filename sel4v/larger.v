`timescale 1ns / 1ns

// Combination of LLRF controller and cavity emulator.
// Portable Verilog, interfaces to a host via an abstract local bus.

// Three clock domains, with the three clocks passed to this module:
//   lb_clk  e.g., 125 MHz Ethernet
//   clk1x   ADC clock of controller, e.g., 94 MHz for LCLS-2
//   clk2x   double-speed clock used by cavity simulator
// Proper data hand-off between clock domains is handled here.

// In an XC7A part, synthesizes to 18132 LUT, 10 RAMB36E1, 9 RAMB18E1, 51 DSP48E1
// Has some "issues" making reasonable timing in the clk2x domain

// 15-bit (0 to 7fff) address map
// write:
//      0 to 3fff   LLRF controller, see llrf_shell.v
//        (use addresses in llrf_shell block of addr_map.vh,
//        and maybe the registers listed in fgen.v and tgen.v)
//   3800           Trigger changeover to next circle_buf
//   4000 to 7fff   Simulator, see vmod1.v
//        (add 4000 to addresses in vmod1 block of addr_map.vh)
// read:
//      0 to   3f   Configuration and parameter ROM, and circle buffer ready flag
//        (see config_romx.v makefile target for bits [7:0]; the ready
//        flag is bit 8)
//   2000 to 21ff   Slow readout, see slow_bridge.v
//        (see slow_larger.list makefile target for the contents)
//   4000 to 5fff   Circular buffer
//        (16-bit signed, usually 8 channels per time step and 1024 time
//        steps, when ch_keep has 8 of 12 bits set)
// Reads are generally passive; the exception is address 5fff, which
// signals that the reading of one buffer is complete so the double-buffer
// logic and flip and make the next one available.

//`define SIMPLE_DEMO  // Used to get a 5-minute bitfile build
module larger(
	input clk1x,
	input clk2x,
	// Local Bus drives both simulator and controller
	// Simulator is in the upper 16K, controller in the lower 16K words.
	input lb_clk,
	input [31:0] lb_data,
	input [14:0] lb_addr,
	input lb_write,  // single-cycle causes a write
	input lb_read,
	output [31:0] lb_out
);

// Note that the following five parameters should all be in the range 0 to 255,
// in order to be properly read out via config_data0, below.
parameter circle_aw = 13; // each half of ping-pong buffer is 8K words
// .. but also allows for testing
// The next four parameters are all passed to vmod1
parameter mode_count = 3;  // drives generate loop in cav4_elec.v
parameter mode_shift = 9;
parameter n_mech_modes = 7;
parameter df_scale = 9;

reg signed [17:0] drive2=0; reg iq2=0;  // computed later
wire [3:0] beam_timing=0;  // XXX for simulator
wire signed [17:0] piezo;  // controller output
wire signed [15:0] a2_field, a2_forward, a2_reflect;  // simulator output

reg signed [15:0] a_field=0, a_forward=0, a_reflect=0;
wire signed [17:0] drive;  wire iq;
wire simple_demo_flag;
`ifndef SIMPLE_DEMO
// Transfer local bus to clk2x domain
wire [31:0] lb2_data;
wire [14:0] lb2_addr;
wire lb2_write;
data_xdomain #(.size(32+15)) lb_to_2x(
	.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
	.clk_out(clk2x), .gate_out(lb2_write), .data_out({lb2_addr,lb2_data})
);

// Instantiate simulator in clk2x domain
wire vmod1_write = lb2_write & lb2_addr[14];
wire [7:0] clips;  // XXX decide on a way to read this out
// Parameter settings here should be mirrored in param.py
vmod1 #(.mode_count(mode_count), .mode_shift(mode_shift), .n_mech_modes(n_mech_modes), .df_scale(df_scale)) vmod1(.clk(clk2x),
	// .beam_timing(beam_timing)
	.iq(iq2), .drive(drive2), .piezo(piezo),
	.a_field(a2_field), .a_forward(a2_forward), .a_reflect(a2_reflect),
	.lb_data(lb2_data), .lb_addr({1'b0,lb2_addr[13:0]}), .lb_write(vmod1_write),
	.clips(clips)
);

// Transfer ADCs to clk1x domain
always @(posedge clk1x) begin
	a_field <= a2_field;
	a_forward <= a2_forward;
	a_reflect <= a2_reflect;
end
assign simple_demo_flag = 0;
`else
assign simple_demo_flag = 1;
`endif  // SIMPLE_DEMO

// Waveform data from llrf
wire [19:0] mon_result;
wire mon_strobe, mon_boundary;

// Instantiate circular buffer
// Reading from 0xfff is magic, says we are done reading a bank
wire [15:0] circle_out, circle_count, circle_stat;
wire circle_stop=0; // not used
wire buf_sync; // temporarily route to llrf_shell trig
//wire circle_stb = lb_read & lb_addr[14:13]==2'b10;
wire circle_data_ready, buf_transferred;

reg [15:0] buf_data=0;
reg buf_strobe=0, buf_bound=0;
wire buf_read = lb_read&(lb_addr[14:13]==2);  // 0x4000 to 0x5fff
wire buf_flip = lb_write&(lb_addr==15'h3800);  // in lb_clk domain
circle_buf #(.aw(circle_aw), .auto_flip(0)) circle(.iclk(clk1x),
	.d_in(buf_data), .stb_in(buf_strobe), .boundary(buf_bound),
	.stop(circle_stop), .buf_sync(buf_sync),
	.buf_transferred(buf_transferred),
	.oclk(lb_clk), .enable(circle_data_ready),
	.read_addr(lb_addr[circle_aw-1:0]), // .read_strobe(buf_read),
	.d_out(circle_out), .stb_out(buf_flip),
	.buf_count(circle_count), .buf_stat(circle_stat)
);

// Bridge slow readout subsystem to the local bus
wire slow_op, slow_invalid;
reg slow_snap=0; always @(posedge clk1x) slow_snap<=buf_sync;
wire [7:0] slow_out, slow_bridge_out;
wire lb_slow_read = lb_read&(lb_addr[14:9]==16);  // 0x2000 to 0x21ff
slow_bridge slow_bridge(
	.lb_clk(lb_clk), .lb_addr(lb_addr),
	.lb_read(lb_slow_read), .lb_out(slow_bridge_out),
	.invalid(slow_invalid),
	.slow_clk(clk1x), .slow_op(slow_op), .slow_snap(buf_transferred),
	.slow_out(slow_out));
wire slow_data_ready = circle_data_ready & ~slow_invalid;  // XXX mixes domains, simulate to make sure it's glitch-free

// Configuration and parameter ROM
wire [7:0] rom_data0;
config_romx rom(.address(lb_addr[4:0]), .data(rom_data0));
reg [7:0] config_data0=0;
always @(lb_addr[4:0]) case(lb_addr[4:0])
	5'h00: config_data0 = 8'haa;
	5'h01: config_data0 = circle_aw;
	5'h02: config_data0 = mode_count;
	5'h03: config_data0 = mode_shift;
	5'h04: config_data0 = n_mech_modes;
	5'h05: config_data0 = df_scale;
	5'h06: config_data0 = simple_demo_flag;
	default: config_data0 = 0;
endcase
reg [9:0] rom_data=0;
always @(posedge lb_clk) rom_data <= {slow_data_ready,circle_data_ready,lb_addr[5]?config_data0:rom_data0};

// This will only get more complex ...
//   control register mirror memory
//   frequency counter
// Configuration has one stage of pipeline circle_buf, slow_bridge, and rom.
// One more here, making read_pipe = 2
reg [14:0] lb_addr_d1=0;
reg [31:0] lb_out_r=0;
always @(posedge lb_clk) begin
	lb_addr_d1 <= lb_addr;
	lb_out_r <= lb_addr_d1[14] ? circle_out : lb_addr_d1[13] ? slow_bridge_out : rom_data;
end
assign lb_out = lb_out_r;

`ifndef SIMPLE_DEMO
// Transfer local bus to clk1x domain
wire [31:0] lb1_data;
wire [14:0] lb1_addr;
wire lb1_write;
data_xdomain #(.size(32+15)) lb_to_1x(
	.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
	.clk_out(clk1x), .gate_out(lb1_write), .data_out({lb1_addr,lb1_data})
);

// Instantiate controller in clk domain
wire ext_trig=buf_sync;
wire master_cic_tick=0;
wire llrf_write = lb1_write & ~lb1_addr[14];
wire [7:0] slow_shell_out;
llrf_shell llrf(.clk(clk1x),
	.a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect),
	.iq(iq), .drive(drive),
	.iq_recv(17'd0), .qsync_rx(1'b0), .tag_rx(8'b0),
	.piezo_ctl(piezo),
	.ext_trig(ext_trig), .master_cic_tick(master_cic_tick),
	.mon_result(mon_result), .mon_strobe(mon_strobe), .mon_boundary(mon_boundary),
	.slow_op(slow_op), .slow_snap(slow_snap), .slow_out(slow_shell_out),
	.lb_clk(lb_clk), .lb_data(lb1_data), .lb_addr(lb1_addr[13:0]), .lb_write(llrf_write)
);

// Move iq and drive to clk2x domain unchanged
reg signed [17:0] drive2x=0;
reg iq2x=0;
always @(posedge clk2x) begin
	drive2x <= drive;
	iq2x <= iq;
end

// Now take care of iq and drive semantics in clk2 domain
reg signed [17:0] drive2_d=0;
reg iq2x_d=0;
always @(posedge clk2x) begin
	iq2x_d <= iq2x;
	drive2 <= iq2x_d ? drive2x: drive2_d;
	drive2_d <= drive2;
	iq2 <= ~clk1x;  // Double Yuck.
end

// decode this address by hand
reg [2:0] cbuf_mode=0;
always @(posedge clk1x) if (lb1_write & (lb1_addr == 554)) cbuf_mode <= lb1_data;

// Make our own additions to slow shift register
// equivalence circle_stat: circle_fault 1, circle_wrap 1, circle_addr 14
`define SLOW_SR_LEN 4*8
`define SLOW_SR_DATA { circle_count, circle_stat }
parameter sr_length = `SLOW_SR_LEN;
reg [sr_length-1:0] slow_read=0;
always @(posedge clk1x) if (slow_op) begin
	slow_read <= slow_snap ? `SLOW_SR_DATA : {slow_read[sr_length-9:0],slow_shell_out};
end
assign slow_out = slow_read[sr_length-1:sr_length-8];

`else
reg simple_iq=0; always @(posedge clk1x) simple_iq <= ~simple_iq;
assign iq=simple_iq;
assign drive=0;
assign mon_result=20'hdead0;
assign mon_strobe=0;
assign mon_boundary=0;
wire [2:0] cbuf_mode=1;  // hard-code simple mode
`endif  // SIMPLE_DEMO

reg [15:0] simple_cnt=0;
always @(posedge clk1x) simple_cnt <= buf_sync ? 0 : simple_cnt+1;
wire [15:0] sim_result = simple_cnt;
wire sim_strobe = simple_cnt[3] == 1;
wire sim_boundary = ~sim_strobe;

always @(posedge clk1x) case (cbuf_mode)
	0: begin buf_data <= mon_result[19:4]; buf_strobe <= mon_strobe; buf_bound <= mon_boundary; end
	1: begin buf_data <= sim_result;       buf_strobe <= sim_strobe; buf_bound <= sim_boundary; end
	2: begin buf_data <= a_field;     buf_strobe <= 1;   buf_bound <= 1; end
	3: begin buf_data <= a_forward;   buf_strobe <= 1;   buf_bound <= 1; end
	4: begin buf_data <= a_reflect;   buf_strobe <= 1;   buf_bound <= 1; end
	5: begin buf_data <= drive[17:2]; buf_strobe <= 1;   buf_bound <= iq; end
	default: begin buf_data <= 0;     buf_strobe <= 0;   buf_bound <= 0; end
endcase

endmodule
