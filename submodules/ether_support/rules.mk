mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(patsubst %/,%,$(dir $(mkfile_path)))

$(DEPDIR)/%_live.d: %_tb.v %.v
	set -e; mkdir -p $(DEPDIR); $(MAKEDEP) && (printf "$*_live $@: "; sort -u $@.$$$$ | tr '\n' ' '; printf "\n" ) > $@ && rm -f $@.$$$$

# prerequisite rules
# UDP port numbers assigned here; they should presumably be in the
# range 1024 (0x0400) through 49151 (0xBFFF), the "registered" ports
aggregate.v: $(current_dir)/core/agg $(current_dir)/core/aggregate.vp
	perl $< 1000 2000 3000 <$(filter %.vp, $^) >$@

aggregate2.v: $(current_dir)/core/agg $(current_dir)/core/aggregate.vp
	perl $< 1000 2000 3000 4000+4001 <$(filter %.vp, $^) | sed -e 's/aggregate/aggregate2/' >$@

vpath %.c $(current_dir)/crc

crc8e_guts.vh: crc_derive
	./$^ -lsb 32 0x04C11DB7 8 > $@

crc8e_guts.v: crc8e_guts.vh

CLEAN += crc_derive.d *.o.d *.o tap-vpi.vpi

ifneq (,$(findstring _live,$(MAKECMDGOALS)))
    include $(current_dir)/model/rules.mk
    vpath %.c $(current_dir)/model
    tap-vpi.vpi: $(OBJS_VPI)
    $(MAKECMDGOALS): tap-vpi.vpi
    #$(MAKECMDGOALS): tap-vpi.vpi $(MAKECMDGOALS:%_live=%_tb)
    -include $(MAKECMDGOALS:%_live=$(DEPDIR)/%_tb.d)
    -include $(MAKECMDGOALS:%_live=$(DEPDIR)/%_live.d)
    VFLAGS_$(MAKECMDGOALS) = -m ./tap-vpi -DLINUX_TUN
    VFLAGS_$(DEPDIR)/$(MAKECMDGOALS).d = -m ./tap-vpi -DLINUX_TUN
    CF_TGT += -I$(current_dir)/crc/include
endif
