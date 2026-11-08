module microtan_joystick_controls (
	input  logic        clk,
	input  logic        reset,
	input  logic [31:0] mister_joystick,
	input  logic 		keyboard_joystick_enabled,
	input  logic 		keyboard_up,
	input  logic 		keyboard_down,
	input  logic 		keyboard_left,
	input  logic 		keyboard_right,
	input  logic 		keyboard_shift,
	input  logic 		keyboard_space,
	input  logic 		keyboard_control,
	output logic 		direction_up,
	output logic 		direction_down,
	output logic 		direction_left,
	output logic 		direction_right,
	output logic 		action_shift,
	output logic 		action_space,
	output logic 		action_control
);

logic [6:0] joystick_meta;
logic [6:0] joystick_sync;

always_ff @(posedge clk) begin
	if(reset) begin
		joystick_meta <= 7'b0000000;
		joystick_sync <= 7'b0000000;
	end
	else begin
		joystick_meta <= mister_joystick[6:0];
		joystick_sync <= joystick_meta;
	end
end

always_comb begin
	direction_right =
		joystick_sync[0] ||	(keyboard_joystick_enabled && keyboard_right);

	direction_left =
		joystick_sync[1] ||	(keyboard_joystick_enabled && keyboard_left);

	direction_down =
		joystick_sync[2] ||	(keyboard_joystick_enabled && keyboard_down);

	direction_up =
		joystick_sync[3] ||	(keyboard_joystick_enabled && keyboard_up);

	action_shift =
		joystick_sync[4] ||	(keyboard_joystick_enabled && keyboard_shift);

	action_space =
		joystick_sync[5] ||	(keyboard_joystick_enabled && keyboard_space);

	action_control =
		joystick_sync[6] ||	(keyboard_joystick_enabled && keyboard_control);
end

endmodule