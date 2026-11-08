module microtan_m65_decoder (
	input  logic        clk,
	input  logic        reset,
	input  logic        download_active,
	input  logic        byte_valid,
	input  logic [7:0]  byte_data,
	output logic        memory_write_valid,
	output logic [12:0] memory_write_address,
	output logic [7:0]  memory_write_data,
	output logic        attribute_write_valid,
	output logic [5:0]  attribute_write_address,
	output logic [7:0]  attribute_write_data,
	output logic        snapshot_state_valid,
	output logic [15:0] snapshot_pc,
	output logic [7:0]  snapshot_p,
	output logic [7:0]  snapshot_a,
	output logic [7:0]  snapshot_x,
	output logic [7:0]  snapshot_y,
	output logic [7:0]  snapshot_sp,
	output logic        load_complete,
	output logic        format_error
);

localparam logic [27:0] RAM_BYTE_COUNT       	= 28'd8192;
localparam logic [27:0] ATTRIBUTE_BYTE_COUNT 	= 28'd64;
localparam logic [27:0] STATE_BYTE_COUNT     	= 28'd7;
localparam logic [27:0] ATTRIBUTE_BASE       	= RAM_BYTE_COUNT;
localparam logic [27:0] STATE_BASE 				= RAM_BYTE_COUNT + ATTRIBUTE_BYTE_COUNT;
localparam logic [27:0] TOTAL_BYTE_COUNT 		= RAM_BYTE_COUNT + ATTRIBUTE_BYTE_COUNT + STATE_BYTE_COUNT;

logic        download_active_d;
logic [27:0] byte_count;

always_ff @(posedge clk) begin
	memory_write_valid    	<= 1'b0;
	attribute_write_valid 	<= 1'b0;
	snapshot_state_valid  	<= 1'b0;
	load_complete         	<= 1'b0;
	download_active_d 		<= download_active;

	if(reset) begin
		download_active_d 		<= 1'b0;
		byte_count        		<= 28'd0;
		memory_write_address 	<= 13'd0;
		memory_write_data    	<= 8'h00;
		attribute_write_address <= 6'd0;
		attribute_write_data    <= 8'h00;
		snapshot_pc 			<= 16'h0000;
		snapshot_p  			<= 8'h00;
		snapshot_a  			<= 8'h00;
		snapshot_x  			<= 8'h00;
		snapshot_y  			<= 8'h00;
		snapshot_sp 			<= 8'h00;
		format_error 			<= 1'b0;
	end
	else if(download_active && !download_active_d) begin
		byte_count 				<= 28'd0;
		memory_write_address 	<= 13'd0;
		memory_write_data    	<= 8'h00;
		attribute_write_address <= 6'd0;
		attribute_write_data    <= 8'h00;
		snapshot_pc 			<= 16'h0000;
		snapshot_p  			<= 8'h00;
		snapshot_a  			<= 8'h00;
		snapshot_x  			<= 8'h00;
		snapshot_y  			<= 8'h00;
		snapshot_sp 			<= 8'h00;
		format_error 			<= 1'b0;
	end
	else if(!download_active && download_active_d) begin
		load_complete <= 1'b1;

		if((byte_count == TOTAL_BYTE_COUNT) && !format_error)
			snapshot_state_valid <= 1'b1;
		else
			format_error <= 1'b1;
	end
	else if(download_active && byte_valid) begin
		if(byte_count < RAM_BYTE_COUNT) begin
			memory_write_valid   <= 1'b1;
			memory_write_address <= byte_count[12:0];
			memory_write_data    <= byte_data;
		end
		else if(byte_count < STATE_BASE) begin
			attribute_write_valid <= 1'b1;
			attribute_write_address <= byte_count[5:0] - ATTRIBUTE_BASE[5:0];
			attribute_write_data <= byte_data;
		end
		else begin
			case(byte_count)
				STATE_BASE + 28'd0:
					snapshot_pc[7:0] <= byte_data;

				STATE_BASE + 28'd1:
					snapshot_pc[15:8] <= byte_data;

				STATE_BASE + 28'd2:
					snapshot_p <= byte_data;

				STATE_BASE + 28'd3:
					snapshot_a <= byte_data;

				STATE_BASE + 28'd4:
					snapshot_x <= byte_data;

				STATE_BASE + 28'd5:
					snapshot_y <= byte_data;

				STATE_BASE + 28'd6:
					snapshot_sp <= byte_data;

				default:
					format_error <= 1'b1;
			endcase
		end

		byte_count <= byte_count + 1'b1;
	end
end

endmodule