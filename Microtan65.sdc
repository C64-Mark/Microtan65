derive_pll_clocks
derive_clock_uncertainty

# core specific constraints

# sys/osd.v writes these slowly changing configuration registers in the
# clk_sys domain and samples them in the video-clock domain. They have no
# cycle-by-cycle timing relationship with clk_video. The standard MiSTer
# constraints already treat equivalent OSD configuration crossings this way.
set_false_path -from {*_osd|osd_enable*}
set_false_path -from {*_osd|info*}
set_false_path -from {*_osd|osd_h[*]}
set_false_path -from {*_osd|osd_t[*]}
set_false_path -from {*_osd|osd_w[*]}

# Aspect-ratio status bits are slowly changing HPS configuration values.
# They drive MiSTer's video metadata and have no cycle-by-cycle relationship
# with the video clock.
set_false_path \
    -from [get_registers {*|hps_io:hps_io|status[121]}]

set_false_path \
    -from [get_registers {*|hps_io:hps_io|status[122]}]

# The MiSTer reset button asynchronously asserts the clk_machine reset
# synchronizer. Reset release is deliberately synchronized by
# machine_reset_sync, so this is not a synchronous recovery path.
set_false_path \
    -from [get_registers {*|hps_io:hps_io|cfg[1]}] \
    -to [get_registers {*|machine_reset_sync[*]}]

# hps_io.video_calc captures video measurements in the video-clock domain
# and exposes stable snapshots through its clk_sys reporting register.
# Exclude only those snapshot-to-report paths, retaining all other analysis.
set_false_path -from {*|video_calc|vid_*} -to {*|video_calc|dout[*]}