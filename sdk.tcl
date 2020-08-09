if { ![info exists env(VIVADO_DESIGN_NAME)] } {
    puts "Please set the environment variable VIVADO_DESIGN_NAME before running the script"
    return
}
set design_name $::env(VIVADO_DESIGN_NAME)
puts "Using design name: ${design_name}"

# Set SDK workspace
setws ./vivado/${design_name}/${design_name}.sdk
# get the file exported by vivado
set hdf_file [glob ./vivado/${design_name}/${design_name}.sdk/*.hdf]
set hdf_file_dir "[file normalize "$hdf_file/"]"
# get the full path 
puts $hdf_file_dir

# Create a HW project
set hw_dir ./vivado/${design_name}/${design_name}.sdk/hw1
if {![file exist $hw_dir]} {
    createhw -name hw1 -hwspec $hdf_file_dir
} else {
    openhw hw1
}
# Create a BSP project
set bsp_dir ./vivado/${design_name}/${design_name}.sdk/bsp1
if {![file exist $bsp_dir]} {
    createbsp -name bsp1 -hwproject hw1 -proc ps7_cortexa9_0 -os standalone
} else {
    openbsp bsp1
}

# Each directory inside the src dir will become and xSDK's Application Project
set list_apps [glob -directory ./src/ -type d *]
puts "$list_apps"
# Now, build each application
foreach app_dir_name $list_apps {
    # get the dir path, split it with '/', and then gets the last item of the list
    # ATTENTION, it will  only work on Linux path. fix it before using for windows
    # perhaps a solution like this is sufficient, although a more OS-independt solution would be preferable
    # https://stackoverflow.com/questions/3261467/run-common-tcl-script-on-windows-and-linux
    set app_prj_name [lindex [split $app_dir_name "/"] end]
    #puts "$app_prj_name"    
    # Create application project
    set app_dir ./vivado/${design_name}/${design_name}.sdk/$app_prj_name
    # if the app were created before, then we skip to the next one
    if {[file exist $app_dir]} {
        continue
    }    
    createapp -name $app_prj_name -hwproject hw1 -bsp bsp1 -proc ps7_cortexa9_0 -os standalone -lang C -app {Empty Application}
    # SDK does not allow to import sources with symbolic links. 
    # https://forums.xilinx.com/t5/Embedded-Development-Tools/xsdk-batch-import-sources-link-to-files/td-p/742063
    # So, it is necessary to import with copy and replace the copy by a symbolic link
    importsources -name $app_prj_name -path $app_dir_name
    # now it's necessary to list the files for their replacement by symbolic links
    set source_files [glob $app_dir_name/*]
    foreach path_file $source_files {
        # get only the file name
        set file_name [file tail $path_file]
        #puts "$file_name"
        exec rm ./vivado/${design_name}/${design_name}.sdk/$app_prj_name/src/$file_name
        exec ln -s ../../../../../src/$app_prj_name/$file_name ./vivado/${design_name}/${design_name}.sdk/$app_prj_name/src/
    }
}

# Build all projects
projects -build

