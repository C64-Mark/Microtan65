module microtan_character_rom (
	input  logic       clk,
	input  logic [6:0] character_code,
	input  logic [3:0] character_row,
	output logic [7:0] row_pixels
);

logic [7:0] rom [0:2047];

initial begin
	$readmemh("rtl/rom/microtan_charset.hex", rom);
end

always_ff @(posedge clk) begin
	row_pixels <= rom[{character_code, character_row}];
end

endmodule