module microtan_hrg_ram (
	input  logic        clk,
	input  logic        cpu_enable,
	input  logic        cpu_selected,
	input  logic        cpu_rw_n,
	input  logic [12:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	input  logic [12:0] video_address,
	output logic [7:0]  cpu_read_data,
	output logic [7:0]  video_read_data
);

logic [7:0] ram [0:8191];

always_ff @(posedge clk) begin
	if(cpu_selected) begin
		if(cpu_enable && !cpu_rw_n)
			ram[cpu_address] <= cpu_write_data;

		cpu_read_data <= ram[cpu_address];
	end
end

always_ff @(posedge clk) begin
	video_read_data <= ram[video_address];
end

endmodule