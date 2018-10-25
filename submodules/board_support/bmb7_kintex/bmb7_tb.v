`timescale  1 ps / 1 ps
//`include "constants.vams"

module bmb7_tb;

parameter max_data_len=1024;
reg [7:0] pack_mem [0:max_data_len-1];

reg clk,adcclk,dacclk;
integer cc,ccadc,ccdac;
reg [127:0] packet_file;
integer data_len, udp_port;
reg use_packfile, trace;
initial begin
	use_packfile = $value$plusargs("packet_file=%s", packet_file);
	if (use_packfile) $readmemh(packet_file,pack_mem);
	if (!$value$plusargs("data_len=%d", data_len))  data_len= 64;
	if (!$value$plusargs("udp_port=%d", udp_port))  udp_port=0;
	// if (udp_port) $udp_init(udp_port);
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("bmb7.vcd");
		$dumpvars(10,bmb7_tb);
	end
	for (cc=0; (udp_port!=0) || (cc<1000); cc=cc+1) begin
		clk=0; #10000;
		clk=1; #10000;
	end
	$finish();
end
initial begin
	for (ccadc=0; (udp_port!=0) || (ccadc<2000); ccadc=ccadc+1) begin
		adcclk=0; #5250;
		adcclk=1; #5250;
	end
end
initial begin
	for (ccdac=0; (udp_port!=0) || (ccdac<4000); ccdac=ccdac+1) begin
		dacclk=0; #2625;
		dacclk=1; #2625;
	end
end

wire  [2:0] bus_bmb7_D4;
wire  [2:0] bus_bmb7_D5;
wire  [159:0] bus_bmb7_J103;
wire  [67:0] bus_bmb7_J106;
wire  [0:0] bus_bmb7_J28;
wire  [0:0] bus_bmb7_J4;
wire  [1:0] bus_bmb7_U19;
wire  [22:0] bus_bmb7_U32;
wire  [1:0] bus_bmb7_U5;
wire  [22:0] bus_bmb7_U50;
wire  [18:0] bus_bmb7_U7;
wire  [2:0] bus_bmb7_Y4;
assign  bus_bmb7_U19={clk,~clk};
assign bus_bmb7_U50[7]=clk;
assign bus_bmb7_U50[14]=clk;
assign bus_bmb7_U50[1]=clk;
assign bus_bmb7_U50[16]=clk;
assign bus_bmb7_U50[3]=clk;
assign bus_bmb7_U50[4]=clk;
assign bus_bmb7_U50[10]=clk;
assign bus_bmb7_U50[18]=clk;

bmb7 bmb7(
.bus_bmb7_D4(bus_bmb7_D4)
,.bus_bmb7_D5(bus_bmb7_D5)
,.bus_bmb7_J103(bus_bmb7_J103)
,.bus_bmb7_J106(bus_bmb7_J106)
,.bus_bmb7_J28(bus_bmb7_J28)
,.bus_bmb7_J4(bus_bmb7_J4)
,.bus_bmb7_U19(bus_bmb7_U19)
,.bus_bmb7_U32(bus_bmb7_U32)
,.bus_bmb7_U5(bus_bmb7_U5)
,.bus_bmb7_U50(bus_bmb7_U50)
,.bus_bmb7_U7(bus_bmb7_U7)
,.bus_bmb7_Y4(bus_bmb7_Y4)
);
endmodule


// If we use any Xilinx simprims, keep them quiet
module glbl();
	reg GSR = 1;
	wire PLL_LOCKG = 0;
	initial begin #10; GSR = 0; end
endmodule
