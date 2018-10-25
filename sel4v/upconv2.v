// Upconversion from serialized IQ to DDR DAC stream
// Specific to output carrier near the middle of the double-data-rate
// Nyquist zone.  Needs tricky lo1 and lo2, see interp2.m

// iq_flag is high for I data (first of the pair), low for Q data
module upconv2(
	input clk,
	input signed [17:0] iq_data,
	input iq_flag,
	input signed [17:0] lo1,
	input signed [17:0] lo2,
	output signed [15:0] dac1,
	output signed [15:0] dac2
);

upconv_half upconv_1(
	.clk(clk), .iq_data(iq_data), .iq_flag(iq_flag),
	.lo(lo1), .dac(dac1));
upconv_half upconv_2(
	.clk(clk), .iq_data(iq_data), .iq_flag(iq_flag),
	.lo(lo2), .dac(dac2));

endmodule

// One half of the data path described in interp2.m
module upconv_half(
	input clk,
	input signed [17:0] iq_data,
	input iq_flag,
	input signed [17:0] lo,
	output signed [15:0] dac
);

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x : {x[old],{new{~x[old]}}})

// Multiply and (1+z^(-1)) filter
reg signed [34:0] prod1=0;  // LO not allowed to be negative full-scale
reg signed [17:0] prod2=0, prod3=0;
reg signed [17:0] filt1=0, filt2=0;
reg signed [18:0] interp1=0;
wire signed [18:0] sum = prod2 + prod3;
always @(posedge clk) begin
	prod1 <= lo*iq_data;
	prod2 <= prod1[34:17];
	prod3 <= prod2;
	if (iq_flag) begin
		filt1 <= `SAT(sum,18,17);
		filt2 <= filt1;
	end
	if (~iq_flag) begin
		interp1 <= filt1 + filt2 - 1;
	end
end

// Final multiplexer
wire signed [15:0] filt2_s = filt2[17:2];
wire signed [15:0] interp1_s = ~interp1[18:3];  // note sign flip
reg signed [15:0] dac_r=0;
always @(posedge clk) dac_r <= iq_flag ? interp1_s : filt2_s;
assign dac = dac_r;

endmodule
