`timescale 1ns / 1ns

module mii_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mii.vcd");
		$dumpvars(5,mii_tb);
	end
	for (cc=0; cc<3000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end


tri1 MDC, MDIO;
mii mut(.clk(clk), .MDC(MDC), .MDIO(MDIO));

reg [4:0] rcnt=0;
reg [1:0] mode=0;
reg [4:0] bcnt=0;
reg [15:0] shift=0;
reg [13:0] command_word=0;
always @(posedge MDC) begin
	rcnt <= (MDIO & mode==2) ? rcnt+1 : 0;
	if (rcnt==26) mode <= 0;
	if (mode==0 && ~MDIO) mode <= 1;
	if ((mode==1) && (bcnt==30)) mode <= 2;
	if (mode==1) bcnt <= bcnt+1;
	if (mode==1) shift <= bcnt==14 ? 16'h1234 : {shift[14:0],MDIO};
	if (mode==1 && bcnt==12) command_word <= shift;
end
wire mdio_drive_b = (mode==1 && bcnt>14 && bcnt!=31);
assign MDIO = mdio_drive_b ? shift[15] : 1'bz;
endmodule
