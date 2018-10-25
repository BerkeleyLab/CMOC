beam1 beam  // auto(cavity_n,2) clk2x

station #(.mode_count(mode_count), .mode_shift(mode_shift), .n_mech_modes(n_mech_modes), .df_scale(df_scale)) cavity // auto(cavity_n,2) clk2x

(* BIDS_description="description of adc_mmcm in top-level" *)
// reg [1:0] adc_mmcm; top-level single-cycle
