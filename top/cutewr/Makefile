all: targets

HARDWARE = cutewr
DSP_FLAVOR = 7
COMMUNICATION = mgt
DAUGHTER = base
include ../../dir_list.mk

ETHER_GENV += s6_gtp_params.vh
mgt_base.ucf: larger_extra.ucf

# hard-coded dependency need to be auto-resolved by MAKEDEP later
larger_shell_mgt_cutewr.bit: s6_gtp_params.vh

vpath %.v $(APP_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk
