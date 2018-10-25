import sys
import string
import re

errs=0

def ofmt(name,wid,sign):
	return 'REG_IN %s %s 0x03 %s\n'%(name,wid,sign)

def set_equiv(sig,elist):
	global errs
	# print 'equiv', sig, elist
	o=''  # build up equivalence string
	b=0   # bit count
	for g in elist.split(','):
		g=g.strip()
		# print 'found',g
		m3=re.search('^(\w+) *(\d+)$',g)
		if m3:
			o=o+ofmt(m3.group(1),m3.group(2),'u')
			b=b+int(m3.group(2))
		else:
			sys.stderr.write('error: unparsable equivalence list entry (%s)\n'%g)
			errs+=1
	if b!=16:
		sys.stderr.write('error: bit count %d for signal %s needs to be 16\n'%(b,sig))
		errs+=1
	o=o.strip()
	# print 'equivalence result',sig,'('+o+')'
	global e_set
	e_set[sig]=o

def set_signed(slist):
	global signed_vars
	# print '# maybe signed list:',slist
	for s in slist.split(','):
		m5=re.search('^\s*(\w+)',s)
		if (m5):
			sv=m5.group(1)
			# print '# maybe signed signal:',sv
			signed_vars[sv]=1

def signal(sig):
	global e_set
	ss=sig.strip()
	if ss in e_set:
		print e_set[ss]
	else:
		sign='u'
		if ss in signed_vars: sign='s'
		print ofmt(ss, 16, sign),

def process(fname):
	global errs
	print '#', fname
	try:
		with open(fname,'r') as f: # takes care of closing "f" when it goes out of scope
			for line in f:
				if not line.strip(): continue
				m1=re.search('define SLOW_SR_DATA *{ *(.*) *}',line)
				if m1:
					sig_list = m1.group(1)
					for sig in sig_list.split(','):
						signal(sig.strip())
				m2=re.search('equivalence *(\w+): *(.*)',line)
				if m2:
					set_equiv(m2.group(1),m2.group(2))
				m3=re.search(' signed *\[ *\d+: *\d+\] *(.*)',line)
				if m3:
					set_signed(m3.group(1))
	except IOError:
		sys.stderr.write('error: cannot open %s\n'%fname)
		errs+=1


for fname in sys.argv[1:]:
	# don't carry state between files
	e_set={}
	signed_vars={}
	process(fname)
exit(errs!=0)
