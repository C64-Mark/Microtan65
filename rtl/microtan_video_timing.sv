module microtan_video_timing (
	input  logic       clk,
	input  logic       reset,
	input  logic       ce_6m,
	output logic [8:0] raster_x,
	output logic [8:0] raster_y,
	output logic [8:0] video_address,
	output logic [3:0] character_row,
	output logic [2:0] pixel_column,
	output logic       active_video,
	output logic       hsync_n,
	output logic       vsync_n
);

always_ff @(posedge clk) begin
	if(reset) begin
		raster_x <= 9'd0;
		raster_y <= 9'd0;
	end
	else if(ce_6m) begin
		if(raster_x == 9'd383) begin
			raster_x <= 9'd0;

			if(raster_y == 9'd311)
				raster_y <= 9'd0;
			else
				raster_y <= raster_y + 9'd1;
		end
		else begin
			raster_x <= raster_x + 9'd1;
		end
	end
end

always_comb begin
	// Display RAM is organised as 16 rows of 32 character cells.
	video_address 	= {raster_y[7:4], raster_x[7:3]};
	character_row 	= raster_y[3:0];
	pixel_column  	= raster_x[2:0];
	active_video 	= (raster_x < 9'd256) && (raster_y < 9'd256);

	// MT001 decodes horizontal character counts 36-39.
	hsync_n = !((raster_x >= 9'd288) && (raster_x <  9'd320));

	// MT001 decodes vertical lines 280-287.
	vsync_n = !((raster_y >= 9'd280) && (raster_y <  9'd288));
end

endmodule