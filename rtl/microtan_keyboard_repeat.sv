module microtan_keyboard_repeat (
	input  logic       clk,
	input  logic       reset,
	input  logic       event_strobe,
	input  logic       key_pressed,
	input  logic       key_extended,
	input  logic [7:0] scan_code,
	input  logic       ascii_strobe,
	input  logic [6:0] ascii_data,
	input  logic       repeat_tick,
	output logic       keyboard_strobe,
	output logic [6:0] keyboard_data,
	output wire        repeat_active
);

logic       repeat_held;
logic       held_valid;
logic       held_key_extended;
logic [7:0] held_key_scan_code;
logic [6:0] held_ascii_data;
logic       pending_key_extended;
logic [7:0] pending_key_scan_code;

wire repeat_key_event = event_strobe &&	key_extended &&	scan_code == 8'h11; // Right Alt / AltGr
wire held_key_release =	event_strobe &&	!key_pressed &&	held_valid && key_extended == held_key_extended && scan_code == held_key_scan_code;
assign repeat_active = repeat_held;

always_ff @(posedge clk) begin
	if(reset) begin
		repeat_held          	<= 1'b0;
		held_valid           	<= 1'b0;
		held_key_extended    	<= 1'b0;
		held_key_scan_code   	<= 8'h00;
		held_ascii_data      	<= 7'h00;
		pending_key_extended 	<= 1'b0;
		pending_key_scan_code 	<= 8'h00;
		keyboard_strobe 		<= 1'b0;
		keyboard_data   		<= 7'h00;
	end
	else begin
		keyboard_strobe <= 1'b0;

		if(event_strobe) begin
			pending_key_extended  <= key_extended;
			pending_key_scan_code <= scan_code;

			if(key_extended && scan_code == 8'h11)
				repeat_held <= key_pressed;

			if(held_key_release)
				held_valid <= 1'b0;
		end

		if(ascii_strobe) begin
			held_valid         	<= 1'b1;
			held_key_extended  	<= pending_key_extended;
			held_key_scan_code 	<= pending_key_scan_code;
			held_ascii_data    	<= ascii_data;
			keyboard_data   	<= ascii_data;
			keyboard_strobe 	<= 1'b1;
		end
		else if(repeat_tick && repeat_held && held_valid && !repeat_key_event && !held_key_release) begin
			keyboard_data   <= held_ascii_data;
			keyboard_strobe <= 1'b1;
		end
	end
end

endmodule