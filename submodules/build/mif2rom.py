import sys
import os.path

""" usage: python mif2rom.py <input.mif> <output.v> <add_width> <data_width>"""

fname = sys.argv[1]
romfname = sys.argv[2]
addw = int(sys.argv[3])
dataw = int(sys.argv[4])
#romfname =fname.split('.')[0] + '.v'
module_name = os.path.basename(fname).split('.')[0]
print romfname
with open(fname, 'r') as f:
    with open(romfname, 'w+') as romf:
        romf.write("// Machine generated by mif2rom.py using %s\n" % romfname)
        romf.write("`timescale 1ns / 1ns\n")
        romf.write("module %s(\n" % module_name)
        romf.write("    input clka,\n    input [%d:0] addra,\n    output reg [%d:0] douta\n);\n" % (addw-1, dataw-1))
        romf.write("always @(addra) case(addra)\n")
        for i,line in enumerate(f):
            romf.write("    %d'h%x:   douta = %d'h%x;\n" % (addw,i,dataw,int(line,2)))
	romf.write("    default: douta = 0;\n")
        romf.write("endcase\nendmodule\n")
