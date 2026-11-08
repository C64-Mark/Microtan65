module microtan_chunky_pixel (
	input  logic [7:0] display_data,
	input  logic [3:0] character_row,
	input  logic [2:0] pixel_column,
	input  logic       active_video,
	output logic       pixel
);

always_comb begin
	if(active_video)
		pixel = display_data[{character_row[3:2], pixel_column[2]}];
	else
		pixel = 1'b0;
end

endmodule