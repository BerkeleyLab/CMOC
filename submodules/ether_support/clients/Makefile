all: targets
include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

TEST_BENCH_SRC := $(wildcard *_tb.v)
TEST_BENCH = $(TEST_BENCH_SRC:%_tb.v=%_tb)
TGT_ = $(TEST_BENCH)
CHK_ = $(TEST_BENCH:%_tb=%_check)
# action = simulation
VFLAGS_DEP += -y. -y$(COMMON_HDL_DIR)
VFLAGS += -I$(COMMON_HDL_DIR)
# ether_support
VFLAGS_DEP += -y$(CORE_DIR) -y$(CRC_DIR) -y$(CLIENTS_DIR)
VFLAGS += -I$(CORE_DIR) -I$(CRC_DIR) -I$(CLIENTS_DIR)

.PHONY: all targets checks
targets: $(TGT_)

# Due to the complicated dependency building, you have to do a plain "make" before a "make checks"
checks: mem_gateway_check mem_gateway_x_check scaffold_check

$(DEPDIR)/client_txu_tb.d: config_romx.v

scaffold_check: scaffold.dat scaffold.gold
	cmp $^ && echo "PASS"

CLEAN += $(TGT_) $(CHK_) config_romx.v scaffold.dat

# Remaking Makefiles
# Only include dependency file if necessary
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifeq (,$(MAKECMDGOALS))
    -include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
endif
