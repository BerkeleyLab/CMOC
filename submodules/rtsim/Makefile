AWK = gawk
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale -DSIMULATE
VVP = vvp$(ICARUS_SUFFIX) -n
GTKWAVE = gtkwave
PYTHON = python
OCTAVE = octave -q
SYNTH = xil_syn  # not supplied here

CFLAGS = --std=c99 -O2 -Wall -Wextra -Wshadow -pedantic
LDFLAGS = -lm

# git clone gitlab.lbl.gov:hdl-libraries/common-hdl.git
COMMON_HDL_DIR = ../common_hdl
# git clone gitlab.lbl.gov:hdl-libraries/build.git
BUILD_DIR = ../build
RTSIM_DIR = .

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.vcd: %_tb
	$(VVP) $< $(VVP_FLAGS) +vcd $(VCD_ARGS)

%.dat: %_tb
	$(VVP) $< +trace > $@

%_view: %.vcd %.sav
	$(GTKWAVE) $^

%_auto.vh: %.v
	python $(BUILD_DIR)/newad.py -i $< -o $@ -a addr_map_$(basename $<).vh -r regmap_gen_$(basename $<).json -l -w 14

%.pdf: %.eps
	gs -dEPSCrop -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE -dBATCH -dAutoRotatePages=/None -c .setpdfwrite -f $<

%.pdf: %.tex
	pdftex $<

addr_map_%.vh: %.v
	python $(BUILD_DIR)/newad.py -i $< -a $@ -w 14 -l -d.

include vsource.mk
# needs to define $(COMMON_SOURCE) $(BASE_SOURCE) $(ELEC_SOURCE) $(VMOD1_SOURCE)

all: outer_prod_tb cav4_mode_tb cav4_elec_tb a_compress_tb vmod1_tb afilter_siso_tb slide7.pdf
checks: cav4_mode_check res_check a_comp_check

VFLAGS = -I $(COMMON_HDL_DIR)

beam1_tb: beam1.v

# One mode in isolation
VFLAGS_cav4_mode_tb = -DLB_DECODE_cav4_mode
cav4_mode_tb: ph_gacc.v $(BASE_SOURCE)

cav4_mode.bit: $(BASE_SOURCE) blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) cav4_mode $^

# Full electrical cavity model, with two modes instantiated
VFLAGS_cav4_elec_tb = -DLB_DECODE_cav4_elec
cav4_elec_tb: cav4_elec_tb_auto.vh $(ELEC_SOURCE) resonator.v

cav4_mode_check: cav4_check1.m cav4_mode.dat
	$(OCTAVE) $<

resonator_tb: resonator_tb_auto.vh resonator.v $(COMMON_RTSIM_SOURCE)
VFLAGS_resonator_tb = -I $(COMMON_HDL_DIR)

resonator_a7.bit: resonator.v $(COMMON_RTSIM_SOURCE) blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) resonator $^

resonator_s6.bit: resonator.v $(COMMON_RTSIM_SOURCE) blank_s6.ucf
	PART=xc6slx45t-fgg484-3 $(SYNTH) resonator $^

res_check: res_check.m resonator.dat
	$(OCTAVE) $<

outer_prod_tb: outer_prod_tb_auto.vh outer_prod.v $(COMMON_RTSIM_SOURCE)

afilter_siso_tb: afilter_siso_tb_auto.vh afilter_siso.v afilter_siso_auto.vh outer_prod.v outer_prod_auto.vh dot_prod.v resonator.v resonator_auto.vh $(COMMON_RTSIM_SOURCE)

afilter_siso_in.dat: filte2.py afilter_siso_tb_auto.vh
	$(PYTHON) $<

afilter_siso.vcd: afilter_siso_in.dat
afilter_siso.dat: afilter_siso_in.dat

slide7.pdf: filt_time.pdf filt_freq.pdf

filt_time.pdf filt_freq.pdf: filte2.py
	$(PYTHON) $<

a_compress_tb: a_compress.v $(COMMON_RTSIM_SOURCE) mag_square.v

a_comp_check: a_comp.m a_compress.dat
	$(OCTAVE) $<

vmod1_in.dat: param.py vmod1_auto.vh
	python $< | sed -e 's/ *#.*//' | grep . > $@

# Full model of a single cavity, including mechanical modes and ADC noise
vmod1_tb: $(VMOD1_SOURCE)
vmod1.vcd: vmod1_in.dat
vmod1.dat: vmod1_tb vmod1_in.dat
	$(VVP) $< +pfile=$@

vmod1_a7.bit: $(VMOD1_SOURCE) blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) vmod1 $^


rtsim_in.dat: param_new.py rtsim_auto.vh
	python $< regmap_gen_rtsim.json | sed -e 's/ *#.*//' | grep . > $@

# Full model of a single cavity, including mechanical modes and ADC noise
rtsim_tb: $(RTSIM_SOURCE)
rtsim.vcd: rtsim_in.dat
rtsim.dat: rtsim_tb rtsim_in.dat
	$(VVP) $< +pfile=$@

rtsim_a7.bit: $(RTSIM_SOURCE) blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) rtsim $^

count:
	cat *.v | sed -e "`printf \"s,[ \t]*//.*,,\"`" | grep -c .
	cat *_tb.v | sed -e "`printf \"s,[ \t]*//.*,,\"`" | grep -c .
	cat *.v | grep -c "// "

clean:
	rm -rf _xilinx
	rm -f *_tb *.vcd *.dat ss1 physics.pdf *.log *_auto.vh *.pyc
	rm -f regmap_gen_*.json addr_map_*.vh slide7.pdf filt_*.pdf
