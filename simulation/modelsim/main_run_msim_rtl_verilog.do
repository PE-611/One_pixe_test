transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/Job/project_quartus/One_pixe_test {D:/Job/project_quartus/One_pixe_test/main.v}
vlog -vlog01compat -work work +incdir+D:/Job/project_quartus/One_pixe_test {D:/Job/project_quartus/One_pixe_test/adc128s022_driver.v}
vlog -vlog01compat -work work +incdir+D:/Job/project_quartus/One_pixe_test {D:/Job/project_quartus/One_pixe_test/uart_tx.v}

vlog -vlog01compat -work work +incdir+D:/Job/project_quartus/One_pixe_test/simulation/modelsim {D:/Job/project_quartus/One_pixe_test/simulation/modelsim/main.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  main_vlg_tst

add wave *
view structure
view signals
run -all
