EPS_FIG := $(wildcard *.eps)
PDF_TGT = $(EPS_FIG:%.eps=%.pdf)

.PHONY: all
all: $(PDF_TGT)
include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk


CLEAN += $(PDF_TGT)
