TEMP_DIR = _temp

TD = tests/test_1/

tests: $(TEMP_DIR)/test_newad

$(TEMP_DIR)/test_newad:
	mkdir -p $(TEMP_DIR)
	python newad.py -i $(TD)main_test.v -r$@.json -a $@_addr_map.vh -o $@_auto.vh -w 23 -l -m -d$(TD),$(TD)/sub_dir/ -b8388608
	diff $(TEMP_DIR)/ tests/test_1_out/

clean:
	rm -rf _temp
