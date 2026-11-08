module microtan_configured_expansion_ram (
	input  logic        clk,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] address,
	input  logic [7:0]  write_data,
	input  logic [2:0]  ram_profile,
	input  logic        force_ram_access,
	input  logic        inhibit_tanram,
	input  logic        tanex_ram_selected,
	input  logic        tanram_selected,
	output logic [7:0]  read_data,
	output logic        read_data_valid
);

logic ram_enabled;

wire effective_ram_enabled = ram_enabled ||	force_ram_access;
wire effective_tanex_selected =	tanex_ram_selected && effective_ram_enabled;
wire effective_tanram_selected = tanram_selected &&	effective_ram_enabled && (!inhibit_tanram || force_ram_access);

microtan_ram_profile profile (
	.address(address),
	.ram_profile(ram_profile),
	.ram_enabled(ram_enabled)
);

microtan_expansion_ram expansion_ram (
	.clk(clk),
	.cpu_enable(cpu_enable),
	.cpu_rw_n(cpu_rw_n),
	.address(address),
	.write_data(write_data),
	.tanex_ram_selected(effective_tanex_selected),
	.tanram_selected(effective_tanram_selected),
	.read_data(read_data),
	.read_data_valid(read_data_valid)
);

endmodule