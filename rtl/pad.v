									  
module pad
(
	input  [9:0] joy_in,
	output [7:0] pad_out
);

wire [7:0] btn = 
	(8'hBF | {8{~joy_in[4]}}) & // k1
	(8'h7B | {8{~joy_in[5]}}) & // k2
	(8'h5F | {8{~joy_in[6]}}) & // k3
	(8'hDF | {8{~joy_in[7]}}) & // k4
	(8'h7D | {8{~joy_in[8]}}) & // k5
	(8'h7E | {8{~joy_in[9]}});  // k6

reg [7:0] rd, ld, ru, lu;
always @(*) begin
	case({joy_in[0],joy_in[2]})
		'b10: rd = 8'hFD;
		'b11: rd = 8'hEC;
		'b01: rd = 8'hFE;
		'b00: rd = 8'hFF;
	endcase

	case({joy_in[1],joy_in[2]})
		'b10: ld = 8'hF7;
		'b11: ld = 8'hE6;
		'b01: ld = 8'hFE;
		'b00: ld = 8'hFF;
	endcase

	case({joy_in[0],joy_in[3]})
		'b10: ru = 8'hFD;
		'b11: ru = 8'hE9;
		'b01: ru = 8'hFB;
		'b00: ru = 8'hFF;
	endcase

	case({joy_in[1],joy_in[3]})
		'b10: lu = 8'hF7;
		'b11: lu = 8'hE3;
		'b01: lu = 8'hFB;
		'b00: lu = 8'hFF;
	endcase
end

assign pad_out = btn & rd & ld & ru & lu;

endmodule
