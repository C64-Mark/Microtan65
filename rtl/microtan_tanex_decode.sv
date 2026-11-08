module microtan_tanex_decode (
	input  logic [15:0] 	address,
	input  logic        	cpu_rw_n,
	output logic 			base_ram_selected,
	output logic 			tanex_ram_selected,
	output logic 			tanram_selected,
	output logic 			user_io_selected,
	output logic 			via0_selected,
	output logic 			serial_selected,
	output logic 			via1_selected,
	output logic 			base_io_selected,
	output logic 			basic_rom_selected,
	output logic 			e2_rom_selected,
	output logic 			xbug_rom_selected,
	output logic 			tanbug_rom_selected
);

always_comb begin
	base_ram_selected   = 1'b0;
	tanex_ram_selected  = 1'b0;
	tanram_selected     = 1'b0;
	user_io_selected    = 1'b0;
	via0_selected       = 1'b0;
	serial_selected     = 1'b0;
	via1_selected       = 1'b0;
	base_io_selected    = 1'b0;
	basic_rom_selected  = 1'b0;
	e2_rom_selected  	= 1'b0;
	xbug_rom_selected   = 1'b0;
	tanbug_rom_selected = 1'b0;

	if(address <= 16'h03FF)
		base_ram_selected = 1'b1;
	else if(address <= 16'h1FFF)
		tanex_ram_selected = 1'b1;
	else if(address <= 16'hBBFF)
		tanram_selected = 1'b1;
	else if(address <= 16'hBFBF)
		user_io_selected = 1'b1;
	else if(address <= 16'hBFCF)
		via0_selected = 1'b1;
	else if(address <= 16'hBFDF)
		serial_selected = 1'b1;
	else if(address <= 16'hBFEF)
		via1_selected = 1'b1;
	else if(address <= 16'hBFFF)
		base_io_selected = 1'b1;
	else if(address <= 16'hE7FF)
		basic_rom_selected = cpu_rw_n;
	else if(address <= 16'hEFFF)
		e2_rom_selected = cpu_rw_n;
	else if(address <= 16'hF7FF)
		xbug_rom_selected = cpu_rw_n;
	else
		tanbug_rom_selected = cpu_rw_n;
end

endmodule