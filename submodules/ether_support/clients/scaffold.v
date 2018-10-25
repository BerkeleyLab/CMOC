`timescale 1ns / 1ns
module scaffold(
	input clk,  // timespec 6.4 ns
	// PSPEPS Rx
	input [1:0] rx_ready,
	input rx_strobe,
	input [7:0] rx_data,
	// PSPEPS Tx
	output [1:0] tx_req,
	output [10:0] tx_len,
	input tx_ack,
	input tx_warn,
	output [7:0] tx_data,
	// Basic 4-wire to microcontroller, plus "interrupt"
	input uc_clk,
	input uc_cs,
	input uc_mosi,
	output uc_miso,
	output uc_look_at_me,
	// 4-wire to e.g., Winbond W25X16
	output flash_clk,
	output flash_cs,
	output flash_mosi,
	input flash_miso,
	// Includes status LEDs, taking advantage of micro's extra pins.
	// Sent over SPI to micro in response to a "read status" opcode.
	input [15:0] status_in,
	// set MAC and IP address
	output [8:0] address_set,
	output eth_inhibit
);

// Rx client
wire pack1_read_ready, pack2_read_ready;
wire [8:0] rx_packet_len;
wire [7:0] pack_data_rx;
wire pack1_read_strobe, pack2_read_strobe;  // forward declarations
wire pack1_read_done, pack2_read_done;  // forward declarations
client_pack_rx client_pack_rx(
	.clk(clk),
	.rx_ready1(rx_ready[0]), .rx_ready2(rx_ready[1]),
	.rx_strobe(rx_strobe), .rx_data(rx_data),
	.pack1_read_ready(pack1_read_ready),
	.pack2_read_ready(pack2_read_ready),
	.input_packet_len(rx_packet_len),
	.pack1_read_strobe(pack1_read_strobe),
	.pack2_read_strobe(pack2_read_strobe),
	.pack_data_out(pack_data_rx),
	.pack1_read_done(pack1_read_done),
	.pack2_read_done(pack2_read_done)
);

// Tx client
wire pack1_write_ack, pack2_write_success;
wire pack1_write, pack1_write_strobe;
wire pack2_write, pack2_write_strobe;
wire [7:0] pack1_data_tx, pack2_data_tx;
client_pack_tx #(.jumbo_dw(11)) client_pack_tx(
	.clk(clk),
	.tx_req1(tx_req[0]),
	.tx_req2(tx_req[1]),
	.tx_len(tx_len),
	.tx_ack(tx_ack),
	.tx_warn(tx_warn),
	.tx_data(tx_data),
	.pack1_write(pack1_write),
	.pack1_write_ack(pack1_write_ack),
	.pack1_write_strobe(pack1_write_strobe),
	.pack1_data_in(pack1_data_tx),
	.pack2_write(pack2_write),
	.pack2_write_strobe(pack2_write_strobe),
	.pack2_data_in(pack2_data_tx),
	.pack2_write_success(pack2_write_success)
);

// SPI Flash Engine
// Port 1 to client_pack_rx and client_pack_tx
spi_flash_engine spi_flash_engine(
	.clk(clk),
	.spi_clk(flash_clk),
	.spi_cs(flash_cs),
	.spi_mosi(flash_mosi),
	.spi_miso(flash_miso),
	.pack_read_ready(pack1_read_ready),
	.input_packet_len(rx_packet_len),
	.pack_read_strobe(pack1_read_strobe),
	.pack_data_in(pack_data_rx),
	.pack_read_done(pack1_read_done),
	.pack_write(pack1_write),
	.pack_write_ack(pack1_write_ack),
	.pack_write_strobe(pack1_write_strobe),
	.pack_data_out(pack1_data_tx)
);

// SPI Slave to microcontroller
// Port 2 to client_pack_rx and client_pack_tx
spi_slave spi_slave(
	.clk(clk),
	.spi_clk(uc_clk),
	.spi_cs(uc_cs),
	.spi_mosi(uc_mosi),
	.spi_miso(uc_miso),
	.uc_look_at_me(uc_look_at_me),
	.pack_read_ready(pack2_read_ready),
	.input_packet_len(rx_packet_len),
	.pack_read_strobe(pack2_read_strobe),
	.pack_data_in(pack_data_rx),
	.pack_read_done(pack2_read_done),
	.pack_write(pack2_write),
	.pack_write_strobe(pack2_write_strobe),
	.pack_data_out(pack2_data_tx),
	.pack_write_success(pack2_write_success),
	.status_in(status_in),
	.address_set(address_set),
	.eth_inhibit(eth_inhibit)
);

endmodule
