`timescale 1ns / 1ns

module set_address_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("set_address.vcd");
		$dumpvars(5,set_address_tb);
	end
	for (cc=0;cc<1800;cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
end

parameter [31:0] ip = {8'd128, 8'd3, 8'd128, 8'd172};  // 128.3.128.172
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter [47:0] mac = 48'h12555500012a;

wire [8:0] address_set;
wire [7:0] last_byte=8'hac;
reg set_address_rst_r=0, set_address_rst1=0;
always @(posedge clk) begin
	set_address_rst_r <= set_address_rst1;
	set_address_rst1 <= 1;
end

wire set_address_rst=~set_address_rst_r;

set_address #(.ip_net(ip), .mac(mac)) set_address( .clk(clk),
	.rst(set_address_rst), .last_ip_byte(last_byte),
	.address_set(address_set)
);

endmodule
