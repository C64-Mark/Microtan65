module microtan_expansion_ram (
	input  logic        clk,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] address,
	input  logic [7:0]  write_data,
	input  logic        tanex_ram_selected,
	input  logic        tanram_selected,
	output logic [7:0]  read_data,
	output logic        read_data_valid
);

wire tanex_write_enable = cpu_enable && !cpu_rw_n && tanex_ram_selected;
wire tanram_write_enable = cpu_enable && !cpu_rw_n && tanram_selected;
logic [7:0] tanex_read_data;
logic [7:0] tanram_read_data;

microtan_tanex_ram tanex_ram (
	.clk(clk),
	.selected(tanex_ram_selected),
	.address(address),
	.write_enable(tanex_write_enable),
	.data_in(write_data),
	.data_out(tanex_read_data)
);

microtan_tanram tanram (
	.clk(clk),
	.selected(tanram_selected),
	.address(address),
	.write_enable(tanram_write_enable),
	.data_in(write_data),
	.data_out(tanram_read_data)
);

always_comb begin
	read_data       = 8'hFF;
	read_data_valid = 1'b0;

	if(cpu_rw_n && tanex_ram_selected) begin
		read_data       = tanex_read_data;
		read_data_valid = 1'b1;
	end
	else if(cpu_rw_n && tanram_selected) begin
		read_data       = tanram_read_data;
		read_data_valid = 1'b1;
	end
end

endmodule