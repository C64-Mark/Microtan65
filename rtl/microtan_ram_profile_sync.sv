module microtan_ram_profile_sync (
	input  logic       destination_clk,
	input  logic       destination_reset,
	input  logic [2:0] source_profile,
	output logic [2:0] destination_profile
);

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic [2:0] profile_meta;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic [2:0] profile_sync;

logic [2:0] profile_candidate;

always_ff @(posedge destination_clk) begin
	if(destination_reset) begin
		profile_meta      <= 3'd0;
		profile_sync      <= 3'd0;
		profile_candidate <= 3'd0;
		destination_profile <= 3'd0;
	end
	else begin
		profile_meta <= source_profile;
		profile_sync <= profile_meta;

		if(profile_sync == profile_candidate)
			destination_profile <= profile_sync;
		else
			profile_candidate <= profile_sync;
	end
end

endmodule