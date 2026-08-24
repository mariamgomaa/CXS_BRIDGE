if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

set block_dirs {
    ATU
    CDC_ASYNCH_FIFO_SYNCHRONIAZER
    CDM
    ENCRYPTION_PARITY
    FLIT_DECODER
    CONTROL_UNIT
    CXS_INTERFACE/CXS_RX
    CXS_INTERFACE/CXS_TX
    CXS_INTERFACE/CXS_TOP
    SYSTEM_TOP
    TEST_BENCH
}


foreach dir $block_dirs {
    set files [glob -nocomplain -directory $dir *.sv]
    if {[llength $files] == 0} {
        puts "WARNING: no .sv files found in $dir"
        continue
    }
    foreach f $files {
        puts "Compiling: $f"
        vlog -sv $f
    }
}

# ------------------------------------------------------------
# 4. Elaborate + load the testbench top
# ------------------------------------------------------------
vsim -voptargs=+acc work.CXS_SYSTEM_TOP_TB

# ------------------------------------------------------------
# 5. Load waveform config and run
# ------------------------------------------------------------
do wave.do
run -all