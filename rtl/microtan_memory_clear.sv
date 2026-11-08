module microtan_memory_clear (
	input  logic        clk,
	input  logic        reset,
	input  logic        clear_screen_request,
	input  logic        clear_all_request,
	output logic        busy,
	output logic        clear_complete,
	output logic        clear_all_active,
	output logic        memory_write_enable,
	output logic [15:0] memory_write_address,
	output logic [7:0]  memory_write_data,
	output logic        attribute_clear_enable
);

localparam logic [15:0] RAM_FIRST_ADDRESS 	= 16'h0000;
localparam logic [15:0] RAM_LAST_ADDRESS  	= 16'hBBFF;
localparam logic [15:0] DISPLAY_FIRST     	= 16'h0200;
localparam logic [15:0] DISPLAY_LAST      	= 16'h03FF;
localparam logic [7:0]  SPACE_CHARACTER  	= 8'h20;

logic [15:0] 	final_address;
logic 			previous_clear_screen_request;
logic 			previous_clear_all_request;

wire clear_screen_start = clear_screen_request && !previous_clear_screen_request;
wire clear_all_start = clear_all_request && !previous_clear_all_request;
wire display_address = (memory_write_address >= DISPLAY_FIRST) && (memory_write_address <= DISPLAY_LAST);

always_comb begin
	memory_write_enable = busy;

	if(display_address)
		memory_write_data = SPACE_CHARACTER;
	else
		memory_write_data = 8'h00;

	attribute_clear_enable = busy && display_address;
end

always_ff @(posedge clk) begin
	if(reset) begin
		busy                          <= 1'b0;
		clear_complete                <= 1'b0;
		clear_all_active              <= 1'b0;
		memory_write_address          <= RAM_FIRST_ADDRESS;
		final_address                 <= RAM_FIRST_ADDRESS;
		previous_clear_screen_request <= 1'b0;
		previous_clear_all_request    <= 1'b0;
	end
	else begin
		previous_clear_screen_request <= clear_screen_request;
		previous_clear_all_request    <= clear_all_request;
		clear_complete                <= 1'b0;

		if(!busy) begin
			// A full clear takes priority if both requests arrive together.
			if(clear_all_start) begin
				busy                 <= 1'b1;
				clear_all_active     <= 1'b1;
				memory_write_address <= RAM_FIRST_ADDRESS;
				final_address        <= RAM_LAST_ADDRESS;
			end
			else if(clear_screen_start) begin
				busy                 <= 1'b1;
				clear_all_active     <= 1'b0;
				memory_write_address <= DISPLAY_FIRST;
				final_address        <= DISPLAY_LAST;
			end
		end
		else if(memory_write_address == final_address) begin
			busy             <= 1'b0;
			clear_complete   <= 1'b1;
			clear_all_active <= 1'b0;
		end
		else begin
			memory_write_address <= memory_write_address + 16'd1;
		end
	end
end

endmodule