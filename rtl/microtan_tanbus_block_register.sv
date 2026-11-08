module microtan_tanbus_block_register (
	input  logic        clk,
	input  logic        reset,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] address,
	input  logic [7:0]  write_data,
	output logic [7:0]  block_register
);

always_ff @(posedge clk) begin
	if(reset)
		block_register <= 8'h00;
	else if(cpu_enable && !cpu_rw_n && (address == 16'hFFFF))
		block_register <= write_data;
end

endmodule