module microtan_cassette_xbug_record_sequence #(
	parameter integer LEADER_MARK_BITS     = 3600,
	parameter integer INTERBLOCK_MARK_BITS = 128,
	parameter integer CHECKSUM_COPIES      = 16
)
(
	input  logic        clk,
	input  logic        reset,
	input  logic        record_start,
	input  logic [63:0] filename,
	input  logic [15:0] start_address,
	input  logic [15:0] end_address,
	input  logic [16:0] payload_length,
	input  logic [7:0]  checksum,
	input  logic        payload_valid,
	input  logic [7:0]  payload_data,
	output logic        payload_ready,
	input  logic        raw_bit_ready,
	output logic        raw_bit_valid,
	output logic        raw_bit_value,
	input  logic        byte_ready,
	output logic        byte_valid,
	output logic [7:0]  byte_data,
	output logic        record_busy,
	output logic        record_done
);

localparam logic [2:0] STATE_IDLE     = 3'd0;
localparam logic [2:0] STATE_LEADER   = 3'd1;
localparam logic [2:0] STATE_HEADER   = 3'd2;
localparam logic [2:0] STATE_MARK     = 3'd3;
localparam logic [2:0] STATE_PAYLOAD  = 3'd4;
localparam logic [2:0] STATE_CHECKSUM = 3'd5;

logic [2:0] 	state;
logic [63:0] 	latched_filename;
logic [15:0] 	latched_start_address;
logic [15:0] 	latched_end_address;
logic [16:0] 	latched_payload_length;
logic [7:0]  	latched_checksum;
logic [15:0] 	raw_bit_count;
logic [3:0]  	header_index;
logic [16:0] 	payload_index;
logic [4:0]  	checksum_index;

function automatic logic [7:0] header_byte (
	input logic [3:0]  index,
	input logic [63:0] filename_value,
	input logic [15:0] start_address_value,
	input logic [15:0] end_address_value
);
begin
	case(index)
		4'd0:
			header_byte = filename_value[63:56];
		4'd1:
			header_byte = filename_value[55:48];
		4'd2:
			header_byte = filename_value[47:40];
		4'd3:
			header_byte = filename_value[39:32];
		4'd4:
			header_byte = filename_value[31:24];
		4'd5:
			header_byte = filename_value[23:16];
		4'd6:
			header_byte = filename_value[15:8];
		4'd7:
			header_byte = filename_value[7:0];
		4'd8:
			header_byte = end_address_value[15:8];
		4'd9:
			header_byte = end_address_value[7:0];
		4'd10:
			header_byte = start_address_value[15:8];
		default:
			header_byte = start_address_value[7:0];
	endcase
end
endfunction

always_comb begin
	payload_ready 	= 1'b0;
	raw_bit_valid 	= 1'b0;
	raw_bit_value 	= 1'b1;
	byte_valid 		= 1'b0;
	byte_data  		= 8'h00;

	case(state)
		STATE_LEADER: begin
			raw_bit_valid = 1'b1;
		end

		STATE_HEADER: begin
			byte_valid = 1'b1;
			byte_data = header_byte(header_index, latched_filename,	latched_start_address, latched_end_address);
		end

		STATE_MARK: begin
			raw_bit_valid = 1'b1;
		end

		STATE_PAYLOAD: begin
			payload_ready = byte_ready;
			byte_valid    = payload_valid;
			byte_data     = payload_data;
		end

		STATE_CHECKSUM: begin
			byte_valid = 1'b1;
			byte_data  = latched_checksum;
		end

		default: begin
		end
	endcase
end

always_ff @(posedge clk) begin
	if(reset) begin
		state                   <= STATE_IDLE;
		latched_filename        <= 64'h0000000000000000;
		latched_start_address   <= 16'h0000;
		latched_end_address     <= 16'h0000;
		latched_payload_length  <= 17'd0;
		latched_checksum        <= 8'h00;
		raw_bit_count           <= 16'd0;
		header_index            <= 4'd0;
		payload_index           <= 17'd0;
		checksum_index          <= 5'd0;
		record_busy             <= 1'b0;
		record_done             <= 1'b0;
	end
	else begin
		record_done <= 1'b0;

		case(state)
			STATE_IDLE: begin
				if(record_start) begin
					latched_filename       	<= filename;
					latched_start_address  	<= start_address;
					latched_end_address    	<= end_address;
					latched_payload_length 	<= payload_length;
					latched_checksum       	<= checksum;
					raw_bit_count  			<= 16'd0;
					header_index   			<= 4'd0;
					payload_index  			<= 17'd0;
					checksum_index 			<= 5'd0;
					record_busy    			<= 1'b1;
					state          			<= STATE_LEADER;
				end
			end

			STATE_LEADER: begin
				if(raw_bit_valid && raw_bit_ready) begin
					if(raw_bit_count ==	LEADER_MARK_BITS - 1) begin
						raw_bit_count <= 16'd0;
						header_index  <= 4'd0;
						state         <= STATE_HEADER;
					end
					else begin
						raw_bit_count <= raw_bit_count + 16'd1;
					end
				end
			end

			STATE_HEADER: begin
				if(byte_valid && byte_ready) begin
					if(header_index == 4'd11) begin
						header_index  <= 4'd0;
						raw_bit_count <= 16'd0;
						state         <= STATE_MARK;
					end
					else begin
						header_index <=	header_index + 4'd1;
					end
				end
			end

			STATE_MARK: begin
				if(raw_bit_valid && raw_bit_ready) begin
					if(raw_bit_count ==	INTERBLOCK_MARK_BITS - 1) begin
						raw_bit_count  <= 16'd0;
						payload_index  <= 17'd0;

						if(latched_payload_length == 17'd0) begin
							checksum_index <= 5'd0;
							state          <= STATE_CHECKSUM;
						end
						else begin
							state <= STATE_PAYLOAD;
						end
					end
					else begin
						raw_bit_count <= raw_bit_count + 16'd1;
					end
				end
			end

			STATE_PAYLOAD: begin
				if(payload_valid &&	payload_ready) begin
					if(payload_index ==	latched_payload_length - 17'd1) begin
						payload_index  <= 17'd0;
						checksum_index <= 5'd0;
						state          <= STATE_CHECKSUM;
					end
					else begin
						payload_index <= payload_index + 17'd1;
					end
				end
			end

			STATE_CHECKSUM: begin
				if(byte_valid && byte_ready) begin
					if(checksum_index == CHECKSUM_COPIES - 1) begin
						checksum_index <= 5'd0;
						record_busy    <= 1'b0;
						record_done    <= 1'b1;
						state          <= STATE_IDLE;
					end
					else begin
						checksum_index <= checksum_index + 5'd1;
					end
				end
			end

			default: begin
				state       <= STATE_IDLE;
				record_busy <= 1'b0;
			end
		endcase
	end
end

endmodule