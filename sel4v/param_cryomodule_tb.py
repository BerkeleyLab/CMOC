import os, sys
from math import sin, cos, pi, sqrt, log, ceil
from cmath import exp
from hashlib import sha1

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))) +
                "/submodules/build")
from read_regmap import get_map, get_reg_info

regmap_cryomodule = get_map("./_autogen/regmap_cryomodule.json")
ctl_regmap = get_map("./_autogen/regmap_llrf_shell.json")


# Note that Tstep is the ADC time step, also clocks the LLRF controller.
# Divide by two for the cavity simulator (rtsim) clock time step.
Tstep = 10e-9 # s
f0 = 1300e6   # Hz
nyquist_sign = -1    # -1 represents frequency inversion,
# as with high-side LO or even-numbered Nyquist zones.

# DDS setup for simulator should be static
# this construction is for 20 MHz / 94.286 MHz = 7/33
dds_num=7
dds_den=33

dds_phstep_h = int(dds_num*2**20/dds_den)
dds_mult = int(4096/dds_den)
dds_phstep_l = (dds_num*2**20)%dds_den * dds_mult
dds_modulo = 4096 - dds_mult*dds_den
dds_phstep = dds_phstep_h << 12 | dds_phstep_l
#print "# dds",dds_mult,dds_phstep_h, dds_phstep_l, dds_modulo

# The following three parameters are set in the Verilog at compile-time,
# not run-time.  Top-level setting in larger.v needs to be mirrored here.
lp_shift = 9  # see lp_pair.v, a.k.a. mode_shift
n_mech_modes = 7  # number of mechanical modes handled
df_scale = 9  # see cav4_freq.v

omega0 = f0*2*pi
mech_tstep = Tstep * n_mech_modes
interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes)/log(2)) # interp0.v

# scale a floating point number in range [-1,1) to fit in b-bit register
error_cnt=0
def fix(x,b,msg,opt=None):
  global error_cnt
  ss = 2**(b-1)
  # cordic_g = 1.646760258
  if (opt is "cordic"): ss = int(ss / 1.646760258)
  xx = int(x*ss+0.5)
  #print x,b,ss,xx
  if (xx > ss-1):
    xx = ss-1
    print("# error: %f too big (%s)"%(x,msg))
    error_cnt+=1
  if (xx < -ss):
    xx = -ss
    print("# error: %f too small (%s)"%(x,msg))
    error_cnt+=1
  return xx

class Mmode:
    """Cavity mechanical mode"""
    def __init__(self, name, freq, Q, mx, piezo_hack, lorentz_en):
	self.name=name
	self.freq = freq # Hz
	self.Q = Q
	self.mx = mx  # sqrt(J)  full-scale for resonator.v state
	self.piezo_hack = piezo_hack
	self.lorentz_en = lorentz_en

class Emode:
    """Cavity electrical mode"""
    def __init__(self, name, RoverQ, foffset, peakV, Q_0, Q_1, Q_2, phase_1, phase_2):
	self.name=name
	self.RoverQ = RoverQ # Ohm
	self.foffset = foffset   # Hz
	self.peakV = peakV  # V
	self.Q_0 = Q_0  # internal loss
	self.Q_1 = Q_1   # drive coupler (should be 4e7, maybe 8e4 for testing?)
	self.Q_2 = Q_2  # field probe
	self.phase_1 = phase_1
	self.phase_2 = phase_1

def RRRRR(name, regmap, value, station_index=None, mode_index=None, addr_offset=0):
    if station_index is not None:
	if mode_index is not None:
	    addr = get_reg_info(regmap_cryomodule, [station_index, mode_index], name)["base_addr"]
	else:
	    addr = get_reg_info(regmap_cryomodule, [station_index], name)["base_addr"]
    else:
	addr = get_reg_info(regmap_cryomodule, [], name)["base_addr"]
    if type(value) is list:
	for i, v in enumerate(value):
	    print addr_offset + addr + i, v, "#", name + "["+str(i)+"]"
    else:
	print addr_offset + addr, value, '#', name

# Pseudo-random generator initialization, see tt800v.v and prng.v
prng_seed="pushmi-pullyu"
def push_seed(addr,hf):
    for jx in range(25):
	mm=hf.digest()
	s=0
	for ix in range(4): s=s*256+ord(mm[ix])
	print "%d %u"%(addr,s)
	hf.update(chr(jx))

def gen_station(station_index, cav4_elec_phase_step, cav4_elec_modulo, emodes):
    # as we scale up, the following 10 parameters replicate per cavity:
    PAmax = 6e3   # W RF amplifier max
    PAbw = 1.5e6  # Hz bandwidth of power amplifier
    cav_adc_max = 1.2 # sqrt(W)
    rfl_adc_max = 180.0 # sqrt(W)
    fwd_adc_max = 160.0 # sqrt(W)
    phase_1 = 0  # forward monitor phase shift
    phase_2 = 0  # reflected monitor prompt phase shift
    a_cav_offset = 10
    a_rfl_offset = 30
    a_for_offset = 20

    amp_lp_bw = fix(Tstep*PAbw*32, 18, "amp_lp_bw")

    cav4_elec_phase_step = cav4_elec_phase_step
    cav4_elec_modulo = cav4_elec_modulo

    drive_couple_out_coupling = [fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic"),
				 fix(-sqrt(PAmax) / rfl_adc_max, 18, "out2", "cordic"),
				 fix(phase_1 / 180.0, 19, "out3"),
				 fix(phase_2 / 180.0, 19, "out4")]

    for i, m in enumerate(emodes):
	print "# Cavity electrical mode %d: %s"%(i, m.name)
	Q_L = 1 / (1/m.Q_0 + 1/m.Q_1 + 1/m.Q_2)
	# x is defined as sqrt(U)
	xmax = m.peakV / sqrt(m.RoverQ*omega0)
	# four registers of pair_couple.v
	out_couple_out_coupling = [
	    fix(sqrt(omega0/m.Q_1) * xmax / rfl_adc_max, 18, m.name+".out1", "cordic"),
	    fix(sqrt(omega0/m.Q_2) * xmax / cav_adc_max, 18, m.name+".out2", "cordic"),
	    fix(m.phase_1 / 180.0, 19, m.name+"out3"),
	    fix(m.phase_2 / 180.0, 19, m.name+"out4")]
	# see Pro tip in eav4_elec.v for better limit on foffset
	# XXX document using 33 for what's really a 28-bit register
	coarse_freq = fix(Tstep*nyquist_sign*m.foffset, 33, m.name+"coarse_freq")
	V_achievable = 2*sqrt(PAmax*m.Q_1*m.RoverQ)
	drive_coupling = fix( V_achievable / m.peakV, 18, m.name+"drive_coupling", "cordic")
	# bandwidth in Hz = f_clk/2/2^shift/(2*pi) * bw_register/2^17 = omega_0/(2*pi*2*Q_L)
	# XXX document origin of *2.0 better, compensates for shift right in lp_pair.v
	bw = fix(Tstep*omega0/(2*Q_L)*(2**lp_shift)*2.0, 18, m.name+".bw")
	RRRRR('coarse_freq', regmap_cryomodule, coarse_freq, station_index, i)
	RRRRR('drive_coupling', regmap_cryomodule, drive_coupling, station_index, i)
	RRRRR('bw', regmap_cryomodule, bw, station_index, i)
	RRRRR('out_couple_out_coupling', regmap_cryomodule, out_couple_out_coupling, station_index, i)

    RRRRR('cav4_elec_phase_step', regmap_cryomodule, cav4_elec_phase_step, station_index)
    RRRRR('cav4_elec_modulo', regmap_cryomodule, cav4_elec_modulo, station_index)
    RRRRR('amp_lp_bw', regmap_cryomodule, amp_lp_bw, station_index)
    RRRRR('drive_couple_out_coupling', regmap_cryomodule, drive_couple_out_coupling, station_index)
    RRRRR('a_cav_offset', regmap_cryomodule, a_cav_offset, station_index)
    RRRRR('a_rfl_offset', regmap_cryomodule, a_rfl_offset, station_index)
    RRRRR('a_for_offset', regmap_cryomodule, a_for_offset, station_index)

    if prng_seed is not None:
	print "# PRNG subsystem seed is '%s'"%prng_seed
	hf = sha1()
	hf.update(prng_seed)
	push_seed(get_reg_info(regmap_cryomodule,[station_index],"prng_iva")["base_addr"],hf)
	push_seed(get_reg_info(regmap_cryomodule,[station_index],"prng_ivb")["base_addr"],hf)
	print "%d 1  # turn on PRNG"%(get_reg_info(regmap_cryomodule,[station_index],"prng_random_run")["base_addr"])

def gen_controller(controller_index, dds_phstep, dds_modulo):
    #set_ctl(addr, "ph_offset", -35800)
    # A change to offset the DDS phase, and match the signals between
    # cryomodule_tb and larger_tb
    wave_samp_per=1
    wave_shift=3
    # The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
    # fits nicely within the 32768 limit for small values of wave_samp_per
    lo_cheat=(32/33.0)**2;
    yscale=lo_cheat*(33*wave_samp_per)**2*4**(8-wave_shift)/32
    RRRRR('wave_samp_per', ctl_regmap, wave_samp_per, addr_offset=controller_base)
    RRRRR('wave_shift', ctl_regmap, wave_shift, addr_offset=controller_base)
    RRRRR('sel_thresh', ctl_regmap, 5000, addr_offset=controller_base)
    RRRRR('ph_offset', ctl_regmap, -150800, addr_offset=controller_base)
    RRRRR('sel_en', ctl_regmap, 1, addr_offset=controller_base)
    RRRRR('lp1a_kx', ctl_regmap, 20486, addr_offset=controller_base)
    RRRRR('lp1a_ky', ctl_regmap, -20486, addr_offset=controller_base)
    RRRRR('chan_keep', ctl_regmap, 4080, addr_offset=controller_base)
    addr = get_reg_info(ctl_regmap,[],'lim')['base_addr']
    delay_pc=4096
    def delay_set_new(ticks,addr,data):
	delay_pc += 4
	print "%d %d # duration"  %(delay_pc-4, ticks)
	print "%d %d # dest addr (%s)" %(delay_pc-3, addr, addr)
	print "%d %d # value_msb" %(delay_pc-2, int(data)/65536)
	print "%d %d # value_lsb" %(delay_pc-1, int(data)%65536)

    if 0:  # FGEN
	print "3 300    # duration"
	print "4 5000   # amp_slope"
	print "7 22640  # amp_max"
	print "555 7600 # wait"
	print "10 36    # amp dest address (lim X hi)"
	print "12 38    # amp dest address (lim X lo)"
    else:  # TGEN
	# delay_set(0,    'lim_X_hi', 22640)
	# delay_set(6000, 'lim_X_lo', 22640)
	# delay_set(0,    'lim_X_hi', 0)
	# delay_set(0,    'lim_X_lo', 0)
	delay_set_new(0, addr, 22640)
	delay_set_new(6000, addr+2, 22640)
	delay_set_new(0, addr, 0)
	delay_set_new(0, addr+2, 0)

    if (error_cnt > 0):
	print "# %d scaling errors found"%error_cnt
	exit(1)

def gen_cryomodule(station_count=2):
    emode_count = 2
    mmode_count = 2
    c_reg_base = []

    VPmax = 48.0  # V piezo drive max

    emode1 = Emode("pi", RoverQ = 1036.0, foffset = 5.0, peakV = 1.5e6,
		   Q_0 = 1e10, Q_1 = 8.1e4, Q_2 = 2e9, phase_1 = 0, phase_2 = 0)
    emode2 = Emode("8pi/9", RoverQ = 10.0, foffset = -8e5, peakV = 0.15e6,
		   Q_0 = 1e10, Q_1 = 8.1e4, Q_2 = 2e9, phase_1 = 10.0, phase_2 = -180.0)

    # This mode is silly, but lets the frequency change on the time scale of
    # software simulation = 40 us
    mmode1 = Mmode("silly", freq = 30000, Q = 5.0, mx = 1.13, piezo_hack = 0, lorentz_en = 1)
    mmode2 = Mmode("piezo", freq = 100000, Q = 5.0, mx = 0, piezo_hack = 80000, lorentz_en = 0)

    for si in range(station_count):
	c_reg_base.append(get_reg_info(regmap_cryomodule,[],'llrf_'+str(si)+'_xxxx')['base_addr'])

    # Mechanical modes
    # Still may have bugs:
    #   Mechanical mode coupling
    resonator_prop_const=[]
    piezo_couple=[]
    dot_0_k=[];  outer_prod_0_k=[]
    dot_1_k=[];  outer_prod_1_k=[]
    dot_2_k=[];  outer_prod_2_k=[]
    for i,m in enumerate([mmode1,mmode2]):
	print "# Cavity mechanical mode %d: %s"%(i,m.name)
	w1 = mech_tstep * 2*pi*m.freq
	# a1 + b1 * i represents the pole in the normalized s-plane
	a1 = w1 * (-1/(2.0*m.Q))
	b1 = w1 * sqrt(1-1/(4.0*m.Q**2))
	z_pole = exp(a1+b1*1j)
	print "# z_pole = %7f + %7fi"%(z_pole.real,z_pole.imag)
	a1 = z_pole.real-1.0
	b1 = z_pole.imag
	scale = int(-log(max(a1,b1))/log(4))
	scale = max(min(scale,9),2)
	a2 = a1 * 4**scale
	b2 = b1 * 4**scale
	print "# debug",w1,a1,b1,scale,a2,b2
	#c1 = -w1**2 / (k*b1)
	resonator_prop_const.append( (fix(a2,18,"a2")&(2**18-1)) + ((9-scale) << 18) )
	resonator_prop_const.append( (fix(b2,18,"b2")&(2**18-1)) + ((9-scale) << 18) )
	# the above is tested.  Onwards to the work-in-progress
	dc_gain = b2/(a2**2+b2**2)  # resonator.v
	net_coupling = 130.0 # Hz / V^2, negative is implicit
	Amn =   sqrt(net_coupling/emode1.RoverQ) / omega0  # sqrt(J)/V^2
	Cmn = - sqrt(net_coupling*emode1.RoverQ) * omega0  # 1/s/sqrt(J)
	outer = m.lorentz_en * Amn / mmode1.mx * emode1.peakV**2 / dc_gain # dimensionless
	inner = m.lorentz_en * Cmn * mmode1.mx * Tstep / 2**df_scale / interp_gain # dimensionless
	# note that inner*outer = net_coupling * emode1.peakV**2 * Tstep
	print "# outer =",outer,"inner =",inner
	# additional scaling below comes from the 32-bit mech_phase_fine
	# accumulator, but only 18-bit d_result
	outer_prod_0_k.append(fix(outer/128,18,"outer"))
	outer_prod_0_k.append(0)
	dot_0_k.append(0)
	dot_0_k.append(fix(inner/128,18,"inner"))
	# Use second resonance to test piezo subsystem
	# The scaling is still non-quantitative
	piezo_couple.append(m.piezo_hack)
	piezo_couple.append(0)
	dot_2_k.append(0)
	dot_2_k.append(m.piezo_hack)
    for si in range(station_count):
	gen_station(si, dds_modulo, dds_phstep, [emode1, emode2])
	RRRRR('dot_0_k', regmap_cryomodule, dot_0_k, si)
	RRRRR('dot_1_k', regmap_cryomodule, dot_1_k, si)
	RRRRR('dot_2_k', regmap_cryomodule, dot_2_k, si)
	RRRRR('outer_prod_0_k', regmap_cryomodule, outer_prod_0_k, si)
	RRRRR('outer_prod_1_k', regmap_cryomodule, outer_prod_1_k, si)
	RRRRR('outer_prod_2_k', regmap_cryomodule, outer_prod_2_k, si)
	RRRRR('piezo_couple', regmap_cryomodule, piezo_couple, si)
	#gen_controller(si, dds_modulo, dds_phstep)
    RRRRR('resonator_prop_const', regmap_cryomodule, resonator_prop_const)
    # TODO HACK:
    # Since the sole purpose of this file is to feed cryomodule_tb
    print "555 600    # Add delay of 600 cycles"
    print "14336 1    # Flip the circle buffer"
    print "14337 1    # Flip the circle buffer"

if __name__ == "__main__":
    gen_cryomodule(station_count=2)
