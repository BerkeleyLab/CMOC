# This file requires external defines for $(RTSIM_DIR) and $(COMMON_HDL_DIR)
# Heavy use here of makefile "substitution reference" feature
PRNG_SOURCE_LOCAL = prng.v addr_map_prng.vh prng_auto.vh
PRNG_SOURCE = $(PRNG_SOURCE_LOCAL:%=$(RTSIM_DIR)/%)

COMMON_RTSIM_SOURCE_COMMON = cordicg.v cordicg.vh cstageg.v addsubg.v vectormul.v dpram.v reg_delay.v
COMMON_RTSIM_SOURCE = $(COMMON_RTSIM_SOURCE_COMMON:%=$(COMMON_HDL_DIR)/%)

BASE_SOURCE_LOCAL = cav4_mode.v cav4_mode_auto.vh lp_pair.v pair_couple.v pair_couple_auto.vh mag_square.v
BASE_SOURCE = $(BASE_SOURCE_LOCAL:%=$(RTSIM_DIR)/%) $(COMMON_RTSIM_SOURCE)

ELEC_SOURCE_LOCAL = cav4_elec.v cav4_elec_auto.vh cav4_freq.v ph_gacc.v dot_prod.v interp0.v outer_prod.v
ELEC_SOURCE = $(ELEC_SOURCE_LOCAL:%=$(RTSIM_DIR)/%) $(BASE_SOURCE)

STATION_SOURCE_LOCAL = station.v addr_map_station.vh station_auto.vh $(PRNG_SOURCE_LOCAL) tt800v.v adc_em.v a_compress.v mag_square.v
STATION_SOURCE = $(STATION_SOURCE_LOCAL:%=$(RTSIM_DIR)/%) $(ELEC_SOURCE)

MECH_SOURCE_LOCAL = cav4_mech.v addr_map_cav4_mech.vh cav4_mech_auto.vh outer_prod.v resonator.v
MECH_SOURCE = $(MECH_SOURCE_LOCAL:%=$(RTSIM_DIR)/%)

VMOD1_SOURCE_LOCAL = vmod1.v addr_map_vmod1.vh vmod1_auto.vh $(PRNG_SOURCE_LOCAL) tt800v.v adc_em.v resonator.v beam1.v a_compress.v mag_square.v
VMOD1_SOURCE = $(VMOD1_SOURCE_LOCAL:%=$(RTSIM_DIR)/%) $(ELEC_SOURCE)

RTSIM_SOURCE_LOCAL = rtsim.v addr_map_rtsim.vh rtsim_auto.vh $(PRNG_SOURCE_LOCAL) tt800v.v adc_em.v resonator.v beam1.v a_compress.v mag_square.v
RTSIM_SOURCE = $(RTSIM_SOURCE_LOCAL:%=$(RTSIM_DIR)/%) $(STATION_SOURCE) $(MECH_SOURCE)
