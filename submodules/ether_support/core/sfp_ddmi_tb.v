`timescale 1ns / 1ns
module sfp_ddmi_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("sfp_ddmi.vcd");
		$dumpvars(5,sfp_ddmi_tb);
	end
	for (cc=0; cc<80000; cc=cc+1) begin
		clk=0; #400;
		clk=1; #400;
	end
end

tri1 SDA, SCL;
wire [7:0] pc_out;
wire [8:0] result_out;
wire strobe_out;
// adjust tck_mask so things happen without wasting too many cycles
sfp_ddmi #(3) mut(.clk(clk), .SDA(SDA), .SCL(SCL), .alt_add(3'b001),
	.pc_out(pc_out), .result_out(result_out), .strobe_out(strobe_out));

always @(negedge clk) if (strobe_out) $display("res[%d]=%d",pc_out,result_out);

endmodule
