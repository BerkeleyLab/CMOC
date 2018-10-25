all: bits

HARDWARE = kc705
DSP_FLAVOR = 7
COMMUNICATION = gmii
DAUGHTER = base
#DAUGHTER = fmc150
#DAUGHTER1 = fmc112
XILINX_TOOL := VIVADO
include ../../dir_list.mk
vpath %.v $(APP_DIR)
vpath %.xdc $(BS_HARDWARE_DIR)

FMC_ASSEBMLE = fmc-lpc_$(DAUGHTER).xdc fmc-hpc_$(DAUGHTER1).xdc
system_top.xdc: larger_extra.xdc gmii.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk

CLEAN += $(FMC_ASSEBMLE)
