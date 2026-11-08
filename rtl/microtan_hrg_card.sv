module microtan_hrg_card (
	input  logic        clk,
	input  logic        reset,
	input  logic        force_ram_access,
	input  logic [1:0]  hrg_mode,
	input  logic        cpu_enable,
	input  logic        cpu_rw_n,
	input  logic [15:0] cpu_address,
	input  logic [7:0]  cpu_write_data,
	input  logic [8:0]  raster_x,
	input  logic [8:0]  raster_y,
	output logic [7:0]  cpu_read_data,
	output logic        cpu_read_data_valid,
	output logic        hrg_selected,
	output logic [7:0]  block_register,
	output logic        hrg_pixel
);

localparam logic [1:0] HRG_MODE_NONE         = 2'd0;
localparam logic [1:0] HRG_MODE_PHANTOM      = 2'd1;
localparam logic [1:0] HRG_MODE_BLOCK_SLOT_1 = 2'd2;

logic [12:0] hrg_video_address;
logic [7:0]  hrg_video_data;
logic        raw_hrg_pixel;
logic        decoded_hrg_selected;

wire maintenance_hrg_selected =	force_ram_access &&	(cpu_address >= 16'h8000) && (cpu_address <= 16'h9FFF);
wire hrg_ram_selected =	decoded_hrg_selected ||	maintenance_hrg_selected;
assign hrg_selected = decoded_hrg_selected;

microtan_tanbus_block_register block_register_inst (
	.clk(clk),
	.reset(reset),
	.cpu_enable(cpu_enable),
	.cpu_rw_n(cpu_rw_n),
	.address(cpu_address),
	.write_data(cpu_write_data),
	.block_register(block_register)
);

microtan_hrg_decode decode_inst (
	.hrg_mode(hrg_mode),
	.address(cpu_address),
	.cpu_rw_n(cpu_rw_n),
	.block_register(block_register),
	.hrg_selected(decoded_hrg_selected)
);

microtan_hrg_ram ram_inst (
	.clk(clk),
	.cpu_enable(cpu_enable),
	.cpu_selected(hrg_ram_selected),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address[12:0]),
	.cpu_write_data(cpu_write_data),
	.video_address(hrg_video_address),
	.cpu_read_data(cpu_read_data),
	.video_read_data(hrg_video_data)
);

microtan_hrg_pixel pixel_inst (
	.raster_x(raster_x),
	.raster_y(raster_y),
	.video_data(hrg_video_data),
	.video_address(hrg_video_address),
	.pixel(raw_hrg_pixel)
);

always_comb begin
	cpu_read_data_valid = cpu_rw_n && decoded_hrg_selected;

	case(hrg_mode)
		HRG_MODE_PHANTOM,
		HRG_MODE_BLOCK_SLOT_1:
			hrg_pixel = raw_hrg_pixel;

		default:
			hrg_pixel = 1'b0;
	endcase
end

endmodule