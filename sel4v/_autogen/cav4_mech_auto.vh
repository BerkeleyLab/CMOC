// parse_vfile  ../submodules/rtsim/cav4_mech.v
// module=outer_prod instance=noise_couple gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/cav4_mech.v ../submodules/rtsim/outer_prod.v
// found output address in module outer_prod, base=k_out
`define AUTOMATIC_noise_couple .k_out(noise_couple_k_out),\
	.k_out_addr(noise_couple_k_out_addr)
// module=resonator instance=resonator gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/cav4_mech.v ../submodules/rtsim/resonator.v
// found output address in module resonator, base=prop_const
`define AUTOMATIC_resonator .prop_const(resonator_prop_const),\
	.prop_const_addr(resonator_prop_const_addr)
// module=prng instance=prng gvar=None gcnt=None
// parse_vfile :../submodules/rtsim/cav4_mech.v ../submodules/rtsim/prng.v
`define AUTOMATIC_prng .random_run(prng_random_run),\
	.iva(prng_iva),\
	.iva_we(prng_iva_we),\
	.ivb(prng_ivb),\
	.ivb_we(prng_ivb_we)
// machine-generated by newad.py
`ifdef LB_DECODE_cav4_mech
`include "addr_map_cav4_mech.vh"
`define AUTOMATIC_self input lb_clk, input [31:0] lb_data, input lb_write, input [13:0] lb_addr
`define AUTOMATIC_decode\
wire [9:0] noise_couple_k_out_addr;\
wire [17:0] noise_couple_k_out;\
wire we_noise_couple_k_out = lb_write&(`ADDR_HIT_noise_couple_k_out);\
dpram #(.aw(10),.dw(18)) dp_noise_couple_k_out(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[17:0]), .wena(we_noise_couple_k_out),\
	.clkb(lb_clk), .addrb(noise_couple_k_out_addr), .doutb(noise_couple_k_out));\
wire [9:0] resonator_prop_const_addr;\
wire [20:0] resonator_prop_const;\
wire we_resonator_prop_const = lb_write&(`ADDR_HIT_resonator_prop_const);\
dpram #(.aw(10),.dw(21)) dp_resonator_prop_const(\
	.clka(lb_clk), .addra(lb_addr[9:0]), .dina(lb_data[20:0]), .wena(we_resonator_prop_const),\
	.clkb(lb_clk), .addrb(resonator_prop_const_addr), .doutb(resonator_prop_const));\
wire we_prng_random_run = lb_write&(`ADDR_HIT_prng_random_run);\
reg [0:0] prng_random_run=0; always @(posedge lb_clk) if (we_prng_random_run) prng_random_run <= lb_data;\
wire we_prng_iva = lb_write&(`ADDR_HIT_prng_iva);\
wire prng_iva_we = we_prng_iva;\
reg [31:0] prng_iva=0; always @(posedge lb_clk) if (we_prng_iva) prng_iva <= lb_data;\
wire we_prng_ivb = lb_write&(`ADDR_HIT_prng_ivb);\
wire prng_ivb_we = we_prng_ivb;\
reg [31:0] prng_ivb=0; always @(posedge lb_clk) if (we_prng_ivb) prng_ivb <= lb_data;\
wire [31:0] mirror_out_0;wire mirror_write_0 = lb_write &(`ADDR_HIT_MIRROR);\
dpram #(.aw(`MIRROR_WIDTH),.dw(32)) mirror_0(\
	.clka(lb_clk), .addra(lb_addr[`MIRROR_WIDTH-1:0]), .dina(lb_data[31:0]), .wena(mirror_write_0),\
	.clkb(lb_clk), .addrb(lb_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_0));\

`else
`define AUTOMATIC_self input signed [17:0] noise_couple_k_out,\
output  [9:0] noise_couple_k_out_addr,\
input  [20:0] resonator_prop_const,\
output  [9:0] resonator_prop_const_addr,\
input  [0:0] prng_random_run,\
input  [31:0] prng_iva,\
input  [0:0] prng_iva_we,\
input  [31:0] prng_ivb,\
input  [0:0] prng_ivb_we
`define AUTOMATIC_decode
`endif