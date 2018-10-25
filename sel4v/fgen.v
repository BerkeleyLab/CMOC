`timescale 1ns / 1ns

// Function generator
// Interposes in and passes-through a local register write bus
// One-cycle delay from input bus to output bus
// Controlling bus has priority for access to the controlled bus.
// Output "collision" when a function generator write gets lost.
// That's a single-cycle output, which needs to be latched and/or
// counted by whoever instantiates this module.
// Local registers are a block of 16 addresses, default to the first
// 16 in the address space, but configurable by the addr_hi parameter.

// Features:
//  pulse with adjustable rise time/fall time
//  linear or quadratic phase generator
//  optional CORDIC
//  optional sqrt(x)
//  (future goal) A*f + B*df/dt
//  selectable destination address

//  Address map (offsets from 16 * addr_hi):
//  1   chirp_q
//  2   chirp_f0
//  3   duration
//  4   amp_slope
//  5   sine_amp
//  6   sig_offset
//  7   amp_max
//  8   chirp dest address
//  9   offset sine dest address
//  10  pulse dest address
//  11  sqrt dest address
//  12  pulse dest address

// With one 18-bit CORDIC and a serial 30-bit sqrt,
// runs at 125 MHz in Spartan-6 using 1761 slice LUTs.

// Larry Doolittle, LBNL, 2014

module fgen(
	input clk,
	input trig,
	output collision,
	// Controlling bus
	input [31:0] lb_data,
	input lb_write,
	input [15:0] lb_addr,
	// Controlled bus
	output [31:0] lbo_data,
	output lbo_write,
	output [15:0] lbo_addr
);

// Run the logic every eight clk cycles
// Align input trig with think cycle

parameter addr_hi = 0;  // base address is 16 * addr_hi

wire [3:0] lb_addr_lo = lb_addr[3:0];
wire write_local = lb_write & (lb_addr[15:4]==addr_hi);
wire  write_thru = lb_write & (lb_addr[15:4]!=addr_hi);

reg pulse_on=0;  // set much later, whenever a pulse of programmable duration is active
wire trig1 = trig&~pulse_on;  // An input trigger that we are prepared to recognize

// slow=0 means 8 cycles per update, good for everything except sqrt
// slow=1 means 16 cycles per update, use this when you care about sqrt results
reg slow=0;

reg think=0, trig_do=0;
reg [3:0] think_cnt=0; always @(posedge clk) think_cnt <= trig1 ? 0 : (think_cnt+1)&{slow,3'd7};
always @(posedge clk) begin
	think <= think_cnt==6;
	if (trig1|(think_cnt==7)) trig_do <= trig1;
end

// Parabola generator
reg [31:0] chirp_q=0; always @(posedge clk) if (write_local & lb_addr_lo==1) chirp_q <= lb_data;
reg [31:0] chirp_f0=0; always @(posedge clk) if (write_local & lb_addr_lo==2) chirp_f0 <= lb_data;
reg [39:0] chirp_f=0;
reg [47:0] chirp_p=0;
always @(posedge clk) if (think) begin
	chirp_f <= trig_do ? {chirp_f0,8'b0} : chirp_f + chirp_q;
	chirp_p <= trig_do ? 0 : chirp_p + chirp_f;
end
wire [31:0] chirp_p32 = chirp_p[47:16];

// Pulse generator
// Maximum on-time ~3 minutes
// Won't work if off time is less than think period
reg [31:0] duration=0; always @(posedge clk) if (write_local & lb_addr_lo==3) duration <= lb_data;
reg [31:0] counter=0;
reg counter_zero=0;
always @(posedge clk) begin
	counter_zero <= counter==0;
	if (think) begin
		if (trig_do | (pulse_on & ~counter_zero)) counter <= trig_do ? duration : counter-1;
		if (trig_do | counter_zero) pulse_on <= trig_do;
	end
end

// Make pulse into analog, with adjustable rise and fall time
reg [15:0] amp_slope=0; always @(posedge clk) if (write_local & lb_addr_lo==4) amp_slope <= lb_data;
reg [15:0] amp_max=0; always @(posedge clk) if (write_local & lb_addr_lo==7) amp_max <= lb_data;
reg [15:0] amp=0;
reg [16:0] amp_step=0;
wire [15:0] amp_zero = 0;
wire [15:0] amp_flat=pulse_on ? amp_max : amp_zero;
reg amp_railed=0;
always @(posedge clk) begin
	amp_step <= pulse_on ? amp+amp_slope : amp-amp_slope;
	amp_railed <= pulse_on ? (amp_step > amp_flat) : amp_step[16];
	if (think) amp <= amp_railed ? amp_flat : amp_step;
end

// Run parabola through CORDIC
// Waste 7 out of 8 cycles
reg signed [17:0] sine_amp=0; always @(posedge clk) if (write_local & lb_addr_lo==5) sine_amp <= lb_data;
wire signed [17:0] sine_out;
cordicg #(.width(18)) cordic(.clk(clk), .opin(2'b00),
	.xin(sine_amp), .yin(18'd0), .phasein(chirp_p32[31:13]),
	.yout(sine_out)
);

// Add an offset to the CORDIC output
reg signed [15:0] sig_offset=0; always @(posedge clk) if (write_local & lb_addr_lo==6) sig_offset <= lb_data;
reg signed [16:0] offset_sine=0;
always @(posedge clk) offset_sine <= sine_out + sig_offset;
// At this point it could be used for amplifier testing,
// with a small CORDIC amplitude

// Non-pipelined sqrt, requires think period >= 16 cycles.  Use "slow" mode above.
wire [14:0] sqrt_out_w;
wire sqrt_dav;
reg sqrt_en=0; always @(posedge clk) sqrt_en <= think_cnt==13;
isqrt #(.X_WIDTH(30))sqrt(.clk(clk), .x({offset_sine,13'b0}), .en(sqrt_en),
	.y(sqrt_out_w), .dav(sqrt_dav));
// Waste 15 FF; in theory we could instead time the data to arrive when used by multiplexer below.
reg signed [15:0] sqrt_out=0; always @(posedge clk) if (sqrt_dav) sqrt_out <= sqrt_out_w;

// A*f + B*df/dt module goes here
// plan for one multiplier
reg signed [15:0] tuned_drive=0;

// Take one cycle to multiplex our various results
reg [31:0] our_data=0;
wire [15:0] our_addr; // was reg
wire dests_write = write_local & (lb_addr_lo[3:3]==1);
dpram #(.dw(16), .aw(3)) dests(.clka(clk), .clkb(clk),
	.addra(lb_addr[2:0]), .dina(lb_data[15:0]), .wena(dests_write),
	.addrb(think_cnt[2:0]), .doutb(our_addr));
// think_cnt[3] processed below

always @(posedge clk) case (think_cnt[2:0])
	3'd0: our_data <= chirp_p32;
	3'd1: our_data <= offset_sine;
	3'd2: our_data <= amp;
	3'd3: our_data <= sqrt_out;
	3'd4: our_data <= amp;
	default: our_data <= 16'd0;
endcase

// Now merge the two streams
reg [31:0] lbo_data_r=0;
reg [15:0] lbo_addr_r=0;
reg lbo_write_r=0, collision_r=0;
reg think_lo=0;
wire addr_match = (our_addr!=0) & think_lo;
always @(posedge clk) begin
	think_lo <= ~think_cnt[3];
	lbo_data_r <= write_thru ? lb_data : our_data;
	lbo_addr_r <= write_thru ? lb_addr : our_addr;
	lbo_write_r <= write_thru | addr_match;
	collision_r <= write_thru & addr_match;
end

// Output ports
assign lbo_addr = lbo_addr_r;
assign lbo_data = lbo_data_r;
assign lbo_write = lbo_write_r;
assign collision = collision_r;

endmodule
