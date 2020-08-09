if { ![info exists env(VIVADO_DESIGN_NAME)] } {
    puts "ERROR: Please set the environment variable VIVADO_DESIGN_NAME before running the script"
    return
}
set design_name $::env(VIVADO_DESIGN_NAME)
puts "Using design name: ${design_name}"

if { ![info exists env(VIVADO_TOP_NAME)] } {
    puts "WARNING: No top design defined. Using the default top name ${design_name}_wrapper"
    set top_name ${design_name}_wrapper
} else {
  set top_name $::env(VIVADO_TOP_NAME)
  puts "Using top name: ${top_name}"
}

open_project vivado/${design_name}/${design_name}.xpr
update_compile_order -fileset sources_1
open_hw
connect_hw_server
open_hw_target
set_property PROGRAM.FILE ./vivado/${design_name}/${design_name}.runs/impl_1/${top_name}.bit [get_hw_devices xc7z020_1]
current_hw_device [get_hw_devices xc7z020_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z020_1] 0]
set_property PROBES.FILE {} [get_hw_devices xc7z020_1]
set_property FULL_PROBES.FILE {} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
#refresh_hw_device [lindex [get_hw_devices xc7z020_1] 0]
