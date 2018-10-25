#!/usr/bin/python

import readjson.parse_simulation as parseSim
import readjson.parse_register_map as parseRegMap
import sys
print sys.path
sys.path.append('/Users/w/work/lbl/cmoc/submodules/build')
print sys.path

def getFPGADict(simulation):
    """getFPGADict: Illustration of conversion of user-defined physics values (contained in the simulation object,
    which is obtained from the JSON parser) and the FPGA register values, contained in the output dictionary linac_reg_dict.
    error_cnt is an error count reported from the floating-point to fix-point arithmetic conversions and scaling.
    """

    from read_regmap import get_map
    regmap = get_map("./_autogen/regmap_cryomodule.json")
    hierarchy = ["station", "cav4_elec", ["mode_", 3]]

    # Initialize empty FPGA register objects
    simulation.Init_FPGA_Registers(regmap, [])

    # (This is where register map should be parsed and register lengths should be filled in)

    # Compute FPGA register values based on configuration parameters
    error_cnt = simulation.Compute_FPGA_Registers()

    return error_cnt

# send a register value "out"
# looks address up in regmap[name]
# finds value via name in python global namespace
# value can be a scalar or a list
# prefix and name are used to give a helpful comment
def set_reg_old(offset, prefix, name, regmap, dict_in, sim_base):

    from readjson.readjson_accelerator import Register

    if isinstance(dict_in[name], Register):
        val = dict_in[name].value  # globals() or locals()?
    else:
        val = dict_in[name]

    reg = regmap[name]
    if (type(val) is list):
        for i,v in enumerate(val):
            print sim_base+offset+reg.get_addr_space()+i, v, "#", prefix+name+"["+str(i)+"]"
    else:
        print sim_base+offset+reg.get_addr_space(), val, "#", prefix+name

def set_reg(offset, prefix, name, regmap, dict_in, sim_base):

    from readjson.readjson_accelerator import Register

    R = dict_in[name]
    if isinstance(R, Register):
        val = R.value  # globals() or locals()?
    else:
        print("#ISSUE", R, name)
        val = R

    if (type(val) is list):
        for i,v in enumerate(val):
            print sim_base+R.base_addr+i, v, "#", R.fpga_name+"["+str(i)+"]", name, R.base_addr + i
    else:
        print sim_base + R.base_addr, val, "#", R.fpga_name, name, R.base_addr

class c_regs:
   def __init__(self,name,addr,value):
      self.name=name
      self.addr=addr
      self.value=(value+2**32) if value <0 else value

   def print_regs(self):
      return '%d %d'%(self.addr,self.value)

global delay_pc, duration
delay_pc = 4096
duration = 300

def delay_set(ticks,addr,data):
	global delay_pc
	delay_pc += 4

	return [
		c_regs('delay',    delay_pc-4,ticks),
		c_regs('dest_addr',delay_pc-3,addr),
		c_regs('value_msb',delay_pc-2,int(data)/65536),
		c_regs('value_lsb',delay_pc-1,int(data)%65536)]

def printFPGADict():
    """printFPGADict: Replication of the old param.py program for illustration purposes.
    Run this program in order to call JSON parser, user-defined physics settings to FPGA register space conversion,
    and prints used by Verilog test-bench for configuration parsing.
    """

    from readjson.readjson_accelerator import push_seed

    # Get the simulation and accelerator objects from the JSON parser
    file_list =  [
        "readjson/configfiles/LCLS-II/default_accelerator.json",
        "readjson/configfiles/LCLS-II/LCLS-II_accelerator.json",
        "readjson/configfiles/LCLS-II/LCLS-II_append.json"]

    simulation = parseSim.ParseSimulation(file_list)

    # ==== the following dictionaries should get pulled in from Verilog somehow
    sim_base=16384  # base address for vmod1, see larger.v line 33

    # regmap_global and regmap_emode dictionaries will be automatically created from a JSON file
    # regmap_mode: base address for cavity n (zero-based) is 16+8*n
    regmap_file = "readjson/configfiles/LCLS-II/register_map.json"
    regmap_global, regmap_emode = parseRegMap.ParseRegisterMap(regmap_file)

    from read_regmap import get_map, get_reg_info
    regmap = get_map("./_autogen/regmap_cryomodule.json")

    print "# Globals"
    # Convert user input into FPGA registers
    error_cnt = getFPGADict(simulation)

    # Grab the variables of interest from the dictionary
    ## First go down the hierarchy and get handles to dictionaries
    linac_obj = simulation.linac_list[0]
    cryomodule_obj = linac_obj.cryomodule_list[0]
    station_obj = cryomodule_obj.station_list[0]

    linac_reg_dict      = linac_obj.reg_dict
    station0_reg_dict   = station_obj.reg_dict
    cm_reg_dict = cryomodule_obj.reg_dict
    mechMode0_reg_dict  = cryomodule_obj.mechanical_mode_list[0].reg_dict
    mechMode1_reg_dict  = cryomodule_obj.mechanical_mode_list[1].reg_dict
    mechMode2_reg_dict  = cryomodule_obj.mechanical_mode_list[2].reg_dict
    elecMode0_reg_dict  = station_obj.cavity.elec_modes[0].reg_dict
    elecMode1_reg_dict  = station_obj.cavity.elec_modes[1].reg_dict
    # Quick hack to add name field
    elecMode0_reg_dict['name'] = station_obj.cavity.elec_modes[0].name
    elecMode1_reg_dict['name'] = station_obj.cavity.elec_modes[1].name

    piezo0_reg_dict     = station_obj.piezo_list[0].reg_dict

    reg_dict = {}
    ## Linac variables
    reg_dict['dds_phstep'] = linac_reg_dict['dds_phstep']
    reg_dict['dds_modulo'] = linac_reg_dict['dds_modulo']
    ## Station variables
    reg_dict['amp_bw'] = station0_reg_dict['amp_bw']

    # Manually construct prompt for now
    reg_dict['prompt'] = station0_reg_dict['prompt']

    for e in [elecMode0_reg_dict, elecMode1_reg_dict]:
        reg_dict['prompt'].value.append(e["prompt_rfl"].value)
        reg_dict['prompt'].value.append(e["prompt_fwd"].value)

    reg_dict['cav_adc_off'] = station0_reg_dict['cav_adc_off']
    reg_dict['rev_adc_off'] = station0_reg_dict['rev_adc_off']
    reg_dict['fwd_adc_off'] = station0_reg_dict['fwd_adc_off']

    reg_dict['res_prop'] = cm_reg_dict['res_prop']
    reg_dict['res_prop'].set_value([
        mechMode0_reg_dict['a2'].value,
        mechMode0_reg_dict['b2'].value,
        mechMode1_reg_dict['a2'].value,
        mechMode1_reg_dict['b2'].value,
        mechMode2_reg_dict['a2'].value,
        mechMode2_reg_dict['b2'].value])

    reg_dict['dot_0_k'] = elecMode0_reg_dict['dot_list']
    reg_dict['outer_0_k'] = elecMode0_reg_dict['outer_list']
    reg_dict['dot_1_k'] = elecMode1_reg_dict['dot_list']
    reg_dict['outer_1_k'] = elecMode1_reg_dict['outer_list']
    reg_dict['dot_2_k'] = [piezo0_reg_dict['piezo_couple'].value[0], piezo0_reg_dict['piezo_couple'].value[1], piezo0_reg_dict['piezo_couple'].value[3],  piezo0_reg_dict['piezo_couple'].value[2]]
    reg_dict['outer_2_k'] = []
    reg_dict['piezo_couple'] = piezo0_reg_dict['piezo_couple']

    # Added to generate the vibration_hack values
    reg_dict['noise_couple'] = cm_reg_dict['noise_couple']
    reg_dict['noise_couple'].set_value([
        mechMode0_reg_dict['vibration_hack'].value[0],
        mechMode0_reg_dict['vibration_hack'].value[1],
        mechMode1_reg_dict['vibration_hack'].value[0],
        mechMode1_reg_dict['vibration_hack'].value[1],
        mechMode2_reg_dict['vibration_hack'].value[0],
        mechMode2_reg_dict['vibration_hack'].value[1]
    ])

    # Pop some elements to match paramhg.py
    del reg_dict['prompt'].value[4:]
    del reg_dict['dot_2_k'][0:]

    for n in regmap_global.keys():
        set_reg(0, "", n, regmap_global, reg_dict, sim_base)

    for i,emode in enumerate([elecMode0_reg_dict, elecMode1_reg_dict]):
        reg_dict['coarse_freq'] = emode['coarse_freq']
        reg_dict['drive_coupling'] = emode['drive_coupling']
        reg_dict['bw'] = emode['bw']
        reg_dict['out_coupling'] = emode['out_coupling']
        reg_dict['out_phase_offset'] = emode['out_phase_offset']
        regmap_emode.pop('out_couple',None)
        regmap_emode['out_coupling'] = None
        regmap_emode['out_phase_offset'] = None
        print "# Cavity electrical mode %d: %s"%(i,emode['name'])
        for n in regmap_emode:
            set_reg(16+8*i,emode['name']+".",n,regmap_emode, reg_dict, sim_base)

    # Pseudo-random generator initialization, see tt800v.v and prng.v
    prng_seed="pushmi-pullyu"
    prng_iva = get_reg_info(regmap, [], "prng_iva")
    prng_ivb = get_reg_info(regmap, [], "prng_ivb")
    prng_random_run = get_reg_info(regmap, [], "prng_random_run")
    if (prng_seed is not None):
        from hashlib import sha1
        print "# PRNG subsystem seed is '%s'"%prng_seed
        hf = sha1()
        hf.update(prng_seed)
        push_seed(prng_iva['base_addr']+sim_base,hf)
        push_seed(prng_ivb['base_addr']+sim_base,hf)
        print "%d 1  # turn on PRNG"%(prng_random_run['base_addr']+sim_base)

    # Just hack in a few quick values for the controller
    # This should really be another construction as above, maybe in a separate Python module?
    # static DDS config, 7/33 as above
    wave_samp_per=1
    wave_shift=3
    # The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
    # fits nicely within the 32768 limit for small values of wave_samp_per
    lo_cheat=(32/33.0)**2;
    yscale=lo_cheat*(33*wave_samp_per)**2*4**(8-wave_shift)/32

    reg_list = []

    # Variables defined to print out the registers value
    piezo_dc = 0
    ph_offset = -35800
    sel_en = 0
    set_X = 0.0
    set_P = 0.0
    k_PA = 0
    k_PP = 0

    from read_regmap import get_map, get_reg_info
    ctl_regmap = get_map("./_autogen/regmap_llrf_shell.json")
    # Maybe the following lines should be removed in the future
    #reg_list.append(c_regs('phase_step', 17+18, reg_dict['dds_phstep'].value))
    #reg_list.append(c_regs('modulo', 18+18, reg_dict['dds_modulo'].value))
    addr = get_reg_info(ctl_regmap,[],'wave_samp_per')['base_addr']
    reg_list.append(c_regs('wave_samp_per', addr, wave_samp_per))
    addr = get_reg_info(ctl_regmap,[],'wave_shift')['base_addr']
    reg_list.append(c_regs('wave_shift', addr, wave_shift))
    addr = get_reg_info(ctl_regmap,[],'piezo_dc')['base_addr']
    reg_list.append(c_regs('piezo_dc', addr, piezo_dc))
    addr = get_reg_info(ctl_regmap,[],'sel_thresh')['base_addr']
    reg_list.append(c_regs('sel_thresh', addr, 5000))
    addr = get_reg_info(ctl_regmap,[],'ph_offset')['base_addr']
    reg_list.append(c_regs('ph_offset', addr, ph_offset))
    addr = get_reg_info(ctl_regmap,[],'sel_en')['base_addr']
    reg_list.append(c_regs('sel_en', addr, sel_en))
    addr = get_reg_info(ctl_regmap,[],'lp1a_kx')['base_addr']
    reg_list.append(c_regs('lp1a', addr, 20486))
    addr = get_reg_info(ctl_regmap,[],'lp1a_ky')['base_addr']
    reg_list.append(c_regs('lp1a', addr, -20486))
    reg_list.append(c_regs('wait', 555, 150-12))
    addr = get_reg_info(ctl_regmap,[],'chan_keep')['base_addr']
    reg_list.append(c_regs('ch_keep', addr, 4080))
    addr = get_reg_info(ctl_regmap,[],'setmp')['base_addr']
    reg_list.append(c_regs('set_X', addr, int(set_X)))
    reg_list.append(c_regs('set_P', addr+1, int(set_P)))
    addr = get_reg_info(ctl_regmap,[],'coeff')['base_addr']
    reg_list.append(c_regs('coeff_X_I', addr+0, -100))
    reg_list.append(c_regs('coeff_X_P', addr+2, k_PA))
    reg_list.append(c_regs('coeff_Y_I', addr+1, -100))
    reg_list.append(c_regs('coeff_Y_P', addr+3, k_PP))
    addr = get_reg_info(ctl_regmap,[],'lim')['base_addr']
    reg_list.append(c_regs('lim_X_hi', addr+0, 0))
    reg_list.append(c_regs('lim_Y_hi', addr+1, 0))
    reg_list.append(c_regs('lim_X_lo', addr+2, 0))
    reg_list.append(c_regs('lim_Y_lo', addr+3, 0))

    # Variables needed
    amp_max = 22640

    reg_list.extend(delay_set(0, addr, amp_max))            # 52 is the address of lim_X_hi
    reg_list.extend(delay_set(duration*8, addr+2, amp_max))   # 54 is the address of lim_X_lo
    reg_list.extend(delay_set(0, addr, 0))                  # 52 is the address of lim_X_hi
    reg_list.extend(delay_set(0, addr+2, 0))                  # 54 is the address of lim_X_lo

    for jx in range(6):
       reg_list.extend(delay_set(0,0,0))

    for reg in reg_list:
       print str(reg.addr) + " " + str(reg.value)

    if (error_cnt > 0):
      print "# %d scaling errors found"%error_cnt
      exit(1)

if __name__=="__main__":

    # Convert user-defined configuration into FPGA registers and print (just like param.py used to do)
    printFPGADict()
