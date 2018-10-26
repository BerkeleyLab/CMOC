all: targets

HARDWARE = ac701
DSP_FLAVOR = 7
COMMUNICATION = rgmii
DAUGHTER = base
XILINX_TOOL := VIVADO
include ../../dir_list.mk

vpath %.v $(APP_DIR)
vpath %.xdc $(BS_HARDWARE_DIR)

include $(BUILD_DIR)/top_rules.mk

# 7series GTP wrapper generation from coregen
ifneq (,$(findstring gtp,$(COMMUNICATION)))
    vpath %.cgp $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)
    vpath %.xco $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)
    VFLAGS_DEP += -y$(GT_SUPP_DIR)
    larger_shell_gtp_$(HARDWARE).bit.d: $(COREGEN_GTP_TGT)
    larger_shell_gtp_rgmii_$(HARDWARE).bit.d: $(COREGEN_GTP_TGT)
endif

VFLAGS_DEP += -y .

system_top.xdc: larger_extra.xdc rgmii.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk
