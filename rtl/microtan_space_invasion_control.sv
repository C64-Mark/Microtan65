module microtan_space_invasion_control (
	input  logic        clk,
	input  logic        reset,
	input  logic        enabled,
	input  logic        cpu_enable,
	input  logic [15:0] cpu_address,
	input  logic        cpu_rw_n,
	input  logic [7:0]  write_data,

	// Original hardware controls from $BFF2 bits 4-1.
	input  logic [4:1]  bff2_controls,

	// Raw effective controls. Bit 5 exists only for the retained $BC04 compatibility snapshot.
	output wire  [5:1] effective_controls,
	output wire        compatibility_active,
	output wire [7:0]  read_data,
	output wire        read_data_valid
);

logic [7:0] compatibility_register = 8'h00;
logic       compatibility_selected = 1'b0;
logic       original_selected      = 1'b0;

wire compatibility_address_selected = (cpu_address == 16'hBC04);
wire original_address_selected = (cpu_address == 16'hBFF2);
wire selected_compatibility_cycle =	enabled && cpu_enable && compatibility_address_selected;
wire compatibility_write_cycle = selected_compatibility_cycle && !cpu_rw_n;
wire original_write_cycle = enabled && cpu_enable && !cpu_rw_n && original_address_selected;

// TANBUG initializes the ordinary keypad latch with $00 followed by $1F.
// Neither value means that the optional sound unit has deliberately been claimed.
// The published Space Invasion program's first write is $01.
wire original_claim_write =	original_write_cycle &&	(write_data[4:0] != 5'b00000) && (write_data[4:0] != 5'b11111);

always_ff @(posedge clk) begin
	if(reset || !enabled) begin
		compatibility_register <= 8'h00;
		compatibility_selected <= 1'b0;
		original_selected      <= 1'b0;
	end
	else if(compatibility_write_cycle) begin
		compatibility_register <= write_data;
		compatibility_selected <= 1'b1;
		original_selected      <= 1'b0;
	end
	else if(original_claim_write && !compatibility_selected) begin
		original_selected <= 1'b1;
	end
end

assign compatibility_active = enabled && compatibility_selected;

// The unclaimed value is silent: heartbeat, saucer and hit are low,
// while the documented active-low fire control is held high.
assign effective_controls =	!enabled ? 5'b00000 : compatibility_selected ? compatibility_register[5:1] :
	original_selected ? {1'b0, bff2_controls} : 5'b00010;

assign read_data_valid = selected_compatibility_cycle && cpu_rw_n;
assign read_data = read_data_valid ? compatibility_register : 8'hFF;

endmodule