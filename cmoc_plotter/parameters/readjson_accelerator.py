"""
Accelerator-specific configuration file:

Defines all the Python classes involved in the simulation.
Parses configuration information from a dictionary and instantiates
Python objects with the configuration values.
Get a Simulation Class instance in order to get a full collection of instances for a simulation run.
"""

from readjson import readentry
from math import pi, sqrt, log
from numpy import exp as cexp
from numpy import ceil
from read_regmap import *
import os, sys

base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
if base_dir not in sys.path: sys.path.insert(0, base_dir)

pspeps_io_dir = os.path.join(base_dir, '../../pspeps_io')
if pspeps_io_dir not in sys.path: sys.path.insert(0, pspeps_io_dir)

from registers import Register

## Define Simulation time step as global
Tstep_global = 0.0

class Synthesis:
    """ Contains parameters specific to a Synthesis run.
    The parameters in this class are not run-time configurable. They therefore need
    to mirror the synthesizable Verilog and are used to compute FPGA register settings.
    """

    def __init__(self, confDict):

        """ Constructor
        Input:
            - confDict: Global configuration dictionary.
        """

        ## Instance name
        self.name = confDict["Synthesis"]["name"]
        ## Instance type
        self.type = confDict["Synthesis"]["type"]

        # Read rest of configuration parameters
        ## Number of Mechanical modes instantiated in FPGA
        self.n_mech_modes = readentry(confDict, confDict["Synthesis"]["n_mech_modes"])
        ## FPGA scaling factor
        self.df_scale = readentry(confDict, confDict["Synthesis"]["df_scale"])

    def __str__ (self):
        """Convenient concatenated string output for printout."""

        return ("\n--Synthesis Object--\n"
         + "name: " + self.name  + "\n"
         + "type: " + self.type  + "\n"
         + "n_mech_modes: " + str(self.n_mech_modes) + "\n"
         + "df_scale: " + str(self.df_scale) + "\n")

class Cavity:
    """ Contains parameters specific to a cavity, including a nested list of electrical modes"""

    def __init__(self, confDict, cav_entry, cryomodule_entry):
        """
        Cavity constructor: includes a recursive read of electrical modes in each cavity,
        where ElecMode objects are created for each electrical mode and contained as a list of ElecMode objects in the Cavity object.

        Inputs:
            - confDict: Global configuration dictionary,
            - cav_entry: Name of the cavity to be read (string),
            - cryomodule_entry: Cryomodule entry in global dictionary in order to access the proper cryomodules.

        (The mechanical mode list is used as a consistency check to generate mechanical coupling vectors for each electrical mode).
        """

        ## Instance name
        self.name = confDict[cav_entry]['name']
        ## Instance type
        self.type = confDict[cav_entry]['type']

        # Read and store the rest of the parameters in a dictionary
        cav_param_dic = {}

        ## cavity electrical length [m]
        self.L = readentry(confDict,confDict[cav_entry]["L"])

        ## cavity Nominal gradient [V/m]
        self.nom_grad = readentry(confDict,confDict[cav_entry]["nom_grad"])

        # Grab the list of electrical modes
        elec_mode_connect = confDict[cav_entry]["elec_mode_connect"]
        n_elec_modes = len(elec_mode_connect) # Number of electrical modes

        elec_mode_list = []

        # Start of loop through electrical modes
        # Cycle through electrical modes, read parameters from global dictionary and append to list of modes.
        for m in range(n_elec_modes):
            # Take mth element of mode list
            elecMode_entry = elec_mode_connect[m]

            # Instantiate ElecMode object
            elec_mode = ElecMode(confDict, elecMode_entry, cryomodule_entry)

            # Append to list of electrical modes
            elec_mode_list.append(elec_mode)
        # End of loop through electrical modes

        # Make the List of Electrical Modes an attribute of the Cavity object
        ## List of ElecMode objects (one per electrical mode)
        self.elec_modes = elec_mode_list

        # Find the fundamental mode based on coupling to the beam
        # Criterium here is the fundamental mode being defined as that with the highest shunt impedance (R/Q)
        RoverQs = map(lambda x: x.RoverQ['value'],self.elec_modes)

        fund_index = RoverQs.index(max(RoverQs))

        ## Index of the fundamental mode
        self.fund_index = {"value" : fund_index, "units" : "N/A", "description" : "Index of the fundamental mode in array"}

        # Add (replicate) parameters that will be filled after object instance
        ## cavity nominal phase with respect to the beam [deg]
        self.rf_phase = {"value" : 0.0, "units" : "deg", "description" : "Nominal Linac RF phase (-30 deg accelerates and puts head energy lower than tail)"}

        ## Related to the cavity set-point (Default at max) [V]
        self.design_voltage = {"value" : self.nom_grad["value"]*self.L["value"], "units" : "V", "description" : "Design operating Cavity voltage"}

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Cavity Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "L: " + str(self.L) + "\n"
        + "nom_grad: " + str(self.nom_grad) + "\n"
        + "rf_phase: " + str(self.rf_phase) + "\n"
        + "design_voltage: " + str(self.design_voltage) + "\n"
        + "electrical modes: " + '\n'.join(str(x) for x in self.elec_modes))

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc
        # First count number of Electrical Modes and Allocate Array
        n_modes = len(self.elec_modes)
        elecMode_net = acc.ElecMode_Allocate_Array(n_modes)

        # Allocate each Electrical Mode and append it to the elecMode_net
        for idx, mode in enumerate(self.elec_modes):
            n_mech = len(mode.mech_couplings_list)
            mech_couplings = acc.double_Array(n_mech)
            for m in xrange(n_mech):
                mech_couplings[m] = mode.mech_couplings_list[m]

            elecMode = acc.ElecMode_Allocate_New(mode.RoverQ['value'], \
                mode.foffset['value'], mode.LO_w0['value'], \
                mode.Q_0['value'], mode.Q_drive['value'], mode.Q_probe['value'], \
                self.rf_phase['value'],  mode.phase_rev['value'], mode.phase_probe['value'], \
                Tstep_global, mech_couplings, n_mech)

            acc.ElecMode_Append(elecMode_net, elecMode, idx)
            mode.C_Pointer = elecMode

        L = self.L['value']
        nom_grad = self.nom_grad['value']
        rf_phase = self.rf_phase['value']
        design_voltage = self.design_voltage['value']
        fund_index = self.fund_index['value']

        # Get a C-pointer to a Cavity structure
        cavity = acc.Cavity_Allocate_New(elecMode_net, n_modes, L, nom_grad, \
            rf_phase, design_voltage, \
            fund_index)

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = cavity

        return cavity

    def Get_State_Pointer(self):
        """ Return reference to the SWIG-wrapped State C structure. """
        import accelerator as acc

        cavity_state = acc.Cavity_State()
        acc.Cavity_State_Allocate(cavity_state, self.C_Pointer)

        ## Pointer to the SWIG-wrapped State C structure
        self.State = cavity_state

        return cavity_state

class ElecMode:
    def __init__(self, confDict, elecMode_entry, cryomodule_entry):
        """
        Contains parameters specific to an electrical mode, including a dictionary specifying the mechanical couplings.
        Note the absence of a readElecMode method, the process for parsing the global configuration dictionary and
        creating ElecMode objects is done recursively in the Cavity constructor.
        """

        ## Instance name
        self.name = confDict[elecMode_entry]['name']
        ## Instance type
        self.type = confDict[elecMode_entry]['type']

        ## Identifier for mode (e.g pi, 8pi/9, etc.)
        self.mode_name = confDict[elecMode_entry]['mode_name']

        # Read rest of parameters and store in dictionary
        ## Mode's (R/Q) [Ohms]
        self.RoverQ = readentry(confDict,confDict[elecMode_entry]["RoverQ"])
        ## Mode's frequency offset (with respect to the RF reference frequency) [Hz]
        self.foffset = readentry(confDict,confDict[elecMode_entry]["foffset"])
        ## Scaling factor for FPGA double precision to fixed point conversion of voltages
        self.peakV = readentry(confDict,confDict[elecMode_entry]["peakV"])
        ## Represents losses in the cavity walls
        self.Q_0 = readentry(confDict,confDict[elecMode_entry]["Q_0"])
        ## Represents coupling to the input coupler
        self.Q_drive = readentry(confDict,confDict[elecMode_entry]["Q_drive"])
        ## Represents coupling to the field probe
        self.Q_probe = readentry(confDict,confDict[elecMode_entry]["Q_probe"])
        ## Phase shift between Cavity cells and reverse ADC
        self.phase_rev = readentry(confDict,confDict[elecMode_entry]["phase_rev"])
        ## Phase shift between Cavity cells and probe ADC
        self.phase_probe = readentry(confDict,confDict[elecMode_entry]["phase_probe"])

        # Read dictionary of couplings from global configuration dictionary
        mech_couplings = readentry(confDict,confDict[elecMode_entry]["mech_couplings"]["value"])
        # Get a coupling list of length M (number of mechanical modes),
        # filled with 0s if no coupling is specified by user
        ## List of mode's mechanical couplings
        self.mech_couplings_list = readCouplings(confDict, mech_couplings, cryomodule_entry)

        # Add (replicate) a parameter that will be filled after object instance
        ## Local Oscillator frequency [rad/s]
        self.LO_w0 = {"value" : 0.0, "units" : "rad/s", "description" : "Linac's Nominal resonance angular frequency"}

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--ElecMode Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "mode_name: " + str(self.mode_name) + "\n"
        + "RoverQ: " + str(self.RoverQ) + "\n"
        + "foffset: " + str(self.foffset) + "\n"
        + "peakV: " + str(self.peakV) + "\n"
        + "Q_0: " + str(self.Q_0) + "\n"
        + "Q_drive: " + str(self.Q_drive) + "\n"
        + "Q_probe: " + str(self.Q_probe) + "\n"
        + "phase_rev: " + str(self.phase_rev) + "\n"
        + "phase_probe: " + str(self.phase_probe) + "\n"
        + "mech_couplings_list: " + str(self.mech_couplings_list))

    def Compute_ElecMode(self, Tstep, rf_phase):
        """
        Helper function to compute Electrical Mode's parameters (normally computed in C).
        Used in unit tests in order to compared measured properties to physical quantities
        Inputs:
            - Tstep: Simulation time step [s]
            - rf_phase: Beam phase relative to the RF [deg]
        """

        import numpy as np

        # Initialize an empty list to return
        modes_out = []

        beam_phase = rf_phase

        mode_name = self.mode_name
        LO_w0 = self.LO_w0['value']
        foffset = self.foffset['value']
        w0 = LO_w0 + 2.0*pi*foffset
        RoverQ = self.RoverQ['value']

        k_probe = np.exp(1j*self.phase_probe['value'])/np.sqrt(self.Q_probe['value']*RoverQ);
        k_em = np.exp(1j*self.phase_rev['value'])/np.sqrt(self.Q_drive['value']*RoverQ);

        Q_L = 1.0/(1.0/self.Q_0['value'] + 1.0/self.Q_drive['value'] + 1.0/self.Q_probe['value'])
        bw = w0/(2.0*Q_L);
        k_beam = RoverQ*Q_L*np.exp(-1j*beam_phase)/Tstep;
        k_drive = 2.0*np.sqrt(self.Q_drive['value']*RoverQ);
        mode_dict = {"mode_name": mode_name,"w0": w0, "beam_phase": beam_phase, "RoverQ": RoverQ, "foffset": foffset, "Q_L": Q_L, "bw": bw, "k_beam": k_beam, "k_drive": k_drive, "k_probe": k_probe, "k_em": k_em}

        return mode_dict

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        coarse_freq = Register(**get_reg_info(regmap, hierarchy, "coarse_freq"))

        drive_coupling = Register(**get_reg_info(regmap, hierarchy, "drive_coupling"))
        bw = Register(**get_reg_info(regmap, hierarchy, "bw"))
        out_coupling = Register(**get_reg_info(regmap, hierarchy, "out_coupling"))

        # ATTENTION: FPGA has 2 registers, but assuming they are contiguous on FPGA
        out_phase_offset = Register(**get_reg_info(regmap, hierarchy, "out_phase_offset"))
        # ATTENTION: FPGA has 2 registers, but assuming they are contiguous on FPGA
        n_mechMode = len(self.mech_couplings_list)

        outer_list = Register(**get_reg_info(regmap, hierarchy, ["outer_prod", "k_out"]))
        dot_list = Register(**get_reg_info(regmap, hierarchy, ["dot", "k_out"]))

        # prompt_rfl = Register(name="prompt_rfl")
        # prompt_fwd = Register(name="prompt_fwd")

        self.reg_dict = {
            "coarse_freq": coarse_freq,
            "drive_coupling": drive_coupling,
            "bw": bw,
            "out_coupling": out_coupling,
            "out_phase_offset": out_phase_offset,
            "outer_list": outer_list,
            "dot_list": dot_list
            # "prompt_rfl": prompt_rfl,
            # "prompt_fwd": prompt_fwd
        }

    def Compute_FPGA_Registers(self, Tstep, omega0, PAmax, rev_adc_max, cav_adc_max, nyquist_sign, lp_shift, mechMode_list, n_mech_modes, df_scale):
        """Compute Electrical mode FPGA registers from user configuration."""

        name = self.mode_name
        Q_0 = self.Q_0['value']
        Q_drive = self.Q_drive['value']
        Q_probe = self.Q_probe['value']
        Q_L = 1 / (1/Q_0 + 1/Q_drive + 1/Q_probe)
        RoverQ = self.RoverQ['value']
        phase_rev = self.phase_rev['value']
        phase_probe = self.phase_probe['value']
        foffset = self.foffset['value']
        peakV = self.peakV['value']

        # see Pro tip in eav4_elec.v for better limit on foffset
        # XXX document using 33 for what's really a 28-bit register
        coarse_freq_val = fix(Tstep*nyquist_sign*foffset, 33, self.mode_name+"coarse_freq")
        coarse_freq_val = (coarse_freq_val+2**32) if coarse_freq_val < 0 else coarse_freq_val
        self.reg_dict["coarse_freq"].value = coarse_freq_val

        V_achievable = 2*sqrt(PAmax*Q_drive*RoverQ)
        drive_coupling_val = fix(V_achievable / peakV, 18, self.mode_name+"drive_coupling", "cordic")
        self.reg_dict["drive_coupling"].value = drive_coupling_val

        # bandwidth in Hz = f_clk/2/2^shift/(2*pi) * bw_register/2^17 = omega_0/(2*pi*2*Q_L)
        # XXX document origin of *2.0 better, compensates for shift right in lp_pair.v
        bw_val = fix(Tstep*omega0/(2*Q_L)*(2**lp_shift)*2.0, 18, self.mode_name+".bw")
        self.reg_dict["bw"].value = bw_val

        # x is defined as sqrt(U)
        xmax = peakV / sqrt(RoverQ*omega0)
        # four registers of pair_couple.v
        out_coupling_val = [
            fix(sqrt(omega0/Q_drive) * xmax / rev_adc_max, 18, self.mode_name+".out1", "cordic"),
            fix(sqrt(omega0/Q_probe) * xmax / cav_adc_max, 18, self.mode_name+".out2", "cordic")]
        out_phase_offset_val = [
            fix(phase_rev / 180.0, 18, self.name+".out3"),
            fix(phase_probe / 180.0, 18, self.name+".out4")]

        for i in range(len(out_coupling_val)):
            out_coupling_val[i] = (out_coupling_val[i]+2**32) if out_coupling_val[i] < 0 else out_coupling_val[i]
        for i in range(len(out_phase_offset_val)):
            out_phase_offset_val[i] = (out_phase_offset_val[i]+2**32) if out_phase_offset_val[i] < 0 else out_phase_offset_val[i]

        # Set the out_couple register values
        self.reg_dict["out_coupling"].value = out_coupling_val
        self.reg_dict["out_phase_offset"].value = out_phase_offset_val

        # Get the Matrix elements to compute couplings
        outer_list_val, dot_list_val = self.ComputeCouplingRegs(mechMode_list, Tstep, omega0, n_mech_modes, df_scale)

        # Fill in register values
        self.reg_dict["outer_list"].value = outer_list_val
        self.reg_dict["dot_list"].value = dot_list_val

        # Get prompt pair
        prompt_rfl = self.phase_rev['value']
        prompt_fwd = self.phase_probe['value']
        # Construct argumenent for fix call
        out_rfl = "out_rfl"
        out_fwd = "out_fwd"
        fix_prompt_rfl_val = fix(prompt_rfl / 180.0, 18, out_rfl)
        fix_prompt_fwd_val = fix(prompt_fwd / 180.0, 18, out_fwd)
        # self.reg_dict["prompt_rfl"].value = fix_prompt_rfl_val
        # self.reg_dict["prompt_fwd"].value = fix_prompt_fwd_val

    def ComputeCouplingRegs(self, mechMode_list, Tstep, omega0, n_mech_modes, df_scale):
        """ Compute Electrical Mode/Mechanical mode coupling FPGA registers from user configuration.
            Note that ComputeMechModeRegs needs to be run before this function, since the Mechanical mode objects in
            mechMode_list need to have an attribute which is computed in that function (dc_gain).
        """
        # Lists containing couplings between electrical and mechanical modes
        outer_list=[]    # Electrical to Mechanical
        dot_list=[]      # Mechanical to Electrical

        RoverQ = self.RoverQ['value']
        peakV = self.peakV['value']

        interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes)/log(2)) # interp0.v

        # Iterate over the (M) mechanical modes in order to calculate M elements of A (outer) and C (inner) matrices
        for m, mode in enumerate(mechMode_list):
            mechMode_name = mode.name
            net_coupling =  self.mech_couplings_list[m] # Hz / (MV/m)^2, negative is implicit
            full_scale = mode.full_scale['value']

            Amn =   sqrt(net_coupling/RoverQ) / omega0  # sqrt(J)/V^2
            Cmn = - sqrt(net_coupling*RoverQ) * omega0  # 1/s/sqrt(J)

            dc_gain = mode.dc_gain

            outer = Amn / full_scale * peakV**2 / dc_gain # dimensionless
            inner = Cmn * full_scale * Tstep / 2**df_scale / interp_gain  # dimensionless

            # print "# outer =",outer,"inner =",inner
            # note that inner*outer = net_coupling * self.peakV**2 * Tstep
            outer_fix = fix(outer/128,18,"outer")
            inner_fix = fix(inner/128,18,"inner")

            # Added to match paramhg.py output
            inner_fix = (inner_fix+2**32) if inner_fix < 0 else inner_fix

            outer_list.append(outer_fix)
            outer_list.append(0)
            dot_list.append(0)
            dot_list.append(inner_fix)

        return outer_list, dot_list

class MechMode:
    """
    Contains parameters specific to a mechanical mode.
    Information concerning couplings with electrical modes and Piezos
    is contained in ElecMode and Piezo objects respectively."""

    def __init__(self, confDict, mechMode_entry):
        """
        MechMode Constructor:
        Inputs:
            - confDict: Global configuration dictionary,
            - mech_mode_entry: Name of the mechanical mode to be read (string).
        """

        ## Instance name
        self.name = confDict[mechMode_entry]['name']
        ## Instance type
        self.type = confDict[mechMode_entry]['type']

        # Read the rest of the configuration parameters and store in a dictionary
        ## Mechanical mode's resonant frequency [Hz]
        self.f0 = readentry(confDict,confDict[mechMode_entry]["f0"])
        ## Mechanical mode's Quality factor [unitless]
        self.Q = readentry(confDict,confDict[mechMode_entry]["Q"])
        ## Scaling factor used by FPGA
        self.full_scale = readentry(confDict,confDict[mechMode_entry]["full_scale"])
        ## XXX Vibration hack
        self.vibration_hack = readentry(confDict,confDict[mechMode_entry]["vibration_hack"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--MechMode Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "f0: " + str(self.f0) + "\n"
        + "Q: " + str(self.Q) + "\n"
        + "full_scale: " + str(self.full_scale) + "\n"
        + "vibration_hack: " + str(self.vibration_hack))

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """
        import accelerator as acc

        # Grab attributes from object
        f0 = self.f0['value']
        Q = self.Q['value']
        k = 1.0

        # Allocate Memory for C struct
        mechMode = acc.MechMode_Allocate_New(f0, Q, k, Tstep_global);

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = mechMode

        # Return C Pointer
        return mechMode

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        # a2 = Register(name="a2")
        # b2 = Register(name="b2")


        # self.reg_dict = {"a2": a2, "b2": b2}
        self.reg_dict = {}

    def Compute_FPGA_Registers(self, Tstep, n_mech_modes):
        """ Compute Mechanical mode FPGA registers from user configuration.
        Note that this function needs to be run before calling ComputeCouplingRegs.
        dc_gain attribute is appended to the MechMode object for later use in the computation of
        coupling-related FPGA registers."""

        # mech_tstep definition is the result, n_mech_modes shouldn't be a hard-coded global
        mech_tstep = Tstep * n_mech_modes

        f0 = self.f0['value']
        Q =  self.Q['value']

        w1 = mech_tstep * 2*pi*f0
        # a1 + b1 * i represents the pole in the normalized s-plane
        a1 = w1 * (-1/(2.0*Q))
        b1 = w1 * sqrt(1-1/(4.0*Q**2))
        z_pole = cexp(a1+b1*1j)
        # print "# z_pole = %7f + %7fi"%(z_pole.real,z_pole.imag)
        a1 = z_pole.real-1.0
        b1 = z_pole.imag
        scale = int(-log(max(a1,b1))/log(4))
        scale = max(min(scale,9),2)
        a2 = a1 * 4**scale
        b2 = b1 * 4**scale
        # print "# debug",w1,a1,b1,scale,a2,b2
        #c1 = -w1**2 / (k*b1)
        a2_fix = (fix(a2,18,"a2")&(2**18-1)) + ((9-scale) << 18)
        b2_fix = (fix(b2,18,"b2")&(2**18-1)) + ((9-scale) << 18)
        # Store the constants to append to res_prop
        self.a2_fix = a2_fix
        self.b2_fix = b2_fix

        dc_gain = b2/(a2**2+b2**2)  # resonator.v

        # Add an attribute to the MechMode object to be used by the ComputeCouplingRegs function
        self.dc_gain = dc_gain


class Piezo:
    """ Contains couplings between the Piezo and each
    one of the mechanical modes (MechMode instances)."""

    def __init__(self, confDict, piezo_entry, cryomodule_entry):
        """
        Piezo Constructor:
            Inputs:
                - confDict: Global configuration dictionary,
                - piezo_entry: Name of the Piezo to be read (string).
                - cryomodule_entry: Cryomodule entry in global dictionary in order to access
                    the proper cryomodule's mechanical mode list, which is used as a consistency
                    check to generate mechanical coupling vectors for each Piezo."""

        ## Instance name
        self.name = confDict[piezo_entry]['name']
        ## Instance type
        self.type = confDict[piezo_entry]['type']

        # Read rest of parameters
        ## Scaling factor used by the FPGA
        self.VPmax = readentry(confDict,confDict[piezo_entry]["VPmax"])

        # Read dictionary of couplings from global configuration dictionary
        mech_couplings = readentry(confDict,confDict[piezo_entry]["mech_couplings"]["value"])

        # Check consistency of coupling entries with the list of mechanical modes,
        # and get a coupling dictionary of length M (number of mechanical modes)
        ## Couplings to the Mechanical modes
        self.mech_couplings_list = readCouplings(confDict, mech_couplings, cryomodule_entry)

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Piezo Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "VPmax: " + str(self.VPmax) + "\n"
        + "mech_couplings_list: " + str(self.mech_couplings_list))

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        piezo_couple = Register(**get_reg_info(regmap, hierarchy, "piezo_couple"))
        self.reg_dict = {"piezo_couple": piezo_couple}

    def Compute_FPGA_Registers(self, mechMode_list):
        """Compute Piezo FPGA registers from user configuration."""

        # List containing couplings between piezo and mechanical modes
        VPmax = self.VPmax['value']

        piezo_couple_val=[] # Piezo to Mechanical

        # Iterate over the mechanical modes
        for m, mode in enumerate(mechMode_list):
            mechMode_name = mode.name
            Bmk = self.mech_couplings_list[m] # sqrt(J)/V
            full_scale = mode.full_scale['value']

            dc_gain = mode.dc_gain

            outer = Bmk / full_scale * VPmax / dc_gain # dimensionless
            outer_fix = fix(outer/128,18,"outer")
            piezo_couple_val.append(outer_fix)
            piezo_couple_val.append(0)

        self.reg_dict["piezo_couple"].value = piezo_couple_val

def readCouplings(confDict, mech_couplings, cryomodule_entry):
    """
    Takes the global configuration dictionary and a dictionary containing non-zero values for the
    mechanical couplings (i.e. coupling between electrical modes or piezos and mechanical modes).
    The cryomodule_entry input is necessary in order to access the proper cryomodule's mechanical mode list.
    The length of the coupling vector used in the simulation code must be equal to the number of mechanical modes (M).
    The mech_couplings input is supposed to contain non-zero values from the configuration file,
    and readCouplings always returns a dictionary of M elements, where the couplings not specified in
    the input file are filled with 0s.
    Inputs:
        - confDict: Global configuration dictionary,
        - mech_couplings: dictionary containing couplings defined in the configuration file (0 to M elements).
        - cryomodule_entry: Cryomodule entry in global dictionary in order to access the proper cryomodule's mechanical mode list.
    Output:
        - mech_couplings_list: ordered list containing mechanical couplings for an electrical mode or piezo (length M).
            Order corresponds to the order of appearance of the mechanical mode in mech_net.
    """

    # Grab the full list of mechanical modes in the Cryomodule
    mech_net = confDict[cryomodule_entry]["mechanical_mode_connect"]

    # Make an ordered list of size M (where M is the total number of mechanical modes, length of mech_net)
    # Fill with 0s if no coupling is specified in mech_couplings by the user
    mech_couplings_list = [mech_couplings[m] if m in mech_couplings else 0.0 for m in mech_net]

    return mech_couplings_list


def readList(confDict, list_in, constructor, cryomodule_entry=None):
    """
    Generic function to read list of components.
    Takes the global configuration dictionary, cycles through the list of components
    (list of names, list_in), uses the names to identify the configuration entries in
    the global dictionary, calls the proper Constructor for each component (constructor),
    and returns a list of instances (objects).
    Inputs:
        - confDict: Global configuration dictionary,
        - list_in: list of components to cycle through (list of strings),
        - constructor: name of Constructor for the component,
        - cryomodule_entry (optional): necessary in some cases in order to pass along cryomodule entry information,
            needed by readStation and Piezo in order to find the mechanical modes in
            their corresponding Cryomodule.
    Output:
        - list_out: List of component objects.
    """

    # Create empty list for component instances
    list_out = []

    # Cycle through list of Instance names
    for k in range(len(list_in)):
        # Read component configuration and create component instance
        if cryomodule_entry == None:
            component = constructor(confDict, list_in[k])
        else:
            component = constructor(confDict, list_in[k], cryomodule_entry)
        # Append object to the component list
        list_out.append(component)

    # Return list
    return list_out

class Controller:
    """ Contains parameters specific to a Controller configuration. """

    def __init__(self, confDict, controller_entry):
        ## Instance name
        self.name = confDict[controller_entry]['name']
        ## Instance type
        self.type = confDict[controller_entry]['type']

        # Read the rest of parameters
        ## FPGA controller Gain-Bandwidth product [Hz]
        self.stable_gbw = readentry(confDict,confDict[controller_entry]["stable_gbw"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Controller Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "stable_gbw: " + str(self.stable_gbw) + "\n")

class ZFilter:
    """ Contains parameters specific to a Filter configuration"""

    def __init__(self, confDict, zfilter_entry):

        ## Instance name
        self.name = confDict[zfilter_entry]['name']
        ## Instance type
        self.type = confDict[zfilter_entry]['type']

        # Read the rest of parameters
        ## Filter order
        self.order = readentry(confDict,confDict[zfilter_entry]["order"])
        ## Total number of modes
        self.nmodes = readentry(confDict,confDict[zfilter_entry]["nmodes"])
        ## Filter poles
        self.poles = readentry(confDict,confDict[zfilter_entry]["poles"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--ZFilter Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "order: " + str(self.order) + "\n"
        + "nmodes: " + str(self.nmodes) + "\n"
        + "poles: " + str(self.poles) + "\n")

class ADC:
    """ Contains parameters specific to a ADC configuration"""

    def __init__(self, confDict, adc_entry):

        ## Instance name
        self.name = confDict[adc_entry]['name']
        ## Instance type
        self.type = confDict[adc_entry]['type']

        # Read the rest of parameters
        ## ADC full scale
        self.adc_max = readentry(confDict,confDict[adc_entry]["adc_max"])
        ## ADC offster
        self.adc_off = readentry(confDict,confDict[adc_entry]["adc_off"])
        ## ADC noise Power-Spectral-Density [dBc/Hz]
        self.noise_psd = readentry(confDict,confDict[adc_entry]["noise_psd"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--ADC Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "adc_max: " + str(self.adc_max) + "\n"
        + "adc_off: " + str(self.adc_off) + "\n"
        + "noise_psd: " + str(self.noise_psd) + "\n")

class Amplifier:
    """ Contains parameters specific to a Amplifier configuration"""

    def __init__(self, confDict, amplifier_entry):

        ## Instance name
        self.name = confDict[amplifier_entry]['name']
        ## Instance type
        self.type = confDict[amplifier_entry]['type']

        # Read the rest of parameters
        ## Maximum SSA output power [sqrt(W)]
        self.PAmax = readentry(confDict,confDict[amplifier_entry]["PAmax"])
        ## SSA scaling (from unitless to sqrt(W))
        self.PAbw = readentry(confDict,confDict[amplifier_entry]["PAbw"])
        ## Harshness parameter of SSA clipping function
        self.Clip = readentry(confDict,confDict[amplifier_entry]["Clip"])
        ## FPGA drive saturation limit [percentage of PAmax]
        self.top_drive = readentry(confDict,confDict[amplifier_entry]["top_drive"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Amplifier Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "PAmax: " + str(self.PAmax) + "\n"
        + "PAbw: " + str(self.PAbw) + "\n"
        + "Clip: " + str(self.Clip) + "\n"
        + "top_drive: " + str(self.top_drive) + "\n")

    def Get_Saturation_Limit(self):
        """Get_Saturation_Limit: Calculate (measure) the output drive limit from the FPGA controller
        based on the clipping parameter of the saturation function and the maximum output power
        percentage level setting. Returns maximum input value to the saturation function in order
        to reach the percentage of the maximum amplifier output power indicated by top_drive."""

        import numpy as np
        import accelerator as acc
        # Input vector
        inp = np.arange(0.0,10.0,0.1,dtype=np.complex)
        # Output vector
        oup = np.zeros(inp.shape,dtype=np.complex)

        # Boolean indicating finding percentile reach
        found = False
        V_sat = max(inp)

        c = self.Clip['value']
        top_drive = float(self.top_drive['value'])/100

        # Sweep input
        for i in xrange(len(inp)):
            oup[i] = acc.Saturate(inp[i],c)
            if (found == False) and (oup[i].real >= top_drive):
                V_sat = inp[i]
                found = True

        return V_sat.real

class Station:
    """ Contains parameters specific to a Station configuration"""

    def __init__(self, confDict, station_entry, cryomodule_entry):


        ## Instance name
        self.name = confDict[station_entry]['name']
        ## Instance type
        self.type = confDict[station_entry]['type']

        # Read all the station components
        amplifier_entry = confDict[station_entry]['Amplifier']
        ## Amplifier object
        self.amplifier = Amplifier(confDict, amplifier_entry)

        cavity_entry = confDict[station_entry]['Cavity']
        ## cavity object
        self.cavity = Cavity(confDict, cavity_entry, cryomodule_entry)

        rx_filter_entry = confDict[station_entry]['Rx_filter']
        ## filter object: Anti-alias filter
        self.rx_filter = ZFilter(confDict, rx_filter_entry)

        tx_filter1_entry = confDict[station_entry]['Tx_filter1']
        ## filter object: SSA filter 1
        self.tx_filter1 = ZFilter(confDict, tx_filter1_entry)

        tx_filter2_entry = confDict[station_entry]['Tx_filter2']
        ## filter object: SSA filter 2
        self.tx_filter2 = ZFilter(confDict, tx_filter2_entry)

        controller_entry = confDict[station_entry]['Controller']
        ## FPGA controller object
        self.controller = Controller(confDict, controller_entry)

        ## RF feedback loop delay in simulation time steps (multiply by Tstep to get seconds)
        self.loop_delay_size = readentry(confDict, confDict[station_entry]['loop_delay_size'])

        cav_adc_entry = confDict[station_entry]['cav_adc']
        ## Cavity field probe port ADC object
        self.cav_adc = ADC(confDict, cav_adc_entry)

        rev_adc_entry = confDict[station_entry]['rev_adc']
        ## Reverse port ADC object
        self.rev_adc = ADC(confDict, rev_adc_entry)

        fwd_adc_entry = confDict[station_entry]['fwd_adc']
        ## Forward port ADC object
        self.fwd_adc = ADC(confDict, fwd_adc_entry)

        piezo_connect = confDict[station_entry]['piezo_connect']
        ## List of Piezo objects
        self.piezo_list = readList(confDict, piezo_connect, Piezo, cryomodule_entry)

        ## Number of RF Stations
        self.N_Stations = confDict[station_entry]['N_Stations']

        # Add (replicate) parameters that will be filled after object instance
        ## Maximum accelerating voltage [V]
        self.max_voltage = {"value" : 0.0, "units" : "V", "description" : "Maximum accelerating voltage"}

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Station Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"

        + "amplifier: " + str(self.amplifier) + "\n"
        + "cavity: " + str(self.cavity) + "\n"
        + "rx_filter: " + str(self.rx_filter) + "\n"
        + "tx_filter1: " + str(self.tx_filter1) + "\n"
        + "tx_filter2: " + str(self.tx_filter2) + "\n"
        + "controller: " + str(self.controller) + "\n"
        + "loop_delay_size: " + str(self.loop_delay_size) + "\n"
        + "cav_adc: " + str(self.cav_adc) + "\n"
        + "fwd_adc: " + str(self.fwd_adc) + "\n"
        + "rev_adc: " + str(self.rev_adc) + "\n"
        + "N_Stations: " + str(self.N_Stations) + "\n"
        + "piezo_list: " + '\n'.join(str(x) for x in self.piezo_list))

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc
        import numpy as np

        p_RXF = acc.complexdouble_Array(3)
        p_RXF[0] = complex(self.rx_filter.poles['value'][0][0])*1e6
        p_RXF[1] = complex(self.rx_filter.poles['value'][1][0])*1e6
        p_RXF[2] = complex(self.rx_filter.poles['value'][2][0])*1e6

        p_TRF1 = acc.complexdouble_Array(2)
        p_TRF1[0] = complex(self.tx_filter1.poles['value'][0][0])*1e6
        p_TRF1[1] = complex(self.tx_filter1.poles['value'][1][0])*1e6

        p_TRF2 = acc.complexdouble_Array(1)
        p_TRF2[0] = complex(self.tx_filter2.poles['value'][0][0])*1e6

        Clip = self.amplifier.Clip['value']
        PAmax = self.amplifier.PAmax['value']
        PAscale = np.sqrt(PAmax)*(float(self.amplifier.top_drive['value'])/100) # [sqrt(W)]

        FPGA_out_sat = self.amplifier.Get_Saturation_Limit()*PAscale

        stable_gbw = self.controller.stable_gbw['value']
        loop_delay_size = self.loop_delay_size['value']

        cavity_pointer = self.cavity.Get_C_Pointer()

        # Translate ADC noise Power Spectral Density (PSD),
        # which is expressed in [dBc/Hz] (where the carrier is the full range of the ADC)
        # into Volts RMS to scale the pseudo-random Gaussian noise
        probe_psd = self.cav_adc.noise_psd['value'] # [dBc/Hz]
        rev_psd = self.rev_adc.noise_psd['value']   # [dBc/Hz]
        fwd_psd = self.fwd_adc.noise_psd['value']   # [dBc/Hz]

        # Pre-calculate some common terms
        cav_V_nominal = self.cavity.nom_grad['value']*self.cavity.L['value']    # Cavity nominal accelerating voltage [V]
        bandwidth = 0.5/Tstep_global                                            # Bandwidth [Hz]

        # Calculate port couplings
        fund_index = self.cavity.fund_index['value']
        fund_Emode = self.cavity.elec_modes[fund_index]
        RoverQ = fund_Emode.RoverQ['value']
        k_probe = 1.0/np.sqrt(fund_Emode.Q_probe['value']*RoverQ);
        k_em = 1.0/np.sqrt(fund_Emode.Q_drive['value']*RoverQ);
        k_drive = 2.0*np.sqrt(fund_Emode.Q_drive['value']*RoverQ);

        # Now calculate ADC noise in Volts RMS (see Physics documentation for details)
        probe_ns_rms = 1.5*np.sqrt(0.5*10.0**(probe_psd/10.0)*bandwidth)*cav_V_nominal*k_probe
        rev_ns_rms = 1.5*np.sqrt(0.5*10.0**(rev_psd/10.0)*bandwidth)*cav_V_nominal*k_em
        fwd_ns_rms = 1.5*np.sqrt(0.5*10.0**(fwd_psd/10.0)*bandwidth)*cav_V_nominal/k_drive

        rf_station = acc.RF_Station()
        acc.RF_Station_Allocate_In(rf_station, Tstep_global, Clip, PAmax, PAscale, p_TRF1, p_TRF2, p_RXF, cavity_pointer, stable_gbw, FPGA_out_sat, loop_delay_size, probe_ns_rms, rev_ns_rms, fwd_ns_rms)

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = rf_station

        return rf_station

    def Get_State_Pointer(self):
        """ Return reference to the SWIG-wrapped State C structure. """
        import accelerator as acc

        rf_state = acc.RF_State()

        acc.RF_State_Allocate(rf_state, self.C_Pointer)
        ## Pointer to the SWIG-wrapped State C structureacc.RF_State_Allocate(rf_state, self.C_Pointer)
        self.State = rf_state

        return rf_state

    def Init_FPGA_Registers(self, regmap, cav_num):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        amp_bw = Register(**get_reg_info(regmap, [cav_num], "amp_lp_bw"))
        cav_adc_off = Register(**get_reg_info(regmap, [cav_num], "a_cav_offset"))
        fwd_adc_off = Register(**get_reg_info(regmap, [cav_num], "a_for_offset"))
        rev_adc_off = Register(**get_reg_info(regmap, [cav_num], "a_rfl_offset"))
        prompt = Register(**get_reg_info(regmap, [cav_num], "drive_couple_out_coupling"))
        dds_phstep = Register(**get_reg_info(regmap, [cav_num], "phase_step"))
        dds_modulo = Register(**get_reg_info(regmap, [cav_num], "modulo"))
        prng_iva = Register(**get_reg_info(regmap, [cav_num], "prng_iva"))
        prng_ivb = Register(**get_reg_info(regmap, [cav_num], "prng_ivb"))
        prng_random_run = Register(**get_reg_info(regmap, [cav_num], "prng_random_run"))

        # Iterate over the electrical modes in the cavity
        for i, m in enumerate(self.cavity.elec_modes):
            m.Init_FPGA_Registers(regmap, [cav_num,i])

        for p in self.piezo_list:
            p.Init_FPGA_Registers(regmap, [cav_num])

        self.reg_dict = {
            "amp_bw": amp_bw,
            "cav_adc_off": cav_adc_off,
            "fwd_adc_off": fwd_adc_off,
            "rev_adc_off": rev_adc_off,
            "prompt": prompt,
            "dds_phstep": dds_phstep,
            "dds_modulo": dds_modulo,
            "prng_iva": prng_iva,
            "prng_ivb": prng_ivb,
            "prng_random_run": prng_random_run
        }

    def Compute_FPGA_Registers(self, Tstep, f0, nyquist_sign, lp_shift, mechMode_list, n_mech_modes, df_scale, dds_phstep_val, dds_modulo_val):
        """ Compute Station FPGA registers from user configuration.
        Recursively append dictionaries of different components in the hierarchy.
        """

        ## Grab some parameter values needed for the register computation
        PAbw = self.amplifier.PAbw['value']
        PAmax = self.amplifier.PAmax['value']
        fwd_adc_max = self.fwd_adc.adc_max['value']
        rev_adc_max = self.rev_adc.adc_max['value']

        ## Make some calculations
        fix_fwd_adc_max_val = fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic")
        fix_rev_adc_max_val = fix(-sqrt(PAmax) / rev_adc_max, 18, "out2", "cordic")

        fix_fwd_adc_max_val = (fix_fwd_adc_max_val+2**32) if fix_fwd_adc_max_val < 0 else fix_fwd_adc_max_val
        fix_rev_adc_max_val = (fix_rev_adc_max_val+2**32) if fix_rev_adc_max_val < 0 else fix_rev_adc_max_val

        ## Fill in Register values
        self.reg_dict["amp_bw"].value = fix(Tstep*PAbw*32, 18, "amp_bw")
        self.reg_dict["cav_adc_off"].value = self.cav_adc.adc_off['value']
        self.reg_dict["fwd_adc_off"].value = self.fwd_adc.adc_off['value']
        self.reg_dict["rev_adc_off"].value = self.rev_adc.adc_off['value']

        self.reg_dict["dds_phstep"].value = dds_phstep_val
        self.reg_dict["dds_modulo"].value = dds_modulo_val

        self.reg_dict["prompt"].value = [fix_fwd_adc_max_val, fix_rev_adc_max_val, 0, 0]

        # Pre-calculations and cavity parameters for electrical modes
        omega0 = f0*2*pi
        cav_adc_max = self.cav_adc.adc_max['value']
        rev_adc_max = self.rev_adc.adc_max['value']

        # Iterate over the electrical modes in the cavity
        for i, m in enumerate(self.cavity.elec_modes):
            m.Compute_FPGA_Registers(Tstep, omega0, PAmax, rev_adc_max, cav_adc_max, nyquist_sign, lp_shift, mechMode_list, n_mech_modes,  df_scale)

        for p in self.piezo_list:
            p.Compute_FPGA_Registers(mechMode_list)

class Cryomodule:
    """ Contains parameters specific to a Cryomodule configuration"""

    def __init__(self, confDict, cryomodule_entry):

        ## Instance name
        self.name = confDict[cryomodule_entry]['name']
        ## Instance type
        self.type = confDict[cryomodule_entry]['type']

        # Read the station and mechanical mode connectivity
        station_connect = confDict[cryomodule_entry]['station_connect']
        mechanical_mode_connect = confDict[cryomodule_entry]['mechanical_mode_connect']

        # Read list of stations and mechanical modes recursively
        ## List of RF Station objects
        self.station_list = readList(confDict, station_connect, Station, cryomodule_entry)
        ## List of mechanical eigenmodes
        self.mechanical_mode_list = readList(confDict, mechanical_mode_connect, MechMode)

        # Read lp_shift
        ## Scaling factor used in the FPGA
        self.lp_shift = readentry(confDict,confDict[cryomodule_entry]["lp_shift"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Cryomodule Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "station_list: " + '\n'.join(str(x) for x in self.station_list)
        + "mechanical_mode_list: " + '\n'.join(str(x) for x in self.mechanical_mode_list)
        + "lp_shift: " + str(self.lp_shift) + "\n")

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc

        # First count number of Stations and Mechanical Modes and Allocate Arrays
        n_Stations = len(self.station_list)
        n_MechModes = len(self.mechanical_mode_list)

        # Allocate memory for RF Station and Mechanical mode Arrays
        rf_station_net = acc.RF_Station_Allocate_Array(n_Stations)
        mechMode_net = acc.MechMode_Allocate_Array(n_MechModes)

        # Allocate each RF Station and append it to the rf_station_net
        for idx, rf_station in enumerate(self.station_list):
            RF_Station_C_Pointer = rf_station.Get_C_Pointer()
            acc.RF_Station_Append(rf_station_net, RF_Station_C_Pointer, idx)

        # Allocate each MechMode and append it to the mechMode_net
        for idx, mechMode in enumerate(self.mechanical_mode_list):
            mechMode_C_Pointer = mechMode.Get_C_Pointer()
            acc.MechMode_Append(mechMode_net, mechMode_C_Pointer, idx)

        # Instantiate Cryomodule C structure
        cryomodule = acc.Cryomodule()
        # Fill in Cryomodule C data structure
        acc.Cryomodule_Allocate_In(cryomodule, rf_station_net, n_Stations, mechMode_net, n_MechModes)

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = cryomodule

        # Return C Pointer for Cryomodule and lists of pointers
        return cryomodule

    def Get_State_Pointer(self, cryo_state=None):
        """
        Return reference to the SWIG-wrapped State C structure.
        Input:
            - cryo_state (optional): if part of a hierarchy and state has already been allocated,
                provide the reference and it will be assigned to the object's State attribute.
        """
        import accelerator as acc

        # Get C pointer to Cryomodule_State C struct,
        # (if it has not been allocated yet)
        if(cryo_state==None):
            cryo_state = acc.Cryomodule_State()
            # Allocate Memory for cryo_state
            acc.Cryomodule_State_Allocate(cryo_state, self.C_Pointer)

        # Get Pointers to RF States
        for idx, station in enumerate(self.station_list):
            station.State = acc.Get_RF_State(cryo_state, idx)

        # Get Pointers to MechMode States
        for idx, mechMode in enumerate(self.mechanical_mode_list):
            mechMode.State = acc.Get_MechMode_State(cryo_state, idx)

        ## Pointer to the SWIG-wrapped State C structure
        self.State = cryo_state

        # Return State C pointer
        return cryo_state

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        res_prop = Register(**get_reg_info(regmap, hierarchy, "resonator_prop_const"))
        noise_couple = Register(**get_reg_info(regmap, hierarchy, "noise_couple_k_out"))

        # Recursively iterate over the lists of components
        for m in self.mechanical_mode_list:
            m.Init_FPGA_Registers(regmap, hierarchy)

        for k, s in enumerate(self.station_list):
            s.Init_FPGA_Registers(regmap, k)

        self.reg_dict = {"res_prop": res_prop, "noise_couple": noise_couple}

    def Compute_FPGA_Registers(self, Tstep, f0, nyquist_sign, n_mech_modes, df_scale, dds_phstep_val, dds_modulo_val):
        """ Compute Module FPGA register values from user configuration.
        Recursively append dictionaries of different components in the hierarchy.
        """

        lp_shift = self.lp_shift['value']

        for i, m in enumerate(self.mechanical_mode_list):
            m.Compute_FPGA_Registers(Tstep, n_mech_modes)
            if i == 0:
                self.reg_dict['noise_couple'].value = [m.vibration_hack['value'], 0]
                self.reg_dict['res_prop'].value = [m.a2_fix, m.b2_fix]
            else:
                self.reg_dict['noise_couple'].value.append(m.vibration_hack['value'])
                self.reg_dict['noise_couple'].value.append(0)
                self.reg_dict['res_prop'].value.append(m.a2_fix)
                self.reg_dict['res_prop'].value.append(m.b2_fix)

        for s in self.station_list:
            s.Compute_FPGA_Registers(Tstep, f0, nyquist_sign, lp_shift, self.mechanical_mode_list, n_mech_modes, df_scale, dds_phstep_val, dds_modulo_val)

class Linac:
    """ Contains parameters specific to a Linac configuration"""

    def __init__(self, confDict, linac_entry):

        import numpy as np

        # Read name and component type
        self.name = confDict[linac_entry]['name']
        ## Instance type
        self.type = confDict[linac_entry]['type']

        ## Local Oscillator frequency [Hz]
        self.f0 = readentry(confDict,confDict[linac_entry]["f0"])
        ## Energy at the end of Linac Section [eV]
        self.E = readentry(confDict,confDict[linac_entry]["E"])
        ## Nominal Linac RF phase [radians]
        self.phi = readentry(confDict,confDict[linac_entry]["phi"])
        self.phi['value'] = self.phi['value']*np.pi/180    # Convert degrees to radians
        ## Wakefield characteristic length (Sband=0.105m, Xband=0.02625m) [m]
        self.s0 = readentry(confDict,confDict[linac_entry]["s0"])
        ## Mean iris radius (Sband=11.654mm,Xband=4.72mm) [m]
        self.iris_rad = readentry(confDict,confDict[linac_entry]["iris_rad"])
        ## Longitudinal dispersion (if any)
        self.R56 = readentry(confDict,confDict[linac_entry]["R56"])
        ## DDS factor used in FPGA
        self.dds_numerator = readentry(confDict,confDict[linac_entry]["dds_numerator"])
        ## DDS factor used in FPGA
        self.dds_denominator = readentry(confDict,confDict[linac_entry]["dds_denominator"])

        # Read the cryomodule connectivity
        cryomodule_connect = confDict[linac_entry]['cryomodule_connect']

        # Read list of modules recursively
        ## List of cryomodule objects
        self.cryomodule_list = readList(confDict, cryomodule_connect, Cryomodule)

        # Add parameters that will be filled after object instance
        ## Energy increase in Linac Section [eV]
        self.dE = {"value" : 0.0, "units" : "eV", "description" : "Energy increase in Linac (final minus initial Energy)"}
        ## Maximum Accelerating Voltage [V]
        self.max_voltage = {"value" : 0.0, "units" : "V", "description" : "Maximum Accelerating Voltage"}
        ## Total number of RF Stations in Linac
        self.N_Stations = {"value" : 0.0, "units" : "N/A", "description" : "Total number of RF Stations in Linac"}
        ## Total Linac Length [m]
        self.L = {"value" : 0.0, "units" : "m", "description" : "Total Linac Length"}

        # Some parameters are deduced from others
        # RF wavelength deduced from f0
        c = 2.99792458e8    # Speed of light [m/s]

        ## RF wavelength [m]
        self.lam = {"value" : c/self.f0['value'], "units" : "m", "description" : "RF wavelength (Sband=0.105m, Xband=0.02625m)"}
        # T566 deduced from R56 (small angle approximation)
        ## 2nd-order longitudinal dispersion (if any)
        self.T566 = {"value" : -1.5*self.R56['value'], "units" : "m", "description" : "Nominal T566 (always >= 0)"}

        # Need to manually propagate values down to the Cavity and Electrical Mode level
        for cryomodule in self.cryomodule_list:
            for station in cryomodule.station_list:
                # Indicate each cavity the nominal beam phase for the Linac
                station.cavity.rf_phase["value"] = self.phi["value"]

                # Calculate each RF Station's maximum accelerating voltage
                N_Stations = station.N_Stations["value"]
                nom_grad = station.cavity.nom_grad["value"]
                L = station.cavity.L["value"]
                station.max_voltage["value"] = N_Stations*nom_grad*L

                # Add to the Linac's total accelerating voltage, number of RF Stations and Length
                self.max_voltage["value"] += station.max_voltage["value"]
                self.N_Stations["value"] += N_Stations
                self.L["value"] += L*N_Stations

                # Indicate each Electrical Eigenmode the nominal LO frequency for the Linac
                for mode in station.cavity.elec_modes:
                    mode.LO_w0["value"] = 2*pi*self.f0["value"]

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Linac Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"

        + "f0: " + str(self.f0) + "\n"
        + "E: " + str(self.E) + "\n"
        + "phi: " + str(self.phi) + "\n"
        + "lam: " + str(self.lam) + "\n"
        + "s0: " + str(self.s0) + "\n"
        + "iris_rad: " + str(self.iris_rad) + "\n"
        + "R56: " + str(self.R56) + "\n"
        + "T566: " + str(self.T566) + "\n"
        + "dE: " + str(self.dE) + "\n"
        + "max_voltage: " + str(self.max_voltage) + "\n"
        + "L: " + str(self.L) + "\n"
        + "dds_numerator: " + str(self.dds_numerator) + "\n"
        + "dds_denominator: " + str(self.dds_denominator) + "\n"

        + "cryomodule_list: " + '\n'.join(str(x) for x in self.cryomodule_list))

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc

        # First count number of Stations and Mechanical Modes and Allocate Arrays
        n_Cryos = len(self.cryomodule_list)

        # Allocate memory for array of Cryomodules
        cryo_net = acc.Cryomodule_Allocate_Array(n_Cryos)

        # Allocate each Cryomodule and append it to the cryo_net
        for idx, cryo in enumerate(self.cryomodule_list):
            Cryo_C_Pointer = cryo.Get_C_Pointer()
            acc.Cryomodule_Append(cryo_net, Cryo_C_Pointer, idx)

        # Instantiate Linac C structure
        linac = acc.Linac()
        # Fill in Linac C data structure
        acc.Linac_Allocate_In(linac, cryo_net, n_Cryos,
            self.dE["value"], self.R56["value"], self.T566["value"], \
            self.phi["value"], self.lam["value"], self.s0["value"], \
            self.iris_rad["value"], self.L["value"])

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = linac

        # Return Linac C Pointer
        return linac

    def Get_State_Pointer(self, linac_state=None):
        """
        Return reference to the SWIG-wrapped State C structure.
        Input:
            - linac_state (optional): if part of a hierarchy and state has already been allocated,
                provide the reference and it will be assigned to the object's State attribute.
        """
        import accelerator as acc

        # Get C pointer to Linac_state C struct,
        # (if it has not been allocated yet)
        if(linac_state==None):
            # Get C pointer to Linac_State C struct
            linac_state = acc.Linac_State()
            # Allocate Memory for linac_state
            acc.Linac_State_Allocate(linac_state, self.C_Pointer)

        # Get Pointers to Cryomodule States
        for idx, cryo in enumerate(self.cryomodule_list):
            cryo_state = acc.Get_Cryo_State(linac_state, idx)
            cryo.Get_State_Pointer(cryo_state)

        # Return State C pointer
        return linac_state

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        # dds_phstep = Register(**get_reg_info(regmap, hierarchy, "beam_phase_step"))
        # dds_modulo = Register(**get_reg_info(regmap, hierarchy, "beam_modulo"))

        # Recursively iterate over the lists of components
        for c in self.cryomodule_list:
            c.Init_FPGA_Registers(regmap, hierarchy)

        # self.reg_dict = {"dds_phstep": dds_phstep, "dds_modulo": dds_modulo}
        self.reg_dict = {}

    def Compute_FPGA_Registers(self, Tstep, nyquist_sign, n_mech_modes, df_scale):
        """ Compute Linac FPGA register values from user configuration.
        Recursively append dictionaries of different components in the hierarchy.
        """

        # Compute register values specific to a linac
        dds_num = self.dds_numerator['value']
        dds_den = self.dds_denominator['value']
        dds_phstep_h = int(dds_num*2**20/dds_den)
        dds_mult = int(4096/dds_den)
        dds_phstep_l = (dds_num*2**20)%dds_den * dds_mult
        dds_modulo_val = 4096 - dds_mult*dds_den
        dds_phstep_val = dds_phstep_h << 12 | dds_phstep_l


        # Needed for components lower in the hierarchy
        f0 = self.f0['value'] # Hz

        # Recursively iterate over the lists of components
        for m in self.cryomodule_list:
            m.Compute_FPGA_Registers(Tstep, f0, nyquist_sign, n_mech_modes, df_scale, dds_phstep_val, dds_modulo_val)

class Simulation:
    """ Contains parameters specific to a Simulation run,
    as well as all parameters in the Accelerator configuration. This Class is
    to be instantiated from upper level programs in order to obtain all necessary instances
    to run a full simulation"""

    def __init__(self, confDict):
        """Simulation Constructor:
            Inputs:
                confDict: Global configuration dictionary."""

        import numpy as np

        ## Instance name
        self.name = confDict["Accelerator"]["name"]
        ## Instance type
        self.type = confDict["Accelerator"]["type"]

        # Read rest of configuration parameters
        ## Simulation time-step [s]
        self.Tstep = readentry(confDict, confDict["Simulation"]["Tstep"])
        ## Total Simulation time duration in time steps
        self.time_steps = readentry(confDict, confDict["Simulation"]["time_steps"])
        ## Factor used in FPGA
        self.nyquist_sign = readentry(confDict,confDict["Simulation"]["nyquist_sign"])

        # Check if simulation dictionary has a Synthesis entry, and if so parse it
        if confDict["Simulation"].has_key("Synthesis"):
            self.synthesis = Synthesis(confDict["Simulation"])
        else:
            self.synthesis = None

        # Accelerator parameters
        self.bunch_rate = readentry(confDict,confDict["Accelerator"]["bunch_rate"])

        # Read Noise Sources
        ## Simulation correlared noise sources
        self.noise_srcs = Noise(confDict)

        # Read Accelerator components (Gun + series of linacs)
        # Read gun
        ## Gun object
        self.gun = Gun(confDict)
        Egun = self.gun.E['value'] # Gun exit Energy

        # Read connectivity of linacs
        linac_connect = confDict["Accelerator"]["linac_connect"]
        # Read linacs recursively
        ## List of Linac objects
        self.linac_list = readList(confDict, linac_connect, Linac)

        # Now that the Array of Linacs has been instantiated and their final Energies are known,
        # fill in the Energy increase parameter for each Linac.
        # Start with the Energy out of the Gun
        Elast = Egun
        # Iterate over Linacs
        for linac in self.linac_list:
            # Energy increase is the difference between Linac's final and initial Energy
            linac.dE["value"] = linac.E["value"] - Elast
            Elast = linac.E["value"]

            # Check if Energy increase is compatible with Linac configuration
            sp_ratio = linac.dE["value"]/np.cos(linac.phi["value"])/linac.max_voltage["value"]
            if np.abs(sp_ratio) > 1.0:
                error_1 = "Linac "+ linac.name + ": Energy increase higher than tolerated:\n"
                error_2 = "\tEnergy increase requested = %.2f eV"%linac.dE["value"]
                error_3 = "\tAt Beam phase = %.2f deg"%linac.phi["value"]
                error_4 = "\tand Maximum Accelerating Voltage = %.2f V"%linac.max_voltage["value"]
                error_text = error_1 + error_2 + error_3 + error_4
                raise Exception(error_text)
            else:
                # Once Energy increase is known, calculate set-point for each RF Station
                for cryo in linac.cryomodule_list:
                    for station in cryo.station_list:
                        station_max_voltage = station.max_voltage['value']
                        station.cavity.design_voltage['value'] = station_max_voltage*sp_ratio

        # Add a parameter which was not parsed from configuration but deduced
        ## Final Accelerator Energy [eV]
        self.E = {"value" : Elast, "units" : "eV", "description" : "Final Accelerator Energy"}

        # Assign Tstep to the global variable
        global Tstep_global
        Tstep_global = self.Tstep['value']

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Simulation Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "Tstep: " + str(self.Tstep) + "\n"
        + "time_steps: " + str(self.time_steps) + "\n"
        + "nyquist_sign: " + str(self.nyquist_sign) + "\n"
        + "synthesis: " + str(self.synthesis) + "\n"
        + "bunch_rate: " + str(self.bunch_rate) + "\n"
        + "noise_srcs: " + str(self.noise_srcs) + "\n"
        + "E: " + str(self.E) + "\n"
        + "gun: " + str(self.gun) + "\n"

        + "linac_list: " + '\n'.join(str(x) for x in self.linac_list))

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc

        # First count number of Linacs and Allocate Arrays
        n_linacs = len(self.linac_list)

        # Allocate memory for array of Linacs
        linac_net = acc.Linac_Allocate_Array(n_linacs)

        # Allocate memory for Gun
        gun_C_Pointer = self.gun.Get_C_Pointer()

        # Allocate each Linac and append it to the linac_net
        for idx, linac in enumerate(self.linac_list):
            Linac_C_Pointer = linac.Get_C_Pointer()
            acc.Linac_Append(linac_net, Linac_C_Pointer, idx)

        # Instantiate Accelerator C structure
        sim = acc.Simulation()

        # Fill in Linac C data structure
        acc.Sim_Allocate_In(sim, \
            self.Tstep['value'], self.time_steps['value'], \
            gun_C_Pointer, linac_net, n_linacs)

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = sim

        # Return C Pointer for Simulation
        return sim

    def Get_State_Pointer(self):
        """ Return reference to the SWIG-wrapped State C structure. """
        import accelerator as acc

        # Allocate memory for Noise State
        noise_State_Pointer = self.noise_srcs.Get_State_Pointer()

        sim_state = acc.Simulation_State()
        acc.Sim_State_Allocate(sim_state, self.C_Pointer, noise_State_Pointer)

        ## Pointer to the SWIG-wrapped State C structure
        self.State = sim_state

        return sim_state

    def Init_FPGA_Registers(self, regmap, hierarchy):
        """ Aggregated constructor to initialize FPGA Register objects and add them as
        attributes of the parent object. Computation of the actual register values and
        parsing of the rest of the register attributes is performed by other functions.
        """

        for l in self.linac_list:
            l.Init_FPGA_Registers(regmap, hierarchy)

    def Compute_FPGA_Registers(self):
        """ Compute FPGA simulation register values for an entire simulation.
        Recursively append dictionaries of different components in the hierarchy.
        Inputs:
            simulation: Simulation object from the parsed JSON configuration file,
        outputs:
            linac_reg_dict: Dictionary of Linac dictionaries, key corresponds to linac name.
                Each dictionary contains register configuration for each linac, where dictionaries are nested for sub-components.
            error_cnt: Scaling error count.
        """

        Tstep = self.Tstep['value'] # s
        nyquist_sign = self.nyquist_sign['value']    # -1 represents frequency inversion, as with high-side LO or even-numbered Nyquist zones.
        n_mech_modes = self.synthesis.n_mech_modes['value']
        df_scale = self.synthesis.df_scale['value']

        for l in self.linac_list:
            l.Compute_FPGA_Registers(Tstep, nyquist_sign, n_mech_modes, df_scale)

        flat_reg_dict = self.Flatten_RegMap()

        return flat_reg_dict, error_cnt

    def Flatten_RegMap(self):
        flat_reg_dict = {}
        reg_dict_list = []

        for linac in self.linac_list:
            reg_dict_list.append(linac.reg_dict)
            for cryomodule in linac.cryomodule_list:
                reg_dict_list.append(cryomodule.reg_dict)
                for mechMode in cryomodule.mechanical_mode_list:
                    reg_dict_list.append(mechMode.reg_dict)
                for station in cryomodule.station_list:
                    reg_dict_list.append(station.reg_dict)
                    for elecMode in station.cavity.elec_modes:
                        reg_dict_list.append(elecMode.reg_dict)
                    for piezo in station.piezo_list:
                        reg_dict_list.append(piezo.reg_dict)

        for reg_dict_item in reg_dict_list:
            for key, value in reg_dict_item.iteritems():
                if value.name != '':
                    flat_reg_dict[value.name] = value



        return flat_reg_dict

class Gun:
    """ Contains parameters specific to an Gun configuration"""

    def __init__(self, confDict):

        gun_entry = confDict["Accelerator"]['gun']

        ## Instance name
        self.name = confDict[gun_entry]['name']
        ## Instance type
        self.type = confDict[gun_entry]['type']

        ## Nominal beam charge [C]
        self.Q = readentry(confDict,confDict[gun_entry]["Q"])
        ## Nominal initial RMS bunch length [m]
        self.sz0 = readentry(confDict,confDict[gun_entry]["sz0"])
        ## Nominal initial incoh. energy spread at nominal gun exit energy [fraction]
        self.sd0 = readentry(confDict,confDict[gun_entry]["sd0"])
        ## Nominal gun exit energy [eV]
        self.E = readentry(confDict,confDict[gun_entry]["E"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Gun Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "Q: " + str(self.Q) + "\n"
        + "sz0: " + str(self.sz0) + "\n"
        + "sd0: " + str(self.sd0) + "\n"
        + "E: " + str(self.E) + "\n")

    def Get_C_Pointer(self):
        """ Return reference to the SWIG-wrapped C structure. """

        import accelerator as acc

        gun = acc.Gun()
        acc.Gun_Allocate_In(gun, self.E['value'], self.sz0['value'], self.sd0['value'], self.Q['value']);

        ## Pointer to the SWIG-wrapped C structure
        self.C_Pointer = gun

        return gun

class Noise:
    """ Contains configuration regarding the correlated noise sources in the Accelerator."""

    def __init__(self, confDict):

        noise_entry = confDict['Noise']

        ## Instance name
        self.name = confDict[noise_entry]['name']
        ## Instance type
        self.type = confDict[noise_entry]['type']

        self.dQ_Q = readentry(confDict,confDict[noise_entry]["dQ_Q"])
        self.dtg = readentry(confDict,confDict[noise_entry]["dtg"])
        self.dE_ing = readentry(confDict,confDict[noise_entry]["dE_ing"])
        self.dsig_z = readentry(confDict,confDict[noise_entry]["dsig_z"])
        self.dsig_E = readentry(confDict,confDict[noise_entry]["dsig_E"])
        self.dchirp = readentry(confDict,confDict[noise_entry]["dchirp"])

    def __str__(self):
        """Convenient concatenated string output for printout."""

        return ("\n--Noise Object--\n"
        + "name: " + self.name + "\n"
        + "type: " + self.type + "\n"
        + "dQ_Q: " + str(self.dQ_Q) + "\n"
        + "dtg: " + str(self.dtg) + "\n"
        + "dE_ing: " + str(self.dE_ing) + "\n"
        + "dsig_z: " + str(self.dsig_z) + "\n"
        + "dsig_E: " + str(self.dsig_E) + "\n"
        + "dchirp: " + str(self.dchirp) + "\n")

    def Get_State_Pointer(self):
        """ Return reference to the SWIG-wrapped State C structure. """

        import accelerator as acc

        noise_srcs = acc.Noise_Srcs()

        type_net = acc.intArray_frompointer(noise_srcs.type)
        setting_net = acc.double_Array_frompointer(noise_srcs.settings)

        # Dictionaries for parameters and indices
        field_dict = ['dQ_Q', 'dtg', 'dE_ing', 'dsig_z', 'dsig_E', 'dchirp']
        type_dict = {'None':0, 'White':1, 'Sine':2, 'Chirp':3, 'Step':4}

        # Loop over all sources of noise in the dictionary,
        # and see if the user specified them
        for i in xrange(len(field_dict)):
            key = field_dict[i]
            # Make sure the key corresponds to a field that the user specified
            try:
                entry = self.key
                # Figure out its type
                type_net[i] = type_dict[entry['Type']]
                # Write the settings for the noise into the C structure
                settings = entry['Settings']
                if not isinstance(settings, list):
                    setting_net[acc.N_NOISE_SETTINGS*i] = float(settings)
                else:
                    for k in xrange(len(settings)):
                        setting_net[acc.N_NOISE_SETTINGS*i+k] = float(settings[k])
            except:
                # Default to no noise and whine to the user
                type_net[i] = 0

        # Return the C Pointer
        return noise_srcs

# scale a floating point number in range [-1,1) to fit in b-bit register
error_cnt=0

def fix(x,b,msg,opt=None):
    """fix: Convert floating point to fixed-point."""
    global error_cnt
    ss = 1 << (b-1)
    cordic_g = 1.646760258
    if opt is "cordic": ss = int(ss / cordic_g)
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

def push_seed(addr,hf):
    for jx in range(25):
        mm=hf.digest()
        s=0
        for ix in range(4): s=s*256+ord(mm[ix])
        # print "%d %u"%(addr,s)
        hf.update(chr(jx))
