`timescale 1ns / 1ps

module video
(
	input        clk_sys,
	
	input        hq2x,
	input        scandoubler,

	output       CE_PIXEL,
	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output       VGA_DE,
	output       VGA_HS,
	output       VGA_VS,

	output reg   vf,
	output [9:0] video_addr,
	input  [7:0] video_data,
	input  [7:0] video_color
);

reg ce_7mp, ce_7mn;
always @(negedge clk_sys) begin	
	reg  [2:0] clk_div;
	
	clk_div <= clk_div + 1'd1;

	ce_7mp <= !clk_div[2:0];
	ce_7mn <= clk_div[2] && !clk_div[1:0];
end

wire  [7:0] char_data;
char_rom char_rom
(
	.clk  (clk_sys),
	.addr ({video_data[7:0], vc[2:0]}),
	.data (char_data)
);

assign video_addr = {vc[7:3], 5'b00000}+{vc[7:3], 3'b000}+hc[8:3];

reg  [8:0] hc;
reg  [8:0] vc;
reg        hs,vs;
always @(posedge clk_sys) begin
	if(ce_7mp) begin
		hc <= hc + 1'd1;
		if(hc == 457) begin 
			hc <=0;
			vc <= vc + 1'd1;
			if(vc == 261) vc <= 0;
		end
	end

	if(ce_7mn) begin
		if(hc == 362) begin
			hs <= 1;
			if(vc == 225) vs <= 1;
			if(vc == 240) vs <= 0;
		end
		if(hc == 395) hs <= 0;
		if(vc == 201) vf <= 0;
		if(vc == 244) vf <= 1;
	end
end

reg  [7:0] vdata;
reg        vblank;
reg        hblank;
wire [3:0] color = vdata[7] ? video_color[7:4] : video_color[3:0];
reg  [7:0] r,g,b;

always @(posedge clk_sys) begin
	reg vbl;
	reg hbl;

	if(ce_7mn) begin
		if(!hc[2:0]) begin
			hbl <= (hc>=320);
			vbl <= (vc>=200);
			if((hc<320) && (vc<200)) vdata <= char_data;
		end
		else begin
			vdata <= {vdata[6:0], 1'b0};
		end
	end

	if(ce_7mp) begin
		hblank <= hbl;
		vblank <= vbl;
		case(color)
			'b0000: {r,g,b} <= {8'd0,   8'd0,   8'd0   };
			'b0001: {r,g,b} <= {8'd196, 8'd0,   8'd27  };
			'b0010: {r,g,b} <= {8'd7,   8'd191, 8'd0   };
			'b0011: {r,g,b} <= {8'd201, 8'd185, 8'd8   };
			'b0100: {r,g,b} <= {8'd0,   8'd6,   8'd183 };
			'b0101: {r,g,b} <= {8'd184, 8'd0,   8'd210 };
			'b0110: {r,g,b} <= {8'd0,   8'd199, 8'd164 };
			'b0111: {r,g,b} <= {8'd255, 8'd255, 8'd255 };
			'b1000: {r,g,b} <= {8'd191, 8'd191, 8'd191 };
			'b1001: {r,g,b} <= {8'd65,  8'd166, 8'd149 };
			'b1010: {r,g,b} <= {8'd131, 8'd40,  8'd144 };
			'b1011: {r,g,b} <= {8'd6,   8'd14,  8'd105 };
			'b1100: {r,g,b} <= {8'd186, 8'd178, 8'd86  };
			'b1101: {r,g,b} <= {8'd60,  8'd152, 8'd47  };
			'b1110: {r,g,b} <= {8'd127, 8'd25,  8'd42  };
			'b1111: {r,g,b} <= {8'd0,   8'd0,   8'd0   };
		endcase
	end
end

video_mixer #(320) mixer
(
	.clk_sys(clk_sys),
	
	.ce_pix(ce_7mn),
	.ce_pix_out(CE_PIXEL),

	.hq2x(hq2x),
	.scanlines(0),
	.scandoubler(scandoubler),

	.R(r),
	.G(g),
	.B(b),

	.mono(0),

	.HSync(hs),
	.VSync(vs),
	.HBlank(hblank),
	.VBlank(vblank),

	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(VGA_DE)
);

endmodule
