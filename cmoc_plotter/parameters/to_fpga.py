from math import sin, cos, pi, sqrt, log
from numpy import log as clog
from numpy import exp as cexp
from hashlib import sha1
from numpy import ceil

class Mmode:
    """Cavity mechanical mode"""
    def __init__(self, name, freq, Q, mx, piezo_hack, lorentz_en,
                 vibration_hack):
        self.name = name
        self.freq = freq
        self.Q = Q
        self.mx = mx
        self.piezo_hack = piezo_hack
        self.lorentz_en = lorentz_en
        self.vibration_hack = vibration_hack

class Emode:
    """Cavity electrical mode"""
    def __init__(self, name, RoverQ, foffset, peakV, Q_0, Q_1, Q_2, phase_1,
                 phase_2, mech_couplings):
        self.name = name
        self.RoverQ = RoverQ
        self.foffset = foffset
        self.peakV = peakV
        self.Q_0 = Q_0
        self.Q_1 = Q_1
        self.Q_2 = Q_2
        self.phase_1 = phase_1
        self.phase_2 = phase_2
        self.mech_couplings = mech_couplings # coupling coefficients in Hz/V^2

print_once = False
error_cnt = 0
def fix(x, b, msg, opt=None):
    '''
    scale a floating point number in range [-1,1) to fit in b-bit register
    '''
    global error_cnt
    ss = 1 << (b - 1)
    # cordic_g = 1.646760258
    if opt is "cordic": ss = int(ss / 1.646760258)
    xx = int(x * ss + 0.5)
    ##print x,b,ss,xx
    if xx > ss - 1:
        xx = ss - 1
        print("# error: %f too big (%s)"%(x,msg))
        error_cnt += 1
    if xx < -ss:
        xx = -ss
        print("# error: %f too small (%s)"%(x,msg))
        error_cnt += 1
    return xx

def generate_seed(hf, seed_length=25):
    values = []
    for jx in range(seed_length):
        mm = hf.digest()
        s = 0
        for ix in range(4):  s=s*256+ord(mm[ix])
        # print "%d %u"%(addr,s)
        hf.update(chr(jx))
        values.append(s)
    return values


class PhysicsToFPGA:

    def __init__(self, mode1_foffset=5.0, mode1_Q1=8.1e4,
                 mmode1_freq=30e3, mmode1_Q=5.0,
                 net1_coupling=100, net2_coupling=200, net3_coupling=150,
                 sel_en=1,
                 set_X=0.0, set_P=0.0,
                 k_PA=0, k_PP=0,
                 maxq=0,
                 ph_offset=-35500,
                 amp_max=22640,
                 fwd_phase_shift=0, rfl_phase_shift=0, cav_phase_shift=0,
                 duration=300,
                 PRNG_en=1,
                 piezo_dc=0):
        self.mode1_foffset = mode1_foffset
        self.mode1_Q1 = mode1_Q1
        self.mmode1_freq = mmode1_freq
        self.mmode1_Q = mmode1_Q
        self.net1_coupling = net1_coupling
        self.net2_coupling = net2_coupling
        self.net3_coupling = net3_coupling
        self.sel_en = sel_en
        self.set_X = set_X
        self.set_P = set_P
        self.k_PA = k_PA
        self.k_PP = k_PP
        self.maxq = maxq
        self.ph_offset = ph_offset
        self.amp_max = amp_max
        self.fwd_phase_shift = fwd_phase_shift
        self.rfl_phase_shift = rfl_phase_shift
        self.cav_phase_shift = cav_phase_shift
        self.duration = duration
        self.PRNG_en = PRNG_en
        self.piezo_dc = piezo_dc


    def __call__(self, lim_register_addr, cav_num=0):
        registers = []
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
        phase_1 = self.fwd_phase_shift  # forward monitor phase shift
        phase_2 = self.rfl_phase_shift  # reflected monitor prompt phase shift
        cav_adc_off = 10
        rfl_adc_off = 20
        fwd_adc_off = 30
        mode1=Emode(name="pi", RoverQ=1036.0, foffset=self.mode1_foffset,
                    peakV=1.5e6, Q_0=1e10, Q_1=self.mode1_Q1, Q_2=2e9,
                    phase_1=self.rfl_phase_shift, phase_2=self.cav_phase_shift,
                    mech_couplings=[self.net1_coupling, self.net2_coupling, self.net3_coupling])
        mode2=Emode(name="8pi/9", RoverQ=10.0, foffset=-8e5, peakV=0.15e6,
                    Q_0=1e10, Q_1=8.1e4, Q_2=2e9, phase_1=10, phase_2=-180,
                    mech_couplings=[0,0,0])
        mmode1=Mmode('silly', self.mmode1_freq, self.mmode1_Q, 1.13, 40000, 1, 80000)
        mmode2=Mmode('lowQ',            100000,           5.0,  1.5, 80000, 1, 20000)
        mmode3=Mmode('other',            24500,          25.0,  1.5, 20000, 1, 10000)

        # DDS setup for simulator should be static
        # this construction is for 20 MHz / 94.286 MHz = 7/33
        dds_num=7
        dds_den=33

        # The following three parameters are set in the Verilog at compile-time,
        # not run-time.  Top-level setting in larger.v needs to be mirrored here.
        lp_shift = 9  # see lp_pair.v, a.k.a. mode_shift
        n_mech_modes = 7  # number of mechanical modes handled
        df_scale = 9  # see cav4_freq.v
        omega0 = f0*2*pi
        mech_tstep = Tstep * n_mech_modes
        interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes)/log(2)) # interp0.v

        amp_bw = fix(Tstep*PAbw*32, 18, "amp_bw")

        dds_phstep_h = int(dds_num*2**20/dds_den)
        dds_mult = int(4096/dds_den)
        dds_phstep_l = (dds_num*2**20)%dds_den * dds_mult
        dds_modulo = 4096 - dds_mult*dds_den
        dds_phstep = dds_phstep_h << 12 | dds_phstep_l
        #print "# dds",dds_mult,dds_phstep_h, dds_phstep_l, dds_modulo

        # four registers of pair_couple.v
        # neglect losses between directional coupler and cavity
        prompt = [fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic"),
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
            # print "# Cavity mechanical mode %d: %s"%(i,m.name)
            w1 = mech_tstep * 2*pi*m.freq
            # a1 + b1 * i represents the pole in the normalized s-plane
            a1 = w1 * (-1/(2.0*m.Q))
            b1 = w1 * sqrt(1-1/(4.0*m.Q**2))
            z_pole = cexp(a1+b1*1j)
            # print "# z_pole = %7f + %7fi"%(z_pole.real,z_pole.imag)
            a1 = z_pole.real-1.0
            b1 = z_pole.imag
            scale = int(-log(max(a1,b1))/log(4))
            scale = max(min(scale,9),2)
            a2 = a1 * 4**scale
            b2 = b1 * 4**scale
            # print "# debug",w1,a1,b1,scale,a2,b2
            # c1 = -w1**2 / (k*b1)
            res_prop.append( (fix(a2,18,"a2")&(2**18-1)) + ((9-scale) << 18) )
            res_prop.append( (fix(b2,18,"b2")&(2**18-1)) + ((9-scale) << 18) )
            # the above is tested.  Onwards to the work-in-progress
            dc_gain = b2/(a2**2+b2**2)  # resonator.v
            m.dc_gain = dc_gain   # per-electical mode coupling computation will need this
            piezo_couple.append(m.piezo_hack)
            piezo_couple.append(0)
            noise_couple.append(m.vibration_hack)
            noise_couple.append(0)
            # dot_2_k.append(0)
            # dot_2_k.append(m.piezo_hack)

        for i, m in enumerate([mode1, mode2]):
            # print "# Cavity electrical mode %d: %s"%(i,m.name)
            Q_L = 1 / (1/m.Q_0 + 1/m.Q_1 + 1/m.Q_2)
            # x is defined as sqrt(U)
            xmax = m.peakV / sqrt(m.RoverQ*omega0)
            # four registers of pair_couple.v
            out_coupling = [fix(sqrt(omega0/m.Q_1) * xmax / rfl_adc_max, 18, m.name+".out1", "cordic"),
                            fix(sqrt(omega0/m.Q_2) * xmax / cav_adc_max, 18, m.name+".out2", "cordic"),
                            fix(m.phase_1 / 180.0, 19, m.name+"out3"),
                            fix(m.phase_2 / 180.0, 19, m.name+"out4")]
            print out_coupling
            # see Pro tip in cav4_elec.v for better limit on foffset
            # XXX document using 33 for what's really a 28-bit register
            coarse_freq = fix(Tstep * nyquist_sign * m.foffset, 33, m.name + "coarse_freq")
            V_achievable = 2 * sqrt(PAmax * m.Q_1 * m.RoverQ)
            drive_coupling = fix(V_achievable / m.peakV, 18, m.name + "drive_coupling", "cordic")
            # bandwidth in Hz = f_clk/2/2^shift/(2*pi) * bw_register/2^17 = omega_0/(2*pi*2*Q_L)
            # XXX document origin of *2.0 better, compensates for shift right in lp_pair.v
            bw = fix(Tstep*omega0/(2*Q_L)*(2**lp_shift)*2.0, 18, m.name+".bw")
            registers.append(['coarse_freq', [cav_num, i], coarse_freq])
            registers.append(['drive_coupling', [cav_num, i], drive_coupling])
            registers.append(['bw', [cav_num, i], bw])
            registers.append(['out_coupling', [cav_num, i], out_coupling])
            for j, mech_couple in enumerate(m.mech_couplings):
                # print "# elec mode %d coupling index %d value %f"%(i,j,mech_couple)
                # Number of electrical modes implemented in the hardware is set by the
                # parameter mode_count in cav4_elec.v, frozen at the time of synthesis.
                # The address decode generator (newad.py) will embed mode index into a
                # text name, which is then given an address by addr_map.vh.  This explains
                # the funny-looking exec at the end of this stanze.
                mech_mode = mech_mode_list[j]
                Amn =   sqrt(mech_couple / m.RoverQ) / omega0  # sqrt(J)/V^2
                Cmn = - sqrt(mech_couple * m.RoverQ) * omega0  # 1/s/sqrt(J)
                lorentz_en = 1
                outer = lorentz_en * Amn / mech_mode.mx * m.peakV**2 / mech_mode.dc_gain # dimensionless
                inner = lorentz_en * Cmn * mech_mode.mx * Tstep / 2**df_scale / interp_gain # dimensionless
                # note that inner*outer = net_coupling * mode1.peakV**2 * Tstep
                #print "# outer =",outer,"inner =",inner
                # additional scaling below comes from the 32-bit mech_phase_fine
                # accumulator, but only 18-bit d_result
                xx = fix(outer/128,18,"outer")
                yy = fix(inner/128,18,"inner")
                if i == 0:
                    outer_0_k.append(xx); outer_0_k.append(0); dot_0_k.append(0); dot_0_k.append(yy)
                elif i == 1:
                    outer_1_k.append(xx); outer_1_k.append(0); dot_1_k.append(0); dot_1_k.append(yy)
                #exec '''outer_%d_k.append(xx); outer_%d_k.append(0); dot_%d_k.append(0); dot_%d_k.append(yy)''' % (i,i,i,i)

        # Must be after electrical mode processing, to pick up outer_0_k etc.
        registers.append(['cav4_elec_phase_step', [cav_num], dds_phstep])
        registers.append(['cav4_elec_modulo', [cav_num], dds_modulo])
        registers.append(['amp_lp_bw', [cav_num], amp_bw])
        registers.append(['drive_couple_out_coupling', [cav_num], prompt])
        registers.append(['a_cav_offset', [cav_num], cav_adc_off])
        registers.append(['a_rfl_offset', [cav_num], rfl_adc_off])
        registers.append(['a_for_offset', [cav_num], fwd_adc_off])
        registers.append(['resonator_prop_const', [cav_num], res_prop])
        registers.append(['dot_0_k_out', [cav_num], dot_0_k])
        registers.append(['dot_1_k_out', [cav_num], dot_1_k])
        registers.append(['dot_2_k_out', [cav_num], dot_2_k])
        registers.append(['outer_prod_0_k_out', [cav_num], outer_0_k])
        registers.append(['outer_prod_1_k_out', [cav_num], outer_1_k])
        registers.append(['outer_prod_2_k_out', [cav_num], outer_2_k])
        registers.append(['piezo_couple', [cav_num], piezo_couple])
        registers.append(['noise_couple', [cav_num], noise_couple])

        # Pseudo-random generator initialization, see tt800v.v and prng.v
        prng_seed="pushmi-pullyu"
        if prng_seed:
            #print "# PRNG subsystem seed is '%s'"%prng_seed
            hf = sha1()
            hf.update(prng_seed)
            for x in generate_seed(hf):
                registers.append(['prng_iva', [cav_num], x])
            for x in generate_seed(hf):
                registers.append(['prng_ivb', [cav_num], x])
        registers.append(['prng_random_run', [cav_num], self.PRNG_en])

        # Just hack in a few quick values for the controller
        # This should really be another construction as above, maybe in a separate Python module?
        # static DDS config, 7/33 as above
        # #print "17 %d  # phase_step"%dds_phstep
        # #print "18 %d  # modulo"%dds_modulo
        #print "phase_step %d  # phase_step"%dds_phstep
        #print "modulo %d  # modulo"%dds_modulo
        wave_samp_per = 1
        wave_shift = 3
        # The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
        # fits nicely within the 32768 limit for small values of wave_samp_per
        lo_cheat = (32/33.0)**2
        yscale = lo_cheat * (33 * wave_samp_per)**2*4**(8 - wave_shift)/32

        registers.append(['phase_step', [cav_num], dds_phstep])
        registers.append(['modulo', [cav_num], 4])
        registers.append(['wave_samp_per', [cav_num], wave_samp_per])
        registers.append(['wave_shift', [cav_num], wave_shift])
        registers.append(['piezo_dc', [cav_num], self.piezo_dc])
        registers.append(['sel_thresh', [cav_num], 5000])
        registers.append(['ph_offset', [cav_num], self.ph_offset])
        registers.append(['sel_en', [cav_num], self.sel_en])
        registers.append(['lp1a_kx', [cav_num], 20486])
        registers.append(['lp1a_ky', [cav_num], -20486])
        registers.append(['chan_keep', [cav_num], 4080])

        registers.append(['setmp', [cav_num], [int(self.set_X), int(self.set_P)]])
        registers.append(['coeff', [cav_num], [-100, -100, self.k_PA, self.k_PP]])
        registers.append(['lim', [cav_num], [0, 0, 0, 0]])
        self.delay_pc = 0

        def delay_set(ticks, addr, data):
            self.delay_pc += 4
            return [['XXX_%d'%(self.delay_pc-4), [cav_num], ticks],
                    ['XXX_%d'%(self.delay_pc-3), [cav_num], addr],
                    ['XXX_%d'%(self.delay_pc-2), [cav_num], int(data)/65536],
                    ['XXX_%d'%(self.delay_pc-1), [cav_num], int(data)%65536]]
        if 0:
            pass
        #     # FGEN
        #     regs.append(c_regs('duration',3,duration))
        #     regs.append(c_regs('amp_slope',4,5000))
        #     regs.append(c_regs('amp_max',7,amp_max))
        #     regs.append(c_regs('amp_dest_addr',10,36))
        #     regs.append(c_regs('amp_dest_addr',12,38))
        # elif 0:
        #     # TGEN
        #     delay_pc = 4096
        #     # start the pulse in open loop (fixed drive amplitude) mode
        #     regs.extend(delay_set(0, 'lim_Y_hi', 0))
        #     regs.extend(delay_set(0, 'lim_Y_lo', 0))
        #     regs.extend(delay_set(0, 'lim_X_hi', 22640))
        #     regs.extend(delay_set(500*8, 'lim_X_lo', 22640))
        #     # allow the amplitude loop to run
        #     #regs.extend(delay_set(0, 52, 26000))
        #     regs.extend(delay_set(duration*8, 'lim_X_lo', 16000))
        #     # allow the phase loop to run
        #     regs.extend(delay_set(0, 'lim_Y_hi',  self.maxq))
        #     regs.extend(delay_set(5000*8, 'lim_Y_lo', -self.maxq))
        #     regs.extend(delay_set(0, 'lim_X_hi', 0))
        #     regs.extend(delay_set(0, 'lim_X_lo', 0))
        else:
            registers.extend(delay_set(0, lim_register_addr, self.amp_max))
            registers.extend(delay_set(self.duration*8, lim_register_addr+2, self.amp_max))
            registers.extend(delay_set(0, lim_register_addr, 0))
            registers.extend(delay_set(0, lim_register_addr+2, 0))
            for jx in range(6):
		registers.extend(delay_set(0,0,0))

            # regs.append(c_regs('Mode Select', 65536+554, 0))
        if error_cnt > 0:
            print "# %d scaling errors found"%error_cnt
            #exit(1)
        convert = lambda x: x + 2**32 if x < 0 else x
        for r in registers:
            if type(r[2]) is list:
                r[2] = map(convert, r[2])
            else:
                r[2] = convert(r[2])
	global print_once
	if print_once == True:
            for r in registers:
                print r[0], r[2]
            print_once = False
        return registers
