module microtan_joystick_keyboard (
	input  logic       	clk,
	input  logic       	reset,
	input  logic       	event_strobe,
	input  logic       	key_pressed,
	input  logic       	key_extended,
	input  logic [7:0] 	scan_code,
	output logic 		direction_up,
	output logic 		direction_down,
	output logic 		direction_left,
	output logic 		direction_right,
	output logic 		action_shift,
	output logic 		action_space,
	output logic 		action_control
);

always_ff @(posedge clk) begin
	if(reset) begin
		direction_up    <= 1'b0;
		direction_down  <= 1'b0;
		direction_left  <= 1'b0;
		direction_right <= 1'b0;
		action_shift   	<= 1'b0;
		action_space   	<= 1'b0;
		action_control 	<= 1'b0;
	end
	else if(event_strobe) begin
		if(key_extended) begin
			case(scan_code)
				8'h75: direction_up    <= key_pressed;
				8'h72: direction_down  <= key_pressed;
				8'h6B: direction_left  <= key_pressed;
				8'h74: direction_right <= key_pressed;

				default: begin end
			endcase
		end
		else begin
			case(scan_code)
				8'h12: action_shift   <= key_pressed; // Left Shift
				8'h29: action_space   <= key_pressed; // Space
				8'h14: action_control <= key_pressed; // Left Control

				default: begin end
			endcase
		end
	end
end

endmodule