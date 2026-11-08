module microtan_toolkit_e2_rom (
	input  logic        clk,
	input  logic        selected,
	input  logic [10:0] address,
	output logic [7:0]  data
);

logic [7:0] rom [0:2047];

initial begin
	$readmemh("rtl/rom/toolkit_e2.hex", rom);
end

always_ff @(posedge clk) begin
	if(selected)
		data <= rom[address];
end

endmodule