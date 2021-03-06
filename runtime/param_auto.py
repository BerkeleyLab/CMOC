from math import sin, cos, pi, sqrt, log
from numpy import log as clog
from numpy import exp as cexp
from hashlib import sha1
from numpy import ceil

class c_regs:
	def __init__(self,name,addr,value):
		self.name=name
		self.addr=addr
		self.value=(value+2**32) if value <0 else value
	def print_regs(self):
		return  '%d %d'%(self.addr,self.value)
		#return  '%d %d # %s'%(self.addr,self.value,self.name)

class Mmode:
  """Cavity mechanical mode"""
  def __init__(self,name,freq,Q,mx,piezo_hack,lorentz_en,vibration_hack):
	self.name=name
	self.freq=freq
	self.Q=Q
	self.mx=mx
	self.piezo_hack=piezo_hack
	self.lorentz_en=lorentz_en
	self.vibration_hack=vibration_hack

class Emode:
  """Cavity electrical mode"""
  def __init__(self, name,RoverQ,foffset,peakV,Q_0,Q_1,Q_2,phase_1,phase_2,mech_couplings):
	self.name=name
	self.RoverQ=RoverQ
	self.foffset=foffset
	self.peakV=peakV
	self.Q_0=Q_0
	self.Q_1=Q_1
	self.Q_2=Q_2
	self.phase_1=phase_1
	self.phase_2=phase_2
	self.mech_couplings=mech_couplings # coupling coefficients in Hz/V^2

# scale a floating point number in range [-1,1) to fit in b-bit register
error_cnt=0
def fix(x,b,msg,opt=None):
  global error_cnt
  ss = 1 << (b-1)
  # cordic_g = 1.646760258
  if opt is "cordic": ss = int(ss / 1.646760258)
  xx = int(x*ss+0.5)
  ##print x,b,ss,xx
  if xx > ss-1:
	xx = ss-1
	#print("# error: %f too big (%s)"%(x,msg))
	error_cnt+=1
  if xx < -ss:
	xx = -ss
	#print("# error: %f too small (%s)"%(x,msg))
	error_cnt+=1
  return xx

def set_reg(offset,prefix,name,regmap,namespace,sim_base):
  _regs=[]
  val = namespace[name]  # globals() or locals()?
  # val = locals()[name]  # globals() or locals()?
  if type(val) is list:
	for i,v in enumerate(val):
	  # #print sim_base+offset+regmap[name]+i, v, "#", prefix+name+"["+str(i)+"]"
	  #print name, v, "#", prefix+name+"["+str(i)+"]"
	  _regs.append(c_regs(name,sim_base+offset+regmap[name]+i,v))
  else:
	# #print sim_base+offset+regmap[name], val, "#", prefix+name
	#print name, val, "#", prefix+name
	_regs.append(c_regs(name,sim_base+offset+regmap[name],val))
  return  _regs

regmap_ctl={"null":0}
for l in open("../sel4v/run_map.txt").readlines():
	ll = l.strip().split()
	regmap_ctl[ll[1]] = int(ll[0])

def set_ctl(n,v):
	return c_regs(n,regmap_ctl[n],v)

global delay_pc
delay_pc=4096
def delay_set(ticks,addr,data):
	global delay_pc
	delay_pc += 4
	return [
		c_regs('delay',    delay_pc-4, ticks),
		c_regs('dest_addr',delay_pc-3, regmap_ctl[addr]),
		c_regs('value_msb',delay_pc-2, int(data)/65536),
		c_regs('value_lsb',delay_pc-1, int(data)%65536)]

def push_seed(addr,hf):
  _regs=[]
  for jx in range(25):
	mm=hf.digest()
	s=0
	for ix in range(4):  s=s*256+ord(mm[ix])
	#print "%d %u"%(addr,s)
	hf.update(chr(jx))
	_regs.append(c_regs('tbd',addr,s))
  return _regs

def gen_reg_list(mode1_foffset=5.0,mode1_Q1=8.1e4,mmode1_freq=30e3,mmode1_Q=5.0,net1_coupling=100,net2_coupling=200,net3_coupling=150,sel_en=1,set_X=0.0,set_P=0.0,k_PA=0,k_PP=0,maxq=0,ph_offset=-35500,amp_max=22640,fwd_phase_shift=0,rfl_phase_shift=0,cav_phase_shift=0,duration=300,PRNG_en=1,piezo_dc=0):
	regs=[]
	error_cnt=0

	#print 'mode1_foffset=%f,mode1_Q1=%f,mmode1_freq=%f,mmode1_Q=%f,net_coupling=%f'%(mode1_foffset,mode1_Q1,mmode1_freq,mmode1_Q,net_coupling)

        # Gang humbly requests that Q_1 be renamed Q_drive, and Q_2 as Q_probe.
        # Should apply here, physics.tex, elsewhere?

	# Note that Tstep is the ADC time step, also clocks the LLRF controller.
	# Divide by two for the cavity simulator (rtsim) clock time step.
	Tstep = 10e-9 # s
	f0 = 1300e6   # Hz
	nyquist_sign = -1    # -1 represents frequency inversion,
	# as with high-side LO or even-numbered Nyquist zones.

	VPmax = 48.0  # V piezo drive max

	# as we scale up, the following 10 parameters replicate per cavity:
	PAmax = 6e3   # W RF amplifier max
	PAbw = 1.5e6  # Hz bandwidth of power amplifier
	cav_adc_max = 1.2 # sqrt(W)
	rfl_adc_max = 180.0 # sqrt(W)
	fwd_adc_max = 160.0 # sqrt(W)
	phase_1 = fwd_phase_shift  # forward monitor phase shift
	phase_2 = rfl_phase_shift  # reflected monitor prompt phase shift
	cav_adc_off = 10
	rfl_adc_off = 20
	fwd_adc_off = 30


	mode1=Emode(name="pi",RoverQ=1036.0,foffset=mode1_foffset,peakV=1.5e6,Q_0=1e10,Q_1=mode1_Q1,Q_2=2e9,phase_1=rfl_phase_shift,phase_2=cav_phase_shift,mech_couplings=[net1_coupling,net2_coupling,net3_coupling])
	mode2=Emode(name="8pi/9",RoverQ=10.0,foffset=-8e5,peakV=0.15e6,Q_0=1e10,Q_1=8.1e4,Q_2=2e9,phase_1=10,phase_2=-180,mech_couplings=[0,0,0])

	mmode1=Mmode('silly', mmode1_freq, mmode1_Q, 1.13, 40000, 1, 80000)
	mmode2=Mmode('lowQ',       100000,      5.0,  1.5, 80000, 1, 20000)
	mmode3=Mmode('other',       24500,     25.0,  1.5, 20000, 1, 10000)

	# DDS setup for simulator should be static
	# this construction is for 20 MHz / 94.286 MHz = 7/33
	dds_num=7
	dds_den=33

	# The following three parameters are set in the Verilog at compile-time,
	# not run-time.  Top-level setting in larger.v needs to be mirrored here.
	lp_shift = 9  # see lp_pair.v, a.k.a. mode_shift
	n_mech_modes = 7  # number of mechanical modes handled
	df_scale = 9  # see cav4_freq.v

        # ==== end of system configuration

        # ==== the following dictionaries should get pulled in from Verilog somehow
	sim_base=16384  # base address for vmod1, see larger.v line 33

	regmap_global = {
                'dds_phstep' : 1,
                'dds_modulo' : 2,
                'amp_bw' : 5,
                'prompt' : 8,  # base address of 4 registers
                'cav_adc_off' : 49,
                'rfl_adc_off' : 50,
                'fwd_adc_off' : 51,
                'sat_ctl'     : 55,
                'res_prop'    : 1*1024,  # base address of 1024 registers
                'dot_0_k'     : 2*1024,  # base address of 1024 registers
                'outer_0_k'   : 3*1024,  # base address of 1024 registers
                'dot_1_k'     : 4*1024,  # base address of 1024 registers
                'outer_1_k'   : 5*1024,  # base address of 1024 registers
                'dot_2_k'     : 6*1024,  # base address of 1024 registers
                'outer_2_k'   : 7*1024,  # base address of 1024 registers
                'piezo_couple' : 8*1024,  # base address of 1024 registers
                'noise_couple' : 9*1024}  # base address of 1024 registers

        # base address for cavity n (zero-based) is 16+8*n
	regmap_emode = {
	  'coarse_freq' : 1,
	  'drive_coupling' : 2,
	  'bw' : 3,
	  'out_couple' : 4}   # base address of 4 registers
        from read_regmap import get_map
        regmap = get_map("../sel4v/_autogen/regmap_cryomodule.json")

        # ==== end of hardware register dictionaries

        # send a register value "out"
        # looks address up in regmap[name]
        # finds value via name in python global namespace
        # value can be a scalar or a list
        # prefix and name are used to give a helpful comment
        # ==== now start the application-specific computations

        # Still may have bugs:
        #   Mechanical mode coupling
        # Needs a lot of work:
        #   LLRF controller

	omega0 = f0*2*pi
	mech_tstep = Tstep * n_mech_modes
	interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes)/log(2)) # interp0.v

        #print "# Globals"
	amp_bw = fix(Tstep*PAbw*32, 18, "amp_bw")

	dds_phstep_h = int(dds_num*2**20/dds_den)
	dds_mult = int(4096/dds_den)
	dds_phstep_l = (dds_num*2**20)%dds_den * dds_mult
	dds_modulo = 4096 - dds_mult*dds_den
	dds_phstep = dds_phstep_h << 12 | dds_phstep_l
	sat_ctl = 65535
	#print "# dds",dds_mult,dds_phstep_h, dds_phstep_l, dds_modulo

	# four registers of pair_couple.v
	# neglect losses between directional coupler and cavity
	prompt = [
		fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic"),
		fix(-sqrt(PAmax) / rfl_adc_max, 18, "out2", "cordic"),
		fix(phase_1 / 180.0, 19, "out3"),
		fix(phase_2 / 180.0, 19, "out4")]

        # Mechanical modes
	res_prop=[]
	piezo_couple=[]
	noise_couple=[]
	dot_0_k=[];  outer_0_k=[]
	dot_1_k=[];  outer_1_k=[]
	dot_2_k=[];  outer_2_k=[]
	mech_mode_list = [mmode1,mmode2,mmode3]
	for i,m in enumerate(mech_mode_list):
	  #print "# Cavity mechanical mode %d: %s"%(i,m.name)
	  w1 = mech_tstep * 2*pi*m.freq
	  # a1 + b1 * i represents the pole in the normalized s-plane
	  a1 = w1 * (-1/(2.0*m.Q))
	  b1 = w1 * sqrt(1-1/(4.0*m.Q**2))
	  z_pole = cexp(a1+b1*1j)
	  #print "# z_pole = %7f + %7fi"%(z_pole.real,z_pole.imag)
	  a1 = z_pole.real-1.0
	  b1 = z_pole.imag
	  scale = int(-log(max(a1,b1))/log(4))
	  scale = max(min(scale,9),2)
	  a2 = a1 * 4**scale
	  b2 = b1 * 4**scale
	  #print "# debug",w1,a1,b1,scale,a2,b2
	  #c1 = -w1**2 / (k*b1)
	  res_prop.append( (fix(a2,18,"a2")&(2**18-1)) + ((9-scale) << 18) )
	  res_prop.append( (fix(b2,18,"b2")&(2**18-1)) + ((9-scale) << 18) )
	  # the above is tested.  Onwards to the work-in-progress
	  dc_gain = b2/(a2**2+b2**2)  # resonator.v
	  m.dc_gain = dc_gain   # per-electical mode coupling computation will need this
	  piezo_couple.append(m.piezo_hack)
	  piezo_couple.append(0)
	  noise_couple.append(m.vibration_hack)
	  noise_couple.append(0)
	  #dot_2_k.append(0)
	  #dot_2_k.append(m.piezo_hack)

	for i,m in enumerate([mode1,mode2]):
	  #print "# Cavity electrical mode %d: %s"%(i,m.name)
	  Q_L = 1 / (1/m.Q_0 + 1/m.Q_1 + 1/m.Q_2)
	  # x is defined as sqrt(U)
	  xmax = m.peakV / sqrt(m.RoverQ*omega0)
	  # four registers of pair_couple.v
	  out_couple = [
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
	  for n in regmap_emode.keys():
		regs.extend(set_reg(16+8*i,m.name+".",n,regmap_emode,locals(),sim_base))
	  for j,mech_couple in enumerate(m.mech_couplings):
		#print "# elec mode %d coupling index %d value %f"%(i,j,mech_couple)
		# Number of electrical modes implemented in the hardware is set by the
		# parameter mode_count in cav4_elec.v, frozen at the time of synthesis.
		# The address decode generator (newad.py) will embed mode index into a
		# text name, which is then given an address by addr_map.vh.  This explains
		# the funny-looking exec at the end of this stanze.
		mech_mode = mech_mode_list[j]
		Amn =   sqrt(mech_couple/m.RoverQ) / omega0  # sqrt(J)/V^2
		Cmn = - sqrt(mech_couple*m.RoverQ) * omega0  # 1/s/sqrt(J)
		lorentz_en = 1
		outer = lorentz_en * Amn / mech_mode.mx * m.peakV**2 / mech_mode.dc_gain # dimensionless
		inner = lorentz_en * Cmn * mech_mode.mx * Tstep / 2**df_scale / interp_gain # dimensionless
		# note that inner*outer = net_coupling * mode1.peakV**2 * Tstep
		#print "# outer =",outer,"inner =",inner
		# additional scaling below comes from the 32-bit mech_phase_fine
		# accumulator, but only 18-bit d_result
		exec '''outer_%d_k.append(fix(outer/128,18,"outer")); outer_%d_k.append(0); dot_%d_k.append(0); dot_%d_k.append(fix(inner/128,18,"inner"))''' % (i,i,i,i)

	# Must be after electrical mode processing, to pick up outer_0_k etc.
	for n in regmap_global.keys():
	  r_hg_0=set_reg(0,"",n,regmap_global,locals(),sim_base)
	  regs.extend(r_hg_0)

	# Pseudo-random generator initialization, see tt800v.v and prng.v
	prng_seed="pushmi-pullyu"
	if prng_seed:
	  #print "# PRNG subsystem seed is '%s'"%prng_seed
	  hf = sha1()
	  hf.update(prng_seed)
	  r53=push_seed(53+sim_base,hf)
	  r54=push_seed(54+sim_base,hf)
	  #print "%d 1  # turn on PRNG"%(52+sim_base)
	regs.extend(r53)
	regs.extend(r54)
	regs.append(c_regs('turn on PRNG',52+sim_base,PRNG_en))

        # Just hack in a few quick values for the controller
        # This should really be another construction as above,
        # maybe in a separate Python module?
        # static DDS config, 7/33 as above
        # #print "17 %d  # phase_step"%dds_phstep
        # #print "18 %d  # modulo"%dds_modulo
        #print "phase_step %d  # phase_step"%dds_phstep
        #print "modulo %d  # modulo"%dds_modulo
	wave_samp_per=1
	wave_shift=3
        # The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
        # fits nicely within the 32768 limit for small values of wave_samp_per
	lo_cheat=(32/33.0)**2
	yscale=lo_cheat*(33*wave_samp_per)**2*4**(8-wave_shift)/32

	regs.append(set_ctl('phase_step',dds_phstep))
	regs.append(set_ctl('modulo',4))
	regs.append(set_ctl('wave_samp_per',wave_samp_per))
	regs.append(set_ctl('wave_shift',wave_shift))
	regs.append(set_ctl('piezo_dc',piezo_dc))
	regs.append(set_ctl('sel_thresh',5000))
	regs.append(set_ctl('ph_offset',ph_offset))
	regs.append(set_ctl('sel_en',sel_en))
	regs.append(set_ctl('lp1a_kx_re',20486))
	regs.append(set_ctl('lp1a_ky_re',-20486))

	#regs.append(c_regs('wait',555,150-12))
	regs.append(set_ctl('chan_keep',4080))
	#regs.append(set_ctl('lim',22640))
	#regs.append(set_ctl('lim',22640))
	regs.append(set_ctl('set_X',int(set_X)))
	regs.append(set_ctl('set_Y',int(set_P)))
	regs.append(set_ctl('coeff_X_I',-100))
	regs.append(set_ctl('coeff_X_P',k_PA))
	regs.append(set_ctl('coeff_Y_I',-100))
	regs.append(set_ctl('coeff_Y_P',k_PP))
	regs.append(set_ctl('lim_X_hi',0))
	regs.append(set_ctl('lim_Y_hi',0))
	regs.append(set_ctl('lim_X_lo',0))
	regs.append(set_ctl('lim_Y_lo',0))

	global delay_pc
	if 0:  # FGEN
	  regs.append(c_regs('duration',3,duration))
	  regs.append(c_regs('amp_slope',4,5000))
	  regs.append(c_regs('amp_max',7,amp_max))
	  regs.append(c_regs('amp_dest_addr',10,36))
	  regs.append(c_regs('amp_dest_addr',12,38))
	elif 0: # TGEN
	  delay_pc = 4096
	  # start the pulse in open loop (fixed drive amplitude) mode
	  regs.extend(delay_set(0, 'lim_Y_hi', 0))
	  regs.extend(delay_set(0, 'lim_Y_lo', 0))
	  regs.extend(delay_set(0, 'lim_X_hi', 22640))
	  regs.extend(delay_set(500*8, 'lim_X_lo', 22640))
	  # allow the amplitude loop to run
	  #regs.extend(delay_set(0, 52, 26000))
	  regs.extend(delay_set(duration*8, 'lim_X_lo', 16000))
	  # allow the phase loop to run
	  regs.extend(delay_set(0, 'lim_Y_hi',  maxq))
	  regs.extend(delay_set(5000*8, 'lim_Y_lo', -maxq))
	  regs.extend(delay_set(0, 'lim_X_hi', 0))
	  regs.extend(delay_set(0, 'lim_X_lo', 0))
	else:
	  delay_pc = 4096
	  regs.extend(delay_set(0, 'lim_X_hi', amp_max))
	  regs.extend(delay_set(duration*8, 'lim_X_lo', amp_max))
	  regs.extend(delay_set(0, 'lim_X_hi', 0))
	  regs.extend(delay_set(0, 'lim_X_lo', 0))
	  for jx in range(6):
		regs.extend(delay_set(0,'null',0))

	if error_cnt > 0:
	  print "# %d scaling errors found"%error_cnt
	  #exit(1)

	return [regs,error_cnt]

if __name__=='__main__':
	param={'net1_coupling': 61.0, 'sel_en': 0.0, 'set_X': 0.0, 'mode1_foffset': 5.0, 'ph_offset': -35800.0, 'mmode1_freq': 30000.0, 'mode1_Q1': 81000.0, 'mmode1_Q': 5.0}
	[regs,err_cnt]=gen_reg_list(**param)
	for reg in regs:  print reg.print_regs()
