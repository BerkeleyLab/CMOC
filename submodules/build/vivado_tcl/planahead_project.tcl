# Usage: "planAhead -mode batch -source planAhead_project.tcl -tclargs <platform_name> <project_name> <project_xdc> <source_files>"
if { $argc <3 } {
    puts "Not enough arguments"
    puts "Usage: planAhead -mode batch -source planAhead_project.tcl -tclargs <platform_name> <project_name> <project_xdc> <source_files>"
    exit
}
set my_platform_name [lindex $argv 0]
set my_proj_name [lindex $argv 1]
set my_proj_ucf [lindex $argv 2]
set my_proj_files [lrange $argv 3 end]

project_create $my_platform_name $my_proj_name
project_add_ucf $my_proj_ucf
project_add_files $my_proj_files
project_run_planahead $my_proj_name
