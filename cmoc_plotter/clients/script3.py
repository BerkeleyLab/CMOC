# TODO:
# This file is hard-coded to work with cavity Number 0: look inside get_reg calls.
import sys
import os
import time
import re
import numpy
from pspeps_io.utilities import decode_2s_comp
from read_regmap import get_map, get_reg_info

visual=0
if visual:
	import matplotlib.pyplot as plt
	plt.ion()
	fig=plt.figure()

cic_base_period = 33  # default parameter in llrf_dsp.v
wave_samp_per = 1  # set by paramhg.py
Tstep = 10e-9  # as set in paramhg.py
dt = cic_base_period*2*wave_samp_per*Tstep   # seconds

base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
reg_map = get_map(os.path.join(base_dir, "../_autogen/regmap_cryomodule.json"))

def get_write_address(name):
	if type(name) is int:
		return name
	else:
		offset = 0
		if name.endswith(']'):
			x = re.search('^(\w+)\s*\[(\d+)\]', name)
			if x:
				name, offset = x.group(1), int(x.group(2))
		r = get_reg_info(reg_map, [0], name)
		return  r['base_addr'] + offset

def get_reg_addr(name):
       return get_write_address(name)

def send_val(set_list):
        regs = []
        for x in set_list:
                name, val = x[0], x[1]
                addr = get_reg_addr(name)
                ethio_reg = target.get_reg_by_addr(addr)
                v = decode_2s_comp(val, bits=ethio_reg.width,
                                   signed=(ethio_reg.sign=='signed'))
                regs.append((addr, v))
        target.write_regs(regs)

global delay_pc
def delay_set(ticks, addr, data):
	global delay_pc
	delay_pc += 4
	return [
		[delay_pc-4, ticks],
		[delay_pc-3, addr],
		[delay_pc-2, int(data)/65536],
		[delay_pc-1, int(data)%65536]]

def tgen_setup(mmlist):
	global delay_pc
	delay_pc = get_reg_addr('XXX')
	l=[]
        lim_X_hi = get_reg_addr('lim')
        lim_Y_hi = lim_X_hi + 1
        lim_X_lo = lim_X_hi + 2
        lim_Y_lo = lim_X_hi + 3
	for a in mmlist:
		l += delay_set(   0, lim_X_lo, a[0])
		l += delay_set(a[2], lim_X_hi, a[1])
	l += delay_set( 0, 0, 0)  # stop program
	return l

def simple_pulse(level,pulse_len):
	a = tgen_setup([[level,level,pulse_len],[0,0,0]])
	#print a
	return a

def triple_pulse(t1,t2,t3,level,maxq):
	global delay_pc
	delay_pc = get_reg_addr('XXX')
	l=[]
        lim_X_hi = get_reg_addr('lim')
        lim_Y_hi = lim_X_hi + 1
        lim_X_lo = lim_X_hi + 2
        lim_Y_lo = lim_X_hi + 3
	if 1:
		l += delay_set(   0, lim_Y_lo, 0)
		l += delay_set(   0, lim_Y_hi, 0)
		l += delay_set(   0, lim_X_lo, level)
		l += delay_set(  t1, lim_X_hi, level)
	if t2 > 0:
                span = 0.2
		l += delay_set(   0, lim_X_lo, level*(1.0-span))
		l += delay_set(  t2, lim_X_hi, level*(1.0+span))
	if t3 > 0:
		l += delay_set(   0, lim_Y_lo, 2**18-maxq)
		l += delay_set(  t3, lim_Y_hi,  maxq)
	l += delay_set( 0, lim_Y_lo, 0)
	l += delay_set( 0, lim_Y_hi, 0)
	l += delay_set( 0, lim_X_lo, 0)
	l += delay_set( 0, lim_X_hi, 0)
	l += delay_set( 0, 0, 0)  # stop program
	#print l
	return l

# query number stored in tag memory
#   0  reserved for never used
#   1  reserved for parameter update in progress
#   2  reserved for process stopped
#   3  unused
#  4-11 rotated through
# I use 4 bits here, even though the hardware is capable of 8
target = None
qnum=0
def query_response(query):
	global qnum, target
	tx_tag = qnum+4
	# print("sending tx_tag", tx_tag)
	send_val([['tag', 1]]+query+[['tag', tx_tag]])
	while True:
                data = yield False
		if data is None: continue
		res, aux = data
                if aux[16] == tx_tag == aux[17]: break
                # print("received tx_tag", tx_tag)
	qnum=(qnum+1)%12
        # Multiply iq_arrays back up with 4. Ethio assumes 14bit adc and scales the signal accordingly. Here we assume 16bit.
	yield res * 4

def angle_shift(angle, shift):
	a = angle+shift
	if (a > 262144): a -= 262144
	if (a <      0): a += 262144
	return a

def check_fwd(data):
	fwdm = abs(data[1])  # forward wave magnitude
        print fwdm
	mx = max(fwdm)
	ex = max(numpy.nonzero(fwdm>0.5*mx)[0])
	print "found end of pulse at %d?"%ex
	return ex

# arange for amplitude printout
# prange for phase fitting (frequency offset)
# drange for log amplitude fitting (decay time)
def find_slope(data,arange,prange,drange):
	#cav=data[:,0]+1j*data[:,1]
        cav=data[0]
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
	cav = data[0]
	phase = numpy.angle(cav)
	phase_avg = numpy.mean(phase[range(start-20,start-5)])
	use_ph_offset = numpy.pi+phase_avg
	if (use_ph_offset<0): use_ph_offset += 2*numpy.pi
	reg_ph_offset = int(use_ph_offset*262144/(2*numpy.pi)+0.5)
	print "found cavity phase %.1f degrees, guess register ph_offset should be %d"%(phase_avg*180/numpy.pi,reg_ph_offset)
	return reg_ph_offset

def find_level(data,start):
	cav=data[0]
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

base_set = [['sel_en',0], ['coeff',0], ['coeff[1]',0], ['ph_offset',0]] + simple_pulse(in_level,16000)
#print "base_set",base_set
#['amp_max',in_level], ['amp_min',in_level]]
sel_set = [['sel_en',1], ['coeff',0], ['coeff[1]',0]]

########
def coarse_tune_cavity():
	global piezo_dc, start, data_array
	vstep = 200
	slope = -10000
	oldslope = slope
	print "Coarse-tune with SEL off"
	while (abs(slope) > 800):
		print "Piezo set %d"%piezo_dc
                query = base_set + [['piezo_dc',
                                     piezo_dc+65536 if piezo_dc<0 else piezo_dc]]
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass
		if (start<0):
			start = check_fwd(data_array)+4
			l = len(data_array[0])
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
	global reg_ph_offset, data_array
	reg_ph_offset = find_ph_offset(data_array,start)
	print "Switching to SEL with ph_offset %d"%reg_ph_offset
	return query_response(sel_set + [['ph_offset',reg_ph_offset]])

########
def ramp_field():
	global in_level, data_array
	print "Ramping up field"
	out_level = 0
	while (out_level < out_level_goal*0.84):
		print "Level set %d"%in_level
                query = sel_set + simple_pulse(in_level,16000)
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass
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
                query = sel_set + [['ph_offset',trial_offset]]
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass
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
        query = sel_set + [['ph_offset',trial_offset]]
        y = query_response(query)
        y.send(None)  # prime the subroutine
        while True:
                try:
                        x = yield  # Capture the value that's sent
                        data_array = y.send(x)  # and pass it to the writer
                        if type(data_array) != numpy.ndarray: pass
                        else: break
                except StopIteration:
                        pass
	find_level(data_array,start)

########
def fine_adjust_field():
	global in_level, data_array
	print "Fine-adjusting field"
	out_level = 0
	while (abs(out_level/out_level_goal-1) > 0.01):
		print "Level set %d"%in_level
                query = sel_set + simple_pulse(in_level,16000)
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass
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
                query = sel_set + [['piezo_dc',piezo_dc+65536 if piezo_dc<0 else piezo_dc]]
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass
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
		query = tgen_setup([[in_level,in_level,llen], [0,0,0]])
		#print len_set
                y = query_response(query)
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                data_array = y.send(x)  # and pass it to the writer
                                if type(data_array) != numpy.ndarray: pass
                                else: break
                        except StopIteration:
                                pass

########
def open_control():
	global in_level, data_array
	print "Opening up control span"
	len_set = tgen_setup([[in_level,in_level,8000], [in_level*0.8,in_level*1.2,36000], [0,0,0]])
	return query_response(len_set)

def close_phase_loop(set_P=2**17):
	global in_level, data_array
	print "Closing phase loop"
	len_set = [['setmp[1]',set_P]]+triple_pulse(8000,4000,32000,in_level,8000)
	return query_response(len_set)

def wrap(coro):
        coro.send(None)  # prime the coro
        while True:
                try:
                        x = yield  # Capture the value that's sent
                        coro.send(x)  # and pass it to the writer
                except StopIteration:
                        pass

def get_name(var, namespace):
        for k, v in list(namespace.iteritems()):
                if v is var: return k

def run_c():
        routines = [coarse_tune_cavity, switch_to_sel, ramp_field,
                    fine_adjust_poffset, fine_adjust_field, fine_tune_cavity,
                    stretch_pulse, open_control, fine_tune_cavity,
                    close_phase_loop]
        for F in routines:
                y = F()
                y.send(None)  # prime the subroutine
                while True:
                        try:
                                x = yield  # Capture the value that's sent
                                y.send(x)  # and pass it to the writer
                        except StopIteration:
                                print("******Routine complete******")
                                break

def run(t):
        global target
        target = t
        return wrap(run_c())

if __name__=='__main__':
	if (len(sys.argv) > 1):
		piezo_dc = int(sys.argv[1])
	run()
	send_val(8*[['tag',2]])
