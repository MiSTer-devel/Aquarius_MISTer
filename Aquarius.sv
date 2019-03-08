//============================================================================
//  Aquarius
// 
//  Enhanced version for MiSTer.
//  Copyright (C) 2017-2019 Sorgelig
//
//  Original Aquarius (c) 2016 Sebastien Delestaing 
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output  [1:0] VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..5 - USR1..USR4
	// Set USER_OUT to 1 to read from USER_IN.
	input   [5:0] USER_IN,
	output  [5:0] USER_OUT,

	input         OSD_STATUS
);

assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign AUDIO_S   = 0;
assign AUDIO_MIX = 0;

assign LED_USER    = ioctl_download | tape_req;
assign LED_DISK[1] = 1;
assign LED_POWER   = 0;

assign VIDEO_ARX = status[1] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[1] ? 8'd9  : 8'd3;

`include "build_id.v"
localparam CONF_STR =
{
	"AQUARIUS;;",
	"-;",
	"F,BIN,Load Cartridge;",
	"F,CAQ,Load Tape;",
	"O9,Fast loading,No,Yes;",
	"-;",
	"O1,Aspect ratio,4:3,16:9;",
	"O24,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O56,CPU Speed,Normal,x2,x4,x8;",
	"O78,RAM expansion,16KB,32KB,None,4KB;",
	"-;",
	"R0,Reset;",
	"-;",
	"J,K1,K2,K3,K4,K5,K6;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys)
);

reg ce_3m5;
reg ce_1m7;
reg ce_3k33;

wire fast_tape = tape_req && {status[9],status[6:5]};

always @(negedge clk_sys) begin	
	reg  [4:0] clk_div;
	reg [14:0] clk_div2;

	clk_div <= clk_div + 1'd1;
	ce_1m7 <= !clk_div[4:0];
	
	casex({fast_tape, status[6:5]}) 
		'b1XX: ce_3m5 <= 1;
		'b000: ce_3m5 <= !clk_div[3:0];
		'b001: ce_3m5 <= !clk_div[2:0];
		'b010: ce_3m5 <= !clk_div[1:0];
		'b011: ce_3m5 <= !clk_div[0:0];
	endcase
	
	clk_div2 <= clk_div2 + 1'd1;
	if(clk_div2 >= (fast_tape ? 1073 : 17187)) clk_div2 <= 0;
	ce_3k33 <= !clk_div2;
end

//////////////////   HPS I/O   ///////////////////
wire [10:0] ps2_key;

wire [15:0] joystick_0;
wire [15:0] joystick_1;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire [31:0] status;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.conf_str(CONF_STR),
	.HPS_BUS(HPS_BUS),

	.ps2_key(ps2_key),
	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.status(status),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index)
);

///////////////////////////////////////////////

wire reset = RESET | status[0] | buttons[1];
wire cpu_reset = reset || (ioctl_download && (ioctl_index == 1));

reg rom_loaded = 0;
always @(posedge clk_sys) begin
	if(ioctl_download && (ioctl_index == 1)) rom_loaded <= 1;
	if(reset) rom_loaded <= 0;
end

// CPU control signals
wire [15:0] cpu_addr;
wire [7:0] cpu_din;
wire [7:0] cpu_dout;
wire cpu_rd_n;
wire cpu_wr_n;
wire cpu_mreq_n;
wire cpu_m1_n;
wire cpu_iorq_n;

T80s T80s
(
	.RESET_n  ( !cpu_reset ),
	.CLK_n    ( clk_sys & ce_3m5 ),
	.WAIT_n   ( 1          ),
	.INT_n    ( 1          ),
	.NMI_n    ( 1          ),
	.BUSRQ_n  ( 1          ),
	.IORQ_n   ( cpu_iorq_n ),
	.M1_n		 ( cpu_m1_n   ),
	.MREQ_n   ( cpu_mreq_n ),
	.RD_n     ( cpu_rd_n   ), 
	.WR_n     ( cpu_wr_n   ),
	.A        ( cpu_addr   ),
	.DI       ( cpu_din    ),
	.DO       ( cpu_dout   )
);

wire [7:0] aquarius_rom_data;
main_rom main_rom
(
	.clk  ( clk_sys           ),
	.addr ( cpu_addr[12:0]    ),
	.data ( aquarius_rom_data )
);

wire       ram_we, ext_we;
wire [7:0] ram_dout, ram_din;
gen_dpram #(16,8) main_ram
(
	.clock_a(clk_sys),
	.address_a({2'b11, ioctl_addr[13:0]}),
	.data_a(ioctl_dout),
	.wren_a((ioctl_index == 1) && ioctl_download && ioctl_wr),

	.clock_b(clk_sys),
	.address_b(cpu_addr),
	.data_b(ram_din),
	.enable_b(ce_3m5),
	.wren_b(ram_we | ext_we),
	.q_b(ram_dout)
);

wire video_we;
wire cass_in, cass_out;
Pla1 Pla1
(
	.CLK          ( clk_sys & ce_3m5 ),
	.RST          ( cpu_reset   ),
	
	.CFG          ( status[8:7] + 2'd2 ),

	.ADDR         ( cpu_addr    ),
	.CPU_IN       ( cpu_dout    ),	 
	.CPU_OUT      ( cpu_din     ),
	.MEMWR        (  !cpu_mreq_n              && !cpu_wr_n ), 
	.IOWR         ( (!cpu_iorq_n && cpu_m1_n) && !cpu_wr_n ),
	.IORD         ( (!cpu_iorq_n && cpu_m1_n) && !cpu_rd_n ),

	.VIDEO_WE     ( video_we    ),

	.DATA_ROM     ( aquarius_rom_data ),
	.DATA_ROMPACK ( ram_dout    ),
	.ROM_EN       ( rom_loaded  ),

	.EXT_WE       ( ext_we      ),
	.RAM_WE       ( ram_we      ),
	.RAM_IN       ( ram_dout    ),
	.RAM_OUT      ( ram_din     ),

	.KEY_VALUE    ( key_value   ),
	.PSG_IN       ( psg_dout    ),
	.PSG_SEL      ( psg_sel     ),
	.LED_OUT      ( LED_DISK[0] ),
	.CASS_OUT     ( cass_out    ),
	.CASS_IN      ( cass_in     ),
	.VSYNC        ( vf          )
);

////////////////////////////////////////////////////////

gen_dpram #(10,8) video_data
(
	.clock_a   ( clk_sys   ),
	.enable_a  ( ce_3m5    ),
	.address_a ( cpu_addr[9:0]),
	.wren_a    (~cpu_addr[10] & video_we ),
	.data_a    ( cpu_dout  ),

	.clock_b   ( clk_sys   ),
	.address_b ( vd_addr   ),
	.q_b       ( vd_data   )
);

gen_dpram #(10,8) video_color
(
	.clock_a   ( clk_sys   ),
	.enable_a  ( ce_3m5    ),
	.address_a ( cpu_addr[9:0]),
	.wren_a    ( cpu_addr[10] & video_we ),
	.data_a    ( cpu_dout  ),

	.clock_b   ( clk_sys   ),
	.address_b ( vd_addr   ),
	.q_b       ( vd_color  )
);

wire [7:0] vd_data, vd_color;
wire [9:0] vd_addr;

assign CLK_VIDEO = clk_sys;

wire [2:0] scale = status[4:2];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

wire vf;
video video
(
	.*,
	.hq2x(scale == 1),
	.scandoubler(|scale),
	.video_addr(vd_addr),
	.video_data(vd_data),
	.video_color(vd_color)
);


////////////////////////////////////////////////////////

wire [7:0] psg_dout;
wire       psg_sel;
wire [9:0] audio_a,audio_b,audio_c;

ym2149 ym2149
(
	.CLK(clk_sys),
	.CE(ce_1m7),
	.RESET(cpu_reset),

	.BDIR(psg_sel && !cpu_wr_n),
	.BC(psg_sel && (cpu_addr[0] || cpu_wr_n)),
	.DI(cpu_dout),
	.DO(psg_dout),

	.CHANNEL_A(audio_a[7:0]),
	.CHANNEL_B(audio_b[7:0]),
	.CHANNEL_C(audio_c[7:0]),

	.SEL(0),
	.MODE(0),

	.IOA_in(pad0),
	.IOB_in(pad1)
);

assign {audio_a[9:8],audio_b[9:8],audio_c[9:8]} = 0;
wire [9:0] audio_data = audio_a+audio_b+audio_c+{2'b00,cass_out,cass_in,6'd0};

assign AUDIO_L = {audio_data, 6'd0};
assign AUDIO_R = {audio_data, 6'd0};

////////////////////////////////////////////////////////

wire [7:0] pad0, pad1;

pad pad_0(.joy_in(joystick_0[9:0]), .pad_out(pad0 | kbd_pad0));
pad pad_1(.joy_in(joystick_1[9:0]), .pad_out(pad1 | kbd_pad1));

// include keyboard decoder
wire [7:0] key_value; // Pla1 <-> PS2_to_matrix

wire [9:0] kbd_pad0,kbd_pad1;
PS2_to_matrix PS2_to_matrix
(
	.clk   ( clk_sys   ),
	.reset ( cpu_reset ),

	// Pla1 interface
	.sfrdatao ( key_value      ),
	.addr     ( cpu_addr[15:8] ),

	.pad0(kbd_pad0),
	.pad1(kbd_pad1),
	
	.psdatai(ps2_key[7:0]),
	.psdataex(ps2_key[8]),
	.pspress(ps2_key[9]),
	.psstate(ps2_key[10])
);

////////////////////////////////////////////////////////

reg tape_loaded = 0;
always @(posedge clk_sys) begin
	reg old_download;
	old_download <= ioctl_download;
	
	tape_loaded <= (old_download & ~ioctl_download && (ioctl_index == 2));
	if(cpu_reset) tape_loaded <= 0;
end

gen_dpram #(16,8) tape_ram
(
	.clock_a(clk_sys),
	.address_a(ioctl_addr[15:0]),
	.data_a(ioctl_dout),
	.wren_a((ioctl_index == 2) && ioctl_download && ioctl_wr),

	.clock_b(clk_sys),
	.address_b(tape_addr),
	.data_b(0),
	.wren_b(0),
	.q_b(tape_data)
);

wire [7:0]  tape_data;
wire [15:0] tape_addr;
wire        tape_req;

tape tape
(
	.clk		( clk_sys      ),
	.ce_tape ( ce_3k33      ),
	.reset	( cpu_reset	   ),

	// Memory interface
	.data 	( tape_data 	),
	.addr		( tape_addr		),
	.length	( ioctl_addr[15:0]),
	.req     ( tape_req     ),

	// Tape interface
	.loaded	( tape_loaded	),
	.out		( cass_in	   )
);

endmodule
