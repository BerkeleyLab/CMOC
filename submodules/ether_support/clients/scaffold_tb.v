`timescale 1ns / 1ns

// Top level test-bench
// Additional sub-modules below.
module scaffold_tb;

reg clk, fail=0;
integer cc;
reg debug=0;
initial begin
	if ($test$plusargs("vcd")) begin
	        $dumpfile("scaffold.vcd");
	        $dumpvars(5,scaffold_tb);
	end
	if ($test$plusargs("debug")) debug=1;
	for (cc=0; cc<4600; cc = cc + 1) begin
	        clk=0; #4;
	        clk=1; #4;
	end
	// $display("%s",fail?"FAIL":"PASS");
end

// Rx port
wire [1:0] rx_ready;
wire rx_strobe;
wire [7:0] rx_data;
rx_gen rx_gen(.clk(clk),
	.rx_ready(rx_ready), .rx_strobe(rx_strobe), .rx_data(rx_data));

// Tx port
// Simple emulation of PSPEPS
wire [1:0] tx_req;
reg tx_ack=0, tx_strobe=0, tx_print=0;
wire [10:0] tx_len;
wire [7:0] tx_data;
reg [10:0] tx_cnt=0;
reg [79:0] rx_reg=0;
wire tx_warn=|tx_cnt;
always @(posedge clk) begin
	tx_ack <= |tx_req;
	if (|tx_req & ~tx_ack) begin
		tx_cnt <= tx_len;
		rx_reg <= 0;
	end
	if (|tx_cnt) tx_cnt <= tx_cnt - 1;
	tx_strobe <= tx_warn;
	if (tx_strobe) rx_reg <= {rx_reg[71:0],tx_data};
	tx_print <= tx_ack & ~(|tx_req);
	if (tx_print) $display("Ether received %x from ???", rx_reg);
end

// Microcontroller
wire uc_clk, uc_cs, uc_mosi, uc_miso, uc_look_at_me;
micro micro(.clk(uc_clk), .cs(uc_cs), .mosi(uc_mosi),
	.miso(uc_miso), .look_at_me(uc_look_at_me));

// SPI Flash memory
wire flash_clk, flash_cs, flash_mosi, flash_miso;
flash flash(.clk(flash_clk), .cs(flash_cs), .mosi(flash_mosi),
	.miso(flash_miso));

// Device under test
reg [15:0] status_in=16'h5a5a;
wire [8:0] address_set;
wire eth_inhibit;
scaffold dut(.clk(clk),
	.rx_ready(rx_ready), .rx_strobe(rx_strobe), .rx_data(rx_data),
	.tx_req(tx_req), .tx_len(tx_len), .tx_ack(tx_ack),
	.tx_warn(tx_warn), .tx_data(tx_data),
	.uc_clk(uc_clk), .uc_cs(uc_cs), .uc_mosi(uc_mosi),
	.uc_miso(uc_miso), .uc_look_at_me(uc_look_at_me),
	.flash_clk(flash_clk), .flash_cs(flash_cs), .flash_mosi(flash_mosi),
	.flash_miso(flash_miso),
	.status_in(status_in),
	.address_set(address_set), .eth_inhibit(eth_inhibit)
);

wire       address_set_s=address_set[8];
wire [7:0] address_set_d=address_set[7:0];
reg [79:0] eth_config=0;
always @(posedge clk) if (address_set_s) eth_config <= {eth_config[71:0],address_set_d};
always @(negedge eth_inhibit) $display("Ether configur %x",eth_config);

endmodule

// Emulate a microprocessor acting as SPI master.
// Send a series of commands to exercise spi_slave.v.
module micro(
	output clk,
	output cs,
	output mosi,
	input miso,
	input look_at_me
);

reg clk_r=0, cs_r=1, mosi_r=0;
assign clk=clk_r;
assign cs=cs_r;
assign mosi=mosi_r;

integer ix;
task write_block;
	input [7:0] len;
	input [71:0] data;
	begin
		#180; cs_r = 0;
		#60;
		for (ix=0; ix<len; ix=ix+1) begin
			mosi_r = data[len-1-ix];
			#30; clk_r = 1;
			#60; clk_r = 0;
			#30;
		end
		cs_r = 1;
		#180;
	end
endtask

initial begin
	#120;
	write_block(64,64'h0223456789abcdef);   // write Ethernet MAC and IP
	#4800
	write_block(64,64'h010e456789abcdef);   // send UDP packet
	write_block(40,40'h0422222222);         // read status
	write_block(72,72'h030000000000000000); // read UDP packet
end

// Receive bits from slave
reg [79:0] rx_reg=0;
always @(negedge cs) rx_reg <= 0;
always @(posedge clk) if (~cs) rx_reg <= {rx_reg[78:0],miso};
always @(posedge cs) $display("micro received %x from SPI slave",rx_reg);

endmodule

// Pathetic emulation of external SPI Flash chip
// Just provide a placeholder message for every SPI command.
module flash(
        input clk,
        input cs,
        input mosi,
        output miso
);
reg [63:0] sr;
always @(negedge cs) sr<=64'h7172737475767778;
always @(posedge clk) sr<={sr[62:0],1'bx};

// Receive bits from master
reg [79:0] rx_reg=0;
always @(negedge cs) rx_reg <= 0;
always @(posedge clk) if (~cs) rx_reg <= {rx_reg[78:0],mosi};
always @(posedge cs) $display("Flash received %x from SPI master",rx_reg);
reg dout;
always @(negedge clk or negedge cs) begin
	dout=1'bx;
	#7;
	dout=sr[63];
end
assign miso = cs ? 1'bx : dout;  // or maybe 1'bx when not addressed?

endmodule

// Simulate packets flowing from PSPEPS to an Rx client.
// Assumes some hackery instantiating emux_rx twice to
// generate two ready lines for two UDP ports, but only one
// set of data and strobe lines.
module rx_gen(
	input clk,
	output [1:0] rx_ready,
	output rx_strobe,
	output [7:0] rx_data
);

integer cc=0;
reg [95:0]msg1=95'h042122452384a44525334e06;
reg [95:0]msg2=96'h450145024503450445054506;
reg ready1=0, ready2=0, strobe=0;
reg [7:0] data=0;
always @(posedge clk) begin
	cc<=cc+1;
	ready1 <= (cc==30);
	ready2 <= (cc==2130);
	if (cc>  35 && cc<=(  35+12)) data<=msg1[(  35+12-cc)*8 +: 8];
	if (cc>2135 && cc<=(2135+12)) data<=msg2[(2135+12-cc)*8 +: 8];
	strobe <= (cc>35 && cc<=(35+12)) | (cc>2135 && cc<=(2135+12));
end
assign rx_ready={ready2,ready1};
assign rx_strobe=strobe;
assign rx_data=data;

endmodule
