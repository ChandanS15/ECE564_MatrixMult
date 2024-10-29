onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/dut/reset_n
add wave -noupdate /tb_top/dut/clk
add wave -noupdate /tb_top/dut/dut_valid
add wave -noupdate /tb_top/dut/dut_ready
add wave -noupdate -color Cyan -itemcolor Cyan /tb_top/dut/dut__tb__sram_input_write_enable
add wave -noupdate -color Cyan -itemcolor Cyan -radix decimal /tb_top/dut/dut__tb__sram_input_read_address
add wave -noupdate -color Cyan -itemcolor Cyan -radix float32 /tb_top/dut/tb__dut__sram_input_read_data
add wave -noupdate -color Pink -itemcolor Pink /tb_top/dut/dut__tb__sram_weight_write_enable
add wave -noupdate -color Pink -itemcolor Pink -radix decimal /tb_top/dut/dut__tb__sram_weight_read_address
add wave -noupdate -color Pink -itemcolor Pink -radix float32 /tb_top/dut/tb__dut__sram_weight_read_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_enable
add wave -noupdate -radix decimal /tb_top/dut/dut__tb__sram_result_write_address
add wave -noupdate -radix float32 /tb_top/dut/dut__tb__sram_result_write_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_read_address
add wave -noupdate /tb_top/dut/tb__dut__sram_result_read_data
add wave -noupdate -divider {Control signals}
add wave -noupdate /tb_top/dut/compute_complete
add wave -noupdate /tb_top/dut/get_array_size
add wave -noupdate /tb_top/dut/save_array_size
add wave -noupdate -divider FP_MAC
add wave -noupdate -radix float32 /tb_top/dut/FP_MAC/inst_a
add wave -noupdate -radix float32 /tb_top/dut/FP_MAC/inst_b
add wave -noupdate -radix float32 /tb_top/dut/FP_MAC/inst_c
add wave -noupdate /tb_top/dut/FP_MAC/inst_rnd
add wave -noupdate -radix float32 /tb_top/dut/FP_MAC/z_inst
add wave -noupdate /tb_top/dut/FP_MAC/status_inst
add wave -noupdate /tb_top/dut/reset_n
add wave -noupdate /tb_top/dut/clk
add wave -noupdate /tb_top/dut/dut_valid
add wave -noupdate /tb_top/dut/dut_ready
add wave -noupdate /tb_top/dut/dut__tb__sram_input_write_enable
add wave -noupdate /tb_top/dut/dut__tb__sram_input_write_address
add wave -noupdate /tb_top/dut/dut__tb__sram_input_write_data
add wave -noupdate /tb_top/dut/dut__tb__sram_input_read_address
add wave -noupdate /tb_top/dut/tb__dut__sram_input_read_data
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_write_enable
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_write_address
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_write_data
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_read_address
add wave -noupdate /tb_top/dut/tb__dut__sram_weight_read_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_enable
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_address
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_data
add wave -noupdate /tb_top/dut/dut__tb__sram_result_read_address
add wave -noupdate /tb_top/dut/tb__dut__sram_result_read_data
add wave -noupdate /tb_top/dut/globalReadCounter
add wave -noupdate /tb_top/dut/matrixBReadCompleteCycleCompleteSignal
add wave -noupdate /tb_top/dut/matrixAReadCompleteCycleCompleteSignal
add wave -noupdate /tb_top/dut/previous_value
add wave -noupdate /tb_top/dut/current_result
add wave -noupdate /tb_top/dut/mac_result_z
add wave -noupdate /tb_top/dut/computed_result_reg
add wave -noupdate /tb_top/dut/computed_result_wire
add wave -noupdate /tb_top/dut/accumulated_reg
add wave -noupdate /tb_top/dut/matrixAColumns
add wave -noupdate /tb_top/dut/matrixARows
add wave -noupdate /tb_top/dut/matrixBColumns
add wave -noupdate /tb_top/dut/matrixBRows
add wave -noupdate /tb_top/dut/clear_mac_signal
add wave -noupdate /tb_top/dut/clear_mac_signal2
add wave -noupdate /tb_top/dut/dut__tb__sram_input_read_address_reg
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_read_address_reg
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_address_reg
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_data_reg
add wave -noupdate /tb_top/dut/sram_result_write_address_reg
add wave -noupdate /tb_top/dut/matrix_A_read_cycle_counter
add wave -noupdate /tb_top/dut/matrix_A_column_counter
add wave -noupdate /tb_top/dut/matrix_B_read_cycle_counter
add wave -noupdate /tb_top/dut/matrix_B_row_column_counter
add wave -noupdate /tb_top/dut/get_array_size
add wave -noupdate /tb_top/dut/read_addr_sel
add wave -noupdate /tb_top/dut/all_element_read_completed
add wave -noupdate /tb_top/dut/compute_accumulation
add wave -noupdate /tb_top/dut/save_array_size
add wave -noupdate /tb_top/dut/write_enable_sel
add wave -noupdate /tb_top/dut/switch_matrix_A_row_signal
add wave -noupdate /tb_top/dut/sum_w
add wave -noupdate /tb_top/dut/sum_r
add wave -noupdate /tb_top/dut/dut_ready_reg
add wave -noupdate /tb_top/dut/write_enable
add wave -noupdate /tb_top/dut/read_enable
add wave -noupdate /tb_top/dut/compute_complete
add wave -noupdate /tb_top/dut/read_cycle_complete
add wave -noupdate /tb_top/dut/all_write_complete
add wave -noupdate /tb_top/dut/dut__tb__sram_result_write_enable_reg
add wave -noupdate /tb_top/dut/dut__tb__sram_weight_write_enable_reg
add wave -noupdate /tb_top/dut/dut__tb__sram_input_write_enable_reg
add wave -noupdate /tb_top/dut/default_mac_input
add wave -noupdate /tb_top/dut/mac_input_a
add wave -noupdate /tb_top/dut/mac_input_b
add wave -noupdate /tb_top/dut/mac_input_c
add wave -noupdate /tb_top/dut/matrix_A_read_counter
add wave -noupdate /tb_top/dut/matrix_A_read_counter_1
add wave -noupdate /tb_top/dut/matrix_B_read_counter_1
add wave -noupdate /tb_top/dut/matrix_B_read_counter_2
add wave -noupdate /tb_top/dut/global_read_cycle_counter
add wave -noupdate /tb_top/dut/matrixBReadLimit
add wave -noupdate /tb_top/dut/numOfReads
add wave -noupdate /tb_top/dut/numOfWrites
add wave -noupdate /tb_top/dut/matrixAColumnCounter
add wave -noupdate /tb_top/dut/matrixBCounter
add wave -noupdate /tb_top/dut/read_cycle_counter
add wave -noupdate /tb_top/dut/totalNumOfWrites
add wave -noupdate /tb_top/dut/numOfReadsToSwitchOver
add wave -noupdate /tb_top/dut/currentWriteCount
add wave -noupdate /tb_top/dut/matrixASwitchOverLimit
add wave -noupdate /tb_top/dut/matrix_C_result_write_address_reg
add wave -noupdate /tb_top/dut/matrix_A_address
add wave -noupdate /tb_top/dut/matrix_A_col_counter
add wave -noupdate /tb_top/dut/matrix_B_row_repeat_counter
add wave -noupdate /tb_top/dut/matrix_A_row_counter
add wave -noupdate /tb_top/dut/current_state
add wave -noupdate /tb_top/dut/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1436 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 317
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
configure wave -timelineunits ns
update
WaveRestoreZoom {1392 ns} {1506 ns}
