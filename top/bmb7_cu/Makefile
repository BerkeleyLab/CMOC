all: targets

HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO
include ../../dir_list.mk


vpath %.v $(APP_DIR)

CLEAN_DIRS += ./.Xil
system_top.xdc: prc.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(ETHER_TOP_DIR) -y.
