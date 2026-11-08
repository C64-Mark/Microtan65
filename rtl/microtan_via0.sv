module microtan_via0 (
	input  wire       clk,
	input  wire       reset,
	input  wire       via_enable,
	input  wire       p2_h,
	input  wire       cpu_enable,
	input  wire       selected,
	input  wire       cpu_rw_n,
	input  wire [3:0] register_address,
	input  wire [7:0] write_data,
	input  wire       ca1_input,
	input  wire       ca2_input,
	input  wire       cb1_input,
	input  wire       cb2_input,
	input  wire [7:0] port_a_input,
	input  wire [7:0] port_b_input,
	output wire       irq_n,
	output wire [7:0] read_data,
	output wire       read_data_valid,
	output wire       ca2_output,
	output wire       ca2_output_enable_n,
	output wire       cb1_output,
	output wire       cb1_output_enable_n,
	output wire       cb2_output,
	output wire       cb2_output_enable_n,
	output wire [7:0] port_a_output,
	output wire [7:0] port_a_output_enable_n,
	output wire [7:0] port_b_output,
	output wire [7:0] port_b_output_enable_n
);

wire selected_cpu_cycle = selected && cpu_enable;
wire data_output_enable_n;

M6522 via0_inst (
	.I_RS(register_address),
	.I_DATA(write_data),
	.O_DATA(read_data),
	.O_DATA_OE_L(data_output_enable_n),
	.I_RW_L(cpu_rw_n),
	.I_CS1(selected_cpu_cycle),
	.I_CS2_L(!selected_cpu_cycle),
	.O_IRQ_L(irq_n),
	.I_CA1(ca1_input),
	.I_CA2(ca2_input),
	.O_CA2(ca2_output),
	.O_CA2_OE_L(ca2_output_enable_n),
	.I_PA(port_a_input),
	.O_PA(port_a_output),
	.O_PA_OE_L(port_a_output_enable_n),
	.I_CB1(cb1_input),
	.O_CB1(cb1_output),
	.O_CB1_OE_L(cb1_output_enable_n),
	.I_CB2(cb2_input),
	.O_CB2(cb2_output),
	.O_CB2_OE_L(cb2_output_enable_n),
	.I_PB(port_b_input),
	.O_PB(port_b_output),
	.O_PB_OE_L(port_b_output_enable_n),
	.I_P2_H(p2_h),
	.RESET_L(!reset),
	.ENA_4(via_enable),
	.CLK(clk)
);

assign read_data_valid = selected_cpu_cycle && cpu_rw_n && p2_h && !data_output_enable_n;

endmodule