module microtan_hrg_pixel (
	input  logic [8:0] raster_x,
	input  logic [8:0] raster_y,
	input  logic [7:0] video_data,
	output logic [12:0] video_address,
	output logic        pixel
);

always_comb begin
	/*
	 * Each display line contains 32 bytes.
	 * The upper eight address bits select Y.
	 * The lower five address bits select the byte containing X.
	 */
	video_address = {raster_y[7:0], raster_x[7:3]};
	pixel = 1'b0;
	if((raster_x < 9'd256) && (raster_y < 9'd256))
		pixel = video_data[3'd7 - raster_x[2:0]];
end

endmodule