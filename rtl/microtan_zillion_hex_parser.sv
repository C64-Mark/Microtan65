module microtan_zillion_hex_parser (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	output logic        write_valid,
	output logic [15:0] write_address,
	output logic [7:0]  write_data,
	output logic        start_valid,
	output logic [15:0] start_address,
	output logic        load_complete,
	output logic        format_error
);

localparam logic PHASE_ADDRESS = 1'b0;
localparam logic PHASE_DATA    = 1'b1;

logic 			download_active_d;
logic 			inside_block;
logic 			ignore_line;
logic 			line_phase;
logic [15:0] 	address_value;
logic [2:0]  	address_digits;
logic [15:0] 	line_address;
logic [7:0] 	data_value;
logic [1:0] 	data_digits;
logic [4:0] 	data_count;
logic 			outside_line_start;
logic 			go_parsing;
logic 			go_invalid;
logic [15:0] 	go_value;
logic [2:0]  	go_digits;

function automatic logic is_hex_digit(input logic [7:0] character);
	begin
		is_hex_digit = ((character >= "0") && (character <= "9")) ||
			((character >= "A") && (character <= "F")) || ((character >= "a") && (character <= "f"));
	end
endfunction

function automatic logic [3:0] hex_value(input logic [7:0] character);
	begin
		if((character >= "0") && (character <= "9"))
			hex_value = character[3:0];
		else if((character >= "A") && (character <= "F"))
			hex_value = character[3:0] + 4'd9;
		else
			hex_value = character[3:0] + 4'd9;
	end
endfunction

function automatic logic is_line_end(input logic [7:0] character);
	begin
		is_line_end = (character == 8'h0A) || (character == 8'h0D);
	end
endfunction

function automatic logic is_horizontal_space(input logic [7:0] character);
	begin
		is_horizontal_space = (character == 8'h20) || (character == 8'h09);
	end
endfunction

always_ff @(posedge clk) begin
	write_valid   <= 1'b0;
	load_complete <= 1'b0;

	download_active_d <= download_active;

	if(reset) begin
		download_active_d 	<= 1'b0;
		write_address 		<= 16'h0000;
		write_data    		<= 8'h00;
		start_valid   		<= 1'b0;
		start_address 		<= 16'h0000;
		format_error 		<= 1'b0;
		inside_block  		<= 1'b0;
		ignore_line   		<= 1'b0;
		line_phase    		<= PHASE_ADDRESS;
		address_value  		<= 16'h0000;
		address_digits 		<= 3'd0;
		line_address   		<= 16'h0000;
		data_value  		<= 8'h00;
		data_digits 		<= 2'd0;
		data_count  		<= 5'd0;
		outside_line_start 	<= 1'b1;
		go_parsing          <= 1'b0;
		go_invalid          <= 1'b0;
		go_value            <= 16'h0000;
		go_digits           <= 3'd0;
	end
	else if(download_active && !download_active_d) begin
		write_address 		<= 16'h0000;
		write_data    		<= 8'h00;
		start_valid   		<= 1'b0;
		start_address 		<= 16'h0000;
		format_error 		<= 1'b0;
		inside_block 		<= 1'b0;
		ignore_line  		<= 1'b0;
		line_phase   		<= PHASE_ADDRESS;
		address_value  		<= 16'h0000;
		address_digits 		<= 3'd0;
		line_address   		<= 16'h0000;
		data_value  		<= 8'h00;
		data_digits 		<= 2'd0;
		data_count  		<= 5'd0;
		outside_line_start 	<= 1'b1;
		go_parsing          <= 1'b0;
		go_invalid          <= 1'b0;
		go_value            <= 16'h0000;
		go_digits           <= 3'd0;
	end
	else if(!download_active && download_active_d) begin
		load_complete <= 1'b1;

		// Accept a final data byte even if the file has no trailing newline.
		if(inside_block && (line_phase == PHASE_DATA) && !ignore_line &&
		   (data_digits == 2) && (data_count < 5'd16)) begin

			if(line_address <= 16'h1FFF) begin
				write_valid   <= 1'b1;
				write_address <= line_address;
				write_data    <= data_value;
			end
			else begin
				format_error <= 1'b1;
			end
		end
		else if(!inside_block && go_parsing && !go_invalid &&
		        (go_digits != 0) && !start_valid) begin

			start_valid   <= 1'b1;
			start_address <= go_value;
		end
	end
	else if(download_active && byte_valid) begin
		if(inside_block) begin
			if(byte_data == "}") begin
				if((line_phase == PHASE_DATA) && !ignore_line &&
				   (data_digits == 2) && (data_count < 5'd16)) begin

					if(line_address <= 16'h1FFF) begin
						write_valid   <= 1'b1;
						write_address <= line_address;
						write_data    <= data_value;
					end
					else begin
						format_error <= 1'b1;
					end
				end

				inside_block 		<= 1'b0;
				ignore_line  		<= 1'b0;
				line_phase   		<= PHASE_ADDRESS;
				address_value  		<= 16'h0000;
				address_digits 		<= 3'd0;
				data_value     		<= 8'h00;
				data_digits    		<= 2'd0;
				data_count     		<= 5'd0;
				outside_line_start 	<= 1'b0;
			end
			else if(is_line_end(byte_data)) begin
				if((line_phase == PHASE_DATA) && !ignore_line &&
				   (data_digits == 2) && (data_count < 5'd16)) begin

					if(line_address <= 16'h1FFF) begin
						write_valid   <= 1'b1;
						write_address <= line_address;
						write_data    <= data_value;
					end
					else begin
						format_error <= 1'b1;
					end
				end

				ignore_line 	<= 1'b0;
				line_phase  	<= PHASE_ADDRESS;
				address_value  	<= 16'h0000;
				address_digits 	<= 3'd0;
				data_value     	<= 8'h00;
				data_digits    	<= 2'd0;
				data_count     	<= 5'd0;
			end
			else if(!ignore_line) begin
				if(line_phase == PHASE_ADDRESS) begin
					if(is_horizontal_space(byte_data)) begin
						if(address_digits != 0) begin
							line_address <= address_value;
							line_phase   <= PHASE_DATA;
							data_count   <= 5'd0;
						end
					end
					else if(is_hex_digit(byte_data)) begin
						if(address_digits < 4) begin
							address_value <= {address_value[11:0], hex_value(byte_data)};
							address_digits <= address_digits + 1'b1;
						end
						else begin
							ignore_line <= 1'b1;
						end
					end
					else begin
						ignore_line <= 1'b1;
					end
				end
				else begin
					if(is_horizontal_space(byte_data)) begin
						if(data_digits == 2) begin
							if(data_count < 5'd16) begin
								if(line_address <= 16'h1FFF) begin
									write_valid   <= 1'b1;
									write_address <= line_address;
									write_data    <= data_value;
								end
								else begin
									format_error <= 1'b1;
								end

								line_address <= line_address + 1'b1;
								data_count   <= data_count + 1'b1;
							end

							data_value  <= 8'h00;
							data_digits <= 2'd0;
						end
						else if(data_digits != 0) begin
							ignore_line <= 1'b1;
						end
					end
					else if(is_hex_digit(byte_data)) begin
						if(data_count >= 5'd16) begin
							ignore_line <= 1'b1;
						end
						else if(data_digits == 0) begin
							data_value <= {4'h0, hex_value(byte_data)};
							data_digits <= 2'd1;
						end
						else if(data_digits == 1) begin
							data_value <= {data_value[3:0], hex_value(byte_data)};
							data_digits <= 2'd2;
						end
						else begin
							// More than two hexadecimal digits cannot be one data byte.
							// This also prevents mnemonics such as "adc" being interpreted as data.
							ignore_line <= 1'b1;
						end
					end
					else begin
						ignore_line <= 1'b1;
					end
				end
			end
		end
		else begin
			if(byte_data == "{") begin
				inside_block 	<= 1'b1;
				ignore_line  	<= 1'b0;
				line_phase   	<= PHASE_ADDRESS;
				address_value  	<= 16'h0000;
				address_digits 	<= 3'd0;
				data_value     	<= 8'h00;
				data_digits    	<= 2'd0;
				data_count     	<= 5'd0;
				go_parsing 		<= 1'b0;
				go_invalid 		<= 1'b0;
			end
			else if(is_line_end(byte_data)) begin
				if(go_parsing && !go_invalid &&
				   (go_digits != 0) && !start_valid) begin

					start_valid   <= 1'b1;
					start_address <= go_value;
				end

				outside_line_start 	<= 1'b1;
				go_parsing          <= 1'b0;
				go_invalid          <= 1'b0;
				go_value            <= 16'h0000;
				go_digits           <= 3'd0;
			end
			else if(go_parsing) begin
				if(is_hex_digit(byte_data)) begin
					if(go_digits < 4) begin
						go_value <= {go_value[11:0], hex_value(byte_data)};
						go_digits <= go_digits + 1'b1;
					end
					else begin
						go_invalid <= 1'b1;
					end
				end
				else if(is_horizontal_space(byte_data)) begin
					if(!go_invalid && (go_digits != 0) && !start_valid) begin

						start_valid   <= 1'b1;
						start_address <= go_value;
					end

					go_parsing          <= 1'b0;
					outside_line_start 	<= 1'b0;
				end
				else begin
					// A prose line beginning with G, such as "Game", is not an execution-address record.
					go_parsing          <= 1'b0;
					go_invalid          <= 1'b1;
					outside_line_start 	<= 1'b0;
				end
			end
			else if(outside_line_start) begin
				if(is_horizontal_space(byte_data)) begin
					outside_line_start <= 1'b1;
				end
				else if((byte_data == "G") || (byte_data == "g")) begin
					go_parsing          <= 1'b1;
					go_invalid          <= 1'b0;
					go_value            <= 16'h0000;
					go_digits           <= 3'd0;
					outside_line_start 	<= 1'b0;
				end
				else begin
					outside_line_start <= 1'b0;
				end
			end
		end
	end
end

endmodule