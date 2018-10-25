from math import sin, cos, pi, sqrt, log
from numpy import log as clog
from numpy import exp as cexp
from numpy import ceil

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
phase_1 = 0  # forward monitor phase shift
phase_2 = 0  # reflected monitor prompt phase shift
cav_adc_off = 10
rfl_adc_off = 20
fwd_adc_off = 30

class Emode:
  """Cavity electrical mode"""
  def __init__(self, name):
    self.name=name

mode1 = Emode("pi")
mode1.RoverQ = 1036.0 # Ohm
mode1.foffset = 5.0   # Hz
mode1.peakV = 1.5e6  # V
mode1.Q_0 = 1e10  # internal loss
mode1.Q_1 = 8.1e4   # drive coupler (should be 4e7, maybe 8e4 for testing?)
mode1.Q_2 = 2e9  # field probe
mode1.phase_1 = 0
mode1.phase_2 = 0

mode2 = Emode("8pi/9")
mode2.RoverQ = 10.0 # Ohm
mode2.foffset = -8e5  # Hz
mode2.peakV = 0.15e6  # V
mode2.Q_0 = 1e10  # internal loss
mode2.Q_1 = 8.1e4   # drive coupler
mode2.Q_2 = 2e9  # field probe
mode2.phase_1 = 10.0
mode2.phase_2 = -180.0

class Mmode:
  """Cavity mechanical mode"""
  def __init__(self,name):
    self.name=name

# This mode is silly, but lets the frequency change on the time scale of
# software simulation = 40 us
mmode1 = Mmode("silly")
mmode1.freq = 30000  # Hz
mmode1.Q = 5.0  # unitless
mmode1.mx = 1.13  # sqrt(J)  full-scale for resonator.v state
mmode1.piezo_hack = 0
mmode1.lorentz_en = 1

mmode2 = Mmode("piezo")
mmode2.freq = 100000  # Hz
mmode2.Q = 5.0  # unitless
mmode2.mx = 0  # disable
mmode2.piezo_hack = 80000
mmode2.lorentz_en = 0

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
  'res_prop'    : 1*1024,  # base address of 1024 registers
  'dot_0_k'     : 2*1024,  # base address of 1024 registers
  'outer_0_k'   : 3*1024,  # base address of 1024 registers
  'dot_1_k'     : 4*1024,  # base address of 1024 registers
  'outer_1_k'   : 5*1024,  # base address of 1024 registers
  'dot_2_k'     : 6*1024,  # base address of 1024 registers
  'outer_2_k'   : 7*1024,  # base address of 1024 registers
  'piezo_couple' : 8*1024}  # base address of 1024 registers

# base address for cavity n (zero-based) is 16+8*n
regmap_emode = {
  'coarse_freq' : 1,
  'drive_coupling' : 2,
  'bw' : 3,
  'out_couple' : 4}   # base address of 4 registers

# ==== end of hardware register dictionaries

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

# send a register value "out"
# looks address up in regmap[name]
# finds value via name in python global namespace
# value can be a scalar or a list
# prefix and name are used to give a helpful comment
def set_reg(offset,prefix,name,regmap):
  val = globals()[name]  # globals() or locals()?
  if (type(val) is list):
    for i,v in enumerate(val):
      print sim_base+offset+regmap[name]+i, v, "#", prefix+name+"["+str(i)+"]"
  else:
    print sim_base+offset+regmap[name], val, "#", prefix+name

# ==== now start the application-specific computations

# Still may have bugs:
#   Mechanical mode coupling
# Needs a lot of work:
#   LLRF controller

omega0 = f0*2*pi
mech_tstep = Tstep * n_mech_modes
interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes)/log(2)) # interp0.v

print "# Globals"
amp_bw = fix(Tstep*PAbw*32, 18, "amp_bw")

dds_phstep_h = int(dds_num*2**20/dds_den)
dds_mult = int(4096/dds_den)
dds_phstep_l = (dds_num*2**20)%dds_den * dds_mult
dds_modulo = 4096 - dds_mult*dds_den
dds_phstep = dds_phstep_h << 12 | dds_phstep_l
print "# dds",dds_mult,dds_phstep_h, dds_phstep_l, dds_modulo

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
dot_0_k=[];  outer_0_k=[]
dot_1_k=[];  outer_1_k=[]
dot_2_k=[];  outer_2_k=[]
for i,m in enumerate([mmode1,mmode2]):
  print "# Cavity mechanical mode %d: %s"%(i,m.name)
  w1 = mech_tstep * 2*pi*m.freq
  # a1 + b1 * i represents the pole in the normalized s-plane
  a1 = w1 * (-1/(2.0*m.Q))
  b1 = w1 * sqrt(1-1/(4.0*m.Q**2))
  z_pole = cexp(a1+b1*1j)
  print "# z_pole = %7f + %7fi"%(z_pole.real,z_pole.imag)
  a1 = z_pole.real-1.0
  b1 = z_pole.imag
  scale = int(-log(max(a1,b1))/log(4))
  scale = max(min(scale,9),2)
  a2 = a1 * 4**scale
  b2 = b1 * 4**scale
  print "# debug",w1,a1,b1,scale,a2,b2
  #c1 = -w1**2 / (k*b1)
  res_prop.append( (fix(a2,18,"a2")&(2**18-1)) + ((9-scale) << 18) )
  res_prop.append( (fix(b2,18,"b2")&(2**18-1)) + ((9-scale) << 18) )
  # the above is tested.  Onwards to the work-in-progress
  dc_gain = b2/(a2**2+b2**2)  # resonator.v
  net_coupling = 130.0 # Hz / V^2, negative is implicit
  Amn =   sqrt(net_coupling/mode1.RoverQ) / omega0  # sqrt(J)/V^2
  Cmn = - sqrt(net_coupling*mode1.RoverQ) * omega0  # 1/s/sqrt(J)
  outer = m.lorentz_en * Amn / mmode1.mx * mode1.peakV**2 / dc_gain # dimensionless
  inner = m.lorentz_en * Cmn * mmode1.mx * Tstep / 2**df_scale / interp_gain # dimensionless
  # note that inner*outer = net_coupling * mode1.peakV**2 * Tstep
  print "# outer =",outer,"inner =",inner
  # additional scaling below comes from the 32-bit mech_phase_fine
  # accumulator, but only 18-bit d_result
  outer_0_k.append(fix(outer/128,18,"outer"))
  outer_0_k.append(0)
  dot_0_k.append(0)
  dot_0_k.append(fix(inner/128,18,"inner"))
  # Use second resonance to test piezo subsystem
  # The scaling is still non-quantitative
  piezo_couple.append(m.piezo_hack)
  piezo_couple.append(0)
  dot_2_k.append(0)
  dot_2_k.append(m.piezo_hack)

for n in regmap_global.keys():
  set_reg(0,"",n,regmap_global)

for i,m in enumerate([mode1,mode2]):
  print "# Cavity electrical mode %d: %s"%(i,m.name)
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
    set_reg(16+8*i,m.name+".",n,regmap_emode)

# Pseudo-random generator initialization, see tt800v.v and prng.v
prng_seed="pushmi-pullyu"
def push_seed(addr,hf):
  for jx in range(25):
    mm=hf.digest()
    s=0
    for ix in range(4): s=s*256+ord(mm[ix])
    print "%d %u"%(addr,s)
    hf.update(chr(jx))
if (prng_seed is not None):
  from hashlib import sha1
  print "# PRNG subsystem seed is '%s'"%prng_seed
  hf = sha1()
  hf.update(prng_seed)
  push_seed(53+sim_base,hf)
  push_seed(54+sim_base,hf)
  print "%d 1  # turn on PRNG"%(52+sim_base)

# Just hack in a few quick values for the controller
# This should really be another construction as above, maybe in a separate Python module?
# static DDS config, 7/33 as above
regmap_ctl={}
for l in open("run_map.txt").readlines():
  ll = l.strip().split()
  regmap_ctl[ll[1]] = int(ll[0])

def set_ctl(n,v):
  print "%s %d  # %s"%(regmap_ctl[n],v,n)

set_ctl("phase_step", dds_phstep)
set_ctl("modulo", dds_modulo)

wave_samp_per=1
wave_shift=3
# The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
# fits nicely within the 32768 limit for small values of wave_samp_per
lo_cheat=(32/33.0)**2;
yscale=lo_cheat*(33*wave_samp_per)**2*4**(8-wave_shift)/32

set_ctl("wave_samp_per", wave_samp_per)

set_ctl("wave_shift",  wave_shift)
set_ctl("sel_thresh",  5000)
set_ctl("ph_offset", -35800)   # -91406 with both FGEN and TGEN
set_ctl("sel_en",   1)
set_ctl("lp1a_kx_re",  20486)
set_ctl("lp1a_ky_re", -20486)

#print "555 150  # wait for 150 cycles to pass"
set_ctl('chan_keep', 4080)
#set_ctl(lim_X_hi, 22640)
#set_ctl(lim_X_lo, 22640)

global delay_pc
delay_pc=4096
def delay_set(ticks,addr,data):
  global delay_pc
  delay_pc += 4
  print "%d %d # duration"  %(delay_pc-4, ticks)
  print "%d %d # dest addr (%s)" %(delay_pc-3, regmap_ctl[addr], addr)
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
  delay_set(0,    'lim_X_hi', 22640)
  delay_set(6000, 'lim_X_lo', 22640)
  delay_set(0,    'lim_X_hi', 0)
  delay_set(0,    'lim_X_lo', 0)

if (error_cnt > 0):
  print "# %d scaling errors found"%error_cnt
  exit(1)
