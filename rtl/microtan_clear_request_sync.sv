module microtan_clear_request_sync (
	input  logic destination_clk,
	input  logic destination_reset,
	input  logic source_clear_screen_request,
	input  logic source_clear_all_request,
	output logic destination_clear_screen_request,
	output logic destination_clear_all_request
);

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic [1:0] clear_screen_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic [1:0] clear_all_sync;

assign destination_clear_screen_request = clear_screen_sync[1];
assign destination_clear_all_request = clear_all_sync[1];

always_ff @(posedge destination_clk) begin
	if(destination_reset) begin
		clear_screen_sync <= 2'b00;
		clear_all_sync    <= 2'b00;
	end
	else begin
		clear_screen_sync <= {clear_screen_sync[0],	source_clear_screen_request};
		clear_all_sync <= {clear_all_sync[0], source_clear_all_request};
	end
end

endmodule