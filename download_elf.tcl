if { ![info exists env(VIVADO_DESIGN_NAME)] } {
    puts "ERROR: Please set the environment variable VIVADO_DESIGN_NAME before running the script"
    return
}
set design_name $::env(VIVADO_DESIGN_NAME)
puts "Using design name: ${design_name}"

# a design might have multiple applications. So the users must choose one to execute
if { ![info exists env(XIL_APP_NAME)] } {
    puts "ERROR: Please set the environment variable XIL_APP_NAME before running the script"
    return
}
set app_name $::env(XIL_APP_NAME)
puts "Using application name: ${app_name}"

connect -url tcp:127.0.0.1:3121
source ./vivado/${design_name}/${design_name}.sdk/hw1/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248470434"} -index 0
loadhw -hw ./vivado/${design_name}/${design_name}.sdk/hw1/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zed 210248470434"} -index 0
stop
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248470434"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248470434"} -index 0
dow ./vivado/${design_name}/${design_name}.sdk/${app_name}/Debug/${app_name}.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zed 210248470434"} -index 0
con
