module tanbug_rom (
	input  logic        clk,
	input  logic [10:0] address,
	output logic [7:0]  data
);

logic [7:0] rom [0:2047];

initial begin
	$readmemh("rtl/rom/tanbug_v23.hex", rom);
end

always_ff @(posedge clk) begin
	data <= rom[address];
end

endmodule