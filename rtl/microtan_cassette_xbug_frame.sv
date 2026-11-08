module microtan_cassette_xbug_frame (
	input  logic       clk,
	input  logic       reset,
	input  logic       byte_valid,
	input  logic [7:0] byte_data,
	output logic       byte_ready,
	output logic       busy,
	input  logic       bit_ready,
	output logic       bit_valid,
	output logic       bit_value
);

logic [7:0] latched_data;
logic [3:0] bit_index;

assign byte_ready = !reset && !busy;
assign bit_valid = !reset && busy;

always_comb begin
	case(bit_index)
		4'd0:
			bit_value = 1'b0;
		4'd1:
			bit_value = latched_data[0];
		4'd2:
			bit_value = latched_data[1];
		4'd3:
			bit_value = latched_data[2];
		4'd4:
			bit_value = latched_data[3];
		4'd5:
			bit_value = latched_data[4];
		4'd6:
			bit_value = latched_data[5];
		4'd7:
			bit_value = latched_data[6];
		4'd8:
			bit_value = latched_data[7];
		4'd9:
			bit_value = ~^latched_data;
		default:
			bit_value = 1'b1;
	endcase
end

always_ff @(posedge clk) begin
	if(reset) begin
		busy        	<= 1'b0;
		latched_data 	<= 8'h00;
		bit_index   	<= 4'd0;
	end
	else begin
		if(!busy) begin
			if(byte_valid) begin
				busy         <= 1'b1;
				latched_data <= byte_data;
				bit_index    <= 4'd0;
			end
		end
		else if(bit_ready) begin
			if(bit_index == 4'd12) begin
				busy      <= 1'b0;
				bit_index <= 4'd0;
			end
			else begin
				bit_index <= bit_index + 4'd1;
			end
		end
	end
end

endmodule