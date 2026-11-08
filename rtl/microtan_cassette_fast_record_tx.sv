module microtan_cassette_fast_record_tx #(
	parameter integer LEADER_MARK_BITS     = 3600,
	parameter integer INTERBLOCK_MARK_BITS = 128,
	parameter integer CHECKSUM_COPIES      = 16
)
(
	input  logic        	clk,
	input  logic        	reset,
	input  logic        	ce_750k,
	input  logic        	record_start,
	input  logic [63:0] 	filename,
	input  logic [15:0] 	start_address,
	input  logic [15:0] 	end_address,
	input  logic [16:0] 	payload_length,
	input  logic [7:0]  	checksum,
	input  logic        	payload_valid,
	input  logic [7:0]  	payload_data,
	output logic        	payload_ready,
	output logic        	record_busy,
	output logic        	record_done,
	output logic        	cassette_level
);

logic 		sequencer_start;
logic 		sequencer_busy;
logic 		sequencer_done;
logic 		sequencer_raw_bit_valid;
logic 		sequencer_raw_bit_value;
logic 		sequencer_raw_bit_ready;
logic       sequencer_byte_valid;
logic [7:0] sequencer_byte_data;
logic       sequencer_byte_ready;
logic 		frame_busy;
logic 		frame_bit_valid;
logic 		frame_bit_value;
logic 		frame_bit_ready;
logic 		timing_busy;
logic 		timing_bit_valid;
logic 		timing_bit_value;
logic 		timing_bit_ready;
logic 		completion_pending;

assign record_busy = sequencer_busy || completion_pending || frame_busy || timing_busy;
assign sequencer_start = record_start && !record_busy;
assign timing_bit_valid = frame_bit_valid ?	frame_bit_valid : sequencer_raw_bit_valid;
assign timing_bit_value = frame_bit_valid ?	frame_bit_value : sequencer_raw_bit_value;
assign sequencer_raw_bit_ready = frame_bit_valid ? 1'b0 :
		(sequencer_raw_bit_valid ? timing_bit_ready : 1'b0);
assign frame_bit_ready = frame_bit_valid ? timing_bit_ready : 1'b0;

microtan_cassette_xbug_record_sequence #(
	.LEADER_MARK_BITS(LEADER_MARK_BITS),
	.INTERBLOCK_MARK_BITS(INTERBLOCK_MARK_BITS),
	.CHECKSUM_COPIES(CHECKSUM_COPIES)
)
record_sequence
(
	.clk(clk),
	.reset(reset),
	.record_start(sequencer_start),
	.filename(filename),
	.start_address(start_address),
	.end_address(end_address),
	.payload_length(payload_length),
	.checksum(checksum),
	.payload_valid(payload_valid),
	.payload_data(payload_data),
	.payload_ready(payload_ready),
	.raw_bit_ready(sequencer_raw_bit_ready),
	.raw_bit_valid(sequencer_raw_bit_valid),
	.raw_bit_value(sequencer_raw_bit_value),
	.byte_ready(sequencer_byte_ready),
	.byte_valid(sequencer_byte_valid),
	.byte_data(sequencer_byte_data),
	.record_busy(sequencer_busy),
	.record_done(sequencer_done)
);

microtan_cassette_xbug_frame frame (
	.clk(clk),
	.reset(reset),
	.byte_valid(sequencer_byte_valid),
	.byte_data(sequencer_byte_data),
	.byte_ready(sequencer_byte_ready),
	.busy(frame_busy),
	.bit_ready(frame_bit_ready),
	.bit_valid(frame_bit_valid),
	.bit_value(frame_bit_value)
);

microtan_cassette_fast_bit_timing timing (
	.clk(clk),
	.reset(reset),
	.ce_750k(ce_750k),
	.bit_valid(timing_bit_valid),
	.bit_value(timing_bit_value),
	.bit_ready(timing_bit_ready),
	.busy(timing_busy),
	.cassette_level(cassette_level)
);

always_ff @(posedge clk) begin
	if(reset) begin
		completion_pending <= 1'b0;
		record_done        <= 1'b0;
	end
	else begin
		record_done <= 1'b0;

		if(sequencer_done)
			completion_pending <= 1'b1;

		if(completion_pending && !frame_busy && !timing_busy) begin
			completion_pending <= 1'b0;
			record_done        <= 1'b1;
		end
	end
end

endmodule