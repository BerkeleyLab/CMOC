`timescale 1ns / 1ns

module fgen_tb;

reg clk;
integer cc, errors;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("fgen.vcd");
		$dumpvars(5,fgen_tb);
	end
	errors=0;
	for (cc=0; cc<1900; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	//$display("%s",errors==0?"PASS":"FAIL");
	$finish();
end

integer file1;
reg [255:0] file1_name;
initial begin
	if (!$value$plusargs("fgen_seq=%s", file1_name)) file1_name="fgen_seq.dat";
	file1 = $fopen(file1_name,"r");
end

integer rc=2;
reg [31:0] control_data, cd;
reg [15:0] control_addr, ca;
reg control_strobe=0;
integer control_cnt=0;
always @(posedge clk) begin
	control_cnt <= control_cnt+1;
	if (control_cnt > 5 && control_cnt%3==1 && rc==2) begin
		rc=$fscanf(file1,"%d %d\n",ca,cd);
		if (rc==2) begin
			$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
			control_data <= cd;
			control_addr <= ca;
			control_strobe <= 1;
		end
	end else begin
		control_data <= 32'hx;
		control_addr <= 7'hx;
		control_strobe <= 0;
	end
end

reg trig=0;
always @(posedge clk) trig <= (cc%820)==40;

wire collision;
wire [31:0] lbo_data;
wire lbo_write;
wire [15:0] lbo_addr;
fgen dut(.clk(clk), .trig(trig), .collision(collision),
	.lb_data(control_data), .lb_write(control_strobe), .lb_addr(control_addr),
	.lbo_data(lbo_data), .lbo_write(lbo_write), .lbo_addr(lbo_addr)
);

always @(negedge clk) begin
	if (lbo_write) $display("slave bus[%d] = 0x%x (%d)",lbo_addr,lbo_data,lbo_data);
end


endmodule
