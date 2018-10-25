`timescale 1ns / 1ns

// Example of how an "external" source can push a new IP/MAC configuration
// into the LBNL Ethernet-in-fabric.
// Might even be useful if last_ip_byte comes from a DIP switch.
module set_address(
	input clk,
	input rst,
	input [7:0] last_ip_byte,
	output [8:0] address_set
);

parameter [31:0] ip_net = {8'd128, 8'd3, 8'd128, 8'd172};  // 128.3.128.172
// parameter [31:0] ip_net = {8'd192, 8'd168, 8'd7, 8'd3};  // 192.168.7.3
parameter [47:0] mac = 48'h125555000135;  // fictitious
// !!!NOTE!!! the final octet of both IP and MAC is overwritten by last_ip_byte

// Write MAC and IP addreses onto ROM
reg [8:0] address_set_reg=8'b0;
reg [3:0] count=4'b0;
reg count_en=1'b0;
reg rst1=1'b0;
wire rst_p = rst & ~rst1;   // Rising edge
always @(posedge clk) begin
	rst1 <= rst;
	if(rst_p) count_en <= 1'b0;
	count <= ~count_en ? count+1 : 0;
	case (count)
	1: address_set_reg <= {1'b1,last_ip_byte};
	2: address_set_reg <= {1'b1,ip_net[15:8]};
	3: address_set_reg <= {1'b1,ip_net[23:16]};
	4: address_set_reg <= {1'b1,ip_net[31:24]};
	5: address_set_reg <= {1'b1,last_ip_byte};
	6: address_set_reg <= {1'b1,mac[15:8]};
	7: address_set_reg <= {1'b1,mac[23:16]};
	8: address_set_reg <= {1'b1,mac[31:24]};
	9: address_set_reg <= {1'b1,mac[39:32]};
	10: begin
		address_set_reg <= {1'b1,mac[47:40]};
		count_en <= 1'b1;
	end
	default: address_set_reg <= 0;
	endcase
end

assign address_set = address_set_reg;

endmodule
