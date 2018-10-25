`timescale 1ns / 1ns

// Bridge from Verilog through VPI to a cavity simulator in C
// Very simple, multiplexed IQ drive and response.
module cavity3(
	input clk,
	input iq,
	input signed [17:0] drive,
	output signed [17:0] field
);

// Save space for reflected wave, but it's not used yet
reg signed [17:0] drive_i=0, field_i=0, field_q=0, reflect_i_=0, reflect_q_=0;
reg signed [17:0] field_i_=0, field_q_=0;  // VPI outputs

always @(posedge clk) if (iq) begin
	drive_i <= drive;
end else begin
	$llrf_sysmodel2(drive_i, drive, field_i_, field_q_, reflect_i_, reflect_q_);
	// sysmodel2 puts values with NoDelay
	field_i <= field_i_;
	field_q <= field_q_;
end
assign field = iq ? field_i : field_q;

endmodule
