`timescale 1ns / 1ns

module mem_gateway_tb;
parameter jumbo_dw=14;

reg clk;
integer cc;
reg [127:0] packet_file;
integer data_len;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mem_gateway.vcd");
		$dumpvars(5,mem_gateway_tb);
	end
	for (cc=0; cc<450; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
end

reg rx_ready=0, rx_strobe=0, rx_crc=0, tx_ack=0, tx_strobe=0;
reg [7:0] packet_in=0;
wire tx_req, control_strobe, control_rd;
wire [jumbo_dw-1:0] tx_len;
wire [7:0] packet_out;
wire [23:0] addr;
wire [31:0] data_out;
reg  [31:0] data_in=0;
mem_gateway dut(.clk(clk),
	.rx_ready(rx_ready), .rx_strobe(rx_strobe), .packet_in(packet_in),
	.rx_crc(rx_crc), .tx_ack(tx_ack), .tx_strobe(tx_strobe),
	.tx_req(tx_req), .tx_len(tx_len), .packet_out(packet_out),
	.addr(addr), .control_strobe(control_strobe), .control_rd(control_rd),
	.data_out(data_out), .data_in(data_in));

reg [575:0] pack=576'h12211221_3456789a_01020304_40302010_11121314_deadbeef_01020304_40302010_11121314_deadbeef_01020304_40302010_11121314_deadbeef_01020304_40302010_11121314_deadbeef;
reg [575:0] reply=0;
reg [575:0] reply_want=576'h12211221_3456789a_01020304_40302010_11121314_01233210_01020304_40302010_11121314_01233210_01020304_40302010_11121314_01233210_01020304_40302010_11121314_01233210;

integer ccc=0;
reg [jumbo_dw-1:0] len=72;  // serial number + 8 transactions
wire rx_push = (ccc>14) & (ccc<(14+len+1));
reg rx_len=0;
reg tx_strobe1=0;
reg fail=0;
always @(posedge clk) begin
	ccc <= cc%150;
	if (ccc==149) begin
		len<=len-0;
		reply<=0;
	end
	rx_ready <= ccc==10;
	rx_len   <= rx_ready;
	rx_strobe <= rx_push;
	packet_in <= rx_ready ? len[jumbo_dw-1:8] : rx_len ? len[7:0] : rx_push ? pack[568-(ccc-15)*8+:8] : 8'hxx;
	data_in <= 32'h01233210;
	if (control_strobe) $display("addr=0x%x rd=%d data_out=0x%x",addr, control_rd, data_out);

	tx_strobe <= (ccc>64) & (ccc<(64+len+1));
	tx_strobe1 <= tx_strobe;
	if (tx_strobe1) reply <= {reply[567:0],packet_out};
	if (ccc==(64+len+3)) begin
		fail=reply != reply_want;
		$display("sent  %x",pack);
		$display("want  %x",reply_want);
		$display("reply %x %s",reply, fail ? "FAIL" : "PASS");
	end
end

endmodule
