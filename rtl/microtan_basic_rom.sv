module microtan_basic_rom (
	input  logic        clk,
	input  logic        selected,
	input  logic [13:0] address,
	output logic [7:0]  data
);

logic [7:0] rom [0:10239];

initial begin
	$readmemh("rtl/rom/tanex_basic.hex", rom);
end

always_ff @(posedge clk) begin
	if(selected)
		data <= rom[address];
end

endmodule