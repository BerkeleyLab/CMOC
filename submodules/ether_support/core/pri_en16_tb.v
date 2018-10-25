`timescale 1ns / 1ns

module pri_en16_tb;

reg [15:0] t;
wire [3:0] which;
wire hit;
pri_en16 mut(.inp(t), .which(which), .hit(hit));

integer cc, p, mark;
reg [3:0] sh;
reg [15:0] tt;
reg fail1;
reg fail=0;
initial begin for (cc=0; cc<100; cc=cc+1) begin
	tt=$random;
	sh=$random;
	t=tt>>sh;
	#1;
	for (p=0; p<16; p=p+1) if (t[p]) mark=p;
	fail1=0;
	if (hit ^ (t!=0)) fail1=1;
	if (hit & (which != mark)) fail1=1;
	if (fail1) fail=1;
	if (fail1) $display("%b %d %d%s", t, which, hit, fail1?" FAIL":"");
end if (~fail) $display("PASS"); end

endmodule
