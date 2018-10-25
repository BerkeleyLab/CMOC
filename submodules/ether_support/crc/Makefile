all: targets
include ../dir_list.mk

include $(BUILD_DIR)/top_rules.mk
# action = simulation
VFLAGS += -y. -y$(COMMON_HDL_DIR) -I$(COMMON_HDL_DIR)
# ether_support
VFLAGS += -y$(TOP_DIR) -y$(CORE_DIR) -y$(CRC_DIR) -y$(CLIENTS_DIR) -I$(CORE_DIR) -I$(CRC_DIR) -I$(CLIENTS_DIR)

TEST_BENCH:= crc_check_tb
TGT_ := crc_derive $(TEST_BENCH) crc_selfcheck
CHK_ := crc_selfcheck_check
CHK_ALL_ := $(TGT_) $(CHK_)

.PHONY: all checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_ALL_)
bits: $(BITS_)

crc_selfcheck_check: crc_selfcheck udp2.dat arp2.dat long.dat icmp2.dat
	./$< udp2.dat
	./$< arp2.dat
	./$< long.dat
	./$< icmp2.dat

crc_selfcheck: crc_selfcheck.o crc32.o
CF_TGT = -Iinclude

CLEAN += $(TGT_) *_tb *.o *.d.* *.d
include ../rules.mk

# Remaking Makefiles
ifneq ($(MAKECMDGOALS),clean)
    ifeq ($(MAKECMDGOALS),bits)
	-include $(BITS_:.bit=.bit.d)
    else
	-include $(TEST_BENCH:_tb=_tb.d)
    endif
endif
