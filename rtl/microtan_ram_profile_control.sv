module microtan_ram_profile_control (
	input  logic       clk,
	input  logic       reset,
	input  logic [2:0] selected_profile,
	input  logic       m65_download_active,
	output logic [2:0] effective_profile,
	output logic       profile_update_request,
	output logic [2:0] profile_update_value,
	output logic       promotion_pending
);

localparam logic [2:0] RAM_PROFILE_8K = 3'd0;
localparam logic [2:0] RAM_PROFILE_1K = 3'd1;
localparam logic [2:0] RAM_MENU_8K    = 3'd1;

logic previous_m65_download;

assign effective_profile = promotion_pending ? RAM_PROFILE_8K : selected_profile;

assign profile_update_value = RAM_MENU_8K;

always_ff @(posedge clk) begin
	if(reset) begin
		previous_m65_download  <= 1'b0;
		profile_update_request <= 1'b0;
		promotion_pending      <= 1'b0;
	end
	else begin
		previous_m65_download 	<= m65_download_active;
		profile_update_request 	<= 1'b0;

		if(selected_profile != RAM_PROFILE_1K)
			promotion_pending <= 1'b0;

		if(m65_download_active && !previous_m65_download && (selected_profile == RAM_PROFILE_1K)) begin
			profile_update_request <= 1'b1;
			promotion_pending <= 1'b1;
		end
	end
end

endmodule