module microtan_basic_workspace_writer (
	input  logic        clk,
	input  logic        reset,
	input  logic        start,
	input  logic [15:0] first_free,
	input  logic [2:0]  active_ram_profile,
	output logic        busy,
	output logic        write_valid,
	output logic [15:0] write_address,
	output logic [7:0]  write_data,
	output logic        complete,
	output logic        success,
	output logic        configuration_error
);

logic [3:0] 	write_index;
logic [15:0] 	active_ram_top;
logic [15:0] 	latched_first_free;
logic [15:0] 	latched_ram_top;
logic        	configuration_valid;

function automatic logic [15:0] profile_top (
	input logic [2:0] profile
);
begin
	case(profile)
		3'd0:
			profile_top = 16'h2000;
		3'd1:
			profile_top = 16'h0400;
		3'd2:
			profile_top = 16'h4000;
		3'd3:
			profile_top = 16'h8000;
		3'd4:
			profile_top = 16'hBC00;
		default:
			profile_top = 16'h0000;
	endcase
end
endfunction

always_comb begin
	active_ram_top = profile_top(active_ram_profile);
	configuration_valid = (active_ram_top >= 16'h2000) &&
		(first_free >= 16'h0403) && (first_free <= active_ram_top);
end

always_ff @(posedge clk) begin
	write_valid <= 1'b0;
	complete    <= 1'b0;

	if(reset) begin
		write_index        		<= 4'd0;
		latched_first_free 		<= 16'h0000;
		latched_ram_top    		<= 16'h0000;
		busy          			<= 1'b0;
		write_valid   			<= 1'b0;
		write_address 			<= 16'h0000;
		write_data    			<= 8'h00;
		complete            	<= 1'b0;
		success             	<= 1'b0;
		configuration_error 	<= 1'b0;
	end
	else if(start && !busy) begin
		success             	<= 1'b0;
		configuration_error 	<= 1'b0;

		if(configuration_valid) begin
			write_index        	<= 4'd0;
			latched_first_free 	<= first_free;
			latched_ram_top    	<= active_ram_top;
			busy               	<= 1'b1;
		end
		else begin
			busy                <= 1'b0;
			complete            <= 1'b1;
			success             <= 1'b0;
			configuration_error <= 1'b1;
		end
	end
	else if(busy) begin
		write_valid <= 1'b1;

		case(write_index)
			4'd0: begin
				write_address <= 16'h009A;
				write_data    <= 8'h01;
			end

			4'd1: begin
				write_address <= 16'h009B;
				write_data    <= 8'h04;
			end

			4'd2: begin
				write_address <= 16'h009C;
				write_data    <= latched_first_free[7:0];
			end

			4'd3: begin
				write_address <= 16'h009D;
				write_data    <= latched_first_free[15:8];
			end

			4'd4: begin
				write_address <= 16'h009E;
				write_data    <= latched_first_free[7:0];
			end

			4'd5: begin
				write_address <= 16'h009F;
				write_data    <= latched_first_free[15:8];
			end

			4'd6: begin
				write_address <= 16'h00A0;
				write_data    <= latched_first_free[7:0];
			end

			4'd7: begin
				write_address <= 16'h00A1;
				write_data    <= latched_first_free[15:8];
			end

			4'd8: begin
				write_address <= 16'h00A2;
				write_data    <= latched_ram_top[7:0];
			end

			4'd9: begin
				write_address <= 16'h00A3;
				write_data    <= latched_ram_top[15:8];
			end

			default: begin
				write_address <= 16'h0000;
				write_data    <= 8'h00;
			end
		endcase

		if(write_index == 4'd9) begin
			busy     <= 1'b0;
			complete <= 1'b1;
			success  <= 1'b1;
		end
		else begin
			write_index <= write_index + 1'b1;
		end
	end
end

endmodule