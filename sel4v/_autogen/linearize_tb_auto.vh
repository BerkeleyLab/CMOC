// parse_vfile  linearize_tb.v
// module=linearize instance=dut gvar=None gcnt=None
// parse_vfile :linearize_tb.v ./linearize.v
// module=lin_curves instance=curvegen gvar=None gcnt=None
// parse_vfile :linearize_tb.v:./linearize.v ./lin_curves.v
// found output address in module lin_curves, base=offset_rom
// found output address in module lin_curves, base=slope_rom
`define AUTOMATIC_dut .curvegen_bank(dut_curvegen_bank),\
	.curvegen_offset_rom(dut_curvegen_offset_rom),\
	.curvegen_slope_rom(dut_curvegen_slope_rom),\
	.curvegen_offset_rom_addr(dut_curvegen_offset_rom_addr),\
	.curvegen_slope_rom_addr(dut_curvegen_slope_rom_addr)
// machine-generated by newad.py
`ifdef LB_DECODE_linearize_tb
`include "addr_map_linearize_tb.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [13:0] lb_addr
`define AUTOMATIC_decode\
wire we_dut_curvegen_bank = lb_write&(`ADDR_HIT_dut_curvegen_bank);\
reg [0:0] dut_curvegen_bank=0; always @(posedge lb_clk) if (we_dut_curvegen_bank) dut_curvegen_bank <= lb_data;\
wire [7:0] dut_curvegen_offset_rom_addr;\
wire [15:0] dut_curvegen_offset_rom;\
wire we_dut_curvegen_offset_rom = lb_write&(`ADDR_HIT_dut_curvegen_offset_rom);\
dpram #(.aw(8),.dw(16)) dp_dut_curvegen_offset_rom(\
	.clka(lb_clk), .addra(lb_addr[7:0]), .dina(lb_data[15:0]), .wena(we_dut_curvegen_offset_rom),\
	.clkb(lb_clk), .addrb(dut_curvegen_offset_rom_addr), .doutb(dut_curvegen_offset_rom));\
wire [7:0] dut_curvegen_slope_rom_addr;\
wire [10:0] dut_curvegen_slope_rom;\
wire we_dut_curvegen_slope_rom = lb_write&(`ADDR_HIT_dut_curvegen_slope_rom);\
dpram #(.aw(8),.dw(11)) dp_dut_curvegen_slope_rom(\
	.clka(lb_clk), .addra(lb_addr[7:0]), .dina(lb_data[10:0]), .wena(we_dut_curvegen_slope_rom),\
	.clkb(lb_clk), .addrb(dut_curvegen_slope_rom_addr), .doutb(dut_curvegen_slope_rom));\
wire [31:0] mirror_out_0;wire mirror_write_0 = lb_write &(`ADDR_HIT_MIRROR);\
dpram #(.aw(`MIRROR_WIDTH),.dw(32)) mirror_0(\
	.clka(lb_clk), .addra(lb_addr[`MIRROR_WIDTH-1:0]), .dina(lb_data[31:0]), .wena(mirror_write_0),\
	.clkb(lb_clk), .addrb(lb_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_0));\

`else
`define AUTOMATIC_self input  [0:0] dut_curvegen_bank,\
input signed [15:0] dut_curvegen_offset_rom,\
input signed [10:0] dut_curvegen_slope_rom,\
output  [7:0] dut_curvegen_offset_rom_addr,\
output  [7:0] dut_curvegen_slope_rom_addr
`define AUTOMATIC_decode
`endif
