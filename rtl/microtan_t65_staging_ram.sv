module microtan_t65_staging_ram (
	input  logic        clk,
	input  logic        write_enable,
	input  logic [15:0] write_address,
	input  logic [7:0]  write_data,
	input  logic [15:0] read_address,
	output logic [7:0]  read_data
);

logic [7:0] memory [0:65535];

always_ff @(posedge clk) begin
	if(write_enable)
		memory[write_address] <= write_data;

	read_data <= memory[read_address];
end

endmodule