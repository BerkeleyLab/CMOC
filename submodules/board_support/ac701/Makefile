include rules.mk
FMC_MAP = awk -F\" 'NR==FNR{a[$$2]=$$4;next}$$4 in a{printf "NET %-15s LOC = %-4s | IOSTANDARD = %10s; \# %s\n",$$2,a[$$4],$$6,$$4}'
XDC_MAP = awk -F"[ \"\t]+" 'NR==FNR{gsub(/]/,"",$$8);a[$$8]=$$4;next}($$3 in a){printf "set_property -dict \"PACKAGE_PIN %-4s IOSTANDARD %s\" [get_ports %s]\n",a[$$3], $$4, $$2}'
all: ac701_rgmii_base.ucf ac701_gtp_base.ucf
