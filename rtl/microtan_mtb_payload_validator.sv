module microtan_mtb_payload_validator (
	input  logic        clk,
	input  logic        reset,
	input  logic        start,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	input  logic        finish,
	input  logic [15:0] expected_payload_length,
	input  logic [15:0] expected_line_count,
	output logic        complete,
	output logic        payload_valid,
	output logic        format_error,
	output logic [15:0] observed_line_count
);

localparam logic [2:0] STATE_LINK_LOW   = 3'd0;
localparam logic [2:0] STATE_LINK_HIGH  = 3'd1;
localparam logic [2:0] STATE_LINE_LOW   = 3'd2;
localparam logic [2:0] STATE_LINE_HIGH  = 3'd3;
localparam logic [2:0] STATE_STATEMENT  = 3'd4;
localparam logic [2:0] STATE_FINAL_SEEN = 3'd5;

logic [2:0] 	state;
logic [15:0] 	byte_count;
logic [15:0] 	record_start;
logic [7:0]  	link_low;
logic [15:0] 	next_line_address;
logic [7:0]  	line_number_low;
logic [15:0] 	previous_line_number;
logic [16:0] 	payload_end_address;
logic [16:0] 	final_link_address;
logic [16:0] 	current_byte_end_address;

always_comb begin
	payload_end_address = 17'h00401 + {1'b0, expected_payload_length};
	final_link_address = payload_end_address - 17'd2;
	current_byte_end_address = 17'h00401 + {1'b0, byte_count} + 17'd1;
end

always_ff @(posedge clk) begin
	complete <= 1'b0;

	if(reset) begin
		state                	<= STATE_LINK_LOW;
		byte_count           	<= 16'h0000;
		record_start         	<= 16'h0401;
		link_low             	<= 8'h00;
		next_line_address    	<= 16'h0000;
		line_number_low      	<= 8'h00;
		previous_line_number 	<= 16'h0000;
		observed_line_count  	<= 16'h0000;
		complete      			<= 1'b0;
		payload_valid 			<= 1'b0;
		format_error  			<= 1'b0;
	end
	else if(start) begin
		state                	<= STATE_LINK_LOW;
		byte_count           	<= 16'h0000;
		record_start         	<= 16'h0401;
		link_low             	<= 8'h00;
		next_line_address    	<= 16'h0000;
		line_number_low      	<= 8'h00;
		previous_line_number 	<= 16'h0000;
		observed_line_count  	<= 16'h0000;
		payload_valid 			<= 1'b0;
		format_error  			<= 1'b0;
	end
	else begin
		if(byte_valid) begin
			case(state)
				STATE_LINK_LOW: begin
					link_low <= byte_data;
					state    <= STATE_LINK_HIGH;
				end

				STATE_LINK_HIGH: begin
					next_line_address <= {byte_data, link_low};

					if({byte_data, link_low} == 16'h0000) begin
						state <= STATE_FINAL_SEEN;
					end
					else begin
						if({1'b0, byte_data, link_low} < ({1'b0, record_start} + 17'd5))
							format_error <= 1'b1;

						if((expected_payload_length < 16'd2) || payload_end_address[16] ||
							({1'b0, byte_data, link_low} > final_link_address))
							format_error <= 1'b1;

						state <= STATE_LINE_LOW;
					end
				end

				STATE_LINE_LOW: begin
					line_number_low <= byte_data;
					state           <= STATE_LINE_HIGH;
				end

				STATE_LINE_HIGH: begin
					if(({byte_data, line_number_low} < 16'd1) || ({byte_data, line_number_low} > 16'd63999))
						format_error <= 1'b1;

					if({byte_data, line_number_low} <= previous_line_number)
						format_error <= 1'b1;

					previous_line_number 	<= {byte_data, line_number_low};
					observed_line_count 	<= observed_line_count + 1'b1;
					state 					<= STATE_STATEMENT;
				end

				STATE_STATEMENT: begin
					if(byte_data == 8'h00) begin
						if({1'b0, next_line_address} !=	current_byte_end_address)
							format_error <= 1'b1;

						record_start <= next_line_address;
						state        <= STATE_LINK_LOW;
					end
				end

				STATE_FINAL_SEEN: begin
					// No byte may follow the final $0000 link.
					format_error <= 1'b1;
				end

				default: begin
					format_error <= 1'b1;
				end
			endcase

			byte_count <= byte_count + 1'b1;
		end

		if(finish) begin
			complete <= 1'b1;

			if(!format_error &&	(expected_payload_length >= 16'd2) && !payload_end_address[16] &&
				(state == STATE_FINAL_SEEN) && (byte_count == expected_payload_length) &&
				(observed_line_count == expected_line_count)) begin
				payload_valid <= 1'b1;
			end
			else begin
				payload_valid <= 1'b0;
				format_error  <= 1'b1;
			end
		end
	end
end

endmodule