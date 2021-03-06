ipx::create_abstraction_definition lbl.gov user lbl_localbus_rtl 1.0
ipx::create_bus_definition lbl.gov user lbl_localbus 1.0
set_property xml_file_name C:/Users/qdu/Documents/work/kc705/project_2/lbl_localbus_rtl.xml [ipx::current_busabs]
set_property xml_file_name C:/Users/qdu/Documents/work/kc705/project_2/lbl_localbus.xml [ipx::current_busdef]
set_property bus_type_vlnv lbl.gov:user:lbl_localbus:1.0 [ipx::current_busabs]
ipx::save_abstraction_definition [ipx::current_busabs]
ipx::save_bus_definition [ipx::current_busdef]
ipx::add_bus_abstraction_port lb_clk [ipx::current_busabs]
set_property is_clock true [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
set_property master_presence required [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
set_property slave_presence required [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
set_property slave_direction in [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
set_property master_width 1 [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
set_property slave_width 1 [ipx::get_bus_abstraction_ports lb_clk -of_objects [ipx::current_busabs]]
ipx::add_bus_abstraction_port lb_addr [ipx::current_busabs]
set_property master_width 24 [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property slave_width 24 [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property slave_direction in [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property slave_presence required [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property master_presence required [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property is_address true [ipx::get_bus_abstraction_ports lb_addr -of_objects [ipx::current_busabs]]
set_property is_addressable true [ipx::current_busdef]
ipx::add_bus_abstraction_port lb_data_m2c [ipx::current_busabs]
set_property master_width 32 [ipx::get_bus_abstraction_ports lb_data_m2c -of_objects [ipx::current_busabs]]
set_property slave_width 32 [ipx::get_bus_abstraction_ports lb_data_m2c -of_objects [ipx::current_busabs]]
set_property slave_direction in [ipx::get_bus_abstraction_ports lb_data_m2c -of_objects [ipx::current_busabs]]
set_property is_data true [ipx::get_bus_abstraction_ports lb_data_m2c -of_objects [ipx::current_busabs]]
ipx::add_bus_abstraction_port lb_data_c2m [ipx::current_busabs]
set_property master_width 32 [ipx::get_bus_abstraction_ports lb_data_c2m -of_objects [ipx::current_busabs]]
set_property master_direction in [ipx::get_bus_abstraction_ports lb_data_c2m -of_objects [ipx::current_busabs]]
set_property slave_width 32 [ipx::get_bus_abstraction_ports lb_data_c2m -of_objects [ipx::current_busabs]]
set_property is_data true [ipx::get_bus_abstraction_ports lb_data_c2m -of_objects [ipx::current_busabs]]
ipx::add_bus_abstraction_port lb_ctl_stb [ipx::current_busabs]
set_property master_width 1 [ipx::get_bus_abstraction_ports lb_ctl_stb -of_objects [ipx::current_busabs]]
set_property slave_direction in [ipx::get_bus_abstraction_ports lb_ctl_stb -of_objects [ipx::current_busabs]]
set_property slave_width 1 [ipx::get_bus_abstraction_ports lb_ctl_stb -of_objects [ipx::current_busabs]]
ipx::add_bus_abstraction_port lb_ctl_rd [ipx::current_busabs]
set_property master_width 1 [ipx::get_bus_abstraction_ports lb_ctl_rd -of_objects [ipx::current_busabs]]
set_property slave_width 1 [ipx::get_bus_abstraction_ports lb_ctl_rd -of_objects [ipx::current_busabs]]
set_property slave_direction in [ipx::get_bus_abstraction_ports lb_ctl_rd -of_objects [ipx::current_busabs]]
set_property display_name {LBNL local bus} [ipx::current_busdef]
set_property display_name {LBNL local bus} [ipx::current_busabs]
set_property description {LBNL local bus} [ipx::current_busdef]
ipx::save_bus_definition [ipx::current_busdef]
ipx::save_abstraction_definition [ipx::current_busabs]

set_property IP_REPO_PATHS C:/Users/qdu/Documents/work/kc705/project_2 [current_fileset]
