module microtan_keyboard_event (
	input  logic        clk,
	input  logic        reset,
	input  logic [10:0] ps2_key,
	output logic        event_strobe,
	output logic        key_pressed,
	output logic        key_extended,
	output logic [7:0]  scan_code
);

logic [10:0] ps2_meta;
logic [10:0] ps2_sync;
logic        event_toggle_seen;
logic [2:0]  startup;

// ps2_key is produced in the MiSTer system-clock domain. 
// Synchronise the complete event word into the Microtan machine-clock domain before using it.
//
// Bit 10 toggles for every make or break event.
// Bit  9 is one for a press and zero for a release.
// Bit  8 marks an extended scan code.
// Bits 7-0 contain the PS/2 Set 2 scan code.
always_ff @(posedge clk) begin
	if(reset) begin
		ps2_meta          	<= 11'd0;
		ps2_sync          	<= 11'd0;
		event_toggle_seen 	<= 1'b0;
		startup           	<= 3'b000;
		event_strobe 		<= 1'b0;
		key_pressed  		<= 1'b0;
		key_extended 		<= 1'b0;
		scan_code    		<= 8'h00;
	end
	else begin
		ps2_meta 		<= ps2_key;
		ps2_sync 		<= ps2_meta;
		event_strobe 	<= 1'b0;

		// Allow the two-stage synchroniser to fill after reset, then align
		// with the current toggle value without reporting a stale event.
		if(!startup[2]) begin
			startup           <= {startup[1:0], 1'b1};
			event_toggle_seen <= ps2_sync[10];
		end
		else if(ps2_sync[10] != event_toggle_seen) begin
			event_toggle_seen 	<= ps2_sync[10];
			key_pressed  		<= ps2_sync[9];
			key_extended 		<= ps2_sync[8];
			scan_code    		<= ps2_sync[7:0];
			event_strobe 		<= 1'b1;
		end
	end
end

endmodule