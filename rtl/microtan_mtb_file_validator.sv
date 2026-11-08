module microtan_mtb_file_validator (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	output logic        validation_complete,
	output logic        file_valid,
	output logic        format_error,
	output logic [15:0] payload_length,
	output logic [15:0] first_free,
	output logic [15:0] ram_top,
	output logic [15:0] line_count,
	output logic [31:0] expected_crc32,
	output logic [31:0] calculated_crc32
);

logic        	download_active_d;
logic [27:0] 	stream_byte_count;
logic 			header_validation_complete;
logic 			header_file_valid;
logic 			header_format_error;
logic 			crc_start;
logic 			crc_byte_valid;
logic 			crc_finish;
logic 			crc_complete;
logic 			crc_match;
logic        	payload_complete;
logic        	payload_valid;
logic        	payload_format_error;
logic [15:0] 	observed_line_count;

assign crc_start = download_active && !download_active_d;
assign crc_byte_valid =	download_active && byte_valid && (stream_byte_count >= 28'd20);
assign crc_finish =	!download_active &&	download_active_d;

microtan_mtb_header_validator header_validator (
	.clk                 (clk),
	.reset               (reset),
	.download_active     (download_active),
	.byte_valid          (byte_valid),
	.byte_data           (byte_data),
	.validation_complete (header_validation_complete),
	.file_valid          (header_file_valid),
	.format_error        (header_format_error),
	.payload_length      (payload_length),
	.first_free          (first_free),
	.ram_top             (ram_top),
	.line_count          (line_count),
	.expected_crc32      (expected_crc32)
);

microtan_mtb_crc32 crc_validator (
	.clk              (clk),
	.reset            (reset),
	.start            (crc_start),
	.byte_valid       (crc_byte_valid),
	.byte_data        (byte_data),
	.finish           (crc_finish),
	.expected_crc32   (expected_crc32),
	.complete         (crc_complete),
	.crc_match        (crc_match),
	.calculated_crc32 (calculated_crc32)
);

microtan_mtb_payload_validator payload_validator (
	.clk                     (clk),
	.reset                   (reset),
	.start                   (crc_start),
	.byte_valid              (crc_byte_valid),
	.byte_data               (byte_data),
	.finish                  (crc_finish),
	.expected_payload_length (payload_length),
	.expected_line_count     (line_count),
	.complete                (payload_complete),
	.payload_valid           (payload_valid),
	.format_error            (payload_format_error),
	.observed_line_count     (observed_line_count)
);

always_ff @(posedge clk) begin
	validation_complete <= 1'b0;
	download_active_d   <= download_active;

	if(reset) begin
		download_active_d   <= 1'b0;
		stream_byte_count   <= 28'd0;
		validation_complete <= 1'b0;
		file_valid          <= 1'b0;
		format_error        <= 1'b0;
	end
	else begin
		if(crc_start) begin
			stream_byte_count <= 28'd0;
			file_valid        <= 1'b0;
			format_error      <= 1'b0;
		end
		else if(download_active && byte_valid) begin
			stream_byte_count <= stream_byte_count + 1'b1;
		end

		// The two child completion pulses are observed together one clock after download_active falls.
		if(header_validation_complete && crc_complete && payload_complete) begin
			validation_complete <= 1'b1;

			if(header_file_valid && !header_format_error && crc_match && payload_valid && !payload_format_error) begin
				file_valid   <= 1'b1;
				format_error <= 1'b0;
			end
			else begin
				file_valid   <= 1'b0;
				format_error <= 1'b1;
			end
		end
	end
end

endmodule