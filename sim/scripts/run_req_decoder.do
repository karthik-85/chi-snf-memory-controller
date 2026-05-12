vlib work
vlog -sv ../rtl/chi_req_decoder/chi_req_decoder.sv
vlog -sv ../verif/unit/chi_req_decoder/tb_chi_req_decoder.sv
vsim -novopt work.tb_chi_req_decoder
run -all
quit