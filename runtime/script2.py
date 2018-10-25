# cavity start-up script
# first command-line argument is starting value of piezo_dc
# recommended demo: start qgui1 in one window, then
#   python script2.py 1000
import eth_test
import sys, os, time
import posix_ipc, mmap, numpy, struct

visual=0
if visual:
	import matplotlib.pyplot as plt
	plt.ion()
	fig=plt.figure()

oldumask=os.umask(0)

# As discussed in the mq_overview man page, it's helpful to
#  mkdir -p /dev/mqueue
#  mount -t mqueue none /dev/mqueue
# so that you can see the message queues and fix permissions problems.
# Shared memory files show up in /dev/shm/.
# TL;DR: rm -f /dev/mqueue/{Exit_Up,Write_Down} /dev/shm/{Up,Down}

cic_base_period = 33  # default parameter in llrf_dsp.v
wave_samp_per = 1  # set by paramhg.py
Tstep = 10e-9  # as set in paramhg.py
dt = cic_base_period*2*wave_samp_per*Tstep   # seconds

regmap_ctl={}
for l in open("../sel4v/run_map.txt").readlines():
	ll = l.strip().split()
	regmap_ctl[ll[1]] = int(ll[0])

write_mq=posix_ipc.MessageQueue(name="/Write_Down",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
os.umask(oldumask)
memUp=posix_ipc.SharedMemory('Up')
mfUp=mmap.mmap(memUp.fd,memUp.size)
memAux=posix_ipc.SharedMemory('Aux')
mfAux=mmap.mmap(memAux.fd,memAux.size)

def reg_num(key):
	if type(key) is int:
		o=key
	elif type(key) is str and key in regmap_ctl:
		o=regmap_ctl[key]
	else:
		o=0
		print "caught bad key",key
	return o

def send_val(set_list):
	a1 = [reg_num(b[0]) for b in set_list]
	a2 = [b[1] for b in set_list]
	write_mq.send(eth_test.mem_gate_write_prep(a1,a2),1,2)

global delay_pc
def delay_set(ticks, addr, data):
	global delay_pc
	delay_pc += 4
	return [
		[delay_pc-4, ticks],
		[delay_pc-3, reg_num(addr)],
		[delay_pc-2, int(data)/65536],
		[delay_pc-1, int(data)%65536]]

def tgen_setup(mmlist):
	global delay_pc
	delay_pc = 4096
	l=[]
	for a in mmlist:
		l += delay_set(   0, 'lim_X_lo', a[0])
		l += delay_set(a[2], 'lim_X_hi', a[1])
	l += delay_set( 0, 0, 0)  # stop program
	return l

def simple_pulse(level,pulse_len):
	a = tgen_setup([[level,level,pulse_len],[0,0,0]])
	#print a
	return a

def triple_pulse(t1,t2,t3,level,maxq):
	global delay_pc
	delay_pc = 4096
	l=[];
	if 1:
		l += delay_set(   0, 'lim_Y_lo', 0)
		l += delay_set(   0, 'lim_Y_hi', 0)
		l += delay_set(   0, 'lim_X_lo', level)
		l += delay_set(  t1, 'lim_X_hi', level)
	if t2 > 0:
		l += delay_set(   0, 'lim_X_lo', level*0.8)
		l += delay_set(  t2, 'lim_X_hi', level*1.2)
	if t3 > 0:
		l += delay_set(   0, 'lim_Y_lo', 2**18-maxq)
		l += delay_set(  t3, 'lim_Y_hi',  maxq)
	l += delay_set( 0, 'lim_Y_lo', 0)
	l += delay_set( 0, 'lim_Y_hi', 0)
	l += delay_set( 0, 'lim_X_lo', 0)
	l += delay_set( 0, 'lim_X_hi', 0)
	l += delay_set( 0, 0, 0)  # stop program
	#print l
	return l

def get_data():
	mfUp.seek(0)
	mfAux.seek(0)
	aux_str=mfAux.read(memAux.size)
	res_str=mfUp.read(memUp.size)
	res=struct.unpack('!%dI'%((len(res_str))/4),res_str)
	aux=struct.unpack('!%dB'%((len(aux_str))),aux_str)
	return [res,aux]

# query number stored in tag memory
#   0  reserved for never used
#   1  reserved for parameter update in progress
#   2  reserved for process stopped
#   3  unused
#  4-11 rotated through
# I use 4 bits here, even though the hardware is capable of 8
qnum=0
def query_response(query):
	global qnum
	tx_tag = qnum+4
	#print "sending tx_tag",tx_tag
	send_val([['tag',1]]+query+[['tag',tx_tag]])
	#time.sleep(0.25)  # stupid way to allow change to take effect
	while True:
		time.sleep(0.01)
		[res,aux] = get_data()
		#print "checking tags",aux[16],aux[17]
		if (aux[16] == tx_tag and aux[17] == tx_tag):
			break
	if 0:
		eth_test.slow_decode(aux)
	qnum=(qnum+1)%12
	resa = numpy.array([x-65536 if x>32767 else x for x in res]).reshape([-1,8])
	return resa

def angle_shift(angle, shift):
	a = angle+shift
	if (a > 262144): a -= 262144
	if (a <      0): a += 262144
	return a

def check_fwd(data):
	fwdm = abs(data[:,2]+1j*data[:,3])  # forward wave magnitude
	mx = max(fwdm)
	ex = max(numpy.nonzero(fwdm>0.5*mx)[0])
	print "found end of pulse at %d?"%ex
	return ex

# arange for amplitude printout
# prange for phase fitting (frequency offset)
# drange for log amplitude fitting (decay time)
def find_slope(data,arange,prange,drange):
	cav=data[:,0]+1j*data[:,1]
	phase=numpy.angle(cav)
	y=numpy.unwrap(phase[prange])
	ix=range(len(y))
	pp=numpy.polyfit(ix,y,1)
	delta_f = pp[0]/dt/2.0/numpy.pi
	amp=numpy.abs(cav)
	y=numpy.log(amp[drange])
	ix=range(len(y))
	pp=numpy.polyfit(ix,y,1)
	bw = -pp[0]/dt/2.0/numpy.pi  # Hz
	max_amp = max(amp[arange])
	print "Measured bandwidth %.3f kHz, detune %.3f kHz, max amp %.1f"%(bw/1000,delta_f/1000,max_amp)
	if visual:
		fig.clear()
		plt.plot(ix,y,ix,numpy.polyval(pp,ix))
		plt.draw()
	return delta_f

def find_ph_offset(data,start):
	cav = data[:,0]+1j*data[:,1]
	phase = numpy.angle(cav)
	phase_avg = numpy.mean(phase[range(start-20,start-5)])
	use_ph_offset = numpy.pi+phase_avg
	if (use_ph_offset<0): use_ph_offset += 2*numpy.pi
	reg_ph_offset = int(use_ph_offset*262144/(2*numpy.pi)+0.5)
	print "found cavity phase %.1f degrees, guess register ph_offset should be %d"%(phase_avg*180/numpy.pi,reg_ph_offset)
	return reg_ph_offset

def find_level(data,start):
	cav=data[:,0]+1j*data[:,1]
	amp=numpy.abs(cav)
	amp_avg = numpy.mean(amp[range(start-20,start-5)])
	print "Measured amplitude %.1f"%amp_avg
	return amp_avg

global piezo_dc, start, in_level, reg_ph_offset
piezo_dc = 1000
in_level = 10000
out_level_goal = 400
global start
start=-1
global data_array

base_set = [['sel_en',0], ['coeff_X_I',0], ['coeff_Y_I',0], ['ph_offset',0]] + simple_pulse(in_level,16000)
#print "base_set",base_set
#['amp_max',in_level], ['amp_min',in_level]]
sel_set = [['sel_en',1], ['coeff_X_I',0], ['coeff_Y_I',0]]

########
def coarse_tune_cavity():
	global piezo_dc, start, data_array
	vstep = 200
	slope = -10000
	oldslope = slope
	print "Coarse-tune with SEL off"
	while (abs(slope) > 800):
		print "Piezo set %d"%piezo_dc
		data_array = query_response(base_set + [['piezo_dc',piezo_dc+65536 if piezo_dc<0 else piezo_dc]])
		if (start<0):
			start = check_fwd(data_array)+4
			l = len(data_array)
			if (start+50 > l):
				start = l - 50
			print "starting trailing waveform analysis at %d"%start
			if (start<0):
				sys.exit(2)
		slope = find_slope(data_array,range(0,start),range(start,start+50),range(start,start+50))
		if oldslope*slope < 0:  # direction change
			vstep = vstep/4
		piezo_dc += vstep*(1 if slope>0 else -1)
		oldslope = slope

########
def switch_to_sel():
	global reg_ph_offset
	reg_ph_offset = find_ph_offset(data_array,start)
	print "Switching to SEL with ph_offset %d"%reg_ph_offset
	query_response(sel_set + [['ph_offset',reg_ph_offset]])

########
def ramp_field():
	global in_level, data_array
	print "Ramping up field"
	out_level = 0
	while (out_level < out_level_goal*0.84):
		print "Level set %d"%in_level
		data_array = query_response(sel_set + simple_pulse(in_level,16000))
		#[['amp_max',in_level]])
		out_level = find_level(data_array,start)
		in_level = min(in_level * out_level_goal * 0.85 / out_level, in_level+2000)

########
def fine_adjust_poffset():
	global data_array
	print "Fine-adjust SEL phase offset"
	start_offset = reg_ph_offset
	in_val=[]
	out_level=[]
	phase_step=8
	for ox in range(-3,6):
		phase_shift = ox*728*phase_step  # seven trials, plus/minus 24 degrees
		trial_offset = angle_shift(start_offset, phase_shift)
		print "Phase delta set %d degrees"%phase_shift
		data_array = query_response(sel_set + [['ph_offset',trial_offset]])
		out_level.append(find_level(data_array,start))
		in_val.append(ox*5825)
	#print in_val
	#print out_level
	pp = numpy.polyfit(in_val, out_level, 2)
	#print pp
	center =  -pp[1]/(2*pp[0])
	ant_peak = numpy.polyval(pp, center)
	#print center
	print "Shifting ph_offset by %.2f degrees, anticipated value %.1f"%(center*360/2**18,ant_peak)
	trial_offset = angle_shift(start_offset, center)
	data_array = query_response(sel_set + [['ph_offset',trial_offset]])
	find_level(data_array,start)

########
def fine_adjust_field():
	global in_level, data_array
	print "Fine-adjusting field"
	out_level = 0
	while (abs(out_level/out_level_goal-1) > 0.01):
		print "Level set %d"%in_level
		data_array = query_response(sel_set + simple_pulse(in_level,16000))
		#[['amp_max',in_level]])
		out_level = find_level(data_array,start)
		in_level = min(in_level * out_level_goal / out_level, in_level+1000)

########
def fine_tune_cavity():
	global piezo_dc, start, data_array
	print "Fine-tune cavity with SEL on"
	vstep = 100
	oldslope=0
	slope = find_slope(data_array,range(0,start),range(start,start+50),range(start,start+50))
	while (abs(slope) > 100):
		print "Piezo set %d"%piezo_dc
		data_array = query_response(sel_set + [['piezo_dc',piezo_dc+65536 if piezo_dc<0 else piezo_dc]])
		slope = find_slope(data_array,range(0,start),range(start-50,start-5),range(start,start+50))
		if oldslope*slope < 0:  # direction change
			vstep = vstep/4
		piezo_dc += vstep*(1 if slope>0 else -1)
		oldslope = slope

########
def stretch_pulse():
	# duration*8, duration=2000
	global in_level, data_array
	print "Stretching pulse"
	for llen in range(16000, 44000, 2000):
		print "Pulse length set %d"%llen
		len_set = tgen_setup([[in_level,in_level,llen], [0,0,0]])
		#print len_set
		data_array = query_response(len_set)

########
def open_control():
	global in_level, data_array
	print "Opening up control span"
	len_set = tgen_setup([[in_level,in_level,8000], [in_level*0.8,in_level*1.2,36000], [0,0,0]])
	data_array = query_response(len_set)

def close_phase_loop(set_P):
	global in_level, data_array
	print "Closing phase loop"
	len_set = [['set_Y',set_P]]+triple_pulse(8000,4000,32000,in_level,8000)
	data_array = query_response(len_set)

def working():
	coarse_tune_cavity()
	switch_to_sel()
	ramp_field()
	fine_adjust_poffset()
	fine_adjust_field()
	fine_tune_cavity()
	stretch_pulse()
	open_control()
	fine_tune_cavity()
	time.sleep(1.2)
	close_phase_loop(2**17)

if __name__=='__main__':
	if (len(sys.argv) > 1):
		piezo_dc = int(sys.argv[1])
	working()
	send_val(8*[['tag',2]])
