module microtan_t65_fast_playback #(
	parameter integer LEADER_MARK_BITS     = 3600,
	parameter integer INTERBLOCK_MARK_BITS = 128,
	parameter integer CHECKSUM_COPIES      = 16
)
(
	input  logic       clk,
	input  logic       reset,
	input  logic       ce_750k,
	input  logic       download_active,
	input  logic       byte_valid,
	input  logic [7:0] byte_data,
	input  logic       playback_start,
	output logic       validation_complete,
	output logic       file_valid,
	output logic       format_error,
	output logic [7:0] playback_encoding,
	output logic       playback_busy,
	output logic       playback_done,
	output logic       cassette_level
);

logic [63:0] 	filename;
logic [15:0] 	start_address;
logic [15:0] 	end_address;
logic [16:0] 	payload_length;
logic [7:0]  	checksum;
logic [31:0] 	expected_crc32;
logic [31:0] 	calculated_crc32;
logic [15:0] 	staging_read_address;
logic [7:0]  	staging_read_data;
logic        	staging_read_request;
logic       	payload_valid;
logic [7:0] 	payload_data;
logic       	payload_ready;
logic 			staging_stream_busy;
logic 			staging_stream_done;
logic 			transmitter_busy;
logic 			transmitter_done;
logic 			accepted_playback_start;

assign accepted_playback_start = playback_start && file_valid &&
	(playback_encoding == 8'h01) &&	!staging_stream_busy && !transmitter_busy;

assign playback_busy = staging_stream_busy || transmitter_busy;
assign playback_done = transmitter_done;

microtan_t65_staged_file staged_file (
	.clk(clk),
	.reset(reset),
	.download_active(download_active),
	.byte_valid(byte_valid),
	.byte_data(byte_data),
	.payload_read_address(staging_read_address),
	.payload_read_data(staging_read_data),
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

microtan_cassette_staging_stream staging_stream (
	.clk(clk),
	.reset(reset),
	.stream_start(accepted_playback_start),
	.payload_length(payload_length),
	.staging_read_request(staging_read_request),
	.staging_read_address(staging_read_address),
	.staging_read_data(staging_read_data),
	.payload_valid(payload_valid),
	.payload_data(payload_data),
	.payload_ready(payload_ready),
	.stream_busy(staging_stream_busy),
	.stream_done(staging_stream_done)
);

microtan_cassette_fast_record_tx #(
	.LEADER_MARK_BITS(LEADER_MARK_BITS),
	.INTERBLOCK_MARK_BITS(INTERBLOCK_MARK_BITS),
	.CHECKSUM_COPIES(CHECKSUM_COPIES)
)
transmitter (
	.clk(clk),
	.reset(reset),
	.ce_750k(ce_750k),
	.record_start(accepted_playback_start),
	.filename(filename),
	.start_address(start_address),
	.end_address(end_address),
	.payload_length(payload_length),
	.checksum(checksum),
	.payload_valid(payload_valid),
	.payload_data(payload_data),
	.payload_ready(payload_ready),
	.record_busy(transmitter_busy),
	.record_done(transmitter_done),
	.cassette_level(cassette_level)
);

endmodule