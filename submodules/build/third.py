#!/usr/bin/python

# Origin of the title "third": the usual Verilog syntax for stitching
# together modules has to render a signal names three times: the declaration,
# the output port, and the input port.
# The input to this function only spells it out in one place, resulting
# in one "third" of the cognitive load.

# In good Fred Brooks style, this program is meant to be thrown away.
# It's supposed to just barely work, and demonstrate the concept.

# Larry Doolittle, LBNL, July 2013
import sys
import re

def change_mode(n):
	global mode
	# print mode
	#if (mode == 2):  # instance
	# print "done with instance", instance_module, ' '.join(instance_parms), instance_name
	mode = n

def ensure_module(m):
	try:
		a=len(mod_ports[m])
	except:
		mod_ports[m]=[]
		mod_ports2[m]={}

def mods_text(m,l):
	if (m=='s'): opt_sign = 'signed '
	else: opt_sign = ''
	try:
		if (int(l)>1):
			bit_range = '[%d:0] '%(int(l)-1)
		else:
			bit_range = ''
	except ValueError:
		bit_range = '[%s-1:0] '%l
	return opt_sign + bit_range

def new_output(sig, mods, rhs):
	out_assigns.append("assign %s = %s;"%(sig,rhs))
	out_ports.append(sig)
	out_port_decls.append("output %s%s;"%(mods,sig))

def register_output(o,mods):
	# print "Noticed output (%s) properties %s %s"%(o,m,l)
	if (re.search("^[0-9]+'d[0-9]+$",o)):
		return o
	try:
		foo=int(o)
		print "// trying constant",o
		return o
	except:
		# print "// stitching",o
		F=o.split('.')
		if (len(F)!=2):
			print "oops in register_output (%s)"%o
			return
		mod = F[0]
		port = F[1]
		if (mod == 'this'):
			signal = port
			# print 'input (%s) (%s)'%(mods,port)
			global_in_mods[port]=mods
			return signal
		else:
			signal = "%s__%s"%(mod,port)
			port_string = ".%s(%s)"%(port,signal)
			ensure_module(mod)
			mod_ports[mod].append(port_string)
			mod_ports2[mod][port_string]=1
			# wires.append('wire %s%s;'%(mods,signal))
			wire_mods[signal]=mods
			return signal

def make_link(o,inst,lhs):
	F=o.split('.')
	if (len(F)!=2):
		# print "oops in register_output"
		return
	mod = F[0]
	port = port = F[1]
	#print mod,port,inst,lhs
	if (port == lhs):
		lab=port
	else:
		lab="%s,%s"%(port,lhs)
	graph_l.append("  %s -> %s [label=\"%s\"]"%(mod,inst,lab))

# degenerate case of command line processing
emit_verilog=0
emit_dot=0
fname=sys.argv[1]
if (sys.argv[1]=="-dot"):
	fname=sys.argv[2]
	emit_dot=1
else:
	emit_verilog=1
fin = open(fname,'r')
sin = fin.read()

mode = 0
parameter_table=[]
#wires=[]
wire_mods={}
mod_ports={}
mod_ports2={}
instance_mods={}
global_in_mods={}
out_assigns=[]
out_ports=[]
out_port_decls=[]
instance_par={}
instance_list=[]
instance_exists={}
ensure_module('this')
graph_l=[]
reg_defines=[]
reg_defined={}
for line in sin.split('\n'):
	lin1 = line.strip()
	lin2 = re.sub("\s*#.*",'',lin1);  # drop comments
	lin = re.sub("\s+",' ',lin2);  # all whitespace -> single space
	if (lin == ''):  # silently skip blank lines
		continue
	# print "// found (%s)"%lin
	T = lin.split(' ')
	# print "token",T[0]
	if   (T[0] == 'instance'):
		change_mode(2)
		instance_module = T[1]
		instance_name   = T[-1]
		instance_parms  = []
		if (len(T) > 3):
			instance_parms=[T[ix].strip() for ix in range(2,len(T)-1)]
		instance_par[instance_name]=instance_parms
		ensure_module(instance_name)
		instance_mods[instance_name]=instance_module
		instance_list.append(instance_name)
		instance_exists[instance_name]=1
	elif (T[0] == 'define'):
		change_mode(3)
		print "define not implemented yet"
	elif (T[0] == 'module'):
		change_mode(4)
		instance_module =""
		instance_name = "this"
		global_module=T[1]
	elif (T[0] == 'parameter'):
		l2 = lin
		#if (re.search(";$"<
		parameter_table.append(lin)
	elif (T[0] == 'register'):
		rtype = "REG"
		if (T[2]=="e"): rtype = "EVT"
		reg_defines.append("`%s_%s // %s %s %s"%(rtype,T[1],T[2],T[3],T[4]))
		reg_defined[T[1]] = 1  # mark as local, so not a port
	elif (mode == 2 or mode == 4):
		S = lin.split('=')
		if (len(S) != 2):
			print "error on instance line",lin
			continue
		lhs = S[0].strip();
		rhs = S[1].strip();
		# print "// assignment of",rhs,"to",lhs
		lhsa = lhs.split(' ');
		if (len(lhsa)!=3):
			print "need three parts to LHS"
			continue
		mods = mods_text(lhsa[0],lhsa[1])
		osig=register_output(rhs,mods)
		make_link(rhs,instance_name,lhsa[2])
		if (instance_name == "this"):
			new_output(lhsa[2],mods,osig)
		else:
			iport_string=".%s(%s)"%(lhsa[2],osig)
			# print "######",instance_name,iport_string
			mod_ports[instance_name].append(iport_string)
			mod_ports2[instance_name][iport_string]=1
	else:
		print "ignored line of input",lin

# Done parsing input; now emit Verilog
if emit_verilog:
	for m in reg_defined.keys():
		del global_in_mods[m]
	print "// machine-generated from third.py",sys.argv[1]
	print "`timescale 1ns / 1ns"
	print ""
	print "module %s(%s);"%(global_module,",".join(global_in_mods.keys()+out_ports))
	print ""
	print "// parameters"
	for m in parameter_table:
		print m
	print ""
	print "// port declarations"
	for m in global_in_mods.keys():
		print "input %s%s;"%(global_in_mods[m],m)
	for o in out_port_decls:
		print o
	for m in mod_ports.keys():
		if (m == "this"): continue
		try:
			x = instance_exists[m]
		except:
			print "Missing instance:",m
	print ""
	print "// auto-register defines"
	print "`include \"regmap_dsp.vh\""
	if (reg_defines):
		print "reg lb_write1=0; always @(posedge clk) lb_write1<=lb_write;"  # XXX absolute hack
	for m in reg_defines:
		print m
	print ""
	print "// declarations"
	for w in wire_mods.keys():
		print "wire %s%s;"%(wire_mods[w],w)
	print ""
	print "// module instances"
	for h in instance_list:
		# print "// attempting instance",h
		if (h == "this"):
			continue
		try:
			modn=instance_mods[h]
		except:
			modn="??"
		ipl=instance_par[h]
		if (len(ipl)>0):
			ipt="#("+",".join(ipl)+") "
		else:
			ipt=""
		print "// %s (%s)"%(modn,ipt)
		# print "%s %s%s (%s);"%(modn, ipt, h, ','.join(list(mod_ports[h])))
		print "%s %s%s (%s);"%(modn, ipt, h, ','.join(mod_ports2[h].keys()))
	print ""
	print "// output assignments"
	for o in out_assigns:
		print o
	print ""
	print "endmodule"
if emit_dot:
	print "digraph {"
	print "  this [shape=box];"
	for h in instance_list:
		print "  %s [shape=box];"%h
	for h in graph_l:
		print h
	print "}"
