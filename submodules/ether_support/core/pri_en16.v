`timescale 1ns / 1ns

module pri_en16(
	input [15:0] inp,
	output [3:0] which,
	output hit
);

wire h0, h1, h2, h3, hx;
wire [1:0] w0, w1, w2, w3, wx;
pri_en4 p0(.inp(inp[  3:0  ]), .which(w0), .hit(h0));
pri_en4 p1(.inp(inp[  7:4  ]), .which(w1), .hit(h1));
pri_en4 p2(.inp(inp[ 11:8  ]), .which(w2), .hit(h2));
pri_en4 p3(.inp(inp[ 15:12 ]), .which(w3), .hit(h3));

wire [3:0] hv={h3,h2,h1,h0};
pri_en4 px(.inp(hv), .which(wx), .hit(hx));

reg [1:0] wm;
always @(*) case(wx)
	2'b00: wm=w0;
	2'b01: wm=w1;
	2'b10: wm=w2;
	2'b11: wm=w3;
endcase

assign which = {wx,wm};
assign hit = hx;

endmodule
