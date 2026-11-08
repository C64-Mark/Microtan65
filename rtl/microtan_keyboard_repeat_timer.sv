module microtan_keyboard_repeat_timer #(
	parameter integer CLOCK_HZ  = 48_000_000,
	parameter integer REPEAT_HZ = 21
)
(
	input  logic clk,
	input  logic reset,
	input  logic enable,
	output logic repeat_tick
);

localparam integer TICK_CYCLES = CLOCK_HZ / REPEAT_HZ;
localparam integer COUNTER_WIDTH = (TICK_CYCLES > 1) ? $clog2(TICK_CYCLES) : 1;

logic [COUNTER_WIDTH-1:0] counter;

always_ff @(posedge clk) begin
	if(reset || !enable) begin
		counter     <= {COUNTER_WIDTH{1'b0}};
		repeat_tick <= 1'b0;
	end
	else begin
		repeat_tick <= 1'b0;

		if(counter == TICK_CYCLES - 1) begin
			counter      	<= {COUNTER_WIDTH{1'b0}};
			repeat_tick 	<= 1'b1;
		end
		else begin
			counter <= counter + 1'b1;
		end
	end
end

endmodule