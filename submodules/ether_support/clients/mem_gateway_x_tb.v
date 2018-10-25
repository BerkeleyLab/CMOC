// -------------------------------------------------------------------------------
// Filename    : mem_gateway_x_tb.v
// Description :
// Author      : Qiang Du
// Maintainer  :
// -------------------------------------------------------------------------------
// Created     : Thu May  3 15:26:55 2012 (-0700)
// Version     :
// Last-Updated:
//           By:
//     Update #: 0
//
// -------------------------------------------------------------------------------

// Commentary  : A simple techbench of mem_gateway with data_xdomain.
//
// -------------------------------------------------------------------------------

// Change Log  :
// 3-May-2012    Qiang
//    Initial draft from mem_geteway_tb.v
//
// -------------------------------------------------------------------------------

// Code:


`timescale 1ns / 1ns

module mem_gateway_x_tb;
parameter jumbo_dw=14;

   reg clk;
   integer cc;
   reg [127:0] packet_file;
   integer     data_len;
   initial begin
      if ($test$plusargs("vcd")) begin
	 $dumpfile("mem_gateway_x.vcd");
	 $dumpvars(5,mem_gateway_x_tb);
      end
      for (cc=0; cc<450; cc=cc+1) begin
	 clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
	 clk=1; #4;
      end
      $finish();
   end

   reg dsp_clk=0;
   // integer cc1;

   //initial begin
   always begin
//      for (cc1=0; cc1<600; cc1=cc1+1) begin
      dsp_clk=0; #5;
      dsp_clk=1; #5;
  //    end
   end


reg rx_ready=0, rx_strobe=0, rx_crc=0, tx_ack=0, tx_strobe=0;
reg [7:0] packet_in=0;
wire tx_req, control_strobe, control_rd;
wire [jumbo_dw-1:0] tx_len;
wire [7:0] packet_out;
wire [23:0] addr;
wire [31:0] data_out;
wire [31:0] data_in;

mem_gateway #(.read_pipe_len(11))
   dut(.clk(clk),
       .rx_ready(rx_ready), .rx_strobe(rx_strobe), .packet_in(packet_in),
       .rx_crc(rx_crc), .tx_ack(tx_ack), .tx_strobe(tx_strobe),
       .tx_req(tx_req), .tx_len(tx_len), .packet_out(packet_out),
       .addr(addr), .control_strobe(control_strobe), .control_rd(control_rd),
       .data_out(data_out), .data_in(data_in));

   // Clock domain crossing ((local bus/Ethernet) --> dsp clock domains)
   wire [56:0] lb_word_out_eth={data_out, addr, control_rd};
   wire [56:0] lb_word_out_dsp;
   wire [31:0] lb_data;
   wire [23:0] lb_addr;
   wire        lb_control_rd;
   wire        lb_control_strobe;

   // gate_in must be & ~control2_rd
   // mem_gateway generate control_strobe at every R/W cycle
   // So just delay lb_control_strobe for a certian time. see below
   data_xdomain #(.size(57))
   x_eth2dsp(.clk_in(clk), .gate_in(control_strobe), .data_in(lb_word_out_eth),
	     .clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
	     );

   assign {lb_data,lb_addr,lb_control_rd}=lb_word_out_dsp;

   // Clock domain crossing (dsp --> (local bus/Ethernet) clock domains)
   reg   lb_control_strobe_d1=1'b0, lb_control_strobe_d2=1'b0, lb_control_strobe_d3=1'b0;
   wire  lb_control_strobe_back;
   // dsp clock domain
   reg [31:0]  lb_data_in;

   // Introduce 3 clock cycle delay to strobe to match data bus pipeline
   always @(posedge dsp_clk) begin
      lb_control_strobe_d1 <= lb_control_strobe;
      lb_control_strobe_d2 <= lb_control_strobe_d1;
      lb_control_strobe_d3 <= lb_control_strobe_d2;
   end

   // Multiplexer selecting data output from the different modules to the Ethernet input via the local data bus
   always @(posedge dsp_clk)
     if (~lb_control_rd) begin
	case(lb_addr[23:20])
	  0: lb_data_in <= "Hell";
	  1: lb_data_in <= "o wo";
	  2: lb_data_in <= "rld!";
	  3: lb_data_in <= "(::)";
	  default: lb_data_in <= 32'hdeadbeef;
	endcase // case (lb_addr[23:20])
     end

   data_xdomain #(.size(32))
   x_dsp2eth(.clk_in(dsp_clk), .gate_in(lb_control_strobe), .data_in(lb_data_in),
	     .clk_out(clk), .gate_out(lb_control_strobe_back), .data_out(data_in)
	     );
   // nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error

   reg [575:0] pack =  576'h12211221_3456789a_01020304_40302010_11121314_deadbeef_01120304_40312010_01221314_deadbeef_01220304_40322010_11321314_deadbeef_01320304_40332010_11421314_deadbeef;
   reg [575:0] reply=0;
   reg [575:0] reply_want=576'h12211221_3456789a_01020304_40302010_11121314_48656c6c_01120304_40312010_01221314_deadbeef_01220304_40322010_11321314_726c6421_01320304_40332010_11421314_283a3a29;


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
	//lb_data_in <= 32'h01233210; // should be in dsp_clk domain
	//if (control_strobe) $display("addr=0x%x rd=%d data_out=0x%x",addr, control_rd, data_out);

	tx_strobe <= (ccc>64) & (ccc<(64+len+1));
	tx_strobe1 <= tx_strobe;
	if (tx_strobe1) reply <= {reply[567:0],packet_out};
	if (ccc==(64+len+3)) begin
		fail=reply != reply_want;
		$display("sent  %x",pack);
		$display("want  %x",reply_want);
		$display("reply %x %s",reply, fail ? "FAIL" : "PASS");
	end
end // always @ (posedge clk)

endmodule

//
// mem_gateway_x_tb.v ends here
