`timescale 1ns / 1ns

// Uber-simple mapping of a UDP packet to a register read/write port.
// Lead with 64 bits of padding (sequence number, ID, nonce, ...),
// then alternate 32 bits of control+address with data.
// Stick with 24 bits of address, leave 8 bits for control.
// Only one of those control bits is actually used, it's the R/W line.
// Every packet is returned to the sender with the read data filled in.
// Local bus read latency is fixed, configurable at compile time.
// Uses standard network byte order (big endian).
// XXX Needs work on interlocking if the output FIFO fills up.

module mem_gateway #(
	parameter read_pipe_len=3,
	parameter jumbo_dw=14  // 14 for jumbo frame support, 11 for traditional Ethernet
) (
	input clk,   // timespec 6.8 ns
	// interface for packet reception
	input rx_ready,
	input rx_strobe,
	input rx_crc,  // ignored
	input [7:0] packet_in,
	// interface for packet transmission
	input tx_ack,
	input tx_strobe,
	output reg tx_req,
	output [jumbo_dw-1:0] tx_len,
	output [7:0] packet_out,
	// local bus
	output [23:0] addr,
	output control_strobe,
	output control_rd,
	output reg [31:0] data_out,
	input [31:0] data_in,
	output fifo_full,
	output underrun
);

reg [read_pipe_len+1:0] read_shift=0;
reg [read_pipe_len+6:0] strobe_shift=0;
reg [(read_pipe_len-1)*8-1:0] data_pipe=0;

initial tx_req=0;
reg [31:0] iword=0;
reg [jumbo_dw-1:0] length=0;
reg [3:0] octet=0;
reg [1:0] mode=0;
reg [31:0] addr_r=0, read_buf=0, oword=0;
reg rx_strobe1=0, rx_ready1=0, rx_ready2=0, hit=0;
wire rd_bit=addr_r[28];
wire oword_shiftctl = read_shift[read_pipe_len];
wire [7:0] oword_shiftin = data_pipe[(read_pipe_len-1)*8-1:(read_pipe_len-2)*8];
always @(posedge clk) begin
	rx_ready1 <= rx_ready;
	rx_ready2 <= rx_ready1;
	rx_strobe1 <= rx_strobe;
	strobe_shift <= {strobe_shift[read_pipe_len+5:0],rx_strobe};
	if (rx_ready1) length[jumbo_dw-1:8] <= packet_in;
	if (rx_ready2) length[ 7:0] <= packet_in;
	iword <= {iword[23:0],packet_in};
	if (rx_strobe) octet <= {octet[2:0],octet[3]};
	if (rx_ready)  octet <= 4'b1;
	if (rx_strobe1 & octet[0]) case (mode)
		0: mode <= 1;
		1: mode <= 2;
		2: mode <= 3;
		3: mode <= 2;
	endcase
	if (rx_ready)  mode  <= 0;
	if (rx_strobe1 & octet[0] & (mode==2)) addr_r <= iword;
	if (rx_strobe1 & octet[0] & (mode==3)) data_out <= iword;
	hit <= rx_strobe1 & octet[0] & (mode==3);
	read_shift <= {read_shift[read_pipe_len-1:0],hit&rd_bit};
	if (rx_ready | tx_ack) tx_req <= rx_ready;
	if (read_shift[read_pipe_len-1]) read_buf <= data_in;
	data_pipe <= {data_pipe[(read_pipe_len-2)*8-1:0], iword[31:24]};
	if (strobe_shift[read_pipe_len+5]|strobe_shift[read_pipe_len+1]) oword <= oword_shiftctl ? read_buf :
		{oword[23:0],oword_shiftin};
end

assign control_strobe = hit;
assign addr = addr_r[23:0];
assign control_rd = rd_bit;
assign tx_len = length-8; // length includes 8-octet UDP header, tx_len does not

// need to buffer at least 51 cycles
wire full, empty;
wire we=strobe_shift[read_pipe_len+6];
wire [7:0] fifod=oword[31:24];
fifo_1c #(.aw(jumbo_dw), .dw(8)) buffr(.clk(clk),
	.din(fifod), .we(we&~full),
	.dout(packet_out), .re(tx_strobe&~empty),
	.full(full), .empty(empty));

assign fifo_full=full;
assign underrun=tx_strobe&empty;
endmodule
