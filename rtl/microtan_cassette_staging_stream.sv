module microtan_cassette_staging_stream (
	input  logic        clk,
	input  logic        reset,
	input  logic        stream_start,
	input  logic [16:0] payload_length,
	output logic        staging_read_request,
	output logic [15:0] staging_read_address,
	input  logic [7:0]  staging_read_data,
	output logic        payload_valid,
	output logic [7:0]  payload_data,
	input  logic        payload_ready,
	output logic        stream_busy,
	output logic        stream_done
);

localparam logic [1:0] STATE_IDLE    = 2'd0;
localparam logic [1:0] STATE_SETTLE  = 2'd1;
localparam logic [1:0] STATE_CAPTURE = 2'd2;
localparam logic [1:0] STATE_HOLD    = 2'd3;

logic [1:0]  state;
logic [16:0] latched_payload_length;
logic [16:0] payload_index;

always_ff @(posedge clk) begin
	staging_read_request <= 1'b0;
	stream_done          <= 1'b0;

	if(reset) begin
		state                    	<= STATE_IDLE;
		latched_payload_length   	<= 17'd0;
		payload_index            	<= 17'd0;
		staging_read_request 		<= 1'b0;
		staging_read_address 		<= 16'h0000;
		payload_valid 				<= 1'b0;
		payload_data  				<= 8'h00;
		stream_busy 				<= 1'b0;
		stream_done 				<= 1'b0;
	end
	else begin
		case(state)
			STATE_IDLE: begin
				payload_valid <= 1'b0;
				stream_busy   <= 1'b0;

				if(stream_start && (payload_length >= 17'd1) && (payload_length <= 17'd65536)) begin
					latched_payload_length 	<= payload_length;
					payload_index          	<= 17'd0;
					staging_read_address 	<= 16'h0000;
					staging_read_request 	<= 1'b1;
					stream_busy 			<= 1'b1;
					state       			<= STATE_SETTLE;
				end
			end

			STATE_SETTLE: begin
				// Allow the synchronous RAM to sample the new address.
				state <= STATE_CAPTURE;
			end

			STATE_CAPTURE: begin
				// The RAM data from the requested address is now valid.
				payload_data  <= staging_read_data;
				payload_valid <= 1'b1;
				state         <= STATE_HOLD;
			end

			STATE_HOLD: begin
				if(payload_valid &&	payload_ready) begin
					payload_valid <= 1'b0;

					if(payload_index ==	latched_payload_length - 17'd1) begin
						payload_index 	<= 17'd0;
						stream_busy  	<= 1'b0;
						stream_done  	<= 1'b1;
						state        	<= STATE_IDLE;
					end
					else begin
						payload_index 			<= payload_index + 17'd1;
						staging_read_address 	<=	payload_index[15:0] + 16'd1;
						staging_read_request 	<= 1'b1;
						state                	<= STATE_SETTLE;
					end
				end
			end

			default: begin
				state         <= STATE_IDLE;
				payload_valid <= 1'b0;
				stream_busy   <= 1'b0;
			end
		endcase
	end
end

endmodule