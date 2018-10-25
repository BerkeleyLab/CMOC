`timescale 1ns / 1ns

module client_thru #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	input rx_ready,
	input rx_strobe,
	input rx_crc,  // ignored
	input [7:0] data_in,
	input nomangle,  // software settable
	output reg tx_req,
	output [jumbo_dw-1:0] tx_len,
	input tx_ack,
	input tx_warn,  // leads tx_strobe by one cycle
	output [7:0] data_out
);

reg [jumbo_dw-1:0] rx_cnt=0, tx_cnt=0, tx_cnt1=0;
reg rx_sel=0, tx_sel=0;
reg rx_ready1=0, rx_ready2=0;
reg [7:0] lh=0, ll=0;
initial tx_req=0;

always @(posedge clk) begin
	rx_cnt <= rx_strobe ? (rx_cnt + 1) : {jumbo_dw {1'b0}};
	tx_cnt <= tx_warn   ? (tx_cnt + 1) : {jumbo_dw {1'b0}};
	tx_cnt1 <= tx_cnt;
	rx_ready1 <= rx_ready;
	rx_ready2 <= rx_ready1;
	if (rx_ready1) lh <= data_in;
	if (rx_ready2) ll <= data_in;
	if (rx_ready & (tx_sel==rx_sel)) begin  // XXX was rx_ready2
		rx_sel <= ~rx_sel;
		tx_req <= 1;
	end
	if (tx_ack) begin
		tx_sel <= ~tx_sel;
		tx_req <= 0;
	end
end

// ping-pong buffer
wire [7:0] mem_out;
dpram #(.dw(8), .aw(jumbo_dw+1)) mem(.clka(clk), .clkb(clk),
	.addra({rx_sel,rx_cnt}), .dina(data_in), .wena(rx_strobe),
	.addrb({tx_sel,tx_cnt}), .doutb(mem_out));

assign data_out = mem_out ^ (tx_cnt1 & {8{~nomangle}});
assign tx_len = {lh,ll}-8;

endmodule
