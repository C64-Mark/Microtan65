module microtan_multi_loader_arbiter (
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	input  logic        hex_machine_owned,
	input  logic        hex_memory_enable,
	input  logic        hex_memory_rw_n,
	input  logic [15:0] hex_memory_address,
	input  logic [7:0]  hex_memory_write_data,
	input  logic        m65_machine_owned,
	input  logic        m65_memory_enable,
	input  logic        m65_memory_rw_n,
	input  logic [15:0] m65_memory_address,
	input  logic [7:0]  m65_memory_write_data,
	input  logic        mtb_machine_owned,
	input  logic        mtb_memory_enable,
	input  logic        mtb_memory_rw_n,
	input  logic [15:0] mtb_memory_address,
	input  logic [7:0]  mtb_memory_write_data,
	output logic        ownership_conflict,
	output logic        cpu_run_enable,
	output logic        memory_enable,
	output logic        memory_rw_n,
	output logic [15:0] memory_address,
	output logic [7:0]  memory_write_data
);

always_comb begin
	ownership_conflict = (hex_machine_owned && m65_machine_owned) || (hex_machine_owned && mtb_machine_owned) || (m65_machine_owned && mtb_machine_owned);
	cpu_run_enable = cpu_enable && !hex_machine_owned && !m65_machine_owned && !mtb_machine_owned;

	// With no loader owner, the processor drives the machine bus.
	memory_enable     = cpu_run_enable;
	memory_rw_n       = cpu_rw_n;
	memory_address    = cpu_address;
	memory_write_data = cpu_write_data;

	// Any multiple-owner condition is invalid. 
	// Suppress the CPU and every memory operation so that no loader can corrupt live machine memory.
	if(ownership_conflict) begin
		cpu_run_enable   	= 1'b0;
		memory_enable    	= 1'b0;
		memory_rw_n      	= 1'b1;
		memory_address   	= 16'h0000;
		memory_write_data 	= 8'h00;
	end
	else if(mtb_machine_owned) begin
		memory_enable     = mtb_memory_enable;
		memory_rw_n       = mtb_memory_rw_n;
		memory_address    = mtb_memory_address;
		memory_write_data = mtb_memory_write_data;
	end
	else if(m65_machine_owned) begin
		memory_enable     = m65_memory_enable;
		memory_rw_n       = m65_memory_rw_n;
		memory_address    = m65_memory_address;
		memory_write_data = m65_memory_write_data;
	end
	else if(hex_machine_owned) begin
		memory_enable     = hex_memory_enable;
		memory_rw_n       = hex_memory_rw_n;
		memory_address    = hex_memory_address;
		memory_write_data = hex_memory_write_data;
	end
end

endmodule