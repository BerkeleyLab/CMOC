// parse_vfile  lp1_tb.v
// module=lp1 instance=dut gvar=None gcnt=None
// parse_vfile :lp1_tb.v ./lp1.v
// found output address in module lp1, base=kx
// found output address in module lp1, base=ky
`define AUTOMATIC_dut .kx(dut_kx),\
	.kx_addr(dut_kx_addr),\
	.ky(dut_ky),\
	.ky_addr(dut_ky_addr)
// machine-generated by newad.py
`ifdef LB_DECODE_lp1_tb
`include "addr_map_lp1_tb.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [13:0] lb_addr
`define AUTOMATIC_decode\
wire [0:0] dut_kx_addr;\
wire [17:0] dut_kx;\
wire we_dut_kx = lb_write&(`ADDR_HIT_dut_kx);\
dpram #(.aw(1),.dw(18)) dp_dut_kx(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_dut_kx),\
	.clkb(lb_clk), .addrb(dut_kx_addr), .doutb(dut_kx));\
wire [0:0] dut_ky_addr;\
wire [17:0] dut_ky;\
wire we_dut_ky = lb_write&(`ADDR_HIT_dut_ky);\
dpram #(.aw(1),.dw(18)) dp_dut_ky(\
	.clka(lb_clk), .addra(lb_addr[0:0]), .dina(lb_data[17:0]), .wena(we_dut_ky),\
	.clkb(lb_clk), .addrb(dut_ky_addr), .doutb(dut_ky));\
wire [31:0] mirror_out_0;wire mirror_write_0 = lb_write &(`ADDR_HIT_MIRROR);\
dpram #(.aw(`MIRROR_WIDTH),.dw(32)) mirror_0(\
	.clka(lb_clk), .addra(lb_addr[`MIRROR_WIDTH-1:0]), .dina(lb_data[31:0]), .wena(mirror_write_0),\
	.clkb(lb_clk), .addrb(lb_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_0));\

`else
`define AUTOMATIC_self input signed [17:0] dut_kx,\
output  [0:0] dut_kx_addr,\
input signed [17:0] dut_ky,\
output  [0:0] dut_ky_addr
`define AUTOMATIC_decode
`endif