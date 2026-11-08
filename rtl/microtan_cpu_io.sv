module microtan_cpu_io (
	input  logic       clk,
	input  logic       cpu_enable,
	input  logic       selected,
	input  logic       cpu_rw_n,
	input  logic [1:0] register_address,
	input  logic       keyboard_strobe,
	input  logic [6:0] keyboard_data,
	input  logic       keypad_mode,
	input  logic [6:0] keypad_sense,
	input  logic [7:0] write_data,
	output logic       graphics_write_mode,
	output logic       keyboard_interrupt,
	output logic [4:0] keypad_drive,
	output logic [7:0] read_data,
	output logic       read_data_valid
);

// No reset values are imposed here. TANBUG establishes text mode by writing
// $BFF3 and clears the keyboard interrupt latch by writing $BFF0 during its reset initialization.
// Read  $BFF0: select graphics mode.
// Write $BFF3: select text mode.
always_ff @(posedge clk) begin
	if(cpu_enable && selected) begin
		if(cpu_rw_n && register_address == 2'b00)
			graphics_write_mode <= 1'b1;
		else if(!cpu_rw_n && register_address == 2'b11)
			graphics_write_mode <= 1'b0;

		if(!cpu_rw_n && register_address == 2'b10)
			keypad_drive <= write_data[4:0];
	end

	/*
	 * Writing BFF0 clears the keyboard-interrupt flip-flop for both possible keyboard peripherals.
	 *
	 * With the MT006 connected, KO4 is looped back to KB_INT. 
	 * TANBUG writes KO4 low, clears this latch, and then writes KO4 high.
	 * That low-to-high transition identifies the attached keypad.
	 *
	 * Matrix key activity itself remains polled and does not set the interrupt.
	 * ASCII keyboard strobes are ignored in MT006 mode.
	 */
	if(cpu_enable && selected && !cpu_rw_n && register_address == 2'b00)
		keyboard_interrupt <= 1'b0;
	else if(keypad_mode) begin
		if(cpu_enable && selected && !cpu_rw_n && register_address == 2'b10 && write_data[4] && !keypad_drive[4])
			keyboard_interrupt <= 1'b1;
	end
	else if(keyboard_strobe)
		keyboard_interrupt <= 1'b1;
end

/*
 * $BFF3 represents the currently selected physical input peripheral.
 *
 * ASCII keyboard:
 *   bits 0-6 = encoded character
 *   bit 7    = keyboard-interrupt latch
 *
 * MT006:
 *   bits 0-6 = matrix return
 *   bit 7    = the same interrupt latch, used during startup for the KO4-to-KB_INT keypad-detection loopback
 */
always_comb begin
	read_data = {keyboard_interrupt, keypad_mode ? keypad_sense : keyboard_data};
	read_data_valid = selected && cpu_rw_n && (register_address == 2'b11);
end

endmodule