.PHONY: all clean
PSPEPS_IO_DIR = ../pspeps_io
JSON_DIR = ./parameters
include ../dir_list.mk

TARGET = $(JSON_DIR)/llrf_core_expand.json
TARGET += $(JSON_DIR)/cryomodule.json

vpath %.v $(APP_DIR)

all: $(TARGET)

$(AUTOGEN_DIR)/regmap_%.json: %.v
	mkdir -p $(AUTOGEN_DIR); python $(BUILD_DIR)/newad.py -i $< -r $@ -w 15 -l -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/regmap_cryomodule.json: $(APP_DIR)/cryomodule.v
	mkdir -p $(AUTOGEN_DIR); python $(BUILD_DIR)/newad.py -i $< -r $@ -w 15 -l -d$(RTSIM_DIR),.

$(JSON_DIR)/llrf_core_expand.json: $(JSON_DIR)/llrf_core.json $(AUTOGEN_DIR)/regmap_cryomodule.json
	python $(JSON_DIR)/expand_regs.py $^ > $@

JSON_CONFIG_DIR = $(JSON_DIR)/configfiles/LCLS-II
JSON_FILES = $(JSON_CONFIG_DIR)/default_accelerator.json \
	$(JSON_CONFIG_DIR)/LCLS-II_accelerator.json \
	$(JSON_CONFIG_DIR)/LCLS-II_append.json \
	$(AUTOGEN_DIR)/regmap_cryomodule.json \
	$(AUTOGEN_DIR)/regmap_llrf_shell.json

READ_JSON_FILES = $(JSON_DIR)/readjson.py $(JSON_DIR)/readjson_accelerator.py
json_test: $(JSON_DIR)/get_configuration.py $(READ_JSON_FILES) $(JSON_FILES)
	python $<

json_regmap: $(AUTOGEN_DIR)/regmap_cryomodule.json $(JSON_DIR)/llrf_core_expand.json

CLEAN += $(JSON_DIR)/*.pyc *.pyc

clean:
	rm -rf $(AUTOGEN_DIR)
	rm -f $(TARGET) *.pyc
