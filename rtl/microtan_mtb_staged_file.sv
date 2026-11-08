module microtan_mtb_staged_file (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	input  logic [15:0] staging_read_address,
	output logic [7:0]  staging_read_data,
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

localparam logic [27:0] HEADER_BYTE_COUNT  = 28'd20;
localparam logic [27:0] STAGING_BYTE_COUNT = 28'd47103;
localparam logic [27:0] STAGING_FILE_LIMIT = HEADER_BYTE_COUNT + STAGING_BYTE_COUNT;

logic        download_active_d;
logic [27:0] stream_byte_count;
logic [27:0] staging_offset;
logic        staging_write_enable;
logic [15:0] staging_write_address;

assign staging_offset =	stream_byte_count - HEADER_BYTE_COUNT;
assign staging_write_enable = download_active && byte_valid &&
	(stream_byte_count >= HEADER_BYTE_COUNT) && (stream_byte_count < STAGING_FILE_LIMIT);
assign staging_write_address = staging_offset[15:0];

microtan_mtb_file_validator file_validator (
	.clk                 (clk),
	.reset               (reset),
	.download_active     (download_active),
	.byte_valid          (byte_valid),
	.byte_data           (byte_data),
	.validation_complete (validation_complete),
	.file_valid          (file_valid),
	.format_error        (format_error),
	.payload_length      (payload_length),
	.first_free          (first_free),
	.ram_top             (ram_top),
	.line_count          (line_count),
	.expected_crc32      (expected_crc32),
	.calculated_crc32    (calculated_crc32)
);

microtan_mtb_staging_ram staging_ram (
	.clk           (clk),
	.write_enable  (staging_write_enable),
	.write_address (staging_write_address),
	.write_data    (byte_data),
	.read_address  (staging_read_address),
	.read_data     (staging_read_data)
);

always_ff @(posedge clk) begin
	download_active_d <= download_active;

	if(reset) begin
		download_active_d <= 1'b0;
		stream_byte_count <= 28'd0;
	end
	else if(download_active && !download_active_d) begin
		stream_byte_count <= 28'd0;
	end
	else if(download_active && byte_valid) begin
		stream_byte_count <= stream_byte_count + 1'b1;
	end
end

endmodule