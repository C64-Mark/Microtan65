module microtan_ioctl_bridge (
	input  logic       source_clk,
	input  logic       source_reset,
	input  logic       source_download_active,
	input  logic       source_write,
	input  logic [7:0] source_data,
	output logic       source_wait,
	input  logic       destination_clk,
	input  logic       destination_reset,
	output logic       destination_download_active,
	output logic       destination_write,
	output logic [7:0] destination_data
);

logic [7:0] source_data_hold;
logic       request_toggle;
logic       request_pending;
logic       source_active_hold;

logic acknowledge_toggle;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic acknowledge_meta;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic acknowledge_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic request_meta;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic request_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic active_meta;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
logic active_sync;

logic request_seen;

assign source_wait = request_pending;
assign source_active_hold = source_download_active || request_pending;

always_ff @(posedge source_clk) begin
	if(source_reset) begin
		source_data_hold 	<= 8'h00;
		request_toggle  	<= 1'b0;
		request_pending 	<= 1'b0;
		acknowledge_meta 	<= 1'b0;
		acknowledge_sync 	<= 1'b0;
	end
	else begin
		acknowledge_meta <= acknowledge_toggle;
		acknowledge_sync <= acknowledge_meta;

		if(request_pending && (acknowledge_sync == request_toggle))
			request_pending <= 1'b0;

		if(source_download_active && source_write && !request_pending) begin
			source_data_hold 	<= source_data;
			request_toggle  	<= !request_toggle;
			request_pending 	<= 1'b1;
		end
	end
end

always_ff @(posedge destination_clk) begin
	if(destination_reset) begin
		request_meta  				<= 1'b0;
		request_sync  				<= 1'b0;
		active_meta   				<= 1'b0;
		active_sync   				<= 1'b0;
		request_seen  				<= 1'b0;
		acknowledge_toggle 			<= 1'b0;
		destination_download_active <= 1'b0;
		destination_write           <= 1'b0;
		destination_data            <= 8'h00;
	end
	else begin
		request_meta 				<= request_toggle;
		request_sync 				<= request_meta;
		active_meta 				<= source_active_hold;
		active_sync 				<= active_meta;
		destination_download_active <= active_sync;
		destination_write           <= 1'b0;

		if(request_sync != request_seen) begin
			request_seen <= request_sync;

			destination_data  	<= source_data_hold;
			destination_write 	<= 1'b1;
			acknowledge_toggle 	<= request_sync;
		end
	end
end

endmodule