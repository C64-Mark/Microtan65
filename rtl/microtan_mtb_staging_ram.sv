module microtan_mtb_staging_ram (
	input  logic        clk,
	input  logic        write_enable,
	input  logic [15:0] write_address,
	input  logic [7:0]  write_data,
	input  logic [15:0] read_address,
	output logic [7:0]  read_data
);

localparam integer STAGING_BYTE_COUNT = 47103;
localparam logic [15:0] STAGING_LIMIT = 16'hB7FF;
logic [7:0] memory [0:STAGING_BYTE_COUNT - 1];

always_ff @(posedge clk) begin
	if(write_enable && (write_address < STAGING_LIMIT))
		memory[write_address] <= write_data;

	if(read_address < STAGING_LIMIT)
		read_data <= memory[read_address];
	else
		read_data <= 8'h00;
end

endmodule