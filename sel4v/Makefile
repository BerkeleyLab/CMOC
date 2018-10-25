# 1. iverilog -M :Autogenerate prerequisites
# 2. iverilog -o $@ :actual complie with dependency from 2.
all: targets

include ../dir_list.mk

include $(BUILD_DIR)/top_rules.mk
include $(APP_DIR)/rules.mk

