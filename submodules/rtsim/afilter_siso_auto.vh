// parse_vfile  afilter_siso.v
// module=outer_prod instance=outer_prod gvar=None gcnt=None
// parse_vfile :afilter_siso.v ./outer_prod.v
// found output address in module outer_prod, base=k_out
`define AUTOMATIC_outer_prod .k_out(outer_prod_k_out),\
	.k_out_addr(outer_prod_k_out_addr)
// module=resonator instance=resonator gvar=None gcnt=None
// parse_vfile :afilter_siso.v ./resonator.v
// found output address in module resonator, base=prop_const
`define AUTOMATIC_resonator .prop_const(resonator_prop_const),\
	.prop_const_addr(resonator_prop_const_addr)
// module=dot_prod instance=dot gvar=None gcnt=None
// parse_vfile :afilter_siso.v ./dot_prod.v
// found output address in module dot_prod, base=k_out
`define AUTOMATIC_dot .k_out(dot_k_out),\
	.k_out_addr(dot_k_out_addr)
// machine-generated by newad.py
`ifdef LB_DECODE_afilter_siso
`include "addr_map_afilter_siso.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [14:0] lb_addr
`define AUTOMATIC_decode\
wire [9:0] outer_prod_k_out_addr;\
wire [17:0] outer_prod_k_out;\
wire we_outer_prod_k_out = lb_write&(`ADDR_HIT_outer_prod_k_out);\
dpram #(.aw(10),.dw(18)) dp_outer_prod_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_outer_prod_k_out),\
	.clkb(lb_clk), .addrb(outer_prod_k_out_addr), .doutb(outer_prod_k_out));\
wire [9:0] resonator_prop_const_addr;\
wire [20:0] resonator_prop_const;\
wire we_resonator_prop_const = lb_write&(`ADDR_HIT_resonator_prop_const);\
dpram #(.aw(10),.dw(21)) dp_resonator_prop_const(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[20:0]), .wena(we_resonator_prop_const),\
	.clkb(lb_clk), .addrb(resonator_prop_const_addr), .doutb(resonator_prop_const));\
wire [9:0] dot_k_out_addr;\
wire [17:0] dot_k_out;\
wire we_dot_k_out = lb_write&(`ADDR_HIT_dot_k_out);\
dpram #(.aw(10),.dw(18)) dp_dot_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_dot_k_out),\
	.clkb(lb_clk), .addrb(dot_k_out_addr), .doutb(dot_k_out));\

`else
`define AUTOMATIC_self input signed [17:0] outer_prod_k_out,\
output  [9:0] outer_prod_k_out_addr,\
input  [20:0] resonator_prop_const,\
output  [9:0] resonator_prop_const_addr,\
input signed [17:0] dot_k_out,\
output  [9:0] dot_k_out_addr
`define AUTOMATIC_decode
`endif