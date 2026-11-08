module microtan_text_video (
	input  logic       clk,
	input  logic       reset,
	input  logic       ce_6m,
	input  logic [7:0] video_data,
	input  logic       video_graphics,
	output logic [8:0] raster_x,
	output logic [8:0] raster_y,
	output logic [8:0] video_address,
	output logic       pixel,
	output logic       active_video,
	output logic       hsync_n,
	output logic       vsync_n
);

logic [3:0] character_row;
logic [2:0] pixel_column;
logic [7:0] row_pixels;
logic       text_pixel;
logic       chunky_pixel;

microtan_video_timing video_timing (
	.clk(clk),
	.reset(reset),
	.ce_6m(ce_6m),
	.raster_x(raster_x),
	.raster_y(raster_y),
	.video_address(video_address),
	.character_row(character_row),
	.pixel_column(pixel_column),
	.active_video(active_video),
	.hsync_n(hsync_n),
	.vsync_n(vsync_n)
);

microtan_character_rom character_rom (
	.clk(clk),
	.character_code(video_data[6:0]),
	.character_row(character_row),
	.row_pixels(row_pixels)
);

microtan_text_pixel text_pixel_selector (
	.row_pixels(row_pixels),
	.pixel_column(pixel_column),
	.active_video(active_video),
	.pixel(text_pixel)
);

microtan_chunky_pixel chunky_pixel_selector (
	.display_data(video_data),
	.character_row(character_row),
	.pixel_column(pixel_column),
	.active_video(active_video),
	.pixel(chunky_pixel)
);

always_comb begin
	if(video_graphics)
		pixel = chunky_pixel;
	else
		pixel = text_pixel;
end

endmodule