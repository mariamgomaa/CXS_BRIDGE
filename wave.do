onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group system -color {Slate Blue} /control_unit_tb/DUT/i_control_unit_clk
add wave -noupdate -expand -group system /control_unit_tb/DUT/i_control_unit_rst_n
add wave -noupdate -expand -group control_signal -color {Violet Red} /control_unit_tb/DUT/i_control_unit_fifo_empty
add wave -noupdate -expand -group control_signal -color {Violet Red} /control_unit_tb/DUT/i_control_unit_config_done
add wave -noupdate -expand -group control_signal /control_unit_tb/DUT/o_control_unit_rd_fifo_en
add wave -noupdate -expand -group control_signal /control_unit_tb/DUT/o_control_unit_config_we
add wave -noupdate -expand -group control_signal /control_unit_tb/DUT/o_control_unit_payload_valid
add wave -noupdate -expand -group control_signal /control_unit_tb/DUT/o_control_unit_status_valid
add wave -noupdate -expand -group control_signal /control_unit_tb/DUT/o_control_unit_rd_config_en
add wave -noupdate -expand -group pathes /control_unit_tb/DUT/i_control_unit_fifo_data
add wave -noupdate -expand -group pathes -itemcolor Cyan -subitemconfig {{/control_unit_tb/DUT/i_control_unit_config_data[15]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[14]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[13]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[12]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[11]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[10]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[9]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[8]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[7]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[6]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[5]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[4]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[3]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[2]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[1]} {-itemcolor Cyan} {/control_unit_tb/DUT/i_control_unit_config_data[0]} {-itemcolor Cyan}} /control_unit_tb/DUT/i_control_unit_config_data
add wave -noupdate -expand -group pathes /control_unit_tb/DUT/o_control_unit_address
add wave -noupdate -expand -group pathes /control_unit_tb/DUT/o_control_unit_data
add wave -noupdate -expand -group pathes /control_unit_tb/DUT/o_control_unit_config_data
add wave -noupdate -expand -group pathes /control_unit_tb/DUT/o_control_unit_config_address
add wave -noupdate -expand -group modes /control_unit_tb/DUT/o_control_unit_addr_mode
add wave -noupdate -expand -group modes /control_unit_tb/DUT/o_control_unit_enc_mode
add wave -noupdate -expand -group modes /control_unit_tb/DUT/o_control_unit_parity_mode
add wave -noupdate -expand -group fsm /control_unit_tb/DUT/u_fsm/current_state
add wave -noupdate -expand -group fsm /control_unit_tb/DUT/u_fsm/next_state
add wave -noupdate -radix decimal /control_unit_tb/DUT/u_fsm/device_cnt_rem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53449 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 198
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {49912 ps} {69714 ps}
