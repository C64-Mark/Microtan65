module microtan_mtb_crc32 (
	input  logic        clk,
	input  logic        reset,
	input  logic        start,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	input  logic        finish,
	input  logic [31:0] expected_crc32,
	output logic        complete,
	output logic        crc_match,
	output logic [31:0] calculated_crc32
);

logic [31:0] crc_state;

function automatic logic [31:0] update_crc32 (
	input logic [31:0] current_crc,
	input logic [7:0]  data
);

logic [31:0] working_crc;
integer bit_index;

begin
	working_crc = current_crc ^ {24'h000000, data};

	for(bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
		if(working_crc[0])
			working_crc = (working_crc >> 1) ^ 32'hEDB88320;
		else
			working_crc = working_crc >> 1;
	end

	update_crc32 = working_crc;
end
endfunction

always_ff @(posedge clk) begin
	complete <= 1'b0;

	if(reset) begin
		crc_state        <= 32'hFFFFFFFF;
		complete         <= 1'b0;
		crc_match        <= 1'b0;
		calculated_crc32 <= 32'h00000000;
	end
	else if(start) begin
		crc_state        <= 32'hFFFFFFFF;
		crc_match        <= 1'b0;
		calculated_crc32 <= 32'h00000000;
	end
	else begin
		if(byte_valid)
			crc_state <= update_crc32(crc_state, byte_data);

		if(finish) begin
			calculated_crc32 <=	crc_state ^ 32'hFFFFFFFF;
			crc_match <= ((crc_state ^ 32'hFFFFFFFF) ==	expected_crc32);
			complete <= 1'b1;
		end
	end
end

endmodule