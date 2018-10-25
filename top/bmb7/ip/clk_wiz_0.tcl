proc create_clkwiz_ip {module_name} {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name $module_name
    set_property -dict {
        CONFIG.PRIM_IN_FREQ {50.000}
        CONFIG.CLKOUT2_USED {true}
        CONFIG.CLKOUT3_USED {true}
        CONFIG.CLKOUT4_USED {true}
        CONFIG.PRIMARY_PORT {clk_in}
        CONFIG.CLK_OUT1_PORT {clk_100}
        CONFIG.CLK_OUT2_PORT {clk_200}
        CONFIG.CLK_OUT3_PORT {clk_75_90}
        CONFIG.CLK_OUT4_PORT {clk_150}
        CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000}
        CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {200.000}
        CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {75.000}
        CONFIG.CLKOUT3_REQUESTED_PHASE {90.000}
        CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {150.000}
        CONFIG.CLKIN1_JITTER_PS {200.0}
        CONFIG.MMCM_DIVCLK_DIVIDE {1}

        CONFIG.MMCM_CLKFBOUT_MULT_F {24.000}
        CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.000}
        CONFIG.MMCM_CLKOUT1_DIVIDE {6}
        CONFIG.MMCM_CLKOUT2_DIVIDE {16}
        CONFIG.MMCM_CLKOUT2_PHASE {90.000}
        CONFIG.MMCM_CLKOUT3_DIVIDE {8}
        CONFIG.NUM_OUT_CLKS {4}
        CONFIG.CLKOUT1_JITTER {139.128}
        CONFIG.CLKOUT1_PHASE_ERROR {154.678}
        CONFIG.CLKOUT2_JITTER {124.134}
        CONFIG.CLKOUT2_PHASE_ERROR {154.678}
        CONFIG.CLKOUT3_JITTER {148.365}
        CONFIG.CLKOUT3_PHASE_ERROR {154.678}
        CONFIG.CLKOUT4_JITTER {129.923}
        CONFIG.CLKOUT4_PHASE_ERROR {154.678}

    } [get_ips $module_name]
    generate_target {instantiation_template} [get_files $module_name.xci]
    generate_target all [get_files $module_name.xci]
    create_ip_run [get_files -of_objects [get_fileset sources_1] $module_name.xci]
}

set module_name "clk_wiz_0"

if {[string match "" [get_ips $module_name]]} {
    create_clkwiz_ip $module_name
}

