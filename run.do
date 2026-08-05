vlib work
vlog *.sv
vsim -voptargs=+acc work.control_unit_tb
do wave.do
run -all