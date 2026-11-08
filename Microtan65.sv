//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	`include "sys/emu_ports.vh"
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

// The core supplies unsigned mono audio to both output channels.
assign AUDIO_S   = 0;
assign AUDIO_MIX = 0;

assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[122:121];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
	"Microtan65;;",

	"F1,hex,Load HEX;",
	"F2,m65,Load M65 Snapshot;",
	"F3,mtb,Load MTB Program;",
	"F4,t65,Load T65 Tape;",
	"O[8],Keyboard,ASCII,MT006 Keypad;",
	"O[15],Keyboard Joystick,No,Yes;",

	"-;",

	"P1,Video Settings;",
	"P1O[122:121],Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O[4:3],Display Colour,White,Red,Green,Blue;",

	"P2,Hardware & ROM;",
	"P2O[11:9],Memory,1K,8K,16K,32K,48K;",
	"P2O[20:19],E2 ROM,None,BASIC Toolkit,HRG Toolkit;",
	"P2O[22:21],HRG Card,None,Phantom,Block Slot 1;",
	"P2O[17:16],Sound Hardware,None,Bulldog AY,Space Invasion;",
	"P2O[18],VIA 1,None,Installed;",
	"-;",

	"R[0],Warm Reset;",
	"R[12],Warm Reset & Clear Screen;",
	"R[13],Cold Reset & Clear Screen;",

	"v,5;",
	"V,v",`BUILD_DATE
};

wire forced_scandoubler;
wire [1:0] 		buttons;
wire [127:0] 	status;
wire [31:0] 	joystick_0;
wire [10:0] 	ps2_key;
wire        	ioctl_download;
wire [15:0] 	ioctl_index;
wire        	ioctl_wr;
wire [26:0] 	ioctl_addr;
wire [7:0]	 	ioctl_dout;
wire        	ioctl_wait;
wire        	hex_ioctl_wait;
wire        	m65_ioctl_wait;
wire        	mtb_ioctl_wait;
wire        	t65_ioctl_wait;
wire         	profile_update_request;
wire         	status_update_request;
wire [127:0] 	status_update;

wire [2:0] 		ram_menu_value;
wire [2:0] 		requested_ram_profile;
wire [2:0] 		effective_ram_profile_sys;
wire [2:0] 		profile_update_value;
wire [2:0] 		ram_profile_machine;

wire 			ram_profile_promotion_pending;

wire 			clear_screen_request_machine;
wire 			clear_all_request_machine;

wire        	memory_clear_busy;
wire        	memory_clear_complete;
wire        	memory_clear_all_active;
wire        	memory_clear_write_enable;
wire [15:0] 	memory_clear_write_address;
wire  [7:0] 	memory_clear_write_data;
wire        	memory_clear_attribute_clear;

assign ram_menu_value = status[11:9];
assign status_update_request = profile_update_request;
assign status_update = {status[127:12],	profile_update_value, status[8:0]};

assign ioctl_wait =	hex_ioctl_wait || m65_ioctl_wait ||	mtb_ioctl_wait || t65_ioctl_wait ||	memory_clear_busy;

hps_io #(.CONF_STR(CONF_STR)) hps_io (
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),

	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.joystick_0(joystick_0),

	.status(status),
	.status_in(status_update),
	.status_set(status_update_request),
	.status_menumask(16'd0),
	
	.ps2_key(ps2_key),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait)
);

///////////////////////   CLOCKS   ///////////////////////////////

wire clk_sys;
wire clk_machine;
wire pll_locked;

pll pll (
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_machine),
	.locked(pll_locked)
);

wire reset = RESET | status[0] | buttons[1];
wire machine_reset_async = reset | ~pll_locked;
reg [1:0] machine_reset_sync = 2'b11;

always @(posedge clk_machine or posedge machine_reset_async) begin
	if(machine_reset_async)
		machine_reset_sync <= 2'b11;
	else
		machine_reset_sync <= {machine_reset_sync[0], 1'b0};
end

wire reset_machine = machine_reset_sync[1];

// The clear controller uses the authentic machine reset so that it continues
// running while the processor and other mutable machine state are held reset.
wire reset_machine_state = reset_machine ||	memory_clear_busy;

microtan_clear_request_sync clear_request_sync_inst (
	.destination_clk(clk_machine),
	.destination_reset(reset_machine),

	.source_clear_screen_request(status[12]),
	.source_clear_all_request(status[13]),

	.destination_clear_screen_request(clear_screen_request_machine),
	.destination_clear_all_request(clear_all_request_machine)
);

microtan_memory_clear memory_clear_inst (
	.clk(clk_machine),
	.reset(reset_machine),

	.clear_screen_request(clear_screen_request_machine),
	.clear_all_request(clear_all_request_machine),

	.busy(memory_clear_busy),
	.clear_complete(memory_clear_complete),
	.clear_all_active(memory_clear_all_active),

	.memory_write_enable(memory_clear_write_enable),
	.memory_write_address(memory_clear_write_address),
	.memory_write_data(memory_clear_write_data),

	.attribute_clear_enable(memory_clear_attribute_clear)
);
wire 			ce_6m;
wire 			ce_via;
wire 			via_p2_h;
wire 			ce_cpu;

microtan_timing microtan_timing (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.ce_6m(ce_6m),
	.ce_via(ce_via),
	.via_p2_h(via_p2_h),
	.ce_cpu(ce_cpu)
);

wire [23:0] 	cpu_address;
wire [7:0] 		cpu_data_in;
wire [7:0] 		cpu_data_out;
wire        	cpu_rw_n;
wire        	cpu_sync;

wire hex_download =	ioctl_download && (ioctl_index[5:0] == 6'd1);
wire m65_download =	ioctl_download && (ioctl_index[5:0] == 6'd2);
wire mtb_download =	ioctl_download && (ioctl_index[5:0] == 6'd3);
wire t65_download =	ioctl_download && (ioctl_index[5:0] == 6'd4);
wire hex_download_write = ioctl_wr && hex_download;
wire m65_download_write = ioctl_wr && m65_download;
wire mtb_download_write = ioctl_wr && mtb_download;
wire t65_download_write = ioctl_wr && t65_download;

microtan_ram_menu_decode ram_menu_decode_inst (
	.menu_value(ram_menu_value),
	.ram_profile(requested_ram_profile)
);

microtan_ram_profile_control ram_profile_control_inst (
	.clk(clk_sys),
	.reset(reset),

	.selected_profile(requested_ram_profile),
	.m65_download_active(m65_download),

	.effective_profile(effective_ram_profile_sys),
	.profile_update_request(profile_update_request),
	.profile_update_value(profile_update_value),
	.promotion_pending(ram_profile_promotion_pending)
);

microtan_ram_profile_sync ram_profile_sync_inst (
	.destination_clk(clk_machine),
	.destination_reset(reset_machine),

	.source_profile(effective_ram_profile_sys),

	.destination_profile(ram_profile_machine)
);

wire       		loader_download_active;
wire       		loader_download_write;
wire [7:0] 		loader_download_data;

wire       		m65_loader_download_active;
wire       		m65_loader_download_write;
wire [7:0] 		m65_loader_download_data;

wire       		mtb_loader_download_active;
wire       		mtb_loader_download_write;
wire [7:0] 		mtb_loader_download_data;

wire       		t65_loader_download_active;
wire       		t65_loader_download_write;
wire [7:0] 		t65_loader_download_data;

wire 			t65_validation_complete;
wire 			t65_file_valid;
wire 			t65_cassette_level;
wire t65_playback_start = t65_validation_complete && t65_file_valid;

wire        	normal_cpu_run_enable;
wire        	normal_memory_enable;
wire        	normal_memory_rw_n;
wire [15:0] 	normal_memory_address;
wire [7:0] 		normal_memory_write_data;

wire        	cpu_run_enable;
wire        	memory_enable;
wire        	memory_rw_n;
wire [15:0] 	memory_address;
wire [7:0] 		memory_write_data;
wire        	force_ram_access;

wire        	loader_ownership_conflict;

wire        	hex_machine_owned;
wire        	hex_cpu_run_enable;
wire        	hex_memory_enable;
wire        	hex_memory_rw_n;
wire [15:0] 	hex_memory_address;
wire [7:0] 		hex_memory_write_data;

wire        	m65_machine_owned;
wire        	m65_cpu_run_enable;
wire        	m65_memory_enable;
wire        	m65_memory_rw_n;
wire [15:0] 	m65_memory_address;
wire [7:0] 		m65_memory_write_data;

wire        	mtb_machine_owned;
wire        	mtb_memory_enable;
wire [15:0] 	mtb_memory_address;
wire [7:0] 		mtb_memory_write_data;

wire        	loader_start_valid;
wire [15:0] 	loader_start_address;
wire        	loader_complete;
wire        	loader_format_error;

wire        	m65_attribute_write_valid;
wire [5:0] 		m65_attribute_write_address;
wire [7:0] 		m65_attribute_write_data;

wire        	m65_snapshot_state_pending;
wire        	m65_snapshot_state_ack;
wire [15:0] 	m65_snapshot_pc;
wire [7:0] 		m65_snapshot_p;
wire [7:0] 		m65_snapshot_a;
wire [7:0] 		m65_snapshot_x;
wire [7:0] 		m65_snapshot_y;
wire [7:0] 		m65_snapshot_sp;
wire [63:0] 	m65_snapshot_state_regs;

wire        	m65_loader_complete;
wire        	m65_loader_format_error;

wire        	mtb_state_load_pending;
wire        	mtb_state_load_ack;
wire [63:0] 	mtb_state_regs;

wire        	mtb_loader_complete;
wire        	mtb_loader_success;
wire        	mtb_loader_format_error;
wire        	mtb_loader_configuration_error;

wire        	cpu_state_load;
wire [63:0] 	cpu_state_regs;
wire        	cpu_state_load_ack;
wire        	cpu_state_load_conflict;

assign m65_snapshot_state_regs = {m65_snapshot_pc, 8'h00, m65_snapshot_sp, m65_snapshot_p,
		m65_snapshot_y,	m65_snapshot_x,	m65_snapshot_a};

assign cpu_state_load_conflict = m65_snapshot_state_pending && mtb_state_load_pending;
assign cpu_state_load =	!cpu_state_load_conflict &&	(m65_snapshot_state_pending || mtb_state_load_pending);
assign cpu_state_regs =	mtb_state_load_pending ? mtb_state_regs : m65_snapshot_state_regs;
assign m65_snapshot_state_ack =	cpu_state_load_ack && m65_snapshot_state_pending &&	!mtb_state_load_pending;
assign mtb_state_load_ack =	cpu_state_load_ack && mtb_state_load_pending &&	!m65_snapshot_state_pending;

microtan_ioctl_bridge ioctl_bridge_inst (
	.source_clk(clk_sys),
	.source_reset(reset),
	.source_download_active(hex_download),
	.source_write(hex_download_write),
	.source_data(ioctl_dout),

	.source_wait(hex_ioctl_wait),

	.destination_clk(clk_machine),
	.destination_reset(reset_machine_state),

	.destination_download_active(loader_download_active),
	.destination_write(loader_download_write),
	.destination_data(loader_download_data)
);

microtan_ioctl_bridge m65_ioctl_bridge_inst (
	.source_clk(clk_sys),
	.source_reset(reset),
	.source_download_active(m65_download),
	.source_write(m65_download_write),
	.source_data(ioctl_dout),

	.source_wait(m65_ioctl_wait),

	.destination_clk(clk_machine),
	.destination_reset(reset_machine_state),

	.destination_download_active(m65_loader_download_active),
	.destination_write(m65_loader_download_write),
	.destination_data(m65_loader_download_data)
);

microtan_ioctl_bridge mtb_ioctl_bridge_inst (
	.source_clk(clk_sys),
	.source_reset(reset),
	.source_download_active(mtb_download),
	.source_write(mtb_download_write),
	.source_data(ioctl_dout),

	.source_wait(mtb_ioctl_wait),

	.destination_clk(clk_machine),
	.destination_reset(reset_machine_state),

	.destination_download_active(mtb_loader_download_active),
	.destination_write(mtb_loader_download_write),
	.destination_data(mtb_loader_download_data)
);

microtan_ioctl_bridge t65_ioctl_bridge_inst (
	.source_clk(clk_sys),
	.source_reset(reset),
	.source_download_active(t65_download),
	.source_write(t65_download_write),
	.source_data(ioctl_dout),

	.source_wait(t65_ioctl_wait),

	.destination_clk(clk_machine),
	.destination_reset(reset_machine_state),

	.destination_download_active(t65_loader_download_active),
	.destination_write(t65_loader_download_write),
	.destination_data(t65_loader_download_data)
);

microtan_t65_fast_playback t65_playback_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.ce_750k(ce_cpu),

	.download_active(t65_loader_download_active),
	.byte_valid(t65_loader_download_write),
	.byte_data(t65_loader_download_data),

	.playback_start(t65_playback_start),

	.validation_complete(t65_validation_complete),
	.file_valid(t65_file_valid),
	.format_error(),
	.playback_encoding(),

	.playback_busy(),
	.playback_done(),
	.cassette_level(t65_cassette_level)
);

microtan_hex_loader hex_loader_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.download_active(loader_download_active),
	.download_write(loader_download_write),
	.download_data(loader_download_data),

	.cpu_enable(ce_cpu),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address[15:0]),
	.cpu_write_data(cpu_data_out),

	.cpu_run_enable(hex_cpu_run_enable),
	.machine_owned(hex_machine_owned),

	.memory_enable(hex_memory_enable),
	.memory_rw_n(hex_memory_rw_n),
	.memory_address(hex_memory_address),
	.memory_write_data(hex_memory_write_data),

	.start_valid(loader_start_valid),
	.start_address(loader_start_address),
	.load_complete(loader_complete),
	.format_error(loader_format_error)
);

microtan_m65_loader m65_loader_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.download_active(m65_loader_download_active),
	.download_write(m65_loader_download_write),
	.download_data(m65_loader_download_data),

	.cpu_enable(ce_cpu),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address[15:0]),
	.cpu_write_data(cpu_data_out),

	.cpu_run_enable(m65_cpu_run_enable),
	.machine_owned(m65_machine_owned),

	.memory_enable(m65_memory_enable),
	.memory_rw_n(m65_memory_rw_n),
	.memory_address(m65_memory_address),
	.memory_write_data(m65_memory_write_data),

	.attribute_write_valid(m65_attribute_write_valid),
	.attribute_write_address(m65_attribute_write_address),
	.attribute_write_data(m65_attribute_write_data),

	.snapshot_state_pending(m65_snapshot_state_pending),
	.snapshot_state_ack(m65_snapshot_state_ack),

	.snapshot_pc(m65_snapshot_pc),
	.snapshot_p(m65_snapshot_p),
	.snapshot_a(m65_snapshot_a),
	.snapshot_x(m65_snapshot_x),
	.snapshot_y(m65_snapshot_y),
	.snapshot_sp(m65_snapshot_sp),

	.load_complete(m65_loader_complete),
	.format_error(m65_loader_format_error)
);

microtan_mtb_loader mtb_loader_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.download_active(mtb_loader_download_active),
	.download_write(mtb_loader_download_write),
	.download_data(mtb_loader_download_data),

	.active_ram_profile(ram_profile_machine),

	.machine_owned(mtb_machine_owned),

	.memory_write_valid(mtb_memory_enable),
	.memory_write_address(mtb_memory_address),
	.memory_write_data(mtb_memory_write_data),

	.state_load_pending(mtb_state_load_pending),
	.state_regs(mtb_state_regs),
	.state_load_ack(mtb_state_load_ack),

	.load_complete(mtb_loader_complete),
	.load_success(mtb_loader_success),
	.format_error(mtb_loader_format_error),
	.configuration_error(mtb_loader_configuration_error),

	.payload_length(),
	.first_free(),
	.required_ram_top(),
	.line_count()
);

microtan_multi_loader_arbiter loader_arbiter_inst (
	.cpu_enable(ce_cpu),
	.cpu_rw_n(cpu_rw_n),
	.cpu_address(cpu_address[15:0]),
	.cpu_write_data(cpu_data_out),

	.hex_machine_owned(hex_machine_owned),
	.hex_memory_enable(hex_memory_enable),
	.hex_memory_rw_n(hex_memory_rw_n),
	.hex_memory_address(hex_memory_address),
	.hex_memory_write_data(hex_memory_write_data),

	.m65_machine_owned(m65_machine_owned),
	.m65_memory_enable(m65_memory_enable),
	.m65_memory_rw_n(m65_memory_rw_n),
	.m65_memory_address(m65_memory_address),
	.m65_memory_write_data(m65_memory_write_data),

	.mtb_machine_owned(mtb_machine_owned),
	.mtb_memory_enable(mtb_memory_enable),
	.mtb_memory_rw_n(1'b0),
	.mtb_memory_address(mtb_memory_address),
	.mtb_memory_write_data(mtb_memory_write_data),

	.ownership_conflict(loader_ownership_conflict),
	.cpu_run_enable(normal_cpu_run_enable),

	.memory_enable(normal_memory_enable),
	.memory_rw_n(normal_memory_rw_n),
	.memory_address(normal_memory_address),
	.memory_write_data(normal_memory_write_data)
);

microtan_memory_maintenance_arbiter memory_maintenance_arbiter_inst (
	.normal_cpu_run_enable(normal_cpu_run_enable),
	.normal_memory_enable(normal_memory_enable),
	.normal_memory_rw_n(normal_memory_rw_n),
	.normal_memory_address(normal_memory_address),
	.normal_memory_write_data(normal_memory_write_data),

	.maintenance_machine_owned(memory_clear_busy),
	.maintenance_write_enable(memory_clear_write_enable),
	.maintenance_write_address(memory_clear_write_address),
	.maintenance_write_data(memory_clear_write_data),
	.maintenance_force_ram_access(memory_clear_all_active),

	.cpu_run_enable(cpu_run_enable),
	.memory_enable(memory_enable),
	.memory_rw_n(memory_rw_n),
	.memory_address(memory_address),
	.memory_write_data(memory_write_data),
	.force_ram_access(force_ram_access)
);

wire        	cpu_io_selected;
wire        	tanex_ram_selected;
wire        	tanram_selected;
wire        	tanex_user_io_selected;
wire        	tanex_via0_selected;
wire        	tanex_serial_selected;
wire        	tanex_via1_selected;
wire        	tanex_base_io_selected;
wire        	tanex_basic_rom_selected;
wire        	tanex_e2_rom_selected;
wire        	tanex_xbug_rom_selected;
wire        	graphics_write_mode;
wire        	keyboard_interrupt;
wire        	keyboard_event_strobe;
wire        	keyboard_key_pressed;
wire        	keyboard_key_extended;
wire [7:0] 		keyboard_scan_code;

wire        	keyboard_ascii_strobe;
wire [6:0] 		keyboard_ascii_data;
wire        	keyboard_repeat_active;
wire        	keyboard_repeat_tick;

wire        	keyboard_strobe;
wire [6:0]  	keyboard_data;

wire 			keyboard_joystick_up;
wire 			keyboard_joystick_down;
wire 			keyboard_joystick_left;
wire 			keyboard_joystick_right;
wire 			keyboard_joystick_shift;
wire 			keyboard_joystick_space;
wire 			keyboard_joystick_control;

wire 			joystick_up;
wire 			joystick_down;
wire 			joystick_left;
wire 			joystick_right;
wire 			joystick_shift;
wire 			joystick_space;
wire 			joystick_control;

wire [7:0] 		joystick_port_a_input;
(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg keypad_mode_meta = 1'b0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg keypad_mode_sync = 1'b0;

always @(posedge clk_machine) begin
	if(reset_machine_state) begin
		keypad_mode_meta <= 1'b0;
		keypad_mode_sync <= 1'b0;
	end
	else begin
		keypad_mode_meta <= status[8];
		keypad_mode_sync <= keypad_mode_meta;
	end
end

wire keypad_mode = keypad_mode_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg keyboard_joystick_enabled_meta = 1'b0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg keyboard_joystick_enabled_sync = 1'b0;

always @(posedge clk_machine) begin
	if(reset_machine) begin
		keyboard_joystick_enabled_meta <= 1'b0;
		keyboard_joystick_enabled_sync <= 1'b0;
	end
	else begin
		keyboard_joystick_enabled_meta <= status[15];
		keyboard_joystick_enabled_sync <= keyboard_joystick_enabled_meta;
	end
end

wire keyboard_joystick_enabled = keyboard_joystick_enabled_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] e2_rom_profile_meta = 2'd0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] e2_rom_profile_sync = 2'd0;

always @(posedge clk_machine) begin
	if(reset_machine) begin
		e2_rom_profile_meta <= 2'd0;
		e2_rom_profile_sync <= 2'd0;
	end
	else begin
		e2_rom_profile_meta <= status[20:19];
		e2_rom_profile_sync <= e2_rom_profile_meta;
	end
end

wire basic_toolkit_e2_selected = tanex_e2_rom_selected && (e2_rom_profile_sync == 2'd1);
wire hrg_toolkit_e2_selected = tanex_e2_rom_selected &&	(e2_rom_profile_sync == 2'd2);

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] hrg_mode_meta = 2'd0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] hrg_mode_sync = 2'd0;

always @(posedge clk_machine) begin
	if(reset_machine) begin
		hrg_mode_meta <= 2'd0;
		hrg_mode_sync <= 2'd0;
	end
	else begin
		hrg_mode_meta <= status[22:21];
		hrg_mode_sync <= hrg_mode_meta;
	end
end

wire [1:0] hrg_mode = hrg_mode_sync;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] sound_profile_meta = 2'd0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg [1:0] sound_profile_sync = 2'd0;

always @(posedge clk_machine) begin
	if(reset_machine) begin
		sound_profile_meta <= 2'd0;
		sound_profile_sync <= 2'd0;
	end
	else begin
		sound_profile_meta <= status[17:16];
		sound_profile_sync <= sound_profile_meta;
	end
end

wire bulldog_sound_enabled = (sound_profile_sync == 2'd1);
wire space_invasion_sound_enabled =	(sound_profile_sync == 2'd2);

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg via1_enabled_meta = 1'b0;

(* altera_attribute = {"-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS"} *)
reg via1_enabled_sync = 1'b0;

always @(posedge clk_machine) begin
	if(reset_machine) begin
		via1_enabled_meta <= 1'b0;
		via1_enabled_sync <= 1'b0;
	end
	else begin
		via1_enabled_meta <= status[18];
		via1_enabled_sync <= via1_enabled_meta;
	end
end

wire 				via1_enabled = via1_enabled_sync;

wire [19:0] 		keypad_keys;
wire [6:0] 			keypad_sense;
wire [4:0] 			keypad_drive;
wire        		delayed_nmi_trigger;
wire        		delayed_nmi_n;
wire [7:0] 			cpu_io_read_data;
wire        		cpu_io_read_data_valid;

wire        		via0_irq_n;
wire [7:0] 			via0_read_data;
wire        		via0_read_data_valid;

wire        		via1_irq_n;
wire [7:0] 			via1_read_data;
wire        		via1_read_data_valid;

wire        		bulldog_sound_selected;
wire [7:0] 			bulldog_read_data;
wire        		bulldog_read_data_valid;
wire [10:0] 		bulldog_mixed_sound;
wire [15:0] 		bulldog_audio;
wire [5:1] 			space_invasion_effective_controls;
wire       			space_invasion_compatibility_active;
wire [7:0] 			space_invasion_read_data;
wire       			space_invasion_read_data_valid;
wire [8:0] 			space_invasion_mixed_sound;
wire [15:0] 		space_invasion_audio;
wire [15:0] 		selected_audio;

wire [7:0] 			base_ram_data;
wire        		base_ram_selected;
wire        		base_ram_write_enable;
wire        		graphics_attribute_write_enable;
wire [8:0] 			video_address;
wire [7:0] 			video_data;
wire        		video_graphics;

wire [7:0] 			tanbug_data;
wire        		tanbug_selected;
wire [7:0] 			tanex_basic_rom_data;
wire [7:0] 			tanex_basic_toolkit_e2_data;
wire [7:0] 			tanex_hrg_toolkit_e2_data;
wire [7:0] 			tanex_xbug_rom_data;
wire [7:0] 			expansion_ram_data;
wire        		expansion_ram_data_valid;

wire [7:0] 			hrg_read_data;
wire        		hrg_read_data_valid;
wire        		hrg_selected;
wire        		hrg_pixel;

microtan_tanex_decode tanex_decode_inst (
	.address(memory_address),
	.cpu_rw_n(memory_rw_n),

	.base_ram_selected(base_ram_selected),
	.tanex_ram_selected(tanex_ram_selected),
	.tanram_selected(tanram_selected),

	.user_io_selected(tanex_user_io_selected),
	.via0_selected(tanex_via0_selected),
	.serial_selected(tanex_serial_selected),
	.via1_selected(tanex_via1_selected),
	.base_io_selected(tanex_base_io_selected),

	.basic_rom_selected(tanex_basic_rom_selected),
	.e2_rom_selected(tanex_e2_rom_selected),
	.xbug_rom_selected(tanex_xbug_rom_selected),
	.tanbug_rom_selected(tanbug_selected)
);

microtan_via0 via0_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.via_enable(ce_via),
	.p2_h(via_p2_h),

	.cpu_enable(cpu_run_enable),
	.selected(tanex_via0_selected),
	.cpu_rw_n(cpu_rw_n),
	.register_address(cpu_address[3:0]),
	.write_data(cpu_data_out),

	// The active-low joystick is connected to VIA 0 Port A.
	// Validated cassette playback drives the documented VIA 0 CB2 input.
	// The remaining external VIA inputs are held inactive.
	.ca1_input(1'b1),
	.ca2_input(1'b1),
	.cb1_input(1'b1),
	.cb2_input(t65_cassette_level),
	.port_a_input(joystick_port_a_input),
	.port_b_input(8'hFF),

	.irq_n(via0_irq_n),

	.read_data(via0_read_data),
	.read_data_valid(via0_read_data_valid),

	.ca2_output(),
	.ca2_output_enable_n(),
	.cb1_output(),
	.cb1_output_enable_n(),
	.cb2_output(),
	.cb2_output_enable_n(),

	.port_a_output(),
	.port_a_output_enable_n(),
	.port_b_output(),
	.port_b_output_enable_n()
);

// The optional second TANEX 6522 occupies $BFE0-$BFEF.
// No printer hardware is attached, so external inputs are inactive.
microtan_via0 via1_inst (
	.clk(clk_machine),
	.reset(reset_machine_state || !via1_enabled),

	.via_enable(ce_via),
	.p2_h(via_p2_h),

	.cpu_enable(cpu_run_enable),
	.selected(tanex_via1_selected && via1_enabled),
	.cpu_rw_n(cpu_rw_n),
	.register_address(cpu_address[3:0]),
	.write_data(cpu_data_out),

	.ca1_input(1'b1),
	.ca2_input(1'b1),
	.cb1_input(1'b1),
	.cb2_input(1'b1),
	.port_a_input(8'hFF),
	.port_b_input(8'hFF),

	.irq_n(via1_irq_n),

	.read_data(via1_read_data),
	.read_data_valid(via1_read_data_valid),

	.ca2_output(),
	.ca2_output_enable_n(),
	.cb1_output(),
	.cb1_output_enable_n(),
	.cb2_output(),
	.cb2_output_enable_n(),

	.port_a_output(),
	.port_a_output_enable_n(),
	.port_b_output(),
	.port_b_output_enable_n()
);

// The Bulldog sound board occupies four consecutive ports:
// $BC00/$BC01 for AY 0 and $BC02/$BC03 for AY 1.
assign bulldog_sound_selected =	(cpu_address[15:2] == 14'h2F00);

microtan_bulldog_sound bulldog_sound_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.enabled(bulldog_sound_enabled),

	// ce_cpu is one pulse per 64 cycles of the 48 MHz machine clock,
	// providing the documented 0.75 MHz Bulldog PSG clock.
	.psg_enable(ce_cpu),

	.cpu_enable(cpu_run_enable),
	.selected(bulldog_sound_selected),
	.cpu_rw_n(cpu_rw_n),
	.address(cpu_address[1:0]),
	.write_data(cpu_data_out),

	.read_data(bulldog_read_data),
	.read_data_valid(bulldog_read_data_valid),

	.sound_0(),
	.sound_1(),
	.mixed_sound(bulldog_mixed_sound),
	.sample_0(),
	.sample_1()
);

// Expand the tested eleven-bit unsigned mix to the MiSTer sixteen-bit
// unsigned audio interface without discarding any source bits.
assign bulldog_audio = {bulldog_mixed_sound, 5'b00000};

// The original Space Invasion interface uses $BFF2 bits 1-4.
// The M65 snapshot uses the profile-scoped $BC04 alias.
microtan_space_invasion_control space_invasion_control_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.enabled(space_invasion_sound_enabled),

	.cpu_enable(cpu_run_enable),
	.cpu_address(cpu_address),
	.cpu_rw_n(cpu_rw_n),
	.write_data(cpu_data_out),

	.bff2_controls(keypad_drive[4:1]),

	.effective_controls(space_invasion_effective_controls),
	.compatibility_active(space_invasion_compatibility_active),

	.read_data(space_invasion_read_data),
	.read_data_valid(space_invasion_read_data_valid)
);

microtan_space_invasion_sound space_invasion_sound_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.tick_6m(ce_6m),
	.enabled(space_invasion_sound_enabled),

	.controls(space_invasion_effective_controls),
	.compatibility_active(space_invasion_compatibility_active),

	.heartbeat_wave(),
	.fire_wave(),
	.saucer_wave(),
	.hit_wave(),

	.mixed_sound(space_invasion_mixed_sound)
);

// Preserve all nine mixer bits while scaling the maximum level
// into the sixteen-bit MiSTer audio range.
assign space_invasion_audio = {space_invasion_mixed_sound, 7'b0000000};

assign selected_audio =	bulldog_sound_enabled ? bulldog_audio :	space_invasion_sound_enabled ? space_invasion_audio : 16'd0;
assign AUDIO_L = selected_audio;
assign AUDIO_R = selected_audio;

// TANEX supplies IOE throughout $BFF0-$BFFF, while the currently
// implemented CPU-board functions remain restricted to $BFF0-$BFF3.
assign cpu_io_selected = tanex_base_io_selected && (cpu_address[3:2] == 2'b00);

microtan_keyboard_event keyboard_event_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.ps2_key(ps2_key),

	.event_strobe(keyboard_event_strobe),
	.key_pressed(keyboard_key_pressed),
	.key_extended(keyboard_key_extended),
	.scan_code(keyboard_scan_code)
);

microtan_joystick_keyboard joystick_keyboard_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.event_strobe(keyboard_event_strobe),
	.key_pressed(keyboard_key_pressed),
	.key_extended(keyboard_key_extended),
	.scan_code(keyboard_scan_code),

	.direction_up(keyboard_joystick_up),
	.direction_down(keyboard_joystick_down),
	.direction_left(keyboard_joystick_left),
	.direction_right(keyboard_joystick_right),

	.action_shift(keyboard_joystick_shift),
	.action_space(keyboard_joystick_space),
	.action_control(keyboard_joystick_control)
);

microtan_joystick_controls joystick_controls_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.mister_joystick(joystick_0),
	.keyboard_joystick_enabled(keyboard_joystick_enabled),

	.keyboard_up(keyboard_joystick_up),
	.keyboard_down(keyboard_joystick_down),
	.keyboard_left(keyboard_joystick_left),
	.keyboard_right(keyboard_joystick_right),

	.keyboard_shift(keyboard_joystick_shift),
	.keyboard_space(keyboard_joystick_space),
	.keyboard_control(keyboard_joystick_control),

	.direction_up(joystick_up),
	.direction_down(joystick_down),
	.direction_left(joystick_left),
	.direction_right(joystick_right),

	.action_shift(joystick_shift),
	.action_space(joystick_space),
	.action_control(joystick_control)
);

microtan_joystick_port_a joystick_port_a_inst (
	.direction_up(joystick_up),
	.direction_down(joystick_down),
	.direction_left(joystick_left),
	.direction_right(joystick_right),

	.action_shift(joystick_shift),
	.action_space(joystick_space),
	.action_control(joystick_control),

	.port_a_input(joystick_port_a_input)
);

microtan_keyboard_ascii #(.CAPS_LOCK_DEFAULT(1'b1))
keyboard_ascii_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.event_strobe(keyboard_event_strobe),
	.key_pressed(keyboard_key_pressed),
	.key_extended(keyboard_key_extended),
	.scan_code(keyboard_scan_code),

	.ascii_strobe(keyboard_ascii_strobe),
	.ascii_data(keyboard_ascii_data)
);

microtan_keyboard_repeat_timer keyboard_repeat_timer_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.enable(keyboard_repeat_active),

	.repeat_tick(keyboard_repeat_tick)
);

microtan_keyboard_repeat keyboard_repeat_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),

	.event_strobe(keyboard_event_strobe),
	.key_pressed(keyboard_key_pressed),
	.key_extended(keyboard_key_extended),
	.scan_code(keyboard_scan_code),

	.ascii_strobe(keyboard_ascii_strobe),
	.ascii_data(keyboard_ascii_data),

	.repeat_tick(keyboard_repeat_tick),

	.keyboard_strobe(keyboard_strobe),
	.keyboard_data(keyboard_data),
	.repeat_active(keyboard_repeat_active)
);

microtan_keypad_keys keypad_keys_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.event_strobe(keyboard_event_strobe),
	.key_pressed(keyboard_key_pressed),
	.key_extended(keyboard_key_extended),
	.scan_code(keyboard_scan_code),

	.keypad_keys(keypad_keys)
);

microtan_keypad_matrix keypad_matrix_inst (
	.drive(keypad_drive[3:0]),
	.key_pressed(keypad_keys),

	.sense(keypad_sense)
);

microtan_cpu_io cpu_io_inst (
	.clk(clk_machine),
	.cpu_enable(cpu_run_enable),
	.selected(cpu_io_selected),
	.cpu_rw_n(cpu_rw_n),
	.register_address(cpu_address[1:0]),
	.keyboard_strobe(keyboard_strobe),
	.keyboard_data(keyboard_data),
	.keypad_mode(keypad_mode),
	.keypad_sense(keypad_sense),
	.write_data(cpu_data_out),

	.graphics_write_mode(graphics_write_mode),
	.keyboard_interrupt(keyboard_interrupt),
	.keypad_drive(keypad_drive),
	.read_data(cpu_io_read_data),
	.read_data_valid(cpu_io_read_data_valid)
);

assign delayed_nmi_trigger = cpu_io_selected &&	!cpu_rw_n && (cpu_address[1:0] == 2'b01);

microtan_delayed_nmi delayed_nmi_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.cpu_enable(cpu_run_enable),
	.cpu_sync(cpu_sync),
	.trigger(delayed_nmi_trigger),

	.nmi_n(delayed_nmi_n)
);

assign base_ram_write_enable = memory_enable &&	base_ram_selected && !memory_rw_n;
assign graphics_attribute_write_enable = memory_clear_busy ? memory_clear_attribute_clear :
	(base_ram_write_enable && memory_address[9]);

microtan_base_ram base_ram_inst (
	.clk(clk_machine),
	.address(memory_address[9:0]),
	.write_enable(base_ram_write_enable),
	.data_in(memory_write_data),
	.video_address(video_address),

	.data_out(base_ram_data),
	.video_data_out(video_data)
);

microtan_configured_expansion_ram expansion_ram_inst (
	.clk(clk_machine),
	.cpu_enable(memory_enable),
	.cpu_rw_n(memory_rw_n),
	.address(memory_address),
	.write_data(memory_write_data),

	.ram_profile(ram_profile_machine),
	.force_ram_access(force_ram_access),
	.inhibit_tanram(hrg_selected),

	.tanex_ram_selected(tanex_ram_selected),
	.tanram_selected(tanram_selected),

	.read_data(expansion_ram_data),
	.read_data_valid(expansion_ram_data_valid)
);

microtan_graphics_attribute_ram graphics_attribute_ram_inst (
	.clk(clk_machine),
	.write_enable(graphics_attribute_write_enable),
	.write_address(memory_address[8:0]),
	.graphics_write_mode(memory_clear_busy ? 1'b0 : graphics_write_mode),
	.snapshot_write_enable(m65_attribute_write_valid),
	.snapshot_write_address(m65_attribute_write_address),
	.snapshot_write_data(m65_attribute_write_data),
	.video_address(video_address),

	.video_graphics(video_graphics)
);

microtan_basic_rom tanex_basic_rom_inst (
	.clk(clk_machine),
	.selected(tanex_basic_rom_selected),
	.address(memory_address[13:0]),
	.data(tanex_basic_rom_data)
);

microtan_toolkit_e2_rom tanex_basic_toolkit_e2_rom_inst (
	.clk(clk_machine),
	.selected(basic_toolkit_e2_selected),
	.address(memory_address[10:0]),
	.data(tanex_basic_toolkit_e2_data)
);

microtan_hrg_toolkit_e2_rom tanex_hrg_toolkit_e2_rom_inst (
	.clk(clk_machine),
	.selected(hrg_toolkit_e2_selected),
	.address(memory_address[10:0]),
	.data(tanex_hrg_toolkit_e2_data)
);

microtan_xbug_rom tanex_xbug_rom_inst (
	.clk(clk_machine),
	.selected(tanex_xbug_rom_selected),
	.address(memory_address[10:0]),
	.data(tanex_xbug_rom_data)
);

tanbug_rom tanbug_rom_inst (
	.clk(clk_machine),
	.address(cpu_address[10:0]),
	.data(tanbug_data)
);

// T65 requires its write data to be returned on DI during write cycles.
// E2 reads return the mutually selected Toolkit ROM, or $FF when empty.
// VIA 0 and the optional VIA 1 are implemented; other expansion
// peripherals remain unpopulated.
assign cpu_data_in =
	!cpu_rw_n                       ? cpu_data_out      	   		:
	base_ram_selected               ? base_ram_data        			:
	hrg_read_data_valid             ? hrg_read_data					:
	expansion_ram_data_valid        ? expansion_ram_data   			:
	cpu_io_read_data_valid          ? cpu_io_read_data     			:
	via0_read_data_valid            ? via0_read_data       			:
	via1_read_data_valid            ? via1_read_data          		:
	bulldog_read_data_valid         ? bulldog_read_data       		:
	space_invasion_read_data_valid  ? space_invasion_read_data		:
	tanex_basic_rom_selected        ? tanex_basic_rom_data    		:
	basic_toolkit_e2_selected       ? tanex_basic_toolkit_e2_data	:
	hrg_toolkit_e2_selected         ? tanex_hrg_toolkit_e2_data		:
	tanex_xbug_rom_selected         ? tanex_xbug_rom_data  			:
	tanbug_selected                 ? tanbug_data          			:
	                                  8'hFF;

T65 cpu (
	.Mode(2'b00),
	.BCD_en(1'b1),

	.State_Load(cpu_state_load),
	.State_Regs(cpu_state_regs),
	.State_Load_Ack(cpu_state_load_ack),

	.Res_n(~reset_machine_state),
	.Enable(cpu_run_enable),
	.Clk(clk_machine),

	.Rdy(1'b1),
	.Abort_n(1'b1),
	.IRQ_n((~keyboard_interrupt) & via0_irq_n & (!via1_enabled || via1_irq_n)),
	.NMI_n(delayed_nmi_n),
	.SO_n(1'b1),

	.R_W_n(cpu_rw_n),
	.Sync(cpu_sync),
	.A(cpu_address),
	.DI(cpu_data_in),
	.DO(cpu_data_out)
);

wire [1:0] 		col = status[4:3];

wire [8:0] 		video_raster_x;
wire [8:0] 		video_raster_y;
wire       		video_pixel;
wire       		video_active;
wire       		video_hsync_n;
wire       		video_vsync_n;
wire [7:0] 		video;

microtan_text_video text_video_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.ce_6m(ce_6m),
	.video_data(video_data),
	.video_graphics(video_graphics),

	.raster_x(video_raster_x),
	.raster_y(video_raster_y),
	.video_address(video_address),
	.pixel(video_pixel),
	.active_video(video_active),
	.hsync_n(video_hsync_n),
	.vsync_n(video_vsync_n)
);

microtan_hrg_card hrg_card_inst (
	.clk(clk_machine),
	.reset(reset_machine_state),
	.force_ram_access(force_ram_access),

	.hrg_mode(hrg_mode),

	.cpu_enable(memory_enable),
	.cpu_rw_n(memory_rw_n),
	.cpu_address(memory_address),
	.cpu_write_data(memory_write_data),

	.raster_x(video_raster_x),
	.raster_y(video_raster_y),

	.cpu_read_data(hrg_read_data),
	.cpu_read_data_valid(hrg_read_data_valid),
	.hrg_selected(hrg_selected),
	.block_register(),
	.hrg_pixel(hrg_pixel)
);

assign video = (video_pixel || hrg_pixel) ? 8'hFF : 8'h00;

assign CLK_VIDEO = clk_machine;
assign CE_PIXEL  = ce_6m;
assign VGA_DE = video_active;

// The Microtan timing module exposes active-low sync. The MiSTer core
// interface follows the template's active-high internal convention.
assign VGA_HS = ~video_hsync_n;
assign VGA_VS = ~video_vsync_n;

assign VGA_G = (!col || col == 2) ? video : 8'd0;
assign VGA_R = (!col || col == 1) ? video : 8'd0;
assign VGA_B = (!col || col == 3) ? video : 8'd0;

// Temporary diagnostic: count completed instruction boundaries.
// The divided counter makes CPU activity visible on the MiSTer user LED.
reg [16:0] cpu_activity = 17'd0;

always @(posedge clk_machine) begin
	if(reset_machine)
		cpu_activity <= 17'd0;
	else if(ce_cpu && cpu_sync)
		cpu_activity <= cpu_activity + 17'd1;
end

assign LED_USER = cpu_activity[16];

endmodule
