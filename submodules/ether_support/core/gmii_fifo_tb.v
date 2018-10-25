`timescale 1ns / 10ps

module gmii_fifo_tb;

reg clk_in;
integer cc_in;
reg fail=0;
integer npt=2000;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("gmii_fifo.vcd");
		$dumpvars(5,gmii_fifo_tb);
	end
	for (cc_in=0; cc_in<(npt*2); cc_in=cc_in+1) begin
		clk_in=0; #4;
		clk_in=1; #4;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
end

reg clk_out;
integer cc_out;
real per;
// approximate 1000 as 2^10
reg [9:0] onek;
initial begin
	// half-periods evenly distributed between 3.8 and 4.1069, mean 3.95
	for (cc_out=0; cc_out<npt; cc_out=cc_out+1) begin
		clk_out=0; onek=$random; per=3.8+onek*0.0003; #per;
		clk_out=1; onek=$random; per=3.8+onek*0.0003; #per;
	end
	// half-periods evenly distributed between 3.9 and 4.2069, mean 4.05
	for (cc_out=npt; cc_out<(npt*3); cc_out=cc_out+1) begin
		clk_out=0; onek=$random; per=3.9+onek*0.0003; #per;
		clk_out=1; onek=$random; per=3.9+onek*0.0003; #per;
	end
end

reg [6:0] in_cnt=0;
wire state_end = in_cnt==0;
wire nextv = strobe_in ^ state_end;
reg [7:0] packet[0:1023];
integer ix;
reg [7:0] in_len, in_len_r;
reg running=0;
always @(posedge clk_in) begin
	in_cnt <= in_cnt+1;
	if (~running & (in_cnt==9)) begin
		in_len = $random;
		in_len = (in_len&8'h3f) + 30;
		// $display("initializing packet length %d", in_len);
		for (ix=0; ix<1024; ix=ix+1) begin
			packet[ix]=(ix<in_len)?ix:8'hxx;  // or $random
		end
		in_len_r <= in_len;
		running <= 1;
		in_cnt <= 0;
	end
	if (running & (in_cnt==in_len-1)) begin
		running <= 0;
		in_cnt <= 0;
	end
end
wire strobe_in = running;
wire [7:0] d_in = running ? packet[in_cnt] : 8'hxx;

wire [7:0] d_out;
wire strobe_out;
gmii_fifo mut(
	.clk_in(clk_in),   .d_in(d_in),   .strobe_in(strobe_in),
	.clk_out(clk_out), .d_out(d_out), .strobe_out(strobe_out));

reg [11:0] out_cnt=0;
reg strobe_out1=0;
reg fail_data, fail_len;
always @(posedge clk_out) begin
	out_cnt <= strobe_out ? (out_cnt+1) : 0;
	strobe_out1 <= strobe_out;
	fail_data = (strobe_out & (d_out !== packet[out_cnt]));
	fail_len  = (strobe_out1 & ~strobe_out & (out_cnt != in_len));
	if (fail_data|fail_len) fail=1;
end

endmodule
