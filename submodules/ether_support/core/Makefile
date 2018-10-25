all: targets
include ../dir_list.mk

include $(BUILD_DIR)/top_rules.mk
# action = simulation
VFLAGS_DEP += -y. -y$(COMMON_HDL_DIR)
VFLAGS += -I$(COMMON_HDL_DIR)
# ether_support
VFLAGS_DEP += -y$(TOP_DIR) -y$(CORE_DIR) -y$(CRC_DIR) -y$(CLIENTS_DIR)
VFLAGS += -I$(CORE_DIR) -I$(CRC_DIR) -I$(CLIENTS_DIR)


TEST_BENCH := aggregate_tb
TGT_ := $(TEST_BENCH)
CHK_ := udp_check arp_check crc_selfcheck

.PHONY: all checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
bits: $(BITS_)

ETHER_GENV = crc8e_guts.vh crc_derive
$(DEPDIR)/aggregate_tb.d: aggregate.v $(ETHER_GENV)
$(DEPDIR)/aggregate_live.d: aggregate.v $(ETHER_GENV)

crc_selfcheck: crc_selfcheck.o crc32.o
CF_TGT += -I$(CRC_DIR)/include

udp_check: aggregate_tb crc_selfcheck $(CRC_DIR)/udp2.dat
	$(VVP) $< +packet_file=$(word 3,$^) | awk '/octet/{print $$2}' | ./$(word 2,$^)

arp_check: aggregate_tb crc_selfcheck $(CRC_DIR)/arp2.dat
	$(VVP) $< +data_len=72 +packet_file=$(word 3,$^) | awk '/octet/{print $$2}' | ./$(word 2,$^)

icmp_check: aggregate_tb crc_selfcheck $(CRC_DIR)/icmp2.dat
	$(VVP) $< +data_len=86 +packet_file=$(word 3,$^) | awk '/octet/{print $$2}' | ./$(word 2,$^)

ifeq ($(MAKECMDGOALS),aggregate_live)
include $(MODEL_DIR)/rules.mk
vpath %.c $(MODEL_DIR)
tap-vpi.vpi: $(OBJS_VPI)
aggregate_live: tap-vpi.vpi aggregate_tb
-include $(DEPDIR)/aggregate_live.d
-include $(DEPDIR)/aggregate_tb.d
VFLAGS_aggregate_live = -m ./tap-vpi -DLINUX_TUN
VFLAGS_$(DEPDIR)/aggregate_live.d = -m ./tap-vpi -DLINUX_TUN
endif

CLEAN += $(ETHER_GENV) $(TGT_) $(CHK_) *.d *.d.* *_tb *_live *.o *vpi aggregate.v aggregate2.v

include ../rules.mk

# Remaking Makefiles
# Only include dependency file if necessary
ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    -include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
endif
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifeq (,$(MAKECMDGOALS))
    -include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
endif
