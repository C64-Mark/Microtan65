module microtan_joystick_port_a (
	input  logic 		direction_up,
	input  logic 		direction_down,
	input  logic 		direction_left,
	input  logic 		direction_right,
	input  logic 		action_shift,
	input  logic 		action_space,
	input  logic 		action_control,
	output logic [7:0] 	port_a_input
);

always_comb begin
	// The joystick interface is active-low. 
	// An asserted logical control therefore drives its corresponding Port A input low.
	port_a_input = 8'hFF;
	port_a_input[1] = !action_shift;
	port_a_input[2] = !action_space;
	port_a_input[3] = !action_control;
	port_a_input[4] = !direction_left;
	port_a_input[5] = !direction_up;
	port_a_input[6] = !direction_right;
	port_a_input[7] = !direction_down;
end

endmodule