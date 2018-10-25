import numpy as np

class controller:
    "Setup feed-back controller"

    def __init__(self,
                 setpoint_amp,      # FPGA counts
                 setpoint_ph,       # Degrees
                 drive_limit,       # Fraction of full drive amplitude
                 phase_limit,       # Degrees (defined over [0,80])
                 kp,                # Unitless [X, Y]
                 controller_zero,   # Hz
                 cavity):           # Cavity 0 or 1

        self.setpoint_amp = setpoint_amp
        self.setpoint_ph = setpoint_ph
        self.drive_limit = clamp(drive_limit, 0.0, 1.0)
        self.phase_limit = clamp(phase_limit, 0.0, 80.0)
        self.kp = kp
        self.controller_zero = controller_zero
        self.cavity = cavity

    def integers(self):
        "Convert controller setup to fdbk_core.v hardware registers"

        # Calculate register values and apply the proper scaling
        cordic_gain = 1.646760258
        lim_gain = 2**17-1

        ki = [self.kp[0]*2.0*np.pi*self.controller_zero[0], self.kp[1]*2.0*np.pi*self.controller_zero[1]]
        setmp_val = [int(clamp(self.setpoint_amp*2/cordic_gain, -lim_gain, lim_gain)),
                     int(clamp(self.setpoint_ph*2.0/360, -lim_gain, lim_gain))]
        # Scaling for ki should really be *2^14/cordic_gain according to the test-benches, cheating here
        # to avoid overflowing the register in the current FPGA build
        coeff_val = [int(ki[0]/3/cordic_gain), int(ki[1]/3/cordic_gain),
                     int(clamp(self.kp[0]*2**6/cordic_gain, -lim_gain, lim_gain)), int(clamp(self.kp[1]*2**6/cordic_gain, -lim_gain, lim_gain))]
        # Limit array is in I/Q coordinates in FPGA. Vector of four elements is defined as:
        # [I max, Q max, I min, Q min]
        phase_limit_rad = self.phase_limit*np.pi/180.0
        lim_val = [fix_scale(self.drive_limit*np.cos(phase_limit_rad)/cordic_gain, 17, 'lim0'), fix_scale(self.drive_limit*np.sin(phase_limit_rad)/cordic_gain, 17, 'lim1'),
                   0, fix_scale(-self.drive_limit*np.sin(phase_limit_rad)/cordic_gain, 17, "lim3")]

        return setmp_val, coeff_val, lim_val

    def dict(self, base):
        ivals = self.integers()
        return {base+'setmp': ivals[0], base+'coeff': ivals[1], base+'lim': ivals[2]}

    def registers(self, regmap_json, cavity):

        # Read register map from JSON file
        from read_regmap import get_map, get_reg_info
        regmap = get_map(regmap_json)

        # Extract the registers of interest
        setmp = get_reg_info(regmap, [self.cavity], 'setmp')  # Set-points
        coeff = get_reg_info(regmap, [self.cavity], 'coeff')  # Feedback loop gains
        lim = get_reg_info(regmap, [self.cavity], 'lim')  # Controller upper and lower limits

        setmp_val, coeff_val, lim_val = self.integers()

        return {setmp['name']: setmp_val, coeff['name']: coeff_val, lim['name']: lim_val}

def clamp(n, minn, maxn):
    "Limit range of n from minn to maxn"
    return max(min(maxn, n), minn)

def fix_scale(val, width, name):
    scale = 2**width-1
    out = int(val*scale)
    if abs(out) > scale:
        print 'Overflow: %s = %d' % (name, out)
        return None
    else:
        return out


if __name__ == "__main__":

    from notch_setup import notch_setup

    cavity_base = 'shell_1_dsp'
    # Feedback controller configuration (cavity 0)
    setpoint_amp = 6600             # FPGA counts
    setpoint_ph = 0                 # Degrees
    drive_limit = 0.7               # Fraction of full drive amplitude
    phase_limit = 12                # Degrees
    kp = [-200, -200]               # Unitless [X, Y]
    controller_zero = [300, 300]    # Hz [X,Y]
    cavity = 0                      # Cavity 0 or 1

    controller_base0 = cavity_base + '_fdbk_core_'
    controller_cav0 = controller(setpoint_amp, setpoint_ph, drive_limit, phase_limit, kp, controller_zero, cavity)
    controller_dict0 = controller_cav0.dict(controller_base0)
    # Notch filter configuration
    notch_bw0 = 200e3        # Hz
    notch_freq0 = -751.6e3   # Hz

    notch_base0 = cavity_base + '_lp_notch_'
    ns_cav0 = notch_setup(bw=notch_bw0, notch=notch_freq0)

    notch_dict0 = ns_cav0.dict(notch_base0)

    controller_dict0.update(notch_dict0)
    print controller_dict0
    for nn in controller_dict0.keys():
        v = controller_dict0[nn]
        for ix in range(len(v)):
            print "%s[%d],%d" % (nn, ix, v[ix])
