module microtan_keypad_matrix (
	// Corresponds to $BFF2 bits KO3-KO0.
	input  logic [3:0]  drive,

	/*
	 * Key positions follow TANBUG's scan-table order:
	 *
	 *  0-4:   KO3 with KI0-KI4
	 *  5-9:   KO2 with KI0-KI4
	 * 10-14:  KO1 with KI0-KI4
	 * 15-19:  KO0 with KI0-KI4
	 *
	 * Position 4 is physically absent. RESET is wired separately.
	 * Position 19 is SHIFT.
	 */
	input  logic [19:0] key_pressed,

	// Corresponds to $BFF3 bits KI6-KI0.
	output logic [6:0]  sense
);

always_comb begin
	sense = 7'b0000000;
	sense[0] = (drive[3] && key_pressed[0]) || (drive[2] && key_pressed[5]) ||
		(drive[1] && key_pressed[10]) || (drive[0] && key_pressed[15]);

	sense[1] = (drive[3] && key_pressed[1]) || (drive[2] && key_pressed[6]) ||
		(drive[1] && key_pressed[11]) || (drive[0] && key_pressed[16]);

	sense[2] = (drive[3] && key_pressed[2]) || (drive[2] && key_pressed[7]) ||
		(drive[1] && key_pressed[12]) || (drive[0] && key_pressed[17]);

	sense[3] = (drive[3] && key_pressed[3]) || (drive[2] && key_pressed[8]) ||
		(drive[1] && key_pressed[13]) || (drive[0] && key_pressed[18]);

	// KO3/KI4 is absent because RESET is not part of the matrix.
	sense[4] = (drive[2] && key_pressed[9]) || (drive[1] && key_pressed[14]) ||	(drive[0] && key_pressed[19]);

	// KI5 and KI6 are pulled low on the MT006.
	sense[6:5] = 2'b00;
end

endmodule