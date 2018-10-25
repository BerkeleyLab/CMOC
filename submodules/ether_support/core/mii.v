`timescale 1ns / 1ns

// 2.5 MHz max clk (400 ns period)
// DP83865 samples data on rising edge (+/- 10 ns) of MDC, and changes
// output state at (or up to 300 ns after) rising edge of MDC.
//
// 32-bit hi-Z preamble
// 01 start
// 10 read
// AAAAA phy address
// RRRRR reg address
// zz turnaround
// dddddddddddddddd  read data
// zz minimum idle/turnaround
//
// 01 start
// 01 write
// AAAAA phy address
// RRRRR reg address
// 10 pad
// dddddddddddddddd  write data
// zz minimum idle/turnaround
//
// We want to, in order:
//   1.  Sample MDIO
//   2.  wait 1 clock
//   3.  Rising edge MDC
//   4.  wait 2 clocks
//   5.  New value and driver state for MDIO
//
// Every 64 ticks, 40.96 microseconds, get a new value
// Two modules, producing 32 bits every 40.96 microseconds, avg 0.097 MB/s

module mii(
	input clk,
	output MDC,
	inout MDIO,
	output strobe,
	output [4:0] addr,
	output [15:0] data
);

reg [5:0] div=0;  // should be [5:0] on the FPGA
reg tick=0, mdio_in=0;
always @(posedge clk) begin
	div <= div+1;
	tick <= &div;
	mdio_in <= MDIO;
end

reg [5:0] state=0;
reg [15:0] shift=0, recv=0;
reg mdio_drive=0;
wire [4:0] phy_addr = 5'b00001;
reg [4:0] reg_addr = 0, reg_outr=0;
wire [15:0] send = {2'b01, 2'b10, phy_addr, reg_addr, 2'b00};
always @(posedge clk) if (tick) begin
	state <= state+1;
	mdio_drive <= state<14;
	shift <= (state==0) ? send : {shift[14:0], mdio_in};
	if (state==33) recv <= shift;
	if (state==33) reg_outr <= reg_addr;
	if (state==33) reg_addr <= reg_addr+1;
end

reg strobe_r=0, mdio_state=0, mdio_drive2=0;
always @(posedge clk) begin
	strobe_r <= tick & (state==34);
	mdio_state <= shift[15];
	mdio_drive2 <= mdio_drive;
end
assign strobe = strobe_r;
assign MDC  = ~div[5];  // XXX doesn't scale
assign MDIO = mdio_drive2 ? mdio_state : 1'bz;

assign data = recv;
assign addr = reg_outr;
endmodule
