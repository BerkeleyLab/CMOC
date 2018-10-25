all: targets

HARDWARE = sp605
DSP_FLAVOR = 7
COMMUNICATION = gmii
#COMMUNICATION = mgt
DAUGHTER = base
include ../../dir_list.mk

ifneq (,$(findstring mgt,$(COMMUNICATION)))
ETHER_GENV += s6_gtp_params.vh
# hard-coded dependency need to be auto-resolved by MAKEDEP later
larger_shell_mgt_sp605.bit: s6_gtp_params.vh
#mgt_base.ucf: larger_extra.ucf
endif

system_top.ucf: larger_extra.ucf

vpath %.v $(APP_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(ETHER_TOP_DIR) -y$(FPGA_FAMILY_DIR)/pll -y.
# $(BITS_): $(BOARD_SUPPORT_DIR)/$(HARDWARE)/qf2_core.vhd $(IP_TCL)
