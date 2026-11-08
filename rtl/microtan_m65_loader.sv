module microtan_m65_loader (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        download_write,
	input  logic [7:0]  download_data,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	output logic        cpu_run_enable,
	output logic        machine_owned,
	output logic        memory_enable,
	output logic        memory_rw_n,
	output logic [15:0] memory_address,
	output logic [7:0]  memory_write_data,
	output logic        attribute_write_valid,
	output logic [5:0]  attribute_write_address,
	output logic [7:0]  attribute_write_data,
	output logic        snapshot_state_pending,
	input  logic        snapshot_state_ack,
	output logic [15:0] snapshot_pc,
	output logic [7:0]  snapshot_p,
	output logic [7:0]  snapshot_a,
	output logic [7:0]  snapshot_x,
	output logic [7:0]  snapshot_y,
	output logic [7:0]  snapshot_sp,
	output logic        load_complete,
	output logic        format_error
);

logic 			download_active_d;
logic 			loader_active_hold;
logic        	decoder_memory_write_valid;
logic [12:0] 	decoder_memory_write_address;
logic [7:0]  	decoder_memory_write_data;
logic 			decoder_state_valid;
logic 			decoder_load_complete;
logic 			decoder_format_error;
logic 			loader_owns_machine;

assign loader_owns_machine = download_active ||	loader_active_hold || decoder_memory_write_valid;
assign machine_owned = loader_owns_machine;
assign load_complete = decoder_load_complete;
assign format_error  = decoder_format_error;

microtan_m65_decoder decoder (
	.clk(clk),
	.reset(reset),
	.download_active(download_active),
	.byte_valid(download_write),
	.byte_data(download_data),
	.memory_write_valid(decoder_memory_write_valid),
	.memory_write_address(decoder_memory_write_address),
	.memory_write_data(decoder_memory_write_data),
	.attribute_write_valid(attribute_write_valid),
	.attribute_write_address(attribute_write_address),
	.attribute_write_data(attribute_write_data),
	.snapshot_state_valid(decoder_state_valid),
	.snapshot_pc(snapshot_pc),
	.snapshot_p(snapshot_p),
	.snapshot_a(snapshot_a),
	.snapshot_x(snapshot_x),
	.snapshot_y(snapshot_y),
	.snapshot_sp(snapshot_sp),
	.load_complete(decoder_load_complete),
	.format_error(decoder_format_error)
);

microtan_loader_bus_mux bus_mux (
	.cpu_enable(cpu_enable),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address),
	.cpu_write_data(cpu_write_data),
	.loader_active(loader_owns_machine),
	.loader_write_valid(decoder_memory_write_valid),
	.loader_address({3'b000, decoder_memory_write_address}),
	.loader_write_data(decoder_memory_write_data),
	.cpu_run_enable(cpu_run_enable),
	.memory_enable(memory_enable),
	.memory_rw_n(memory_rw_n),
	.memory_address(memory_address),
	.memory_write_data(memory_write_data)
);

always_ff @(posedge clk) begin
	download_active_d <= download_active;

	if(reset) begin
		download_active_d      <= 1'b0;
		loader_active_hold     <= 1'b0;
		snapshot_state_pending <= 1'b0;
	end
	else begin
		// A new snapshot supersedes any unacknowledged previous state.
		if(download_active && !download_active_d) begin
			loader_active_hold     <= 1'b1;
			snapshot_state_pending <= 1'b0;
		end
		else if(decoder_load_complete && decoder_format_error) begin
			// Invalid input has no processor state to apply.
			loader_active_hold     <= 1'b0;
			snapshot_state_pending <= 1'b0;
		end
		else if(decoder_state_valid) begin
			// Keep the CPU held until the state consumer confirms that all saved registers have been restored.
			loader_active_hold     <= 1'b1;
			snapshot_state_pending <= 1'b1;
		end
		else if(snapshot_state_pending && snapshot_state_ack) begin
			snapshot_state_pending <= 1'b0;
			loader_active_hold     <= 1'b0;
		end
		else if(download_active) begin
			loader_active_hold <= 1'b1;
		end
	end
end

endmodule