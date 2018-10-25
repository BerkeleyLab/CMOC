input [31:0] phase_step,  // external
input [11:0] modulo,  // external
input [0:0] trace_reset_we,  // external we-strobe
cav4_freq #(.df_scale(df_scale)) freq  // auto(mode_n,3)
