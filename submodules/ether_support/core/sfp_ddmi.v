`timescale 1ns / 1ns

// Defects:
//   only reads 120 of 256 bytes
//   maybe doesn't latch SDA at the right time - DONE?
//   doesn't acknowledge bytes read from DDTC (see p. 30) - DONE?

//     pull SDA low (start)
//     pull SCL low
//     set SDA msb
//       let SCL high
//         record SDA value
//           pull SCL low
//     set SDA next
//       let SCL high
//     ...
//     set SDA lsb
//       let SCL high
//         record SDA value
//           pull SCL low
// 01  let SDA high
// 10    let SCL high
// 11      record SDA value (ack)
// 00        pull SCL low
//     repeat set of 8 bits plus ack (use SDA high when reading)
//     keep SDA high
//       let SCL high
//         pull SDA low
//           let SDA high (stop)
//
// Finisar AN-2030:
// Digital Diagnostic Monitoring Interface for Optical Transceivers
// "Serial Clock interface (SCL). The serial clock input is used to clock
// data into the DDTC on rising edges and clock data out on falling edges."
// 128-byte ROM at 0xA0
// Monitoring at 0xA2, interesting data is in the first 120 bytes.
//
// Avago ABCU-57x0RZ uses same ROM at 0xA0, but uses chip address 0xAC
// for real-time measurement.  Interesting data is in the first 32
// 16-bit words, presumably lines up with MII address map.
// XXX find out if this code reads 16-bit words


// work with a tick at 400 kHz (100 MHz/256), four ticks per SDA cycle
// Data:
//          ___     ___     ___           ___     ___     ___
// SCK   __/   \___/   \___/   \__ ... __/   \___/   \___/   \__
// SDA   |1111111|2222222|3333333| ... |7777777|8888888|AAAAAAA|
//                                                          ^latch
//
// Start/stop:
//          ___________
// SCK   __/           \__
// SDA   |EEEEEEE|SSSSSSS|
// where E=1 S=0 is a start condition
//   and E=0 S=1 is a stop condition

module sfp_ddmi(
	input clk,
	inout SDA,
	inout SCL,
	output sync,  // debug
	input [2:0] alt_add,   // 001 for optical, 110 for copper?
	output [7:0] pc_out,
	output [8:0] result_out,
	output strobe_out
);

// use 3 for simulation with 1.2 MHz clock
// parameter tck_mask=255;  // 100 MHz clk
parameter tck_mask=1023;  // 48 MHz clk (and 4 times slower than necessary)

reg [9:0] div=0;
reg tick=0, sda_latch;
always @(posedge clk) begin
	div <= div+1;
	tick <= ((div&tck_mask) == 0);
end
reg [5:0] state=0;
reg ss=0;  // start or stop condition
wire last = state==35 | (state==7 & ss);
reg [8:0] shift=8'h53, result=0;
// reg sda_high=0;
reg scl_high=0;
wire [8:0] sr_next;
wire ss_next, ak_next;
always @(posedge clk) if (tick) begin
	state <= last ? 0 : state+1;
	scl_high <= ss ? ((state!=7) & (state!=6)) : (~state[1]);
	if (state[1:0]==2'b11) shift <= last ? {sr_next,~ak_next} :
		{shift[7:0],sda_latch};
	// if (state[1:0]==2'b11) sda_high <= shift[8];
	if (last) ss <= ss_next;
	sda_latch <= SDA;
	if (last) result <= {shift[7:0],sda_latch};
end
wire sda_high = shift[8];

reg [7:0] pc=0;  // program (cough) counter
always @(posedge clk) if (tick & last) pc <= pc+1;
reg [8:0] sr1;   // next SR value for 0 <= pc < 8
wire [2:0] alt_add_masked = alt_add & {3{pc[7]}};
always @(*) case (pc[2:0])
	0:  sr1 = 8'h40;   // stop
	1:  sr1 = 8'hff;   // high
	2:  sr1 = 8'hff;   // high
	3:  sr1 = 8'h80;   // start
	4:  sr1 = 8'hA0 | {alt_add_masked,1'b0};  // write Ax
	5:  sr1 = 8'h00;   // zero
	6:  sr1 = 8'h90;   // start
	7:  sr1 = 8'hA1 | {alt_add_masked,1'b0};  // read Ax
endcase
assign sr_next = |pc[6:3] ? 8'hff : sr1;
assign ss_next = (pc[6:0] == 0) | (pc[6:0] == 3) | (pc[6:0]==6);
assign ak_next = |pc[6:3] & ~ (&pc[6:0]);
reg strobe=0, sync_r=0;
always @(posedge clk) strobe <= last & tick;
always @(posedge clk) sync_r <= ~(|pc[7:5]);

assign pc_out = pc;
assign result_out = result;
assign strobe_out = strobe;

// Apparently the sequence is:
//   0xFF  (idle, make sure nobody pulls SDA down)
//     start
//   0xA0  (write A0 space)
//   0x00  (register address)
//     start
//   0xA1  (read A0 space)
//   0xFF  (data register 0)
//   0xFF  (data register 1)
//   ...
//   0xFF  (data register 127)
//     stop
//     start
//   0xA2  (write A2 space)
//   0x00  (register address)
//     start
//   0xA3  (read A2 space)
//   0xFF  (data register 0)
//   0xFF  (data register 1)
//   ...
//   0xFF  (data register 127)
//     stop

assign SDA = sda_high ? 1'bz : 1'b0 ;
assign SCL = scl_high ? 1'bz : 1'b0 ;
assign sync = sync_r;

endmodule
