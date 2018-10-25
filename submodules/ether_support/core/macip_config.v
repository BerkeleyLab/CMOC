`timescale 1ns / 1ns

module macip_config(
	input clk,
	input [8:0] address_set,
	input [3:0] ipn,
	output [7:0] ip1
);

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd2};  // 192.168.7.2
parameter [47:0] mac = 48'h125555000136;

// Local memory for our MAC and IP address.  The intent is to write to it
// during an initialization step, using data read from Flash.
// On Xilinx, this should synthesize to a bank of 8 x SRL16E.
wire ip_push=address_set[8];
wire [7:0] ip_octet=address_set[7:0];
reg [127:0] local_data={mac,ip};
reg [7:0] ip1_r=0;
always @(posedge clk) begin
	if (ip_push) local_data <= {ip_octet,local_data[79:8]};
	ip1_r <= local_data[{ipn,3'b0}+:8];
end
assign ip1 = ip1_r;

endmodule
