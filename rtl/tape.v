// tape.v

module tape
(
	input             clk, 
	input             ce_tape,
	input             reset,

	input       [7:0] data, 
	input      [15:0] length,
	output reg [15:0] addr,
	output reg        req,

	input             loaded,
	output reg        out
);

always @(posedge clk) begin
	reg  [2:0] state = 0;
	reg [10:0] byte_reg;
	reg  [3:0] bit_cnt;
	reg  [3:0] tape_state;

	if (reset | loaded) begin
		state <= {1'b0, loaded};
		req   <= loaded;
		addr  <= 0;
		out   <= 0;
	end else begin
		case(state)
		// Fetch byte to send
		1:	begin
				if (addr >= length) begin
					req      <= 0;
					state    <= 0;
				end else begin
					byte_reg <= { 1'b0, data, 2'b11 };
					addr     <= addr + 1'd1;
					bit_cnt  <= 11;
					state    <= 2; // START sending
				end
			end

		// Send byte
		2: begin
				if (bit_cnt == 0) begin
					state      <= 1; // Fetch next byte
				end else begin
					bit_cnt    <= bit_cnt - 1'd1;
					tape_state <= 0;
					state      <= byte_reg[bit_cnt-1'd1] ? 3'd3 : 3'd4;
				end
         end

		// Send 1
		3: if (ce_tape) begin
				tape_state <= tape_state + 1'd1;
				case(tape_state)
					0:	out <= 1;
					1:	out <= 0;
					2:	out <= 1;
					3:	begin
							out <= 0;
							state <= 2;
						end
				endcase
			end

		// Send 0
		4: if (ce_tape) begin
				tape_state <= tape_state + 1'd1;
				case(tape_state)
					0:	out <= 1;
					2:	out <= 0;
					4:	out <= 1;
					6:	out <= 0;
					7: state <= 2;
				endcase
			end
		endcase
	end
end

endmodule
