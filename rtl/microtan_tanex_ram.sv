module microtan_tanex_ram (
	input  logic        clk,
	input  logic        selected,
	input  logic [15:0] address,
	input  logic        write_enable,
	input  logic [7:0]  data_in,
	output logic [7:0]  data_out
);

logic [7:0] ram_0400 [0:1023];
logic [7:0] ram_0800 [0:1023];
logic [7:0] ram_0c00 [0:1023];
logic [7:0] ram_1000 [0:1023];
logic [7:0] ram_1400 [0:1023];
logic [7:0] ram_1800 [0:1023];
logic [7:0] ram_1c00 [0:1023];
logic [7:0] data_0400;
logic [7:0] data_0800;
logic [7:0] data_0c00;
logic [7:0] data_1000;
logic [7:0] data_1400;
logic [7:0] data_1800;
logic [7:0] data_1c00;

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd1)) begin
		if(write_enable)
			ram_0400[address[9:0]] <= data_in;

		data_0400 <= ram_0400[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd2)) begin
		if(write_enable)
			ram_0800[address[9:0]] <= data_in;

		data_0800 <= ram_0800[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd3)) begin
		if(write_enable)
			ram_0c00[address[9:0]] <= data_in;

		data_0c00 <= ram_0c00[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd4)) begin
		if(write_enable)
			ram_1000[address[9:0]] <= data_in;

		data_1000 <= ram_1000[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd5)) begin
		if(write_enable)
			ram_1400[address[9:0]] <= data_in;

		data_1400 <= ram_1400[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd6)) begin
		if(write_enable)
			ram_1800[address[9:0]] <= data_in;

		data_1800 <= ram_1800[address[9:0]];
	end
end

always_ff @(posedge clk) begin
	if(selected && (address[12:10] == 3'd7)) begin
		if(write_enable)
			ram_1c00[address[9:0]] <= data_in;

		data_1c00 <= ram_1c00[address[9:0]];
	end
end

always_comb begin
	case(address[12:10])
		3'd1:    data_out = data_0400;
		3'd2:    data_out = data_0800;
		3'd3:    data_out = data_0c00;
		3'd4:    data_out = data_1000;
		3'd5:    data_out = data_1400;
		3'd6:    data_out = data_1800;
		3'd7:    data_out = data_1c00;
		default: data_out = 8'hFF;
	endcase
end

endmodule