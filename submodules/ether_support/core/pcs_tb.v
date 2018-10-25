module pcs_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pcs.vcd");
		$dumpvars(5,pcs_tb);
	end
	for (cc=0; cc<450; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
end

reg rst=1;
initial begin #8; rst=0; end

reg [7:0] tx_data=0;
reg tx_enable=0;
reg even=0;
integer f;
wire operate;  // from link negotiator
integer oc=0;  // octet counter, only runs when negotiator says we're ready
always @(posedge clk) begin
	if (operate) oc <= oc+1;
	f=oc%79 + (oc/178);
	tx_enable <= f > 30;
	tx_data <= (f>38) ? oc : (f==38) ? 8'hd5 : 8'h55 ;
	even <= ~even;
end

wire [7:0] tx_odata;
wire tx_is_k;
wire [15:0] lacr_out;
wire lacr_send;
wire [7:0] loop_d;
wire loop_dv, loop_er;
wire [9:0] channel;
gmii_link #(.DELAY(50)) link(
	.RX_CLK(clk), .RXD(loop_d), .RX_DV(loop_dv), .RX_ER(loop_er),
	.GTX_CLK(clk), .TXD(tx_data), .TX_EN(tx_enable), .TX_ER(1'b0),
	.an_bypass(1'b0),
	.txdata(channel), .rx_err_los(1'b0),
	.rxdata(channel), .operate(operate));

endmodule
