`timescale 1ns / 1ns

// Simplest possible receive-only client:
// Uses the first two octets of the UDP packet to set
// the brightness (via PWM) of two LEDs.

module client_rx #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	input ready,
	input strobe,
	input crc,
	input [7:0] data_in,
	output reg [1:0] led
);

reg [jumbo_dw-1:0] cnt_str = 0;
reg crc_in=0;
reg [7:0] d_in1_mem=0, d_in2_mem=0, d_in1=0, d_in2=0;

// Keep track of the input packet, and latch the input octets
always @(posedge clk) begin
	cnt_str <= strobe ? cnt_str + 1 : 11'b0;
	if (strobe & (cnt_str == 0)) d_in1_mem <= data_in;
	if (strobe & (cnt_str == 1)) d_in2_mem <= data_in;
end

// Pass the data to the PWM register when told the CRC is OK
always @(posedge clk) begin
	crc_in <= crc;
	if (crc_in) begin
		d_in1 <= d_in1_mem;
		d_in2 <= d_in2_mem;
	end
end

// Blink the LEDs with the specified duty factor
// (your eyes won't notice the blink, because it's at 488 kHz)
reg l1=0, l2=0;
reg [9:0] cc=0;
always @(posedge clk) begin
	cc <= cc+1;
	l1 <= cc < {d_in1,2'b0};
	l2 <= cc < {d_in2,2'b0};
end

// Another set of latches to become the IOB
always @(posedge clk) led <= {l2, l1};
endmodule
