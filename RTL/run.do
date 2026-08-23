vlib work
vlog *.sv
vsim -voptargs=+acc work.CXS_SYSTEM_TOP_TB
do wave.do
run -all