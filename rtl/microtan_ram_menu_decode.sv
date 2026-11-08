module microtan_ram_menu_decode (
	input  logic [2:0] menu_value,
	output logic [2:0] ram_profile
);

localparam logic [2:0] RAM_PROFILE_8K  = 3'd0;
localparam logic [2:0] RAM_PROFILE_1K  = 3'd1;
localparam logic [2:0] RAM_PROFILE_16K = 3'd2;
localparam logic [2:0] RAM_PROFILE_32K = 3'd3;
localparam logic [2:0] RAM_PROFILE_48K = 3'd4;

always_comb begin
	case(menu_value)
		3'd0:
			ram_profile = RAM_PROFILE_1K;
		3'd1:
			ram_profile = RAM_PROFILE_8K;
		3'd2:
			ram_profile = RAM_PROFILE_16K;
		3'd3:
			ram_profile = RAM_PROFILE_32K;
		3'd4:
			ram_profile = RAM_PROFILE_48K;
		default:
			ram_profile = RAM_PROFILE_8K;
	endcase
end

endmodule