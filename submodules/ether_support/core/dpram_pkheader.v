`timescale 1ns / 1ns
// Dual port memory with independent clocks, port B is read-only
// Altera and Xilinx synthesis tools successfully "find" this as block memory
// Initializer parameters can be provided.
module dpram_pkheader #(
    parameter aw=5,
    parameter dw=8,
    parameter [47:0] DEFAULT_DESTINATION_MAC_ADDRESS = 48'hFFFFFFFFFFFF,
    parameter [31:0] DEFAULT_DESTINATION_IP_ADDRESS  = 32'hFFFFFFFF,
    parameter [15:0] DEFAULT_DESTINATION_UDP_PORT    = 16'h80F0) (
	input clka, clkb, wena,
	input [aw-1:0] addra, addrb,
	input [dw-1:0] dina,
	output [dw-1:0] douta, doutb);

localparam sz=(32'b1<<aw)-1;

reg [dw-1:0] mem[sz:0];
reg [aw-1:0] ala=0, alb=0;

initial begin
	mem[5'h00] = DEFAULT_DESTINATION_MAC_ADDRESS[47:40];
	mem[5'h01] = DEFAULT_DESTINATION_MAC_ADDRESS[39:32];
	mem[5'h02] = DEFAULT_DESTINATION_MAC_ADDRESS[31:24];
	mem[5'h03] = DEFAULT_DESTINATION_MAC_ADDRESS[23:16];
	mem[5'h04] = DEFAULT_DESTINATION_MAC_ADDRESS[15:8];
	mem[5'h05] = DEFAULT_DESTINATION_MAC_ADDRESS[7:0];
	mem[5'h06] = DEFAULT_DESTINATION_IP_ADDRESS[31:24];
	mem[5'h07] = DEFAULT_DESTINATION_IP_ADDRESS[23:16];
	mem[5'h08] = DEFAULT_DESTINATION_IP_ADDRESS[15:8];
	mem[5'h09] = DEFAULT_DESTINATION_IP_ADDRESS[7:0];
	mem[5'h0A] = DEFAULT_DESTINATION_UDP_PORT[15:8];
	mem[5'h0B] = DEFAULT_DESTINATION_UDP_PORT[7:0];
	mem[5'h0C] = 8'h00; // Unused, just get rid of ugly xx's in VCD file
end

assign douta = mem[ala];
assign doutb = mem[alb];
always @(posedge clka) begin
	ala <= addra;
	if (wena) mem[addra]<=dina;
end
always @(posedge clkb) begin
	alb <= addrb;
end

endmodule
