module microtan_mtb_header_validator (
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
	output logic [31:0] expected_crc32
);

logic        download_active_d;
logic [27:0] byte_count;
logic [16:0] calculated_first_free;
logic [27:0] expected_file_length;
logic [15:0] minimum_ram_top;
logic        final_header_valid;

function automatic logic [15:0] required_ram_top (
	input logic [15:0] address
);
begin
	if(address <= 16'h2000)
		required_ram_top = 16'h2000;
	else if(address <= 16'h4000)
		required_ram_top = 16'h4000;
	else if(address <= 16'h8000)
		required_ram_top = 16'h8000;
	else if(address <= 16'hBC00)
		required_ram_top = 16'hBC00;
	else
		required_ram_top = 16'h0000;
end
endfunction

always_comb begin
	calculated_first_free =	17'h00401 + {1'b0, payload_length};
	expected_file_length = 28'd20 + {{12{1'b0}}, payload_length};
	minimum_ram_top = required_ram_top(first_free);

	final_header_valid = (byte_count >= 28'd20) && (payload_length >= 16'd2) &&
		!calculated_first_free[16] && (first_free == calculated_first_free[15:0]) &&
		(minimum_ram_top != 16'h0000) && (ram_top == minimum_ram_top) && (byte_count == expected_file_length);
end

always_ff @(posedge clk) begin
	validation_complete <= 1'b0;
	file_valid          <= 1'b0;
	download_active_d 	<= download_active;

	if(reset) begin
		download_active_d 	<= 1'b0;
		byte_count        	<= 28'd0;
		validation_complete <= 1'b0;
		file_valid          <= 1'b0;
		format_error        <= 1'b0;
		payload_length 		<= 16'h0000;
		first_free     		<= 16'h0000;
		ram_top        		<= 16'h0000;
		line_count     		<= 16'h0000;
		expected_crc32 		<= 32'h00000000;
	end
	else if(download_active && !download_active_d) begin
		byte_count 		<= 28'd0;
		format_error 	<= 1'b0;
		payload_length 	<= 16'h0000;
		first_free     	<= 16'h0000;
		ram_top        	<= 16'h0000;
		line_count     	<= 16'h0000;
		expected_crc32 	<= 32'h00000000;
	end
	else if(!download_active && download_active_d) begin
		validation_complete <= 1'b1;

		if(final_header_valid && !format_error)
			file_valid <= 1'b1;
		else
			format_error <= 1'b1;
	end
	else if(download_active && byte_valid) begin
		case(byte_count)
			28'd0:
				if(byte_data != 8'h4D)
					format_error <= 1'b1;
			28'd1:
				if(byte_data != 8'h54)
					format_error <= 1'b1;
			28'd2:
				if(byte_data != 8'h42)
					format_error <= 1'b1;
			28'd3:
				if(byte_data != 8'h31)
					format_error <= 1'b1;
			28'd4:
				if(byte_data != 8'h14)
					format_error <= 1'b1;
			28'd5:
				if(byte_data != 8'h00)
					format_error <= 1'b1;
			28'd6:
				if(byte_data != 8'h01)
					format_error <= 1'b1;
			28'd7:
				if(byte_data != 8'h04)
					format_error <= 1'b1;
			28'd8:
				payload_length[7:0] <= byte_data;
			28'd9:
				payload_length[15:8] <= byte_data;
			28'd10:
				first_free[7:0] <= byte_data;
			28'd11:
				first_free[15:8] <= byte_data;
			28'd12:
				ram_top[7:0] <= byte_data;
			28'd13:
				ram_top[15:8] <= byte_data;
			28'd14:
				line_count[7:0] <= byte_data;
			28'd15:
				line_count[15:8] <= byte_data;
			28'd16:
				expected_crc32[7:0] <= byte_data;
			28'd17:
				expected_crc32[15:8] <= byte_data;
			28'd18:
				expected_crc32[23:16] <= byte_data;
			28'd19:
				expected_crc32[31:24] <= byte_data;
			default:
				;
		endcase

		byte_count <= byte_count + 1'b1;
	end
end

endmodule