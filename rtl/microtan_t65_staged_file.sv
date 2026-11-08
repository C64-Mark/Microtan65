module microtan_t65_staged_file (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	input  logic [15:0] payload_read_address,
	output logic [7:0]  payload_read_data,
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

logic        staging_write_valid;
logic [15:0] staging_write_address;
logic [7:0]  staging_write_data;
logic [7:0]  staging_read_data;

microtan_t65_stream_validator validator (
	.clk(clk),
	.reset(reset),
	.download_active(download_active),
	.byte_valid(byte_valid),
	.byte_data(byte_data),
	.staging_write_valid(staging_write_valid),
	.staging_write_address(staging_write_address),
	.staging_write_data(staging_write_data),
	.validation_complete(validation_complete),
	.file_valid(file_valid),
	.format_error(format_error),
	.playback_encoding(playback_encoding),
	.filename(filename),
	.start_address(start_address),
	.end_address(end_address),
	.payload_length(payload_length),
	.checksum(checksum),
	.expected_crc32(expected_crc32),
	.calculated_crc32(calculated_crc32)
);

microtan_t65_staging_ram staging_ram (
	.clk(clk),
	.write_enable(staging_write_valid),
	.write_address(staging_write_address),
	.write_data(staging_write_data),
	.read_address(payload_read_address),
	.read_data(staging_read_data)
);

assign payload_read_data = file_valid ? staging_read_data : 8'h00;

endmodule