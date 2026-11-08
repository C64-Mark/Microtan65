module microtan_hrg_decode (
	input  logic [1:0]  hrg_mode,
	input  logic [15:0] address,
	input  logic        cpu_rw_n,
	input  logic [7:0]  block_register,
	output logic        hrg_selected
);

localparam logic [1:0] HRG_MODE_NONE         = 2'd0;
localparam logic [1:0] HRG_MODE_PHANTOM      = 2'd1;
localparam logic [1:0] HRG_MODE_BLOCK_SLOT_1 = 2'd2;

wire hrg_address_window = (address >= 16'h8000) && (address <= 16'h9FFF);

always_comb begin
	hrg_selected = 1'b0;

	if(hrg_address_window) begin
		case(hrg_mode)
			HRG_MODE_PHANTOM:
				hrg_selected = 1'b1;

			HRG_MODE_BLOCK_SLOT_1:
				hrg_selected = cpu_rw_n ? (block_register[6:4] == 3'd1)	: (block_register[2:0] == 3'd1);

			default:
				hrg_selected = 1'b0;
		endcase
	end
end

endmodule