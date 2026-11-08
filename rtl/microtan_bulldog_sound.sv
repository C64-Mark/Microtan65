module microtan_bulldog_sound (
	input  logic       	clk,
	input  logic       	reset,
	input  logic       	enabled,
	input  logic       	psg_enable,
	input  logic       	cpu_enable,
	input  logic       	selected,
	input  logic       	cpu_rw_n,
	input  logic [1:0] 	address,
	input  logic [7:0] 	write_data,

	output wire [7:0] 	read_data,
	output wire       	read_data_valid,
	output wire [9:0]  	sound_0,
	output wire [9:0]  	sound_1,
	output wire [10:0] 	mixed_sound,
	output wire        	sample_0,
	output wire        	sample_1
);

wire selected_cpu_cycle = enabled && selected && cpu_enable;
logic ay0_bdir;
logic ay0_bc1;
logic ay1_bdir;
logic ay1_bc1;

always_comb begin
	ay0_bdir = 1'b0;
	ay0_bc1  = 1'b0;
	ay1_bdir = 1'b0;
	ay1_bc1  = 1'b0;

	if(selected_cpu_cycle) begin
		if(!address[1]) begin
			if(!cpu_rw_n) begin
				ay0_bdir = 1'b1;
				ay0_bc1  = !address[0];
			end
			else if(!address[0]) begin
				ay0_bc1 = 1'b1;
			end
		end
		else begin
			if(!cpu_rw_n) begin
				ay1_bdir = 1'b1;
				ay1_bc1  = !address[0];
			end
			else if(!address[0]) begin
				ay1_bc1 = 1'b1;
			end
		end
	end
end

wire sound_reset_n = !reset && enabled;

wire [7:0] 	ay0_read_data;
wire [7:0] 	ay1_read_data;
wire [9:0] 	ay0_sound;
wire [9:0] 	ay1_sound;
wire 		ay0_sample;
wire 		ay1_sample;

jt49_bus ay0_inst (
	.rst_n(sound_reset_n),
	.clk(clk),
	.clk_en(psg_enable),
	.bdir(ay0_bdir),
	.bc1(ay0_bc1),
	.din(write_data),
	.sel(1'b1),
	.dout(ay0_read_data),
	.sound(ay0_sound),
	.A(),
	.B(),
	.C(),
	.sample(ay0_sample),
	.IOA_in(8'hFF),
	.IOA_out(),
	.IOA_oe(),
	.IOB_in(8'hFF),
	.IOB_out(),
	.IOB_oe()
);

jt49_bus ay1_inst (
	.rst_n(sound_reset_n),
	.clk(clk),
	.clk_en(psg_enable),
	.bdir(ay1_bdir),
	.bc1(ay1_bc1),
	.din(write_data),
	.sel(1'b1),
	.dout(ay1_read_data),
	.sound(ay1_sound),
	.A(),
	.B(),
	.C(),
	.sample(ay1_sample),
	.IOA_in(8'hFF),
	.IOA_out(),
	.IOA_oe(),
	.IOB_in(8'hFF),
	.IOB_out(),
	.IOB_oe()
);

assign read_data_valid = selected_cpu_cycle && cpu_rw_n && !address[0];
assign read_data = read_data_valid ? (address[1] ? ay1_read_data : ay0_read_data) : 8'hFF;
assign sound_0 = enabled ? ay0_sound : 10'd0;
assign sound_1 = enabled ? ay1_sound : 10'd0;

// Preserve the complete output of both PSGs. Eleven bits accommodate
// the sum of two ten-bit JT49 outputs without clipping.
assign mixed_sound = {1'b0, sound_0} + {1'b0, sound_1};
assign sample_0 = enabled && ay0_sample;
assign sample_1 = enabled && ay1_sample;

endmodule