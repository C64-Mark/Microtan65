module microtan_mtb_replay (
	input  logic        clk,
	input  logic        reset,
	input  logic        start,
	input  logic [15:0] payload_length,
	input  logic [15:0] required_ram_top,
	input  logic [2:0]  active_ram_profile,
	output logic [15:0] staging_read_address,
	input  logic [7:0]  staging_read_data,
	output logic        busy,
	output logic        memory_write_valid,
	output logic [15:0] memory_write_address,
	output logic [7:0]  memory_write_data,
	output logic        replay_complete,
	output logic        replay_success,
	output logic        configuration_error
);

localparam logic [1:0] STATE_IDLE       = 2'd0;
localparam logic [1:0] STATE_WAIT_READ  = 2'd1;
localparam logic [1:0] STATE_WRITE_BYTE = 2'd2;

logic [1:0] 	state;
logic [15:0] 	read_index;
logic [16:0] 	payload_end_address;
logic [15:0] 	minimum_required_top;
logic [15:0] 	active_ram_top;
logic        	metadata_valid;

function automatic logic [15:0] required_top_for_address (
	input logic [15:0] address
);
begin
	if(address <= 16'h2000)
		required_top_for_address = 16'h2000;
	else if(address <= 16'h4000)
		required_top_for_address = 16'h4000;
	else if(address <= 16'h8000)
		required_top_for_address = 16'h8000;
	else if(address <= 16'hBC00)
		required_top_for_address = 16'hBC00;
	else
		required_top_for_address = 16'h0000;
end
endfunction

function automatic logic [15:0] profile_top (
	input logic [2:0] profile
);
begin
	case(profile)
		3'd0:
			profile_top = 16'h2000;
		3'd1:
			profile_top = 16'h0400;
		3'd2:
			profile_top = 16'h4000;
		3'd3:
			profile_top = 16'h8000;
		3'd4:
			profile_top = 16'hBC00;
		default:
			profile_top = 16'h0000;
	endcase
end
endfunction

always_comb begin
	payload_end_address = 17'h00401 + {1'b0, payload_length};

	minimum_required_top = required_top_for_address(payload_end_address[15:0]);
	active_ram_top = profile_top(active_ram_profile);

	metadata_valid = (payload_length >= 16'd2) && !payload_end_address[16] &&
		(minimum_required_top != 16'h0000) && (required_ram_top == minimum_required_top) &&
		(active_ram_top != 16'h0000) && (active_ram_top >= required_ram_top);
end

always_ff @(posedge clk) begin
	memory_write_valid <= 1'b0;
	replay_complete    <= 1'b0;

	if(reset) begin
		state                	<= STATE_IDLE;
		read_index           	<= 16'h0000;
		staging_read_address 	<= 16'h0000;
		busy                 	<= 1'b0;
		memory_write_valid   	<= 1'b0;
		memory_write_address 	<= 16'h0000;
		memory_write_data    	<= 8'h00;
		replay_complete    		<= 1'b0;
		replay_success     		<= 1'b0;
		configuration_error 	<= 1'b0;
	end
	else begin
		case(state)
			STATE_IDLE: begin
				if(start) begin
					replay_success      <= 1'b0;
					configuration_error <= 1'b0;

					if(metadata_valid) begin
						read_index           <= 16'h0000;
						staging_read_address <= 16'h0000;
						busy                 <= 1'b1;
						state                <= STATE_WAIT_READ;
					end
					else begin
						busy                 <= 1'b0;
						replay_complete      <= 1'b1;
						replay_success       <= 1'b0;
						configuration_error  <= 1'b1;
					end
				end
			end

			STATE_WAIT_READ: begin
				// Allow one clock for the synchronous staging read.
				state <= STATE_WRITE_BYTE;
			end

			STATE_WRITE_BYTE: begin
				memory_write_valid 		<= 1'b1;
				memory_write_address 	<= 16'h0401 + read_index;
				memory_write_data 		<= staging_read_data;

				if(read_index == (payload_length - 1'b1)) begin
					busy            <= 1'b0;
					replay_complete <= 1'b1;
					replay_success  <= 1'b1;
					state           <= STATE_IDLE;
				end
				else begin
					read_index 				<= read_index + 1'b1;
					staging_read_address 	<= read_index + 1'b1;
					state 					<= STATE_WAIT_READ;
				end
			end

			default: begin
				state                <= STATE_IDLE;
				busy                 <= 1'b0;
				replay_success       <= 1'b0;
				configuration_error  <= 1'b1;
			end
		endcase
	end
end

endmodule