module microtan_base_ram (
	input  logic       clk,
	input  logic [9:0] address,
	input  logic       write_enable,
	input  logic [7:0] data_in,
	input  logic [8:0] video_address,
	output logic [7:0] data_out,
	output logic [7:0] video_data_out
);

logic [7:0] system_ram  [0:511];
logic [7:0] display_ram [0:511];
logic [7:0] system_data_out;
logic [7:0] display_data_out;

always_ff @(posedge clk) begin
	if(write_enable && !address[9])
		system_ram[address[8:0]] <= data_in;

	system_data_out <= system_ram[address[8:0]];
end

always_ff @(posedge clk) begin
	if(write_enable && address[9])
		display_ram[address[8:0]] <= data_in;

	display_data_out <= display_ram[address[8:0]];
end

always_ff @(posedge clk) begin
	video_data_out <= display_ram[video_address];
end

assign data_out =
	address[9] ? display_data_out : system_data_out;

endmodule