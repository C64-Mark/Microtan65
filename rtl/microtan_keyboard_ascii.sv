module microtan_keyboard_ascii #(parameter CAPS_LOCK_DEFAULT = 1'b1) (
	input  logic       clk,
	input  logic       reset,
	input  logic       event_strobe,
	input  logic       key_pressed,
	input  logic       key_extended,
	input  logic [7:0] scan_code,
	output logic       ascii_strobe,
	output logic [6:0] ascii_data
);

logic 		left_shift;
logic 		right_shift;
logic 		left_control;
logic 		right_control;
logic 		caps_lock;
logic       mapped_valid;
logic       letter_key;
logic [6:0] mapped_ascii;

wire shift_active   = left_shift || right_shift;
wire control_active = left_control || right_control;

always_comb begin
	mapped_valid = 1'b0;
	letter_key   = 1'b0;
	mapped_ascii = 7'h00;

	if(!key_extended) begin
		case(scan_code)
			// PS/2 Set 2 alphabetic keys. Lower-case is the base value; Shift and Caps Lock are applied below.
			8'h1C: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h61; end // A
			8'h32: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h62; end // B
			8'h21: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h63; end // C
			8'h23: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h64; end // D
			8'h24: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h65; end // E
			8'h2B: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h66; end // F
			8'h34: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h67; end // G
			8'h33: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h68; end // H
			8'h43: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h69; end // I
			8'h3B: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6A; end // J
			8'h42: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6B; end // K
			8'h4B: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6C; end // L
			8'h3A: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6D; end // M
			8'h31: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6E; end // N
			8'h44: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h6F; end // O
			8'h4D: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h70; end // P
			8'h15: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h71; end // Q
			8'h2D: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h72; end // R
			8'h1B: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h73; end // S
			8'h2C: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h74; end // T
			8'h3C: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h75; end // U
			8'h2A: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h76; end // V
			8'h1D: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h77; end // W
			8'h22: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h78; end // X
			8'h35: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h79; end // Y
			8'h1A: begin mapped_valid = 1'b1; letter_key = 1'b1; mapped_ascii = 7'h7A; end // Z

			// UK-style host digit row. The Microtan receives seven-bit ASCII characters rather than physical keyboard positions.
			8'h45: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h29 : 7'h30; end // 0 / )
			8'h16: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h21 : 7'h31; end // 1 / !
			8'h1E: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h22 : 7'h32; end // 2 / "
			8'h26: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h23 : 7'h33; end // 3 / #
			8'h25: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h24 : 7'h34; end // 4 / $
			8'h2E: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h25 : 7'h35; end // 5 / %
			8'h36: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h5E : 7'h36; end // 6 / ^
			8'h3D: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h26 : 7'h37; end // 7 / &
			8'h3E: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h2A : 7'h38; end // 8 / *
			8'h46: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h28 : 7'h39; end // 9 / (

			// UK-style host punctuation translated to seven-bit ASCII.
			8'h0E: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h7E : 7'h60; end // ` / ~
			8'h4E: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h5F : 7'h2D; end // - / _
			8'h55: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h2B : 7'h3D; end // = / +
			8'h54: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h7B : 7'h5B; end // [ / {
			8'h5B: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h7D : 7'h5D; end // ] / }
			8'h5D: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h7E : 7'h23; end // # / ~
			8'h61: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h7C : 7'h5C; end // \ / |
			8'h4C: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h3A : 7'h3B; end // ; / :
			8'h52: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h40 : 7'h27; end // ' / @
			8'h41: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h3C : 7'h2C; end // , / <
			8'h49: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h3E : 7'h2E; end // . / >
			8'h4A: if(!control_active) begin mapped_valid = 1'b1; mapped_ascii = shift_active ? 7'h3F : 7'h2F; end // / / ?

			// Character-producing special keys.
			8'h0D: begin mapped_valid = 1'b1; mapped_ascii = 7'h09; end // TAB
			8'h76: begin mapped_valid = 1'b1; mapped_ascii = 7'h1B; end // ESC
			8'h5A: begin mapped_valid = 1'b1; mapped_ascii = 7'h0D; end // RETURN
			8'h29: begin mapped_valid = 1'b1; mapped_ascii = 7'h20; end // SPACE
			8'h66: begin mapped_valid = 1'b1; mapped_ascii = 7'h7F; end // host Backspace -> DELETE / RUBOUT
			default: begin end
		endcase
	end
	else begin
		case(scan_code)
			8'h5A: begin mapped_valid = 1'b1; mapped_ascii = 7'h0A; end // keypad Enter -> LINE FEED
			8'h70: begin mapped_valid = 1'b1; mapped_ascii = 7'h0A; end // Insert -> LINE FEED
			8'h71: begin mapped_valid = 1'b1; mapped_ascii = 7'h08; end // host Delete -> BACKSPACE
			8'h77: begin mapped_valid = 1'b1; mapped_ascii = 7'h03; end // Pause/Break -> BREAK
			default: begin end
		endcase
	end

	if(letter_key) begin
		if(control_active)
			mapped_ascii = mapped_ascii & 7'h1F;
		else if(shift_active ^ caps_lock)
			mapped_ascii = mapped_ascii - 7'h20;
	end
end

always_ff @(posedge clk) begin
	if(reset) begin
		left_shift    	<= 1'b0;
		right_shift   	<= 1'b0;
		left_control  	<= 1'b0;
		right_control 	<= 1'b0;
		caps_lock     	<= CAPS_LOCK_DEFAULT;
		ascii_strobe 	<= 1'b0;
		ascii_data   	<= 7'h00;
	end
	else begin
		ascii_strobe <= 1'b0;

		if(event_strobe) begin
			if(!key_extended && scan_code == 8'h12)
				left_shift <= key_pressed;
			else if(!key_extended && scan_code == 8'h59)
				right_shift <= key_pressed;
			else if(scan_code == 8'h14) begin
				if(key_extended)
					right_control <= key_pressed;
				else
					left_control <= key_pressed;
			end
			else if(!key_extended && scan_code == 8'h58) begin
				if(key_pressed)
					caps_lock <= ~caps_lock;
			end
			else if(key_pressed && mapped_valid) begin
				ascii_data   <= mapped_ascii;
				ascii_strobe <= 1'b1;
			end
		end
	end
end

endmodule