include ../../dir_list.mk
all: sel4.pdf
include $(BUILD_DIR)/top_rules.mk

.PHONY: all clean

FDBK_SYS_TB = $(APP_DIR)/fdbk_sys_tb

$(FDBK_SYS_TB): $(APP_DIR)/fdbk_sys_tb.v
	cd .. && make fdbk_sys_tb

%.out: $(APP_DIR)/%_tb
	$(VVP) $< $(VVP_FLAGS) +trace > $@

%.eps: %.m
	$(OCTAVE_SILENT) $<

GEN_FIGURES = delays.eps over.eps sima_m.eps sima_p.eps
ALL_FIGURES = intro.eps sel_quad.eps boxes.eps $(GEN_FIGURES)
over.eps: delays.eps

fdbk_sys.out fdbk_sys.vcd: llrf_sysmodel2.vpi

# Cavity model
CFLAGS_llrf_sysmodel2.o := $(shell iverilog-vpi --cflags)
#CFLAGS_pmodel.o = -I/usr/include/python2.7
#LDFLAGS_llrf_sysmodel2.vpi = -lpython2.7
llrf_sysmodel2.vpi: llrf_sysmodel2.o pmodel.o
#iverilog-vpi -lpython2.7 $^

trace1.dat: fdbk_sys.out
	awk 'FNR>18 && /fdbk_sys_tb/{print $$1,$$2,$$3,$$4,$$5,$$6,$$7,$$8,$$9}' $< >$@

sima_m.eps sima_p.eps: sima.m trace1.dat
	$(OCTAVE_SILENT) $<

# four columns are 2 (complex) drive, and 2 (complex) cavity
# XXX broken!  To restore:  re-enable print in pmodel.c
chirp.out: $(FDBK_SYS_TB) llrf_sysmodel2.vpi
	$(VVP) $< +chirp | awk '/pmodel/{print $$1,$$2,$$3,$$4}' > $@

chirp.eps: chirp.out

# Documentation: just as important as the code?
sel4.dvi: sel4.tex $(ALL_FIGURES)
	tex $<

sel4.pdf: sel4.tex $(ALL_FIGURES:.eps=.pdf)
	pdftex $<

sel4_draft.pdf: sel4.pdf draft.pdf
	pdftk $< multibackground draft.pdf output $@

draft.pdf: draft.ps
	ps2pdf $< $@

CLEAN += *.pdf *.out *.dat *.d *.o $(GEN_FIGURES) *.log *.vpi
