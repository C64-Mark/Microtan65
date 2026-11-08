module microtan_ram_profile (
	input  logic [15:0] address,
	input  logic [2:0]  ram_profile,
	output logic        ram_enabled
);

localparam logic [2:0] RAM_PROFILE_8K  = 3'd0;
localparam logic [2:0] RAM_PROFILE_1K  = 3'd1;
localparam logic [2:0] RAM_PROFILE_16K = 3'd2;
localparam logic [2:0] RAM_PROFILE_32K = 3'd3;
localparam logic [2:0] RAM_PROFILE_48K = 3'd4;

always_comb begin
	case(ram_profile)
		RAM_PROFILE_1K:
			ram_enabled = address <= 16'h03FF;

		RAM_PROFILE_8K:
			ram_enabled = address <= 16'h1FFF;

		RAM_PROFILE_16K:
			ram_enabled = address <= 16'h3FFF;

		RAM_PROFILE_32K:
			ram_enabled = address <= 16'h7FFF;

		RAM_PROFILE_48K:
			ram_enabled = address <= 16'hBBFF;

		default:
			ram_enabled = address <= 16'h1FFF;
	endcase
end

endmodule