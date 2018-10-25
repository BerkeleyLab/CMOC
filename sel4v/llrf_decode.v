`timescale 1ns / 1ns

// kind of stupid, but needed to rename lb2_foo wires (used in mres_dsp.v)
// to lb_foo (needed by the automatically generated address decoder).

// always need this
`define LB_DECODE_llrf_decode
`include "llrf_decode_auto.vh"

module llrf_decode(
	input clk,
	// RF ADC inputs, at IF
	input signed [15:0] a_field,
	input signed [15:0] a_forward,
	input signed [15:0] a_reflect,
	input signed [15:0] a_phref,
	// RF drive without local upconversion
	output iq,
	output [17:0] drive,
	// SSB RF DAC drive (if you don't use it, six multipliers will disappear)
	output [15:0] dac1_out0,
	output [15:0] dac1_out1,
	output [15:0] dac2_out0,
	output [15:0] dac2_out1,
	// Piezo interface
	output signed [15:0] piezo_ctl,
	output piezo_stb,
	// External trigger capability (not sure how useful this will be)
	input ext_trig,
	// External waveform recording
	output signed [19:0] mon_result,
	output mon_strobe,
	output mon_boundary,

	// Local Bus -- DSP clock domain (clk)
	input [31:0] lb_data,
	input [15:0] lb_addr,
	input lb_write  // single-cycle causes a write
);

`AUTOMATIC_decode

llrf_dsp dsp // auto
	(.clk(clk),
	.a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect), .a_phref(a_phref),
	.iq(iq), .drive(drive),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.dac2_out0(dac2_out0), .dac2_out1(dac2_out1),
	.piezo_ctl(piezo_ctl), .piezo_stb(piezo_stb),
	.ext_trig(ext_trig),
	.mon_result(mon_result), .mon_strobe(mon_strobe), .mon_boundary(mon_boundary),
	`AUTOMATIC_dsp
);

endmodule
