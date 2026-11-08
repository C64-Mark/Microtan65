module microtan_graphics_attribute_ram (
	input  logic       clk,
	input  logic       write_enable,
	input  logic [8:0] write_address,
	input  logic       graphics_write_mode,
	input  logic       snapshot_write_enable,
	input  logic [5:0] snapshot_write_address,
	input  logic [7:0] snapshot_write_data,
	input  logic [8:0] video_address,
	output logic       video_graphics
);

logic graphics_attribute [0:511];
logic [8:0] snapshot_base_address;

assign snapshot_base_address = {snapshot_write_address, 3'b000};

// The original 2102 has no machine-reset initialization. Software establishes
// an attribute only when it writes the corresponding display-memory cell.
//
// A legacy M65 snapshot packs eight consecutive attributes into each byte, least-significant bit first.
// Snapshot writes take priority because the CPU will be held while a snapshot owns the machine.
always_ff @(posedge clk) begin
	if(snapshot_write_enable) begin
		graphics_attribute[snapshot_base_address + 9'd0] <=	snapshot_write_data[0];
		graphics_attribute[snapshot_base_address + 9'd1] <=	snapshot_write_data[1];
		graphics_attribute[snapshot_base_address + 9'd2] <=	snapshot_write_data[2];
		graphics_attribute[snapshot_base_address + 9'd3] <=	snapshot_write_data[3];
		graphics_attribute[snapshot_base_address + 9'd4] <=	snapshot_write_data[4];
		graphics_attribute[snapshot_base_address + 9'd5] <=	snapshot_write_data[5];
		graphics_attribute[snapshot_base_address + 9'd6] <=	snapshot_write_data[6];
		graphics_attribute[snapshot_base_address + 9'd7] <=	snapshot_write_data[7];
	end
	else if(write_enable)
		graphics_attribute[write_address] <= graphics_write_mode;

	video_graphics <= graphics_attribute[video_address];
end

endmodule