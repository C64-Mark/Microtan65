module microtan_basic_entry_controller (
	input  logic        clk,
	input  logic        reset,
	input  logic        start,
	output logic        busy,
	output logic        state_load_pending,
	output logic [63:0] state_regs,
	input  logic        state_load_ack,
	output logic        complete,
	output logic        success
);

localparam logic [15:0] TANBUG_BASIC_WARM_TAIL = 16'hFA95;

// T65 State_Regs layout:
// PC[15:0], zero-extension byte, SP, P, Y, X, A.
//
// P=$20 keeps bit 5 set, enables maskable interrupts and leaves decimal mode clear.
// TANBUG's $FA95 path and BASIC's $C558 reinitialization establish the subsequent working state.
localparam logic [63:0] BASIC_ENTRY_STATE = {TANBUG_BASIC_WARM_TAIL, 8'h00,	8'hFE, 8'h20, 8'h00, 8'h00,	8'h00};

assign state_regs =	BASIC_ENTRY_STATE;

always_ff @(posedge clk) begin
	complete <= 1'b0;

	if(reset) begin
		busy               <= 1'b0;
		state_load_pending <= 1'b0;
		complete           <= 1'b0;
		success            <= 1'b0;
	end
	else if(start && !busy) begin
		busy               <= 1'b1;
		state_load_pending <= 1'b1;
		success            <= 1'b0;
	end
	else if(
		state_load_pending && state_load_ack) begin
		busy               <= 1'b0;
		state_load_pending <= 1'b0;
		complete           <= 1'b1;
		success            <= 1'b1;
	end
end

endmodule