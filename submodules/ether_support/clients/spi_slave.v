`timescale 1ns / 1ns
module spi_slave(
	input clk,
	// Basic 4-wire to microcontroller, plus "interrupt"
	input spi_clk,
	input spi_cs,
	input spi_mosi,
	output spi_miso,
	output uc_look_at_me,
	// port to read packet memory
	input pack_read_ready,
	input [8:0] input_packet_len,
	output pack_read_strobe,
	input [7:0] pack_data_in,
	output pack_read_done,   // marks memory as empty
	// port to write packet memory
	output pack_write,   // high for whole transaction
	output pack_write_strobe,  // single-cycle for each data byte
	output [7:0] pack_data_out,
	input pack_write_success,
	// Includes status LEDs, taking advantage of micro's extra pins.
	// Sent over SPI to micro in response to a "read status" opcode.
	input [15:0] status_in,
	// set MAC and IP address
	output [8:0] address_set,
	output eth_inhibit
);

// pack_read_ready both shows up in the status readback, and
// creates a uc_look_at_me.
assign uc_look_at_me = pack_read_ready;

// Note that the SPI slave logic can happily exist in the 125 MHz Ethernet
// clock domain, since the microcontroller's clock is both slow and coherent
// with it.  The actual spi_clk is likely to be 6.25 MHz (OSC_IN=25 MHz,
// SYSCLK=HSE, APB Prescaler /2, APB1 and APB2 Prescaler=1, SPI baud rate =
// f_PCLK/2 according to SPI_CR1 BR=0).  Thus the 125 MHz logic will detect
// a positive edge on one clock cycle in 20.

// SPI Commands:
//  1  Write UDP packet contents
//  2  Write Ethernet MAC and IP address
//  3  Read UDP packet contents
//  4  Read status (LED values, UDP packet ready, ..?)

// Because of possible contention for the packet output buffer, any given
// "write UDP packet contents" command might be ignored.  The micro needs
// to check the pack_write_success bit in the status register afterwards,
// and retry if it's false.

// Create status response message from parallel input
`define SRLEN 32
wire [`SRLEN-1:0] new_status_sr = {pack_read_ready, pack_write_success,
	5'b0, input_packet_len, status_in};
reg [`SRLEN-1:0] status_sr=0;
wire status_sr_strobe, status_sr_load;
always @(posedge clk) if (status_sr_strobe|status_sr_load) status_sr <=
	status_sr_load ? new_status_sr : {status_sr[`SRLEN-2:0],1'b0};

// Latch inputs in IOB
reg spi_clk_s=0, spi_cs_s=0, spi_mosi_s=0;
always @(posedge clk) begin
	spi_clk_s <= spi_clk;
	spi_cs_s <= spi_cs;
	spi_mosi_s <= spi_mosi;
end

// Rising edge detect on input SPI clock
reg spi_clk_d=0;
always @(posedge clk) spi_clk_d <= spi_clk_s;
wire spi_clk_e = spi_clk_s &~ spi_clk_d & ~spi_cs_s;

// Shift data in
reg [7:0] spi_byte=0;
reg [2:0] spi_oct=0;
always @(posedge clk) if (spi_clk_e) begin
	spi_byte <= {spi_byte[6:0], spi_mosi_s};
	spi_oct <= spi_oct+1;
end
reg rx_strobe=0, rx_strobe_d=0;
always @(posedge clk) begin
	rx_strobe <= spi_clk_e & (spi_oct==7);
	rx_strobe_d <= rx_strobe;
end

// Interpret the first byte sent by the micro in an SPI message
// Leading 0 bytes will be ignored
reg [2:0] command_mode=0;
always @(posedge clk) begin
	if (rx_strobe & (command_mode==0)) command_mode <= spi_byte[2:0];
	if (spi_cs_s) command_mode <= 0;
end

// command_mode 1: send message to UDP buffer
reg in_msg=0;
reg pack_write_strobe_r=0;
always @(posedge clk) begin
	pack_write_strobe_r <= rx_strobe & (command_mode==1) & in_msg;
	if (rx_strobe & (command_mode==1)) in_msg <= 1;
	if (spi_cs_s) in_msg <= 0;
end
assign pack_write_strobe = pack_write_strobe_r;
assign pack_write = in_msg;
assign pack_data_out = spi_byte;

// command_mode 2: send byte to Ethernet MAC and IP address configurator
reg [8:0] address_set_r=0;
reg eth_inhibit_r=0;
always @(posedge clk) begin
	if (rx_strobe & (command_mode==2)) address_set_r[7:0] <= spi_byte;
	address_set_r[8] <= rx_strobe & (command_mode==2);
	eth_inhibit_r <= command_mode==2;
end
assign address_set=address_set_r;
assign eth_inhibit=eth_inhibit_r;

// Serialize the data from Ethernet
reg [7:0] spi_tx_byte=0;
reg [2:0] spi_tx_oct=0;
always @(posedge clk) if (spi_clk_e /* & (command_mode==3) */) begin
	spi_tx_byte <= (spi_tx_oct==7) ? pack_data_in : {spi_tx_byte[6:0], 1'b0};
	spi_tx_oct <= spi_tx_oct+1;
end
assign pack_read_strobe = rx_strobe_d & (command_mode==3);
assign pack_read_done = (command_mode==3) & spi_cs_s;  // single-cycle

// command_mode 4: snapshot and serialize the status shift register
assign status_sr_load=rx_strobe & (spi_byte[2:0]==4);
assign status_sr_strobe=spi_clk_e & (command_mode==4);

// Decide on the bit to send back to the micro
reg miso_r=0;
always @(posedge clk) case (command_mode)
	3'd0: miso_r <= 0;
	3'd1: miso_r <= 0;
	3'd2: miso_r <= 0;
	3'd3: miso_r <= spi_tx_byte[7];
	3'd4: miso_r <= status_sr[`SRLEN-1];
	3'd5: miso_r <= 0;
	3'd6: miso_r <= 0;
	3'd7: miso_r <= 0;
endcase
assign spi_miso=miso_r;

endmodule
