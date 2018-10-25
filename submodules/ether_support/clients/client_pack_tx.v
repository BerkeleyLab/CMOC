`timescale 1ns / 1ns

module client_pack_tx #(
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,
	// PSPEPS Tx
	output tx_req1,
	output tx_req2,
	output [jumbo_dw-1:0] tx_len,
	input tx_ack,
	input tx_warn,
	output [7:0] tx_data,
	// port to spi_flash_engine to write outgoing packets
	input pack1_write,
	output pack1_write_ack,
	input pack1_write_strobe,
	input [7:0] pack1_data_in,
	// port to spi_slave to write outgoing packets
	input pack2_write,
	input pack2_write_strobe,
	input [7:0] pack2_data_in,
	output pack2_write_success
);

// Arbiter
reg pack1_tx_mode=0, pack2_tx_mode=0, p2wd=0, p2ws=0;
wire idle=~pack1_tx_mode&~pack2_tx_mode;
always @(posedge clk) begin
	p2wd <= pack2_write;
	if (idle &  pack1_write) pack1_tx_mode<=1;
	if (idle & ~pack1_write & pack2_write & ~p2wd) pack2_tx_mode<=1;
	if (pack2_write & ~p2wd) p2ws <= idle & ~pack1_write;
	if (pack1_tx_mode & ~pack1_write) pack1_tx_mode<=0;
	if (pack2_tx_mode & ~pack2_write) pack2_tx_mode<=0;
end
assign pack1_write_ack = pack1_tx_mode;
assign pack2_write_success = p2ws;

// 2K x 8 packet DPRAM
// XXX wish to subdivide so we can ping-pong
// But Ethernet Tx is so fast it hardly matters.
reg [jumbo_dw-1:0] addra=0, addrb=0;
wire stepa = pack1_tx_mode&pack1_write_strobe | pack2_tx_mode&pack2_write_strobe;
wire eot = (pack1_tx_mode & ~pack1_write) | (pack2_tx_mode & ~pack2_write);
always @(posedge clk) begin
	if (stepa) addra <= addra+1;
	if (eot) addra <= 0;
	addrb <= tx_warn ? addrb+1 : 0;
end
wire [7:0] doutb;
wire [7:0] ram_din=pack1_tx_mode?pack1_data_in:pack2_data_in;
dpram #(.aw(11), .dw(8)) pack(
	.clka(clk), .clkb(clk),
	.addra(addra), .dina(ram_din), .wena(stepa),
	.addrb(addrb), .doutb(doutb)
);
assign tx_data=doutb;

reg tx_req1_r=0, tx_req2_r=0, tx_warn_d=0;
reg [jumbo_dw-1:0] tx_len_r=0;
always @(posedge clk) begin
	if (pack1_tx_mode&~pack1_write) begin
		tx_req1_r <= 1;
		tx_len_r <= addra;
	end
	if (pack2_tx_mode&~pack2_write) begin
		tx_req2_r <= 1;
		tx_len_r <= addra;
	end
	tx_warn_d <= tx_warn;
	if (~tx_warn & tx_warn_d) begin
		tx_req1_r <= 0;
		tx_req2_r <= 0;
	end
end
assign tx_req1=tx_req1_r;
assign tx_req2=tx_req2_r;
assign tx_len=tx_len_r;
endmodule
