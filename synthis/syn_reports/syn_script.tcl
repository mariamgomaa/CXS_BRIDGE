############################################################
# Top Module
############################################################

set top_module CXS_SYSTEM_TOP


############################################################
# Working Library
############################################################

define_design_lib WORK -path ./work


############################################################
# Paths
############################################################

set RTL_DIR /home/ICer/Shared_Folder/CXS_BRIDGE/RTL
set LIB_DIR /home/ICer/Shared_Folder/CXS_BRIDGE/std_cells

lappend search_path $RTL_DIR
lappend search_path $LIB_DIR


############################################################
# Libraries
############################################################

set SSLIB "scmetro_tsmc_cl013g_rvt_ss_1p08v_125c.db"
set TTLIB "scmetro_tsmc_cl013g_rvt_tt_1p2v_25c.db"
set FFLIB "scmetro_tsmc_cl013g_rvt_ff_1p32v_m40c.db"

set target_library [list $SSLIB $TTLIB $FFLIB]
set link_library   [list * $SSLIB $TTLIB $FFLIB]


############################################################
# Analyze RTL
############################################################

puts "############################################################"
puts "################## Analyzing RTL ##########################"
puts "############################################################"
analyze -format sverilog $RTL_DIR/cxscntl_decoder.sv
analyze -format sverilog $RTL_DIR/cxscntl_encoder.sv
analyze -format sverilog $RTL_DIR/header_validitor.sv
analyze -format sverilog $RTL_DIR/address_translation_unit.sv
analyze -format sverilog $RTL_DIR/async_fifo.sv
analyze -format sverilog $RTL_DIR/central_data_memory.sv
analyze -format sverilog $RTL_DIR/config_addr_ctrl.sv
analyze -format sverilog $RTL_DIR/control_unit.sv
analyze -format sverilog $RTL_DIR/control_unit_fsm.sv
analyze -format sverilog $RTL_DIR/CXS_Boundry_Extractor.sv
analyze -format sverilog $RTL_DIR/CXS_Credit_Generator.sv
analyze -format sverilog $RTL_DIR/CXS_flit_receiver.sv
analyze -format sverilog $RTL_DIR/CXS_flit_transmitter.sv
analyze -format sverilog $RTL_DIR/CXS_Link_Control.sv
analyze -format sverilog $RTL_DIR/CXS_Link_Control_TX.sv
analyze -format sverilog $RTL_DIR/CXS_Pkt_Formatter.sv
analyze -format sverilog $RTL_DIR/CXS_RX_TOP.sv
analyze -format sverilog $RTL_DIR/CXS_SYSTEM_TOP.sv
analyze -format sverilog $RTL_DIR/CXS_TOP.sv
analyze -format sverilog $RTL_DIR/CXS_TX_Credit_Counter.sv
analyze -format sverilog $RTL_DIR/CXS_TX_TOP.sv
analyze -format sverilog $RTL_DIR/DATA_SYNC.sv
analyze -format sverilog $RTL_DIR/encryption_unit.sv
analyze -format sverilog $RTL_DIR/Flit_Decoder.sv
analyze -format sverilog $RTL_DIR/header_decoder.sv
analyze -format sverilog $RTL_DIR/parity_unit.sv
analyze -format sverilog $RTL_DIR/RST_SYNCH.sv


############################################################
# Elaborate Top
############################################################

puts "############################################################"
puts "################## Elaborating Top ########################"
puts "############################################################"

elaborate $top_module


############################################################
# Current Design
############################################################

current_design $top_module


############################################################
# Link
############################################################

puts "############################################################"
puts "################## Linking Design #########################"
puts "############################################################"

get_designs *

link


############################################################
# Check Design
############################################################

puts "###############################################"
puts "######## Checking Design Consistency ##########"
puts "###############################################"

check_design


############################################################
# Path Groups
############################################################

puts "###############################################"
puts "################ Path Groups ###################"
puts "###############################################"

group_path -name CXS_IN \
           -from [get_ports i_cxsdata]

group_path -name CXS_OUT \
           -to [get_ports o_CXSDATA]

group_path -name SYSTEM_IN \
           -from [get_ports i_app_rd_en]

group_path -name SYSTEM_OUT \
           -to [get_ports o_app_rd_data]

group_path -name INOUT \
           -from [all_inputs] \
           -to [all_outputs]


############################################################
# Apply Constraints
############################################################

puts "###############################################"
puts "############ Applying Constraints #############"
puts "###############################################"

source -echo ./const.tcl


############################################################
# Mapping and Optimization
############################################################

puts "###############################################"
puts "########## Mapping & Optimization #############"
puts "###############################################"

compile -map_effort high


############################################################
# Reports
############################################################

report_area -hierarchy > area.rpt

report_power -hierarchy > power.rpt

report_timing \
    -max_paths 100 \
    -delay_type min \
    > hold.rpt

report_timing \
    -max_paths 100 \
    -delay_type max \
    > setup.rpt

report_clock -attributes > clocks.rpt

report_constraint -all_violators > constraints.rpt

report_qor > qor.rpt


############################################################
# Netlist
############################################################

write_file \
    -format verilog \
    -hierarchy \
    -output CXS_SYSTEM_TOP_Netlist.v

write_file \
    -format ddc \
    -hierarchy \
    -output CXS_SYSTEM_TOP_Netlist.ddc

write_sdc \
    -nosplit \
    CXS_SYSTEM_TOP.sdc

write_sdf \
    CXS_SYSTEM_TOP.sdf


############################################################
# GUI
############################################################

# gui_start