`timescale 1ns / 1ns
module client_pack_rx(
	input clk,
	// PSPEPS Rx
	input rx_ready1,
	input rx_ready2,
	input rx_strobe,
	input [7:0] rx_data,
	// port to spi_flash_engine and spi_slave to read incoming packets
	output pack1_read_ready,
	output pack2_read_ready,
	output [8:0] input_packet_len,
	input pack1_read_strobe,
	input pack2_read_strobe,
	output [7:0] pack_data_out,
	input pack1_read_done,
	input pack2_read_done
);

// Hold each incoming packet until the right read_done line is pulsed

// Would really like to ping-pong/double-buffer input packets,
// use 2048x8 DPRAM to hold two packets up to 1024 bytes each.

reg [8:0] bufa=0;
reg rx_strobe_d=0, pack1_read_ready_r=0, pack2_read_ready_r=0;
reg which=0;  // 0: port 1,  1: port 2
always @(posedge clk) begin
	if (rx_ready1 | rx_ready2) begin
		bufa <= 0;
		which <= rx_ready2;
	end
	if (rx_strobe) bufa <= bufa+1;
	// trigger on falling edge of rx_strobe
	rx_strobe_d <= rx_strobe;
	if (~rx_strobe & rx_strobe_d) begin
		if (~which) pack1_read_ready_r <= 1;
		if ( which) pack2_read_ready_r <= 1;
	end
	if (pack1_read_done & ~which) pack1_read_ready_r <= 0;
	if (pack2_read_done &  which) pack2_read_ready_r <= 0;
end

reg [8:0] bufb=0;
always @(posedge clk) begin
	if (which?pack2_read_strobe:pack1_read_strobe) bufb <= bufb+1;
	if (which?pack2_read_done:pack1_read_done) bufb <= 0;
end
wire [7:0] doutb;
dpram #(.aw(9), .dw(8)) buffer(
	.clka(clk), .clkb(clk),
	.addra(bufa), .dina(rx_data), .wena(rx_strobe),
	.addrb(bufb), .doutb(doutb)
);

assign pack1_read_ready=pack1_read_ready_r;
assign pack2_read_ready=pack2_read_ready_r;
assign input_packet_len=bufa;
assign pack_data_out=doutb;

endmodule
