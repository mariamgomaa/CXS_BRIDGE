################################################################################
# CXS SYSTEM TOP CONSTRAINTS
################################################################################


################################################################################
# 1. CLOCK DEFINITIONS
################################################################################

# CXS clock = 27.027 ns
set CXS_CLK_PER 27.027

# System clock = 40 ns
set SYSTEM_CLK_PER 40.0


################################################################################
# 2. CLOCK CREATION
################################################################################

create_clock \
    -name CXS_CLK \
    -period $CXS_CLK_PER \
    -waveform "0 [expr $CXS_CLK_PER/2]" \
    [get_ports i_cxs_clk]


create_clock \
    -name SYSTEM_CLK \
    -period $SYSTEM_CLK_PER \
    -waveform "0 [expr $SYSTEM_CLK_PER/2]" \
    [get_ports i_system_clk]


################################################################################
# 3. CLOCK UNCERTAINTY
################################################################################

set CXS_SETUP_SKEW    0.25
set CXS_HOLD_SKEW     0.05

set SYSTEM_SETUP_SKEW 0.25
set SYSTEM_HOLD_SKEW  0.05


set_clock_uncertainty \
    -setup $CXS_SETUP_SKEW \
    [get_clocks CXS_CLK]

set_clock_uncertainty \
    -hold $CXS_HOLD_SKEW \
    [get_clocks CXS_CLK]


set_clock_uncertainty \
    -setup $SYSTEM_SETUP_SKEW \
    [get_clocks SYSTEM_CLK]

set_clock_uncertainty \
    -hold $SYSTEM_HOLD_SKEW \
    [get_clocks SYSTEM_CLK]


################################################################################
# 4. CLOCK TRANSITION
################################################################################

set_clock_transition -rise 0.1 [get_clocks CXS_CLK]
set_clock_transition -fall 0.1 [get_clocks CXS_CLK]

set_clock_transition -rise 0.1 [get_clocks SYSTEM_CLK]
set_clock_transition -fall 0.1 [get_clocks SYSTEM_CLK]


################################################################################
# 5. CLOCK LATENCY
################################################################################

set_clock_latency 0 [get_clocks CXS_CLK]
set_clock_latency 0 [get_clocks SYSTEM_CLK]


################################################################################
# 6. CLOCK RELATIONSHIP
################################################################################

# CXS_CLK and SYSTEM_CLK are asynchronous.
#
# The asynchronous FIFO handles:
#
#       CXS_CLK
#          |
#          v
#      async FIFO
#          |
#          v
#      SYSTEM_CLK
#
# Therefore timing paths between these two clocks should not be
# analyzed as normal synchronous paths.

set_clock_groups -asynchronous \
    -group [get_clocks CXS_CLK] \
    -group [get_clocks SYSTEM_CLK]


################################################################################
# 7. INPUT DELAYS
################################################################################

# CXS input interface
#
# Inputs:
#   i_cxsdata
#   i_cxscntl
#   i_cxsvalid
#   i_cxsactivereq
#   i_cxscrdrtn
#   i_cxs_cxscrdgnt
#   i_cxs_cxsactiveack

set CXS_IN_DELAY  [expr 0.3 * $CXS_CLK_PER]


set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxsdata]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxscntl]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxsvalid]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxsactivereq]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxscrdrtn]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxs_cxscrdgnt]

set_input_delay \
    $CXS_IN_DELAY \
    -clock CXS_CLK \
    [get_ports i_cxs_cxsactiveack]


################################################################################
# 8. SYSTEM CLOCK INPUT DELAYS
################################################################################

set SYSTEM_IN_DELAY [expr 0.3 * $SYSTEM_CLK_PER]


set_input_delay \
    $SYSTEM_IN_DELAY \
    -clock SYSTEM_CLK \
    [get_ports i_app_rd_en]

set_input_delay \
    $SYSTEM_IN_DELAY \
    -clock SYSTEM_CLK \
    [get_ports i_app_rd_address]

set_input_delay \
    $SYSTEM_IN_DELAY \
    -clock SYSTEM_CLK \
    [get_ports i_app_ack]


################################################################################
# 9. OUTPUT DELAYS
################################################################################

set CXS_OUT_DELAY [expr 0.3 * $CXS_CLK_PER]


set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_cxscrdgnt]

set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_cxsactiveack]

set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_CXSVALID]

set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_CXSDATA]

set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_CXSCNTL]

set_output_delay \
    $CXS_OUT_DELAY \
    -clock CXS_CLK \
    [get_ports o_CXSACTIVEREQ]


################################################################################
# 10. SYSTEM CLOCK OUTPUT
################################################################################

set SYSTEM_OUT_DELAY [expr 0.3 * $SYSTEM_CLK_PER]


set_output_delay \
    $SYSTEM_OUT_DELAY \
    -clock SYSTEM_CLK \
    [get_ports o_app_rd_data]


################################################################################
# 11. DRIVING CELLS
################################################################################

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxsdata]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxscntl]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxsvalid]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxsactivereq]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxs_cxscrdgnt]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_cxs_cxsactiveack]
    
################################################################################
# 12. DRIVING CELLS - SYSTEM CLOCK DOMAIN
################################################################################

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_app_rd_en]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_app_rd_address]

set_driving_cell \
    -library scmetro_tsmc_cl013g_rvt_ss_1p08v_125c \
    -lib_cell BUFX2M \
    -pin Y \
    [get_ports i_app_ack]

################################################################################
# 13. OUTPUT LOAD
################################################################################

set_load 0.5 [get_ports o_cxscrdgnt]
set_load 0.5 [get_ports o_cxsactiveack]

set_load 0.5 [get_ports o_CXSVALID]
set_load 0.5 [get_ports o_CXSDATA]
set_load 0.5 [get_ports o_CXSCNTL]
set_load 0.5 [get_ports o_CXSACTIVEREQ]

set_load 0.5 [get_ports o_app_rd_data]


################################################################################
# 14. DON'T TOUCH CLOCK NETWORK
################################################################################

set_dont_touch_network [get_clocks CXS_CLK]
set_dont_touch_network [get_clocks SYSTEM_CLK]


################################################################################
# 15. OPERATING CONDITIONS
################################################################################

# Setup:
#   Slow library = worst case delay
#
# Hold:
#   Fast library = shortest delay

set_operating_conditions \
    -min_library "scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c" \
    -min "scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c" \
    -max_library "scmetro_tsmc_cl013g_rvt_ss_1p08v_125c" \
    -max "scmetro_tsmc_cl013g_rvt_ss_1p08v_125c"


################################################################################
# 16. CHECK TIMING
################################################################################

check_timing

report_clock

report_clock -skew

report_constraint -all_violators