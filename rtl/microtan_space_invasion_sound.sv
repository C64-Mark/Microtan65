module microtan_space_invasion_rc_oscillator #(parameter integer HALF_PERIOD_TICKS = 1,	parameter logic   IDLE_LEVEL       = 1'b0) (
	input  logic clk,
	input  logic reset,
	input  logic tick,
	input  logic run,
	output logic wave
);

localparam integer COUNTER_WIDTH = (HALF_PERIOD_TICKS <= 1) ? 1 : $clog2(HALF_PERIOD_TICKS);
logic [COUNTER_WIDTH-1:0] counter = {COUNTER_WIDTH{1'b0}};

always_ff @(posedge clk) begin
	if(reset || !run) begin
		counter <= {COUNTER_WIDTH{1'b0}};
		wave    <= IDLE_LEVEL;
	end
	else if(tick) begin
		if(counter == HALF_PERIOD_TICKS - 1) begin
			counter <= {COUNTER_WIDTH{1'b0}};
			wave    <= !wave;
		end
		else begin
			counter <= counter + 1'b1;
		end
	end
end

endmodule


module microtan_space_invasion_sound #(
	// Nominal CD4001/CD4011 astable timing:
	// half-period ticks = 6 MHz * 1.1 * R * C.
	parameter integer FIRE_MOD_HALF_PERIOD_TICKS       = 148_104,
	parameter integer FIRE_CARRIER_HALF_PERIOD_TICKS   = 1_024,
	parameter integer HEART_MOD_HALF_PERIOD_TICKS      = 990_000,
	parameter integer HEART_CARRIER_HALF_PERIOD_TICKS  = 25_436,
	parameter integer SAUCER_MOD_HALF_PERIOD_TICKS     = 210_936,
	parameter integer SAUCER_CARRIER_HALF_PERIOD_TICKS = 2_109
)
(
	input  logic       clk,
	input  logic       reset,
	input  logic       tick_6m,
	input  logic       enabled,
	input  logic [5:1] controls,
	input  logic       compatibility_active,
	output wire        heartbeat_wave,
	output wire        fire_wave,
	output wire        saucer_wave,
	output wire        hit_wave,
	output wire [8:0]  mixed_sound
);

wire heartbeat_run = enabled &&	controls[1];
wire fire_run =	enabled && !controls[2];
wire saucer_run = enabled && controls[3];
wire heartbeat_modulator;
wire heartbeat_carrier;
wire fire_modulator;
wire fire_carrier;
wire saucer_modulator;
wire saucer_carrier;

// Heartbeat: R5/C3 low-frequency modulation and R6/C4 carrier.
microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(HEART_MOD_HALF_PERIOD_TICKS), .IDLE_LEVEL(1'b1))
heartbeat_modulator_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(heartbeat_run),
	.wave(heartbeat_modulator)
);

microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(HEART_CARRIER_HALF_PERIOD_TICKS))
heartbeat_carrier_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(heartbeat_run),
	.wave(heartbeat_carrier)
);

// Fire: R2/C1 low-frequency modulation and R3/C2 carrier.
// The original gated-NOR input is active low.
microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(FIRE_MOD_HALF_PERIOD_TICKS), .IDLE_LEVEL(1'b1))
fire_modulator_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(fire_run),
	.wave(fire_modulator)
);

microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(FIRE_CARRIER_HALF_PERIOD_TICKS))
fire_carrier_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(fire_run),
	.wave(fire_carrier)
);

// Saucer: R8/C5 low-frequency modulation and R10/C6 carrier.
microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(SAUCER_MOD_HALF_PERIOD_TICKS), .IDLE_LEVEL(1'b1))
saucer_modulator_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(saucer_run),
	.wave(saucer_modulator)
);

microtan_space_invasion_rc_oscillator #(.HALF_PERIOD_TICKS(SAUCER_CARRIER_HALF_PERIOD_TICKS))
saucer_carrier_inst (
	.clk(clk),
	.reset(reset),
	.tick(tick_6m),
	.run(saucer_run),
	.wave(saucer_carrier)
);

assign heartbeat_wave =	heartbeat_run && heartbeat_modulator &&	heartbeat_carrier;
assign fire_wave = fire_run && fire_modulator && fire_carrier;
assign saucer_wave = saucer_run && saucer_modulator && saucer_carrier;

// Original bit 4 is the software-generated hit/explosion waveform.
// Compatibility bit 5 is accepted only after BC04 compatibility selection.
assign hit_wave = enabled && (controls[4] || (compatibility_active && controls[5]));

// Relative levels approximate the original summing resistors:
// fire 10K, heartbeat 8.2K, saucer 10K and hit 6.8K.
// Maximum simultaneous output is 319, fitting safely in nine bits.
assign mixed_sound = (heartbeat_wave ? 9'd83  : 9'd0) +	(fire_wave ? 9'd68  : 9'd0) +
	(saucer_wave ? 9'd68  : 9'd0) + (hit_wave ? 9'd100 : 9'd0);

endmodule