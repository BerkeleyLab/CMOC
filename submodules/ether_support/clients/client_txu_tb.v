`timescale 1ns / 1ns

module client_txu_tb;
parameter jumbo_dw=14;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("client_txu.vcd");
		$dumpvars(5,client_txu_tb);
	end
	for (cc=0; cc<80000; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$finish();
end

reg rx_clk=0; always begin #11; rx_clk<=~rx_clk; end
reg tx_clk=0; always begin #13; tx_clk<=~tx_clk; end
reg gr_clk=0; always begin  #3; gr_clk<=~gr_clk; end

tri1 MDC0, MDIO0, SFP0_MOD1, SFP0_MOD2;
tri1 MDC1, MDIO1, SFP1_MOD1, SFP1_MOD2;
reg ack=0, strobe=0;
wire req;
wire [jumbo_dw-1:0] length;
wire [7:0] data_out;
client_txu #(.tck_mask(3), .REFCNT_WIDTH(12)) mut(.clk(clk),
	.ack(ack), .strobe(strobe),
	.req(req), .length(length), .data_out(data_out),
	.if_config(8'h13),
	.rx_clk(rx_clk), .tx_clk(tx_clk), .gr_clk(gr_clk),
	.GBE_FP_MDC(MDC0), .GBE_FP_MDIO(MDIO0),
	.GBE_AX_MDC(MDC1), .GBE_AX_MDIO(MDIO1),
	.SFP0_MOD1(SFP0_MOD1), .SFP0_MOD2(SFP0_MOD2),
	.SFP1_MOD1(SFP1_MOD1), .SFP1_MOD2(SFP1_MOD2),
	.other(32'hdeadbeef));

// Fake Tx port
reg [jumbo_dw-1:0] ocnt=0;
always @(posedge clk) begin
	ack <= req;
	if (req | strobe) ocnt <= req ? length : ocnt-1;
	if (ack) strobe <= 1;
	if (ocnt==0) strobe <= 0;
end

endmodule
