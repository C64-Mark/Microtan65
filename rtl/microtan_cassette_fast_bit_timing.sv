module microtan_cassette_fast_bit_timing (
	input  logic clk,
	input  logic reset,
	input  logic ce_750k,
	input  logic bit_valid,
	input  logic bit_value,
	output logic bit_ready,
	output logic busy,
	output logic cassette_level
);

localparam logic [8:0] SHORT_HALF_TICKS = 9'd157;
localparam logic [8:0] LONG_HALF_TICKS  = 9'd313;

logic       data_half;
logic       latched_bit;
logic [8:0] ticks_remaining;

assign bit_ready = !reset && !busy;

always_ff @(posedge clk) begin
	if(reset) begin
		busy            <= 1'b0;
		cassette_level  <= 1'b1;
		data_half       <= 1'b0;
		latched_bit     <= 1'b0;
		ticks_remaining <= 9'd0;
	end
	else begin
		if(!busy) begin
			if(bit_valid) begin
				busy            <= 1'b1;
				data_half       <= 1'b0;
				latched_bit     <= bit_value;
				ticks_remaining <= SHORT_HALF_TICKS;
			end
		end
		else if(ce_750k) begin
			if(ticks_remaining == 9'd1) begin
				cassette_level <= !cassette_level;

				if(!data_half) begin
					data_half <= 1'b1;

					if(latched_bit)
						ticks_remaining <= SHORT_HALF_TICKS;
					else
						ticks_remaining <= LONG_HALF_TICKS;
				end
				else begin
					busy            <= 1'b0;
					data_half       <= 1'b0;
					ticks_remaining <= 9'd0;
				end
			end
			else begin
				ticks_remaining <= ticks_remaining - 9'd1;
			end
		end
	end
end

endmodule