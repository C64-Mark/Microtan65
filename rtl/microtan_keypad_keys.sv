module microtan_keypad_keys (
	input  logic        clk,
	input  logic        reset,
	input  logic        event_strobe,
	input  logic        key_pressed,
	input  logic        key_extended,
	input  logic [7:0]  scan_code,

	/*
	 * Physical MT006 positions in TANBUG scan-table order:
	 *
	 *  0-4:   KO3 with KI0-KI4
	 *  5-9:   KO2 with KI0-KI4
	 * 10-14:  KO1 with KI0-KI4
	 * 15-19:  KO0 with KI0-KI4
	 *
	 * Position 4 is physically absent.
	 * Position 19 is the MT006 SHIFT key.
	 */
	output logic [19:0] keypad_keys
);

logic       mapped_valid;
logic [4:0] mapped_index;

always_comb begin
	mapped_valid = 1'b0;
	mapped_index = 5'd0;

	/*
	 * Map ordinary host keys to the corresponding unshifted physical MT006 keys.
	 * Extended keys are deliberately ignored at this checkpoint.
	 */
	if(!key_extended) begin
		case(scan_code)
			// Hexadecimal digits.
			8'h45: begin mapped_valid = 1'b1; mapped_index = 5'd15; end // 0
			8'h16: begin mapped_valid = 1'b1; mapped_index = 5'd10; end // 1
			8'h1E: begin mapped_valid = 1'b1; mapped_index = 5'd5;  end // 2
			8'h26: begin mapped_valid = 1'b1; mapped_index = 5'd0;  end // 3
			8'h25: begin mapped_valid = 1'b1; mapped_index = 5'd16; end // 4
			8'h2E: begin mapped_valid = 1'b1; mapped_index = 5'd11; end // 5
			8'h36: begin mapped_valid = 1'b1; mapped_index = 5'd6;  end // 6
			8'h3D: begin mapped_valid = 1'b1; mapped_index = 5'd1;  end // 7
			8'h3E: begin mapped_valid = 1'b1; mapped_index = 5'd17; end // 8
			8'h46: begin mapped_valid = 1'b1; mapped_index = 5'd12; end // 9
			8'h1C: begin mapped_valid = 1'b1; mapped_index = 5'd7;  end // A
			8'h32: begin mapped_valid = 1'b1; mapped_index = 5'd2;  end // B
			8'h21: begin mapped_valid = 1'b1; mapped_index = 5'd18; end // C
			8'h23: begin mapped_valid = 1'b1; mapped_index = 5'd13; end // D
			8'h24: begin mapped_valid = 1'b1; mapped_index = 5'd8;  end // E
			8'h2B: begin mapped_valid = 1'b1; mapped_index = 5'd3;  end // F

			// Other directly represented physical keys.
			8'h5A: begin mapped_valid = 1'b1; mapped_index = 5'd9;  end // RETURN -> CR/SP
			8'h66: begin mapped_valid = 1'b1; mapped_index = 5'd14; end // BACKSPACE -> LF/DEL
			8'h12: begin mapped_valid = 1'b1; mapped_index = 5'd19; end // Left Shift
			8'h59: begin mapped_valid = 1'b1; mapped_index = 5'd19; end // Right Shift

			default: begin end
		endcase
	end
end

always_ff @(posedge clk) begin
	if(reset)
		keypad_keys <= 20'b0;
	else if(event_strobe && mapped_valid)
		keypad_keys[mapped_index] <= key_pressed;
end

endmodule