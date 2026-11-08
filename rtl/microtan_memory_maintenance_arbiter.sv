module microtan_memory_maintenance_arbiter (
	input  logic        normal_cpu_run_enable,
	input  logic        normal_memory_enable,
	input  logic        normal_memory_rw_n,
	input  logic [15:0] normal_memory_address,
	input  logic [7:0]  normal_memory_write_data,
	input  logic        maintenance_machine_owned,
	input  logic        maintenance_write_enable,
	input  logic [15:0] maintenance_write_address,
	input  logic [7:0]  maintenance_write_data,
	input  logic        maintenance_force_ram_access,
	output logic        cpu_run_enable,
	output logic        memory_enable,
	output logic        memory_rw_n,
	output logic [15:0] memory_address,
	output logic [7:0]  memory_write_data,
	output logic        force_ram_access
);

always_comb begin
	// With no maintenance owner, preserve the existing CPU/loader bus.
	cpu_run_enable     = normal_cpu_run_enable;
	memory_enable      = normal_memory_enable;
	memory_rw_n        = normal_memory_rw_n;
	memory_address     = normal_memory_address;
	memory_write_data  = normal_memory_write_data;
	force_ram_access   = 1'b0;

	if(maintenance_machine_owned) begin
		// Maintenance owns the memory bus atomically. 
		// An inactive write-enable becomes an idle read-direction cycle and cannot modify memory.
		cpu_run_enable    = 1'b0;
		memory_enable     = maintenance_write_enable;
		memory_rw_n       = !maintenance_write_enable;
		memory_address    = maintenance_write_address;
		memory_write_data = maintenance_write_data;

		// Screen-only clearing never needs to bypass the selected RAM profile.
		// Full clearing asserts this for access to all physical expansion RAM.
		force_ram_access = maintenance_force_ram_access;
	end
end

endmodule