# Board & part definition
ifneq (,$(findstring larger_eth_tb,$(MAKECMDGOALS)))   # maybe this test could be improved
    VFLAGS_DEP += -y$(ETHER_TOP_DIR) -y$(ETHER_CORE_DIR) -y$(ETHER_CRC_DIR) -y$(ETHER_CLIENTS_DIR)
    VFLAGS += -I$(ETHER_CORE_DIR) -I$(ETHER_CRC_DIR) -I$(ETHER_CLIENTS_DIR)
endif
ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    vpath %.ucf $(BS_HARDWARE_DIR)
    vpath %.xdc $(BS_HARDWARE_DIR)
    # ether_support
    VFLAGS_DEP += -y$(ETHER_TOP_DIR) -y$(ETHER_CORE_DIR) -y$(ETHER_CRC_DIR) -y$(ETHER_CLIENTS_DIR) -y$(CURDIR)
    VFLAGS += -I$(ETHER_CORE_DIR) -I$(ETHER_CRC_DIR) -I$(ETHER_CLIENTS_DIR)
    # action = synthesize
    VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(PERIPHERAL_DRIVERS_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)
    VFLAGS += -I$(BS_HARDWARE_DIR)
endif

%.out: %_tb
	$(VVP) $< $(VVP_FLAGS) > $@

DOC_DIR = doc
VFLAGS += -I$(AUTOGEN_DIR)

# action = simulation
VFLAGS_DEP += -y$(APP_DIR) -y$(COMMON_HDL_DIR) -y$(RTSIM_DIR)
VFLAGS += -I$(APP_DIR) -I$(COMMON_HDL_DIR) -I$(RTSIM_DIR)

TEST_BENCH := cordic_mux_tb cryomodule_tb fdbk_core_tb fdbk_sys_tb fgen_tb iq_chain4_tb larger_tb linearize_tb llrf_dsp_tb lp1_tb lp_notch_tb mp_proc_tb ssb_out_tb tgen_tb upconv2_tb xy_pi_clip_tb
# broken and/or obsolete: larger_eth_tb

TGT_ := $(TEST_BENCH)
CHK_ := $(TGT_) notch_setup_check linearize_check mp_proc_check upconv2_check
BITS_ :=  larger_shell_$(COMMUNICATION)_$(HARDWARE).bit

targets: $(TGT_)
checks: $(CHK_)
bits: $(BITS_)
doc:
	$(MAKE) -C $(DOC_DIR)

### Auto-dependency generation
vpath %.v $(RTSIM_DIR)
vpath %.vh $(RTSIM_DIR)
ROM_GENV = config_romx.v

FDBK_CORE_AUTO = $(AUTOGEN_DIR)/fdbk_core_auto.vh
FDBK_CORE_TB_AUTO = $(AUTOGEN_DIR)/fdbk_core_tb_auto.vh  $(AUTOGEN_DIR)/addr_map_fdbk_core_tb.vh $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
LP_NOTCH_AUTO = $(AUTOGEN_DIR)/lp_notch_auto.vh
LP1_AUTO = $(AUTOGEN_DIR)/lp1_auto.vh $(AUTOGEN_DIR)/addr_map_lp1_tb.vh
LLRF_DSP_AUTO = $(AUTOGEN_DIR)/llrf_dsp_auto.vh $(AUTOGEN_DIR)/piezo_control_auto.vh $(FDBK_CORE_AUTO) $(LP_NOTCH_AUTO)
LARGER_AUTO = $(AUTOGEN_DIR)/vmod1_auto.vh $(AUTOGEN_DIR)/cav4_elec_auto.vh $(AUTOGEN_DIR)/llrf_shell_auto.vh $(AUTOGEN_DIR)/cav4_mode_auto.vh $(LLRF_DSP_AUTO) $(AUTOGEN_DIR)/addr_map_llrf_shell.vh $(AUTOGEN_DIR)/addr_map_vmod1.vh $(AUTOGEN_DIR)/prng_auto.vh $(AUTOGEN_DIR)/regmap_llrf_shell.json
CRYOMODULE_AUTO = $(AUTOGEN_DIR)/cryomodule_auto.vh $(AUTOGEN_DIR)/cav4_mech_auto.vh $(AUTOGEN_DIR)/beam1_auto.vh $(AUTOGEN_DIR)/station_auto.vh $(AUTOGEN_DIR)/prng_auto.vh $(AUTOGEN_DIR)/cav4_elec_auto.vh $(AUTOGEN_DIR)/llrf_shell_auto.vh $(AUTOGEN_DIR)/cav4_mode_auto.vh $(LLRF_DSP_AUTO) $(AUTOGEN_DIR)/addr_map_llrf_shell.vh $(AUTOGEN_DIR)/addr_map_cryomodule.vh $(AUTOGEN_DIR)/regmap_cryomodule.json
LINEARIZE_AUTO = $(AUTOGEN_DIR)/linearize_auto.vh

$(DEPDIR)/mp_proc_tb.d: $(AUTOGEN_DIR)/mp_proc_tb_auto.vh $(AUTOGEN_DIR)/addr_map_mp_proc_tb.vh
$(DEPDIR)/lp1_tb.d: $(AUTOGEN_DIR)/lp1_tb_auto.vh $(LP1_AUTO)
$(DEPDIR)/lp_notch_tb.d: $(AUTOGEN_DIR)/lp_notch_tb_auto.vh $(AUTOGEN_DIR)/addr_map_lp_notch_tb.vh
$(DEPDIR)/fdbk_core_tb.d: $(FDBK_CORE_TB_AUTO) $(FDBK_CORE_AUTO)
$(DEPDIR)/lp_notch_tb.d: $(LP_NOTCH_AUTO)
$(DEPDIR)/llrf_shell_tb.d: $(AUTOGEN_DIR)/llrf_shell_auto.vh $(AUTOGEN_DIR)/llrf_dsp_auto.vh
$(DEPDIR)/llrf_dsp_tb.d: $(LLRF_DSP_AUTO) $(AUTOGEN_DIR)/llrf_dsp_tb_auto.vh
$(DEPDIR)/larger_tb.d: $(LARGER_AUTO) $(ROM_GENV)
$(DEPDIR)/cryomodule_tb.d: $(CRYOMODULE_AUTO) $(ROM_GENV) $(AUTOGEN_DIR)/addr_map_cryomodule.vh $(AUTOGEN_DIR)/regmap_cryomodule.json
$(DEPDIR)/larger_eth_tb.d: $(ETHER_GENV) $(LARGER_AUTO) $(CRYOMODULE_AUTO)
$(DEPDIR)/llrf_dsp_tb.d: $(AUTOGEN_DIR)/llrf_dsp_tb_auto.vh $(AUTOGEN_DIR)/addr_map_llrf_dsp_tb.vh $(LARGER_AUTO)
$(DEPDIR)/linearize_tb.d: $(AUTOGEN_DIR)/linearize_tb_auto.vh $(AUTOGEN_DIR)/addr_map_linearize_tb.vh $(LINEARIZE_AUTO)

# synthesize related
ETHER_GENV += aggregate.v crc8e_guts.vh $(ROM_GENV)
$(DEPDIR)/$(BITS_).d: $(ETHER_GENV) $(LARGER_AUTO) $(CRYOMODULE_AUTO)
$(DEPDIR)/fdbk_core.bit.d: $(FDBK_CORE_AUTO)
#$(DEPDIR)/llrf_shell.bit.d: $(AUTOGEN_DIR)/llrf_shell_auto.vh $(AUTOGEN_DIR)/llrf_dsp_auto.vh blank_a7.ucf addr_map.vh
$(DEPDIR)/llrf_shell.bit.d: $(AUTOGEN_DIR)/llrf_shell_auto.vh $(AUTOGEN_DIR)/llrf_dsp_auto.vh blank_a7.ucf

# XXX overriding implicit rule since fdbk_sys_tb.v is not tb for fdbk_sys.v
$(DEPDIR)/fdbk_sys_tb.d: fdbk_sys_tb.v $(AUTOGEN_DIR)/fdbk_sys_tb_auto.vh $(AUTOGEN_DIR)/addr_map_fdbk_sys_tb.vh $(FDBK_CORE_AUTO)
	set -e; mkdir -p $(DEPDIR); $(MAKEDEP) && (printf "fdbk_sys_tb $@: "; sort -u $@.$$$$ | tr '\n' ' '; printf "\n" ) > $@ && rm -f $@.$$$$

VFLAGS_fdbk_sys_tb = -m ./llrf_sysmodel2
#VFLAGS_$(DEPDIR)/lp_notch_tb.d = -DLB_DECODE_lp_notch_tb
#VFLAGS_$(DEPDIR)/llrf_dsp_tb.d = -DLB_DECODE_llrf_dsp
VFLAGS_$(DEPDIR)/larger_tb.d = -DLB_DECODE_llrf_shell
VFLAGS_larger_tb = -DLB_DECODE_llrf_shell
#VFLAGS_$(DEPDIR)/cryomodule_tb.d = -DLB_DECODE_llrf_shell

### Local rules
lp1_tb: $(DEPDIR)/lp1_tb.d

lp1.bit: lp1.v
	arch=s6 $(ISE_SYNTH) lp1 $^
	mv _xilinx lp1.bit $@

#lp1.vcd: $(LP1_AUTO) $(LP1_TB_AUTO) lp1_tb lp_notch_test.py
#	$(PYTHON) lp_notch_test.py

fdbk_core.bit:
	arch=s6 $(ISE_SYNTH) fdbk_core $^
	mv _xilinx/fdbk_core.bit $@

fdbk_core_tb: $(DEPDIR)/fdbk_core_tb.d

fdbk_core.vcd: $(FDBK_CORE_AUTO) $(FDBK_CORE_TB_AUTO) fdbk_core_tb fdbk_core_test.py
	$(PYTHON) fdbk_core_test.py

# XXX still broken
llrf_shell.bit:
	PART=$(PART) $(ISE_SYNTH) llrf_shell $^

upconv2.dat: upconv2_tb
	$(VVP) $< +trace > $@

upconv2_check: upconv2a.m upconv2.dat
	$(OCTAVE) -q $<

notch_setup_check: notch_setup.py lp1_tb lp_notch_tb
	$(PYTHON) $<

larger_in.dat: param.py
	$(PYTHON) $< | sed -e 's/ *#.*//' | grep . > $@

cryomodule_in.dat: param_new.py
	$(PYTHON) $< | sed -e 's/ *#.*//' | grep . > $@

VVP_FLAGS_larger.out = +pfile=larger_p.dat
larger.out: larger_in.dat
larger_p.dat: larger.out

VVP_FLAGS_cryomodule.out = +pfile=cryomodule_p.dat
cryomodule.out: cryomodule_in.dat
cryomodule_p.dat: cryomodule.out

fgen.vcd: fgen_seq.dat
tgen.vcd: tgen_seq.dat
LB_HI = 13
$(AUTOGEN_DIR)/%_auto.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -o $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/addr_map_%.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -a $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/regmap_%.json: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -r $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/cryomodule_auto.vh: $(APP_DIR)/cryomodule.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -o $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/addr_map_cryomodule.vh: $(APP_DIR)/cryomodule.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -a $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

$(AUTOGEN_DIR)/regmap_cryomodule.json: $(APP_DIR)/cryomodule.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -r $@ -w $(LB_HI) -l -m -d$(RTSIM_DIR),.

#Broken: XXX how to auto-include .d for current target?
larger.vcd: larger_in.dat
cryomodule.vcd: cryomodule_in.dat

fdbk_sys_check fdbk_sys.out fdbk_sys.vcd: llrf_sysmodel2.vpi

llrf_sysmodel2.vpi: doc/llrf_sysmodel2.o doc/pmodel.o
	$(VPI_LINK)

CFLAGS_doc/llrf_sysmodel2.o := $(shell iverilog-vpi --cflags)

slow_larger.list: $(BUILD_DIR)/slow.py $(COMMON_HDL_DIR)/timestamp.v ./llrf_shell.v
	$(PYTHON) $^ > $@

CLEAN += *.pyc
CLEAN += $(ETHER_GENV) slow_larger.list
CLEAN += $(HARDWARE)_$(COMMUNICATION)_$(DAUGHTER).*
CLEAN += $(TGT_) $(CHK_) *.out *.o *.vpi *.dvi *.log  *.bak *.bit larger_in.dat *_tb *.jou $(COREGEN_GTP_TGT) *_auto.vh crc_derive larger_p.dat cryomodule_p.dat upconv2.dat notch_test.dat *.d *.vcd *_in.dat *_out.dat $(GEN_FIGURES)
CLEAN += doc/*.o doc/*.o.d
CLEAN_DIRS += _xilinx _vivado .Xil _coregen $(GT_SUPP_DIR) $(AUTOGEN_DIR) crc_derive.dSYM

.PHONY: clean-$(DOC_DIR)
.PHONY: all checks bits check_all clean_all doc
clean_all: clean clean-$(DOC_DIR)
clean-$(DOC_DIR):
	$(MAKE) -C $(DOC_DIR) clean

# Remaking Makefiles
# Only include dependency file if necessary
ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
    -include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
else
    -include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _view,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_view=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _check,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_check=$(DEPDIR)/%_tb.d)
endif
ifeq (,$(MAKECMDGOALS))
    -include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
endif
