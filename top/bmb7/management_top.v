module management_top(
        // link ports
        input bmb7_clk,
        output [7:0] port_50006_word_k7tos6,
        input [7:0] port_50006_word_s6tok7,
        output port_50006_tx_available,
        input port_50006_rx_available,
        output port_50006_tx_complete,
        input port_50006_rx_complete,
        input port_50006_word_read,
        // Ethernet configuration port
        output eth_cfg_clk,
        output [9:0] eth_cfg_set,
        // Link status and debug
        output an_bypass,
        input [5:0] link_leds,
        input [15:0] lacr_stat,
        // monitor/debug I/O
        input [3:0] freq_count_in
);

// Generate localbus based on link to Spartan
wire lb_clk = bmb7_clk;
wire [23:0] lb_addr;
wire [31:0] lb_dout;
reg [31:0] lb_din=0;
wire lb_strobe, lb_rd;
jxj_gate jxjgate(
	.clk(lb_clk),
	.rx_din(port_50006_word_s6tok7), .rx_stb(port_50006_rx_available), .rx_end(port_50006_rx_complete),
	.tx_dout(port_50006_word_k7tos6), .tx_rdy(port_50006_tx_available), .tx_end(port_50006_tx_complete), .tx_stb(port_50006_word_read),
	.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
	.lb_strobe(lb_strobe), .lb_rd(lb_rd)
);

// Use the same configuration data already setup for application
wire [7:0] config_rom_out;
config_romx rom(.address(lb_addr[4:0]), .data(config_rom_out));

// Frequency counter
wire [25:0] freq_multi_count_out;
freq_multi_count #(.NF(4), .NA(3), .rw(23), .uw(26)) freq_multi_count(
	.unk_clk(freq_count_in), .refclk(lb_clk),
	.addr(lb_addr[2:0]), .frequency(freq_multi_count_out)
);

// Configuration port for fiber Ethernet link
wire eth_cfg_hit = lb_strobe & ~lb_rd & (lb_addr[23:12] == 2);  // 002xxx
reg [7:0] eth_cfg_cmd=0;
reg eth_cfg_strobe=0, eth_cfg_ena=0;
always @(posedge lb_clk) begin
	if (eth_cfg_hit) eth_cfg_ena <= lb_addr[11];
	if (eth_cfg_hit) eth_cfg_cmd <= lb_dout;
	eth_cfg_strobe <= eth_cfg_hit & ~lb_addr[11];
end
assign eth_cfg_clk = lb_clk;
assign eth_cfg_set = {eth_cfg_ena, eth_cfg_strobe, eth_cfg_cmd};

// Troubleshooting
wire [31:0] ctrace_out;
wire ctrace_running;
wire ctrace_hit = lb_strobe & ~lb_rd & (lb_addr[23:12] == 3);  // 003xxx
reg ctrace_start=0;  // single-cycle
always @(posedge lb_clk) ctrace_start <= ctrace_hit & lb_dout[0];
wire [ctrace_aw-1:0] ctrace_pc;
wire [ctrace_aw-0:0] ctrace_status = {ctrace_pc, ctrace_running};
parameter ctrace_aw = 11;
ctrace #(.dw(6), .tw(26), .aw(ctrace_aw)) ctrace(
	.clk(lb_clk), .data(link_leds), .start(ctrace_start),
	.running(ctrace_running), .pc_mon(ctrace_pc),
	.lb_clk(lb_clk), .lb_addr(lb_addr[ctrace_aw-1:0]), .lb_out(ctrace_out)
);

// Other
reg an_bypass_r=0;
assign an_bypass = an_bypass_r;
reg other_hit = lb_strobe & ~lb_rd & (lb_addr[23:12] == 4);  // 004xxx
always @(posedge lb_clk) if (other_hit) an_bypass_r <= lb_dout[0];

// Simple redefinitions to harmonize names in output decoder
wire [31:0] hello_0 = "Hell";
wire [31:0] hello_1 = "o wo";
wire [31:0] hello_2 = "rld!";
wire [31:0] hello_3 = 32'h0d0a0d0a;

// Very basic pipelining of read process
reg [23:0] lb_addr_r=0;
always @ (posedge lb_clk) if (lb_strobe) lb_addr_r <= lb_addr;

// Output decoder
reg [31:0] reg_bank_0=0;
always @(posedge lb_clk) begin
        case (lb_addr[3:0])
		4'h0: reg_bank_0 <= hello_0;
		4'h1: reg_bank_0 <= hello_1;
		4'h2: reg_bank_0 <= hello_2;
		4'h3: reg_bank_0 <= hello_3;
		4'h4: reg_bank_0 <= lacr_stat;
		4'h5: reg_bank_0 <= link_leds;
		4'h6: reg_bank_0 <= ctrace_status;
		default: reg_bank_0 <= 32'hfaceface;
	endcase
	// All of the following rhs have had one stage of decode pipeline;
	// either the reg_bank_x multiplexer above, or a dpram clock cycle.
	// Thus the address is also one cycle delayed.
	casex (lb_addr_r)
		24'h16xxxx: lb_din <= ctrace_out;
		24'h1exxxx: lb_din <= freq_multi_count_out;
		24'bxxxx_xxxx_xxxx_1xxx_xxxx_xxxx: lb_din <= config_rom_out;  // xxx800 through xxxfff, 2K
		24'hxxxx0x: lb_din <= reg_bank_0;
		default: lb_din <= 32'hfaceface;
	endcase
end

endmodule
