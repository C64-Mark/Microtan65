module microtan_text_pixel (
	input  logic [7:0] row_pixels,
	input  logic [2:0] pixel_column,
	input  logic       active_video,
	output logic       pixel
);

always_comb begin
	if(active_video)
		pixel = row_pixels[3'd7 - pixel_column];
	else
		pixel = 1'b0;
end

endmodule