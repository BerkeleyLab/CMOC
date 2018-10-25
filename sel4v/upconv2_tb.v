module upconv2_tb;

reg clk, trace;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("upconv2.vcd");
		$dumpvars(5,upconv2_tb);
	end
	trace = $test$plusargs("trace");
	for (cc=0; cc<543; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

// Generate the LO signals.
// In hardware, this could be table-based or CORDIC-based.
reg signed [17:0] lo1=0, lo2=0;
reg iq_flag=0;
real phase, trig1, trig2;
real ps = 5.0/132.0*2*3.1415926535;  // phase shift per clock tick
real lo_amp = 131070.0;  // almost full-scale 18-bit value
always @(posedge clk) begin
	iq_flag <= ~iq_flag;
	if (iq_flag) begin
		phase = cc*ps;
		trig1 = $cos(phase);
		trig2 = $sin(phase+0.5*ps);
	end else begin
		trig1 = $sin(phase);
		trig2 = -$cos(phase+0.5*ps);
	end
	lo1 <= lo_amp * trig1;
	lo2 <= lo_amp * trig2;
end

// Simple test pattern of IQ data input
reg signed [17:0] iq_data=0;
always @(posedge clk) begin
	iq_data <= 0;
	if (cc==3) iq_data <= 4000;
	if (cc==12) iq_data <= 4000;
	if (cc>20 && iq_flag) iq_data <= 4000;
end

// Expect a numerical gain of 1/4, since we have 18-bit input and 16-bit output
wire signed [15:0] dac1, dac2;
upconv2 dut(.clk(clk), .iq_data(iq_data), .iq_flag(iq_flag),
	.lo1(lo1), .lo2(lo2),
	.dac1(dac1), .dac2(dac2));

// Outputs are serialized like this to the DAC using a DDR output cell
// or similar.
always @(negedge clk) if (trace & (cc>30)) begin
	$display("%d", dac1);
	$display("%d", dac2);
end

endmodule
