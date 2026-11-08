module microtan_loader_bus_mux (
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	input  logic        loader_active,
	input  logic        loader_write_valid,
	input  logic [15:0] loader_address,
	input  logic [7:0]  loader_write_data,
	output logic        cpu_run_enable,
	output logic        memory_enable,
	output logic        memory_rw_n,
	output logic [15:0] memory_address,
	output logic [7:0]  memory_write_data
);

logic loader_owns_bus;

always_comb begin
	// loader_write_valid remains authoritative for the final parser write, which may occur one clock after loader_active falls. 
	loader_owns_bus = loader_active || loader_write_valid;
	cpu_run_enable = cpu_enable && !loader_owns_bus;

	if(loader_owns_bus) begin
		memory_enable     = loader_write_valid;
		memory_rw_n       = 1'b0;
		memory_address    = loader_address;
		memory_write_data = loader_write_data;
	end
	else begin
		memory_enable     = cpu_enable;
		memory_rw_n       = cpu_rw_n;
		memory_address    = cpu_address;
		memory_write_data = cpu_write_data;
	end
end

endmodule