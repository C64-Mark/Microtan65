module microtan_delayed_nmi (
	input  logic clk,
	input  logic reset,
	input  logic cpu_enable,
	input  logic cpu_sync,
	input  logic trigger,
	output logic nmi_n
);

logic [1:0] sync_events_remaining;

// The MT001 circuit releases the active-low NMI line when $BFF1 is written, then asserts it after two subsequent 6502 SYNC events.
//
// nmi_n is low after reset, matching the reset state established by the original flip-flop circuit. 
// A $BFF1 trigger raises it before the delayed falling edge is generated.
always_ff @(posedge clk) begin
	if(reset) begin
		sync_events_remaining <= 2'd0;
		nmi_n                 <= 1'b0;
	end
	else if(cpu_enable) begin
		// Trigger has priority. Although a real CPU write cannot also be an opcode-fetch cycle, this makes the behavior deterministic.
		if(trigger) begin
			sync_events_remaining <= 2'd2;
			nmi_n                 <= 1'b1;
		end
		else if(cpu_sync) begin
			if(sync_events_remaining == 2'd2)
				sync_events_remaining <= 2'd1;
			else if(sync_events_remaining == 2'd1) begin
				sync_events_remaining <= 2'd0;
				nmi_n                 <= 1'b0;
			end
		end
	end
end

endmodule