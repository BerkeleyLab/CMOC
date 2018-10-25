// Started life cut-and-pasted from lcls2_llrf/firmware/prc/
// but with all digitizer-specific ports chopped away.
// Here purely to resolve the otherwise dangling instantiation in bmb7.v
module application_top(
        input bmb7_U7_clkout,
        input bmb7_U7_clk4xout,
        output [7:0] port_50006_word_k7tos6,
        input [7:0] port_50006_word_s6tok7,
        output port_50006_tx_available,
        input port_50006_rx_available,
        output port_50006_tx_complete,
        input port_50006_rx_complete,
        input port_50006_word_read,
        output [7:0] port_50007_word_k7tos6,
        input [7:0] port_50007_word_s6tok7,
        input port_50007_tx_available,
        input port_50007_rx_available,
        input port_50007_tx_complete,
        input port_50007_rx_complete,
        input port_50007_word_read,
        input s6_to_k7_clk_out,

        output clk200,

        output mmcm_reset,

        output [2:0] D4rgb,
        output [2:0] D5rgb,

        output [3:0] U50_gtrefclk,
        output [3:0] U50_gtrefclkbuf,
        output U50_sysclk,
        output [3:0] U50_soft_reset,
        output [3:0]  U50_gt_txusrrdy,
        output [3:0]  U50_gt_rxusrrdy,
        output [3:0] U50_txusrclk,
        output [3:0] U50_rxusrclk,
        input [3:0] U50_txoutclk,
        input [3:0] U50_rxoutclk,
        output [4*20-1:0] U50_gt_txdata,
        input [4*20-1:0] U50_gt_rxdata,
        input [3:0] U50_rxbyteisaligned,
        output U50_resetl,
        input U50_modprsl,
        output U50_lpmode,
        output U50_modsel,

        output [3:0] U32_gtrefclk,
        output [3:0] U32_gtrefclkbuf,
        output U32_sysclk,
        output [3:0] U32_soft_reset,
        output [3:0]  U32_gt_txusrrdy,
        output [3:0] U32_gt_rxusrrdy,
        output [3:0] U32_txusrclk,
        output [3:0] U32_rxusrclk,
        input [3:0] U32_txoutclk,
        input [3:0] U32_rxoutclk,
        output [4*20-1:0] U32_gt_txdata,
        input [4*20-1:0] U32_gt_rxdata,
        input [3:0] U32_rxbyteisaligned,
        output U32_resetl,
        input U32_modprsl,
        output U32_lpmode,
        output U32_modsel,

        inout QSFP_scl,
        inout QSFP_sda,

        output Y4_oe,
        input Y4_clkp,
        input Y4_clkn,
        input U5_clkp_out,
        input U5_clkn_out,
        input J4_pout,
        input J28_pout,
        input U19_U0P_out,
        input U19_U0N_out
);

endmodule