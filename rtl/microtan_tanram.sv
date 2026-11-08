module microtan_tanram (
	input  logic        clk,
	input  logic        selected,
	input  logic [15:0] address,
	input  logic        write_enable,
	input  logic [7:0]  data_in,
	output logic [7:0]  data_out
);

localparam integer TANRAM_BYTES = 16'h9C00;

logic [7:0]  ram [0:TANRAM_BYTES - 1];
logic [15:0] ram_address;

always_comb begin
	ram_address = address - 16'h2000;
end

always_ff @(posedge clk) begin
	if(selected) begin
		if(write_enable)
			ram[ram_address] <= data_in;

		data_out <= ram[ram_address];
	end
end

endmodule