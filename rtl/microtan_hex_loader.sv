module microtan_hex_loader (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        download_write,
	input  logic [7:0]  download_data,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	output logic        cpu_run_enable,
	output logic        machine_owned,
	output logic        memory_enable,
	output logic        memory_rw_n,
	output logic [15:0] memory_address,
	output logic [7:0]  memory_write_data,
	output logic        start_valid,
	output logic [15:0] start_address,
	output logic        load_complete,
	output logic        format_error
);

logic        loader_write_valid;
logic [15:0] loader_write_address;
logic [7:0]  loader_write_data;
assign machine_owned = download_active || loader_write_valid;

microtan_zillion_hex_parser parser (
	.clk(clk),
	.reset(reset),
	.download_active(download_active),
	.byte_valid(download_write),
	.byte_data(download_data),
	.write_valid(loader_write_valid),
	.write_address(loader_write_address),
	.write_data(loader_write_data),
	.start_valid(start_valid),
	.start_address(start_address),
	.load_complete(load_complete),
	.format_error(format_error)
);

microtan_loader_bus_mux bus_mux (
	.cpu_enable(cpu_enable),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address),
	.cpu_write_data(cpu_write_data),
	.loader_active(download_active),
	.loader_write_valid(loader_write_valid),
	.loader_address(loader_write_address),
	.loader_write_data(loader_write_data),
	.cpu_run_enable(cpu_run_enable),
	.memory_enable(memory_enable),
	.memory_rw_n(memory_rw_n),
	.memory_address(memory_address),
	.memory_write_data(memory_write_data)
);

endmodule