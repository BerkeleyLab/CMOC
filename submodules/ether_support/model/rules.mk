# Local variables

TGT_VPI = tap-vpi.$(VPIEXT)

OBJS_VPI := tap-vpi.o tap_alloc.o crc32.o
DEPS_ := $(OBJS_VPI:%=%.d) $(TGT_VPI:%=%.d)

# Local rules

$(TGT_VPI): $(OBJS_VPI)
CFLAGS_tap-vpi.o = $(VPI_CFLAGS)
CF_TGT := -I$(CRC_DIR)/include
#$(TGT_VPI): CF_TGT := -I$(CRC_DIR)/include

CLEAN := $(CLEAN) $(TGT_VPI) $(OBJS_VPI) $(DEPS_)
# Standard things

-include $(DEPS_)

