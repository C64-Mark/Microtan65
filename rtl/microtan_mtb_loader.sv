module microtan_mtb_loader (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        download_write,
	input  logic [7:0]  download_data,
	input  logic [2:0]  active_ram_profile,
	output logic        machine_owned,
	output logic        memory_write_valid,
	output logic [15:0] memory_write_address,
	output logic [7:0]  memory_write_data,
	output logic        state_load_pending,
	output logic [63:0] state_regs,
	input  logic        state_load_ack,
	output logic        load_complete,
	output logic        load_success,
	output logic        format_error,
	output logic        configuration_error,
	output logic [15:0] payload_length,
	output logic [15:0] first_free,
	output logic [15:0] required_ram_top,
	output logic [15:0] line_count
);

logic 			download_active_d;
logic 			ownership_hold;
logic [15:0] 	staging_read_address;
logic [7:0]  	staging_read_data;
logic        	staged_validation_complete;
logic        	staged_file_valid;
logic        	staged_format_error;
logic [31:0] 	staged_expected_crc32;
logic [31:0] 	staged_calculated_crc32;
logic 			replay_start;
logic 			replay_busy;
logic 			replay_complete;
logic 			replay_success;
logic 			replay_configuration_error;
logic        	replay_memory_write_valid;
logic [15:0] 	replay_memory_write_address;
logic [7:0]  	replay_memory_write_data;
logic 			workspace_start;
logic 			workspace_busy;
logic 			workspace_write_valid;
logic [15:0] 	workspace_write_address;
logic [7:0]  	workspace_write_data;
logic 			workspace_complete;
logic 			workspace_success;
logic 			workspace_configuration_error;
logic 			entry_start;
logic 			entry_busy;
logic 			entry_complete;
logic 			entry_success;
assign replay_start = staged_validation_complete && staged_file_valid;
assign machine_owned = download_active || ownership_hold || replay_busy ||
	workspace_busy || entry_busy || state_load_pending || replay_memory_write_valid || workspace_write_valid;

assign format_error = staged_format_error;
assign configuration_error = replay_configuration_error || workspace_configuration_error;
assign workspace_start = replay_complete && replay_success;
assign entry_start = workspace_complete && workspace_success;

always_comb begin
	memory_write_valid   = 1'b0;
	memory_write_address = 16'h0000;
	memory_write_data    = 8'h00;

	if(workspace_write_valid) begin
		memory_write_valid   = 1'b1;
		memory_write_address = workspace_write_address;
		memory_write_data    = workspace_write_data;
	end
	else if(replay_memory_write_valid) begin
		memory_write_valid   = 1'b1;
		memory_write_address = replay_memory_write_address;
		memory_write_data    = replay_memory_write_data;
	end
end

microtan_mtb_staged_file staged_file (
	.clk                  (clk),
	.reset                (reset),
	.download_active      (download_active),
	.byte_valid           (download_write),
	.byte_data            (download_data),
	.staging_read_address (staging_read_address),
	.staging_read_data    (staging_read_data),
	.validation_complete  (staged_validation_complete),
	.file_valid           (staged_file_valid),
	.format_error         (staged_format_error),
	.payload_length       (payload_length),
	.first_free           (first_free),
	.ram_top              (required_ram_top),
	.line_count           (line_count),
	.expected_crc32       (staged_expected_crc32),
	.calculated_crc32     (staged_calculated_crc32)
);

microtan_mtb_replay replay (
	.clk                  (clk),
	.reset                (reset),
	.start                (replay_start),
	.payload_length       (payload_length),
	.required_ram_top     (required_ram_top),
	.active_ram_profile   (active_ram_profile),
	.staging_read_address (staging_read_address),
	.staging_read_data    (staging_read_data),
	.busy                 (replay_busy),
	.memory_write_valid   (replay_memory_write_valid),
	.memory_write_address (replay_memory_write_address),
	.memory_write_data    (replay_memory_write_data),
	.replay_complete      (replay_complete),
	.replay_success       (replay_success),
	.configuration_error  (replay_configuration_error)
);

microtan_basic_workspace_writer workspace_writer (
	.clk                 (clk),
	.reset               (reset),
	.start               (workspace_start),
	.first_free          (first_free),
	.active_ram_profile  (active_ram_profile),
	.busy                (workspace_busy),
	.write_valid         (workspace_write_valid),
	.write_address       (workspace_write_address),
	.write_data          (workspace_write_data),
	.complete            (workspace_complete),
	.success             (workspace_success),
	.configuration_error (workspace_configuration_error)
);

microtan_basic_entry_controller entry_controller (
	.clk                (clk),
	.reset              (reset),
	.start              (entry_start),
	.busy               (entry_busy),
	.state_load_pending (state_load_pending),
	.state_regs         (state_regs),
	.state_load_ack     (state_load_ack),
	.complete           (entry_complete),
	.success            (entry_success)
);

always_ff @(posedge clk) begin
	load_complete 		<= 1'b0;
	download_active_d 	<= download_active;

	if(reset) begin
		download_active_d 	<= 1'b0;
		ownership_hold    	<= 1'b0;
		load_complete 		<= 1'b0;
		load_success  		<= 1'b0;
	end
	else begin
		if(download_active && !download_active_d) begin
			ownership_hold <= 1'b1;
			load_success   <= 1'b0;
		end

		if(staged_validation_complete && !staged_file_valid) begin
			ownership_hold <= 1'b0;
			load_complete  <= 1'b1;
			load_success   <= 1'b0;
		end

		if(replay_complete && !replay_success) begin
			ownership_hold <= 1'b0;
			load_complete  <= 1'b1;
			load_success   <= 1'b0;
		end

		if(workspace_complete && !workspace_success) begin
			ownership_hold <= 1'b0;
			load_complete  <= 1'b1;
			load_success   <= 1'b0;
		end

		if(entry_complete) begin
			ownership_hold <= 1'b0;
			load_complete  <= 1'b1;
			load_success   <= entry_success;
		end
	end
end

endmodule