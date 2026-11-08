module microtan_timing (
	input  logic clk,
	input  logic reset,
	output logic ce_6m,
	output logic ce_via,
	output logic via_p2_h,
	output logic ce_cpu
);

logic [5:0] divider;

always_ff @(posedge clk) begin
	if(reset)
		divider <= 6'd0;
	else
		divider <= divider + 6'd1;
end

assign ce_6m    = !reset && (divider[2:0] == 3'd7);
assign ce_via   = !reset && (divider[3:0] == 4'd15);
assign via_p2_h = !reset && divider[5];
assign ce_cpu   = !reset && (divider == 6'd63);

endmodule