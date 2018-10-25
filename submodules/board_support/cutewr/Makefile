all: bits
include rules.mk
include ../../dir_list.mk
include ../../top_rules.mk

HARDWARE = cutewr
TGT_ :=
CHK_ :=
CHK_ALL_ := $(CHK_)
BITS_ := ether_mgt_cute.bit

VFLAGS += -I$(BS_HARDWARE_DIR) -y$(BS_HARDWARE_DIR) -y$(PERIPHERAL_DRIVERS_DIR) -y$(FPGA_DIR)
VFLAGS += -y../common_top

ether_mgt_cute.bit: ether_mgt_cute.v $(S6GTP_SUPPORT) $(FPGA_DIR)/sp60x_clocks.v config_romx.v cutewr_mgt_base.ucf $(ETH_MGT_DEPS)
	PART=$(PART) $(SYNTH) ether_mgt $^
	mv _xilinx/ether_mgt.bit $@

targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_ALL_)
bits: $(BITS_)

CLEAN += $(CHK_ALL_) *.bit *.rbf *_tb
CLEAN_DIRS := $(CLEAN_DIRS) _xilinx/ _xilinx
