`timescale 1ns / 1ns

// assumed magic bits of in/out bus
//   crc_in  in_c[11]
//   strobe  out_c[9]
module crc_check(
	input clk,
	input  [11:0] in_c,
	output [11:0] out_c
);

reg [11:0] cnt=0;
reg data_we1=0;
reg cnt_en=0;
reg crc_result=0;
reg eth_strobe1=0, eth_strobe2=0, eth_strobe_out1=0, delay=0;
reg f_stop=0, f_stop1=0;
reg crc_out1=0, crc_re1=0, data_re1=0;

wire data_re = delay;
wire crc_out, strobe_out, eth_strobe_out;
wire crc_we = f_stop;
wire crc_re = (eth_strobe_out & ~eth_strobe_out1) | (data_re & ~data_re1);
wire data_we = data_we1;
wire crc_in=in_c[11];
wire eth_strobe=in_c[9];
wire [11:0] out_data;
wire fifo_data_full, fifo_data_empty, fifo_crc_full, fifo_crc_empty;

fifo_1c #(.dw(13), .aw(11)) fifo_data(.clk(clk),
	.din({eth_strobe,in_c}), .we(data_we),
	.dout({eth_strobe_out,out_data}), .re(data_re),
	.full(fifo_data_full), .empty(fifo_data_empty));

fifo_1c #(.dw(1), .aw(5)) fifo_crc(.clk(clk),
	.din(crc_in), .we(crc_we),
	.dout(crc_out), .re(crc_re),
	.full(fifo_crc_full), .empty(fifo_crc_empty));

always @(posedge clk) begin
	if (eth_strobe) begin
		cnt_en <= 1;        //starts at first eth_strobe (in_c[9]), never stops
		data_we1 <=1;
	end
	cnt <= (cnt_en & (cnt<1521)) ? (cnt+1) : 0;
	if (cnt==1520) delay <=1;   //input delayed by 1520 cycles (starting on first packet)
end

always @(posedge clk) begin
	eth_strobe1 <= eth_strobe;
	eth_strobe2 <= eth_strobe1;
	eth_strobe_out1 <= eth_strobe_out;
	f_stop <= (~eth_strobe1 & eth_strobe2);         //frame stop -- CRC reading
	f_stop1 <= f_stop;      //CRC write enable
end

always @(posedge clk) begin
	crc_re1 <= crc_re;
	data_re1 <= data_re;
	if (crc_re1)crc_out1 <= crc_out;
end

assign out_c = {2'b11,eth_strobe_out,9'b111111111} & out_data;

endmodule
