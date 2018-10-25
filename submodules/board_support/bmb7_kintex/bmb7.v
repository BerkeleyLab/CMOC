module bmb7 (output [2:0] bus_bmb7_D4,
output [2:0] bus_bmb7_D5,
output [159:0] bus_bmb7_J103,
output [67:0] bus_bmb7_J106,
inout [0:0] bus_bmb7_J28,
inout [0:0] bus_bmb7_J4,
inout [1:0] bus_bmb7_U19,
inout [22:0] bus_bmb7_U32,
inout [1:0] bus_bmb7_U5,
inout [22:0] bus_bmb7_U50,
inout [18:0] bus_bmb7_U7,
inout [2:0] bus_bmb7_Y4);


wire J4_pout;
SMP bmb7_J4(.PIN(bus_bmb7_J4[0])
,.pout(J4_pout)
);

wire J28_pout;
SMP bmb7_J28(.PIN(bus_bmb7_J28[0])
,.pout(J28_pout)
);

wire U5_clkp_out,U5_clkn_out;
SI571 bmb7_U5(.CLKN(bus_bmb7_U5[1]),.CLKP(bus_bmb7_U5[0])
,.clkp_out(U5_clkp_out)
,.clkn_out(U5_clkn_out)
);

wire Y4_oe,Y4_clkp,Y4_clkn;
SIT9122 bmb7_Y4(.OE_ST(bus_bmb7_Y4[0]),.OUTN(bus_bmb7_Y4[1]),.OUTP(bus_bmb7_Y4[2])
,.oe(Y4_oe)
,.clkp(Y4_clkp)
,.clkn(Y4_clkn)
);

wire U19_U0P_out,U19_U0N_out;
CDCE62005 bmb7_U19(.U0N(bus_bmb7_U19[0]),.U0P(bus_bmb7_U19[1])
,.U0P_out(U19_U0P_out)
,.U0N_out(U19_U0N_out)
);

wire [2:0] bmb7_D4_rgb;
triled bmb7_D4(.BLUE(bus_bmb7_D4[0]),.GREEN(bus_bmb7_D4[2]),.RED(bus_bmb7_D4[1])
,.rgb(bmb7_D4_rgb)
);

wire [2:0] bmb7_D5_rgb;
triled bmb7_D5(.BLUE(bus_bmb7_D5[0]),.GREEN(bus_bmb7_D5[1]),.RED(bus_bmb7_D5[2])
,.rgb(bmb7_D5_rgb)
);

wire [3:0] U50_gtrefclk, U50_gtrefclkbuf,U50_gt_txusrrdy,U50_gt_rxusrrdy, U50_txusrclk,U50_rxusrclk, U50_txoutclk,U50_rxoutclk;
wire U50_sysclk, U50_resetl,U50_modprsl,U50_lpmode,U50_modsel;
wire [3:0] U50_soft_reset;
wire [4*20-1:0] U50_gt_txdata, U50_gt_rxdata;
wire [3:0] U50_rxbyteisaligned;

QSFP bmb7_U50(.IntL(bus_bmb7_U50[12]),.LPMode(bus_bmb7_U50[19]),.ModPrsL(bus_bmb7_U50[20]),.ModSelL(bus_bmb7_U50[6]),.ResetL(bus_bmb7_U50[5]),.Rx1n(bus_bmb7_U50[7]),.Rx1p(bus_bmb7_U50[14]),.Rx2n(bus_bmb7_U50[1]),.Rx2p(bus_bmb7_U50[16]),.Rx3n(bus_bmb7_U50[3]),.Rx3p(bus_bmb7_U50[4]),.Rx4n(bus_bmb7_U50[10]),.Rx4p(bus_bmb7_U50[18]),.Tx1n(bus_bmb7_U50[22]),.Tx1p(bus_bmb7_U50[21]),.Tx2n(bus_bmb7_U50[8]),.Tx2p(bus_bmb7_U50[0]),.Tx3n(bus_bmb7_U50[17]),.Tx3p(bus_bmb7_U50[13]),.Tx4n(bus_bmb7_U50[15]),.Tx4p(bus_bmb7_U50[9])
,.gtrefclk(U50_gtrefclk)
,.gtrefclkbuf(U50_gtrefclkbuf)
,.sysclk(U50_sysclk)
,.soft_reset(U50_soft_reset)
,.gt_txusrrdy(U50_gt_txusrrdy)
,.gt_rxusrrdy(U50_gt_rxusrrdy)
,.txusrclk(U50_txusrclk)
,.rxusrclk(U50_rxusrclk)
,.txoutclk(U50_txoutclk)
,.rxoutclk(U50_rxoutclk)
,.gt_txdata(U50_gt_txdata)
,.gt_rxdata(U50_gt_rxdata)
,.rxbyteisaligned(U50_rxbyteisaligned)
,.resetl(U50_resetl)
,.modprsl(U50_modprsl)
,.lpmode(U50_lpmode)
,.modsel(U50_modsel)
);

wire [3:0] U32_gtrefclk, U32_gtrefclkbuf,U32_gt_txusrrdy,U32_gt_rxusrrdy,U32_txusrclk,U32_rxusrclk,U32_txoutclk,U32_rxoutclk;
wire U32_sysclk, U32_resetl,U32_modprsl,U32_lpmode,U32_modsel;
wire [3:0] U32_soft_reset;
wire [4*20-1:0] U32_gt_txdata, U32_gt_rxdata;
wire [3:0] U32_rxbyteisaligned;

QSFP bmb7_U32(.IntL(bus_bmb7_U32[20]),.LPMode(bus_bmb7_U32[8]),.ModPrsL(bus_bmb7_U32[9]),.ModSelL(bus_bmb7_U32[16]),.ResetL(bus_bmb7_U32[21]),.Rx1n(bus_bmb7_U32[11]),.Rx1p(bus_bmb7_U32[0]),.Rx2n(bus_bmb7_U32[14]),.Rx2p(bus_bmb7_U32[12]),.Rx3n(bus_bmb7_U32[10]),.Rx3p(bus_bmb7_U32[1]),.Rx4n(bus_bmb7_U32[15]),.Rx4p(bus_bmb7_U32[18]),.Tx1n(bus_bmb7_U32[13]),.Tx1p(bus_bmb7_U32[17]),.Tx2n(bus_bmb7_U32[6]),.Tx2p(bus_bmb7_U32[19]),.Tx3n(bus_bmb7_U32[7]),.Tx3p(bus_bmb7_U32[5]),.Tx4n(bus_bmb7_U32[22]),.Tx4p(bus_bmb7_U32[2])
,.gtrefclk(U32_gtrefclk)
,.gtrefclkbuf(U32_gtrefclkbuf)
,.sysclk(U32_sysclk)
,.soft_reset(U32_soft_reset)
,.gt_txusrrdy(U32_gt_txusrrdy)
,.gt_rxusrrdy(U32_gt_rxusrrdy)
,.txusrclk(U32_txusrclk)
,.rxusrclk(U32_rxusrclk)
,.txoutclk(U32_txoutclk)
,.rxoutclk(U32_rxoutclk)
,.gt_txdata(U32_gt_txdata)
,.gt_rxdata(U32_gt_rxdata)
,.rxbyteisaligned(U32_rxbyteisaligned)
,.resetl(U32_resetl)
,.modprsl(U32_modprsl)
,.lpmode(U32_lpmode)
,.modsel(U32_modsel)
);

wire bmb7_U7_clkout,bmb7_U7_clk4xout;
wire [7:0] port_50006_word_k7tos6,port_50007_word_k7tos6,port_50007_word_s6tok7,port_50006_word_s6tok7;
wire port_50006_word_read, port_50007_word_read, port_50006_tx_available,port_50006_tx_complete, port_50007_tx_available,port_50007_tx_complete,port_50006_rx_available,port_50006_rx_complete, port_50007_rx_available,port_50007_rx_complete,s6_to_k7_clk_out;
k7_s6 bmb7_U7(.K7_S6_IO_0(bus_bmb7_U7[11]),.K7_S6_IO_1(bus_bmb7_U7[16]),.K7_S6_IO_10(bus_bmb7_U7[6]),.K7_S6_IO_11(bus_bmb7_U7[9]),.K7_S6_IO_2(bus_bmb7_U7[17]),.K7_S6_IO_3(bus_bmb7_U7[7]),.K7_S6_IO_4(bus_bmb7_U7[14]),.K7_S6_IO_5(bus_bmb7_U7[8]),.K7_S6_IO_6(bus_bmb7_U7[12]),.K7_S6_IO_7(bus_bmb7_U7[0]),.K7_S6_IO_8(bus_bmb7_U7[2]),.K7_S6_IO_9(bus_bmb7_U7[5]),.K7_TO_S6_CLK_0(bus_bmb7_U7[15]),.K7_TO_S6_CLK_1(bus_bmb7_U7[4]),.K7_TO_S6_CLK_2(bus_bmb7_U7[18]),.S6_TO_K7_CLK_0(bus_bmb7_U7[13]),.S6_TO_K7_CLK_1(bus_bmb7_U7[3]),.S6_TO_K7_CLK_2(bus_bmb7_U7[1]),.S6_TO_K7_CLK_3(bus_bmb7_U7[10])
,.s6_to_k7_clk_out(s6_to_k7_clk_out)
,.port_50006_word_k7tos6(port_50006_word_k7tos6)
,.port_50006_word_s6tok7(port_50006_word_s6tok7)
,.port_50006_tx_available(port_50006_tx_available)
,.port_50006_tx_complete(port_50006_tx_complete)
,.port_50006_rx_available(port_50006_rx_available)
,.port_50006_rx_complete(port_50006_rx_complete)
,.port_50006_word_read(port_50006_word_read)
,.port_50007_word_k7tos6(port_50007_word_k7tos6)
,.port_50007_word_s6tok7(port_50007_word_s6tok7)
,.port_50007_tx_available(port_50007_tx_available)
,.port_50007_tx_complete(port_50007_tx_complete)
,.port_50007_rx_available(port_50007_rx_available)
,.port_50007_rx_complete(port_50007_rx_complete)
,.port_50007_word_read(port_50007_word_read)
,.clkout(bmb7_U7_clkout)
,.clk4xout(bmb7_U7_clk4xout)
);
fmc_lpc bmb7_J106(.LA00_N_CC(bus_bmb7_J106[13]),.LA00_P_CC(bus_bmb7_J106[2]),.LA01_N_CC(bus_bmb7_J106[65]),.LA01_P_CC(bus_bmb7_J106[35]),.LA02_N(bus_bmb7_J106[17]),.LA02_P(bus_bmb7_J106[14]),.LA03_N(bus_bmb7_J106[26]),.LA03_P(bus_bmb7_J106[48]),.LA04_N(bus_bmb7_J106[38]),.LA04_P(bus_bmb7_J106[54]),.LA05_N(bus_bmb7_J106[3]),.LA05_P(bus_bmb7_J106[42]),.LA06_N(bus_bmb7_J106[5]),.LA06_P(bus_bmb7_J106[29]),.LA07_N(bus_bmb7_J106[58]),.LA07_P(bus_bmb7_J106[55]),.LA08_N(bus_bmb7_J106[24]),.LA08_P(bus_bmb7_J106[22]),.LA09_N(bus_bmb7_J106[31]),.LA09_P(bus_bmb7_J106[28]),.LA10_N(bus_bmb7_J106[57]),.LA10_P(bus_bmb7_J106[43]),.LA11_N(bus_bmb7_J106[15]),.LA11_P(bus_bmb7_J106[11]),.LA12_N(bus_bmb7_J106[59]),.LA12_P(bus_bmb7_J106[61]),.LA13_N(bus_bmb7_J106[19]),.LA13_P(bus_bmb7_J106[18]),.LA14_N(bus_bmb7_J106[10]),.LA14_P(bus_bmb7_J106[52]),.LA15_N(bus_bmb7_J106[45]),.LA15_P(bus_bmb7_J106[67]),.LA16_N(bus_bmb7_J106[34]),.LA16_P(bus_bmb7_J106[32]),.LA17_N_CC(bus_bmb7_J106[16]),.LA17_P_CC(bus_bmb7_J106[7]),.LA18_N_CC(bus_bmb7_J106[66]),.LA18_P_CC(bus_bmb7_J106[63]),.LA19_N(bus_bmb7_J106[37]),.LA19_P(bus_bmb7_J106[27]),.LA20_N(bus_bmb7_J106[60]),.LA20_P(bus_bmb7_J106[51]),.LA21_N(bus_bmb7_J106[53]),.LA21_P(bus_bmb7_J106[64]),.LA22_N(bus_bmb7_J106[33]),.LA22_P(bus_bmb7_J106[23]),.LA23_N(bus_bmb7_J106[4]),.LA23_P(bus_bmb7_J106[12]),.LA24_N(bus_bmb7_J106[0]),.LA24_P(bus_bmb7_J106[25]),.LA25_N(bus_bmb7_J106[8]),.LA25_P(bus_bmb7_J106[62]),.LA26_N(bus_bmb7_J106[41]),.LA26_P(bus_bmb7_J106[50]),.LA27_N(bus_bmb7_J106[46]),.LA27_P(bus_bmb7_J106[39]),.LA28_N(bus_bmb7_J106[20]),.LA28_P(bus_bmb7_J106[44]),.LA29_N(bus_bmb7_J106[30]),.LA29_P(bus_bmb7_J106[47]),.LA30_N(bus_bmb7_J106[40]),.LA30_P(bus_bmb7_J106[49]),.LA31_N(bus_bmb7_J106[9]),.LA31_P(bus_bmb7_J106[6]),.LA32_N(bus_bmb7_J106[21]),.LA32_P(bus_bmb7_J106[56]),.LA33_N(bus_bmb7_J106[1]),.LA33_P(bus_bmb7_J106[36]));
fmc_hpc bmb7_J103(.HA00_N_CC(bus_bmb7_J103[143]),.HA00_P_CC(bus_bmb7_J103[59]),.HA01_N_CC(bus_bmb7_J103[109]),.HA01_P_CC(bus_bmb7_J103[153]),.HA02_N(bus_bmb7_J103[81]),.HA02_P(bus_bmb7_J103[142]),.HA03_N(bus_bmb7_J103[114]),.HA03_P(bus_bmb7_J103[100]),.HA04_N(bus_bmb7_J103[65]),.HA04_P(bus_bmb7_J103[26]),.HA05_N(bus_bmb7_J103[58]),.HA05_P(bus_bmb7_J103[17]),.HA06_N(bus_bmb7_J103[158]),.HA06_P(bus_bmb7_J103[92]),.HA07_N(bus_bmb7_J103[23]),.HA07_P(bus_bmb7_J103[28]),.HA08_N(bus_bmb7_J103[154]),.HA08_P(bus_bmb7_J103[121]),.HA09_N(bus_bmb7_J103[73]),.HA09_P(bus_bmb7_J103[129]),.HA10_N(bus_bmb7_J103[80]),.HA10_P(bus_bmb7_J103[24]),.HA11_N(bus_bmb7_J103[122]),.HA11_P(bus_bmb7_J103[108]),.HA12_N(bus_bmb7_J103[66]),.HA12_P(bus_bmb7_J103[30]),.HA13_N(bus_bmb7_J103[74]),.HA13_P(bus_bmb7_J103[4]),.HA14_N(bus_bmb7_J103[118]),.HA14_P(bus_bmb7_J103[83]),.HA15_N(bus_bmb7_J103[0]),.HA15_P(bus_bmb7_J103[34]),.HA16_N(bus_bmb7_J103[90]),.HA16_P(bus_bmb7_J103[110]),.HA17_N_CC(bus_bmb7_J103[128]),.HA17_P_CC(bus_bmb7_J103[49]),.HA18_N(bus_bmb7_J103[136]),.HA18_P(bus_bmb7_J103[15]),.HA19_N(bus_bmb7_J103[60]),.HA19_P(bus_bmb7_J103[86]),.HA20_N(bus_bmb7_J103[104]),.HA20_P(bus_bmb7_J103[149]),.HA21_N(bus_bmb7_J103[146]),.HA21_P(bus_bmb7_J103[6]),.HA22_N(bus_bmb7_J103[84]),.HA22_P(bus_bmb7_J103[133]),.HA23_N(bus_bmb7_J103[124]),.HA23_P(bus_bmb7_J103[125]),.HB00_N_CC(bus_bmb7_J103[62]),.HB00_P_CC(bus_bmb7_J103[46]),.HB01_N(bus_bmb7_J103[61]),.HB01_P(bus_bmb7_J103[67]),.HB02_N(bus_bmb7_J103[117]),.HB02_P(bus_bmb7_J103[3]),.HB03_N(bus_bmb7_J103[36]),.HB03_P(bus_bmb7_J103[88]),.HB04_N(bus_bmb7_J103[112]),.HB04_P(bus_bmb7_J103[25]),.HB05_N(bus_bmb7_J103[147]),.HB05_P(bus_bmb7_J103[113]),.HB06_N_CC(bus_bmb7_J103[71]),.HB06_P_CC(bus_bmb7_J103[51]),.HB07_N(bus_bmb7_J103[139]),.HB07_P(bus_bmb7_J103[157]),.HB08_N(bus_bmb7_J103[37]),.HB08_P(bus_bmb7_J103[135]),.HB09_N(bus_bmb7_J103[132]),.HB09_P(bus_bmb7_J103[126]),.HB10_N(bus_bmb7_J103[69]),.HB10_P(bus_bmb7_J103[91]),.HB11_N(bus_bmb7_J103[76]),.HB11_P(bus_bmb7_J103[16]),.HB12_N(bus_bmb7_J103[89]),.HB12_P(bus_bmb7_J103[159]),.HB13_N(bus_bmb7_J103[102]),.HB13_P(bus_bmb7_J103[96]),.HB14_N(bus_bmb7_J103[29]),.HB14_P(bus_bmb7_J103[120]),.HB15_N(bus_bmb7_J103[134]),.HB15_P(bus_bmb7_J103[40]),.HB16_N(bus_bmb7_J103[98]),.HB16_P(bus_bmb7_J103[93]),.HB17_N_CC(bus_bmb7_J103[5]),.HB17_P_CC(bus_bmb7_J103[63]),.HB18_N(bus_bmb7_J103[111]),.HB18_P(bus_bmb7_J103[70]),.HB19_N(bus_bmb7_J103[9]),.HB19_P(bus_bmb7_J103[127]),.HB20_N(bus_bmb7_J103[31]),.HB20_P(bus_bmb7_J103[45]),.HB21_N(bus_bmb7_J103[148]),.HB21_P(bus_bmb7_J103[52]),.LA00_N_CC(bus_bmb7_J103[115]),.LA00_P_CC(bus_bmb7_J103[38]),.LA01_N_CC(bus_bmb7_J103[82]),.LA01_P_CC(bus_bmb7_J103[138]),.LA02_N(bus_bmb7_J103[14]),.LA02_P(bus_bmb7_J103[87]),.LA03_N(bus_bmb7_J103[1]),.LA03_P(bus_bmb7_J103[53]),.LA04_N(bus_bmb7_J103[78]),.LA04_P(bus_bmb7_J103[85]),.LA05_N(bus_bmb7_J103[123]),.LA05_P(bus_bmb7_J103[55]),.LA06_N(bus_bmb7_J103[137]),.LA06_P(bus_bmb7_J103[131]),.LA07_N(bus_bmb7_J103[12]),.LA07_P(bus_bmb7_J103[42]),.LA08_N(bus_bmb7_J103[116]),.LA08_P(bus_bmb7_J103[105]),.LA09_N(bus_bmb7_J103[141]),.LA09_P(bus_bmb7_J103[144]),.LA10_N(bus_bmb7_J103[119]),.LA10_P(bus_bmb7_J103[68]),.LA11_N(bus_bmb7_J103[33]),.LA11_P(bus_bmb7_J103[94]),.LA12_N(bus_bmb7_J103[97]),.LA12_P(bus_bmb7_J103[64]),.LA13_N(bus_bmb7_J103[48]),.LA13_P(bus_bmb7_J103[57]),.LA14_N(bus_bmb7_J103[22]),.LA14_P(bus_bmb7_J103[35]),.LA15_N(bus_bmb7_J103[107]),.LA15_P(bus_bmb7_J103[43]),.LA16_N(bus_bmb7_J103[13]),.LA16_P(bus_bmb7_J103[156]),.LA17_N_CC(bus_bmb7_J103[130]),.LA17_P_CC(bus_bmb7_J103[101]),.LA18_N_CC(bus_bmb7_J103[140]),.LA18_P_CC(bus_bmb7_J103[75]),.LA19_N(bus_bmb7_J103[8]),.LA19_P(bus_bmb7_J103[95]),.LA20_N(bus_bmb7_J103[103]),.LA20_P(bus_bmb7_J103[151]),.LA21_N(bus_bmb7_J103[2]),.LA21_P(bus_bmb7_J103[106]),.LA22_N(bus_bmb7_J103[44]),.LA22_P(bus_bmb7_J103[145]),.LA23_N(bus_bmb7_J103[150]),.LA23_P(bus_bmb7_J103[19]),.LA24_N(bus_bmb7_J103[79]),.LA24_P(bus_bmb7_J103[21]),.LA25_N(bus_bmb7_J103[32]),.LA25_P(bus_bmb7_J103[56]),.LA26_N(bus_bmb7_J103[152]),.LA26_P(bus_bmb7_J103[10]),.LA27_N(bus_bmb7_J103[155]),.LA27_P(bus_bmb7_J103[11]),.LA28_N(bus_bmb7_J103[47]),.LA28_P(bus_bmb7_J103[20]),.LA29_N(bus_bmb7_J103[99]),.LA29_P(bus_bmb7_J103[72]),.LA30_N(bus_bmb7_J103[54]),.LA30_P(bus_bmb7_J103[39]),.LA31_N(bus_bmb7_J103[50]),.LA31_P(bus_bmb7_J103[27]),.LA32_N(bus_bmb7_J103[41]),.LA32_P(bus_bmb7_J103[77]),.LA33_N(bus_bmb7_J103[18]),.LA33_P(bus_bmb7_J103[7]));
application_top application_top(
.bmb7_U7_clkout(bmb7_U7_clkout)
,.bmb7_U7_clk4xout(bmb7_U7_clk4xout)
,.port_50006_word_k7tos6(port_50006_word_k7tos6)
,.port_50006_word_s6tok7(port_50006_word_s6tok7)
,.port_50006_tx_available(port_50006_tx_available)
,.port_50006_rx_available(port_50006_rx_available)
,.port_50006_tx_complete(port_50006_tx_complete)
,.port_50006_rx_complete(port_50006_rx_complete)
,.port_50006_word_read(port_50006_word_read)
,.port_50007_word_k7tos6(port_50007_word_k7tos6)
,.port_50007_word_s6tok7(port_50007_word_s6tok7)
,.port_50007_tx_available(port_50007_tx_available)
,.port_50007_rx_available(port_50007_rx_available)
,.port_50007_tx_complete(port_50007_tx_complete)
,.port_50007_rx_complete(port_50007_rx_complete)
,.port_50007_word_read(port_50007_word_read)
,.s6_to_k7_clk_out(s6_to_k7_clk_out)

,.U50_gtrefclk(U50_gtrefclk)
,.U50_gtrefclkbuf(U50_gtrefclkbuf)
,.U50_sysclk(U50_sysclk)
,.U50_soft_reset(U50_soft_reset)
,.U50_gt_txusrrdy(U50_gt_txusrrdy)
,.U50_gt_rxusrrdy(U50_gt_rxusrrdy)
,.U50_txusrclk(U50_txusrclk)
,.U50_rxusrclk(U50_rxusrclk)
,.U50_txoutclk(U50_txoutclk)
,.U50_rxoutclk(U50_rxoutclk)
,.U50_gt_txdata(U50_gt_txdata)
,.U50_gt_rxdata(U50_gt_rxdata)
,.U50_rxbyteisaligned(U50_rxbyteisaligned)
,.U50_resetl(U50_resetl)
,.U50_modprsl(U50_modprsl)
,.U50_lpmode(U50_lpmode)

,.U32_gtrefclk(U32_gtrefclk)
,.U32_gtrefclkbuf(U32_gtrefclkbuf)
,.U32_sysclk(U32_sysclk)
,.U32_soft_reset(U32_soft_reset)
,.U32_gt_txusrrdy(U32_gt_txusrrdy)
,.U32_gt_rxusrrdy(U32_gt_rxusrrdy)
,.U32_txusrclk(U32_txusrclk)
,.U32_rxusrclk(U32_rxusrclk)
,.U32_txoutclk(U32_txoutclk)
,.U32_rxoutclk(U32_rxoutclk)
,.U32_gt_txdata(U32_gt_txdata)
,.U32_gt_rxdata(U32_gt_rxdata)
,.U32_rxbyteisaligned(U32_rxbyteisaligned)
,.U32_resetl(U32_resetl)
,.U32_modprsl(U32_modprsl)
,.U32_lpmode(U32_lpmode)

,.Y4_oe(Y4_oe)
,.Y4_clkp(Y4_clkp)
,.Y4_clkn(Y4_clkn)
,.U5_clkp_out(U5_clkp_out)
,.U5_clkn_out(U5_clkn_out)
,.J4_pout(J4_pout)
,.J28_pout(J28_pout)
,.U19_U0P_out(U19_U0P_out)
,.U19_U0N_out(U19_U0N_out)
,.D4rgb(bmb7_D4_rgb)
,.D5rgb(bmb7_D5_rgb)
);
endmodule
