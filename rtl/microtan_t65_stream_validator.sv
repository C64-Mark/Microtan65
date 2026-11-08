module microtan_t65_stream_validator (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	output logic        staging_write_valid,
	output logic [15:0] staging_write_address,
	output logic [7:0]  staging_write_data,
	output logic        validation_complete,
	output logic        file_valid,
	output logic        format_error,
	output logic [7:0]  playback_encoding,
	output logic [63:0] filename,
	output logic [15:0] start_address,
	output logic [15:0] end_address,
	output logic [16:0] payload_length,
	output logic [7:0]  checksum,
	output logic [31:0] expected_crc32,
	output logic [31:0] calculated_crc32
);

localparam logic [31:0] HEADER_SIZE = 32'd32;
localparam logic [31:0] MAX_PAYLOAD = 32'd65536;

logic 			download_active_d;
logic [31:0] 	stream_byte_count;
logic [31:0] 	staging_offset;
logic 			fixed_format_error;
logic [7:0]  	candidate_encoding;
logic [63:0] 	candidate_filename;
logic [15:0] 	candidate_start_address;
logic [15:0] 	candidate_end_address;
logic [31:0] 	candidate_payload_length;
logic [7:0]  	candidate_checksum;
logic [31:0] 	candidate_expected_crc32;
logic [7:0]  	calculated_checksum;
logic [31:0] 	crc_state;
logic 			start_event;
logic 			finish_event;

assign start_event = download_active && !download_active_d;
assign finish_event = !download_active && download_active_d;
assign staging_offset = stream_byte_count - HEADER_SIZE;
assign staging_write_valid = !reset && download_active && byte_valid &&
	(stream_byte_count >= HEADER_SIZE) && (stream_byte_count < HEADER_SIZE + MAX_PAYLOAD);
assign staging_write_address = staging_offset[15:0];
assign staging_write_data = byte_data;

function automatic logic [31:0] update_crc32 (
	input logic [31:0] current_crc,
	input logic [7:0]  data
);

logic [31:0] working_crc;
integer bit_index;

begin
	working_crc = current_crc ^ {24'h000000, data};
	for(bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
		if(working_crc[0])
			working_crc = (working_crc >> 1) ^ 32'hEDB88320;
		else
			working_crc = working_crc >> 1;
	end

	update_crc32 = working_crc;
end
endfunction

always_ff @(posedge clk) begin
	validation_complete <= 1'b0;
	download_active_d   <= download_active;

	if(reset) begin
		download_active_d 			<= 1'b0;
		stream_byte_count 			<= 32'd0;
		fixed_format_error 			<= 1'b0;
		candidate_encoding       	<= 8'h00;
		candidate_filename       	<= 64'h0000000000000000;
		candidate_start_address  	<= 16'h0000;
		candidate_end_address    	<= 16'h0000;
		candidate_payload_length 	<= 32'd0;
		candidate_checksum       	<= 8'h00;
		candidate_expected_crc32 	<= 32'h00000000;
		calculated_checksum 		<= 8'h00;
		crc_state           		<= 32'hFFFFFFFF;
		validation_complete 		<= 1'b0;
		file_valid          		<= 1'b0;
		format_error        		<= 1'b0;
		playback_encoding 			<= 8'h00;
		filename          			<= 64'h0000000000000000;
		start_address     			<= 16'h0000;
		end_address       			<= 16'h0000;
		payload_length    			<= 17'd0;
		checksum          			<= 8'h00;
		expected_crc32   			<= 32'h00000000;
		calculated_crc32 			<= 32'h00000000;
	end
	else begin
		if(start_event) begin
			stream_byte_count 			<= 32'd0;
			fixed_format_error 			<= 1'b0;
			candidate_encoding       	<= 8'h00;
			candidate_filename       	<= 64'h0000000000000000;
			candidate_start_address  	<= 16'h0000;
			candidate_end_address    	<= 16'h0000;
			candidate_payload_length 	<= 32'd0;
			candidate_checksum       	<= 8'h00;
			candidate_expected_crc32 	<= 32'h00000000;
			calculated_checksum 		<= 8'h00;
			crc_state           		<= 32'hFFFFFFFF;
			file_valid   				<= 1'b0;
			format_error 				<= 1'b0;
			playback_encoding 			<= 8'h00;
			filename          			<= 64'h0000000000000000;
			start_address     			<= 16'h0000;
			end_address       			<= 16'h0000;
			payload_length    			<= 17'd0;
			checksum          			<= 8'h00;
			expected_crc32   			<= 32'h00000000;
			calculated_crc32 			<= 32'h00000000;
		end
		else if(download_active && byte_valid) begin
			if((stream_byte_count < 32'd28) || (stream_byte_count >= 32'd32))
				crc_state <= update_crc32(crc_state, byte_data);

			if(stream_byte_count >= HEADER_SIZE)
				calculated_checksum <= calculated_checksum + byte_data;

			case(stream_byte_count)
				32'd0:
					if(byte_data != 8'h54)
						fixed_format_error <= 1'b1;
				32'd1:
					if(byte_data != 8'h36)
						fixed_format_error <= 1'b1;
				32'd2:
					if(byte_data != 8'h35)
						fixed_format_error <= 1'b1;
				32'd3:
					if(byte_data != 8'h1A)
						fixed_format_error <= 1'b1;
				32'd4:
					if(byte_data != 8'h01)
						fixed_format_error <= 1'b1;
				32'd5:
					if(byte_data != 8'h01)
						fixed_format_error <= 1'b1;
				32'd6: begin
					candidate_encoding <= byte_data;
					if((byte_data != 8'h01) && (byte_data != 8'h02))
						fixed_format_error <= 1'b1;
				end
				32'd7:
					if(byte_data != 8'h20)
						fixed_format_error <= 1'b1;
				32'd8:
					candidate_filename[63:56] <= byte_data;
				32'd9:
					candidate_filename[55:48] <= byte_data;
				32'd10:
					candidate_filename[47:40] <= byte_data;
				32'd11:
					candidate_filename[39:32] <= byte_data;
				32'd12:
					candidate_filename[31:24] <= byte_data;
				32'd13:
					candidate_filename[23:16] <= byte_data;
				32'd14:
					candidate_filename[15:8] <= byte_data;
				32'd15:
					candidate_filename[7:0] <= byte_data;
				32'd16:
					candidate_start_address[7:0] <= byte_data;
				32'd17:
					candidate_start_address[15:8] <= byte_data;
				32'd18:
					candidate_end_address[7:0] <= byte_data;
				32'd19:
					candidate_end_address[15:8] <= byte_data;
				32'd20:
					candidate_payload_length[7:0] <= byte_data;
				32'd21:
					candidate_payload_length[15:8] <= byte_data;
				32'd22:
					candidate_payload_length[23:16] <= byte_data;
				32'd23:
					candidate_payload_length[31:24] <= byte_data;
				32'd24:
					candidate_checksum <= byte_data;
				32'd25:
					if(byte_data != 8'h01)
						fixed_format_error <= 1'b1;
				32'd26:
					if(byte_data != 8'h10)
						fixed_format_error <= 1'b1;
				32'd27:
					if(byte_data != 8'h00)
						fixed_format_error <= 1'b1;
				32'd28:
					candidate_expected_crc32[7:0] <= byte_data;
				32'd29:
					candidate_expected_crc32[15:8] <= byte_data;
				32'd30:
					candidate_expected_crc32[23:16] <= byte_data;
				32'd31:
					candidate_expected_crc32[31:24] <= byte_data;

				default: begin
				end
			endcase

			stream_byte_count <= stream_byte_count + 32'd1;
		end

		if(finish_event) begin
			validation_complete <= 1'b1;
			calculated_crc32 	<=	crc_state ^ 32'hFFFFFFFF;

			if(!fixed_format_error && (candidate_payload_length >= 32'd1) &&
				(candidate_payload_length <= MAX_PAYLOAD) && (candidate_end_address >= candidate_start_address) &&
				(
					({16'h0000, candidate_end_address} - {16'h0000, candidate_start_address} + 32'd1) == candidate_payload_length) &&
				(
					stream_byte_count == HEADER_SIZE + candidate_payload_length) &&
				(
					calculated_checksum == candidate_checksum) &&
				(
					(crc_state ^ 32'hFFFFFFFF) == candidate_expected_crc32
				)
			) begin
				file_valid   		<= 1'b1;
				format_error 		<= 1'b0;
				playback_encoding 	<= candidate_encoding;
				filename          	<= candidate_filename;
				start_address     	<= candidate_start_address;
				end_address       	<= candidate_end_address;
				payload_length    	<= candidate_payload_length[16:0];
				checksum          	<= candidate_checksum;
				expected_crc32 		<= candidate_expected_crc32;
			end
			else begin
				file_valid   <= 1'b0;
				format_error <= 1'b1;
			end
		end
	end
end

endmodule