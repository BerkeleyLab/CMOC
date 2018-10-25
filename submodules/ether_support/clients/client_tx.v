`timescale 1ns / 1ns

// Simplest possible transmit-only client:
// Send a "Hello World" message in response to a stimulus
module client_tx #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	input srx,
	input ack,
	input strobe,
	output req,
	output [jumbo_dw-1:0] length,
	output [7:0] data_out
);

reg [17:0] cnt = 0;  // periodic send: every 2^18 ticks = 2.1 ms
reg [jumbo_dw-1:0] cnt_d = 0;
reg req_r = 0;
reg [jumbo_dw-1:0] length_r = 0;
reg [7:0] d_out = 0;
reg ack1 = 0;

wire [jumbo_dw-1:0] next_cnt_d = strobe ? cnt_d + 1 : 0;
always @(posedge clk) begin
	cnt <= cnt + 1;
	cnt_d <= next_cnt_d;
	// periodic send disabled in this version
	if (/*(cnt==50) |*/ srx) begin
		req_r <= 1;
		length_r <= 26;
	end

	if (ack) req_r <= 0;
	ack1 <= ack;
	if (ack1) length_r <= 0;  // XXX maybe there's a better way
	case (next_cnt_d)
		0  : d_out <= "H";
		1  : d_out <= "e";
		2  : d_out <= "l";
		3  : d_out <= "l";
		4  : d_out <= "o";
		5  : d_out <= " ";
		6  : d_out <= "W";
		7  : d_out <= "o";
		8  : d_out <= "r";
		9  : d_out <= "l";
		10 : d_out <= "d";
		11 : d_out <= " ";
		12 : d_out <= "f";
		13 : d_out <= "r";
		14 : d_out <= "o";
		15 : d_out <= "m";
		16 : d_out <= " ";
		17 : d_out <= "V";
		18 : d_out <= "e";
		19 : d_out <= "r";
		20 : d_out <= "i";
		21 : d_out <= "l";
		22 : d_out <= "o";
		23 : d_out <= "g";
		24 : d_out <= "!";
		25 : d_out <= "\n";
		default : d_out <= " ";
	endcase
end

assign req = req_r;
assign length = length_r;
assign data_out = strobe ? d_out : 8'h00;

endmodule
