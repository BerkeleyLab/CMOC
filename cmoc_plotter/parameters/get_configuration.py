#!/usr/bin/python

import parse_simulation as parseSim
import os
import sys
base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
if base_dir not in sys.path: sys.path.insert(0, base_dir)

build_dir = os.path.join(base_dir, '../../../build')
if build_dir not in sys.path: sys.path.insert(0, build_dir)

from read_regmap import get_map, get_reg_info
from readjson_accelerator import Register

def getFPGADict(simulation):
    """
    getFPGADict: Illustration of conversion of user-defined physics values
    (contained in the simulation object, which is obtained from the JSON parser)
    and the FPGA register values, contained in the output dictionary
    linac_reg_dict.  error_cnt is an error count reported from the
    floating-point to fix-point arithmetic conversions and scaling.
    """

    from read_regmap import get_map
    regmap = get_map(base_dir+"/../_autogen/regmap_cryomodule.json")
    c_reg_base = get_reg_info(regmap, [], 'llrf_'+str(0)+'_xxxx')['base_addr']

    # Initialize empty FPGA register objects
    simulation.Init_FPGA_Registers(regmap, [])

    # Compute FPGA register values based on configuration parameters
    flat_reg_dict, error_cnt = simulation.Compute_FPGA_Registers()

    # Replace computed values directly in register map
    for key, value in flat_reg_dict.iteritems():
        regmap[key] = value

    # Make sure all values are Register instances
    for key, value in regmap.iteritems():
        if not isinstance(value, Register):
            regmap[key] = Register(**value)

    return regmap, error_cnt, c_reg_base

def print_regmap(regmap):

    for key, val in regmap.iteritems():
        if isinstance(val.value, (list, tuple)):
            for k, value_now in enumerate(val.value):
                print '{} {}'.format(val.address+k, val.value[k])+' # '+key+'[{}]'.format(k)
        else:
            print '{} {}'.format(
                val.address, val.value)+' # '+key

# send a register value "out"
# finds value via name in python global namespace
# value can be a scalar or a list
def set_reg(name, dict_in, sim_base):
    R = dict_in[name]
    if isinstance(R, Register):
        val = R.value
    else:
        print("#ISSUE", R, name)
        val = R

    # XXX if (type(val) is list):
    #     for i,v in enumerate(val):
    #         # print sim_base+R.address+i, v, "#", R.name+"["+str(i)+"]"
    #         print v
    # else:
    #     print R
    #     # print sim_base + R.address, val, "#", R.name

def set_reg_dict(dict_in, sim_base):
    for key, val in dict_in.iteritems():
            if (key != "name") & (key != "prompt_fwd") & (key != "prompt_rfl"):
                set_reg(key, dict_in, 0)

def set_reg_value(value):
    return (value+2**32) if value <0 else value

global delay_pc, duration
delay_pc = 4096
duration = 750

def delay_set(ticks,addr,data):
    global delay_pc
    delay_pc += 4

    name_base = 'tgen_' + str(delay_pc-4   ) + '_'

    delay_dict = {
        'name':name_base+'delay',
        'base_addr': delay_pc-4,
        'data_width': 16,
        'value': ticks,
        'in_regmap': False
    }

    dest_addr_dict = {
        'name':name_base+'dest_addr',
        'base_addr': delay_pc-3,
        'data_width': 16,
        'value': addr,
        'in_regmap': False
    }

    value_msb_dict = {
        'name':name_base+'value_msb',
        'base_addr': delay_pc-2,
        'data_width': 16,
        'value': int(data)/65536,
        'in_regmap': False
    }

    value_lsb_dict = {
        'name':name_base+'value_lsb',
        'base_addr': delay_pc-1,
        'data_width': 16,
        'value': int(data)%65536,
        'in_regmap': False
    }

    return [
        Register(**delay_dict),
        Register(**dest_addr_dict),
        Register(**value_msb_dict),
        Register(**value_lsb_dict)]

def gen_reg_list(verbose=False):
    """
    gen_reg_list: Replication of the old param.py program for illustration
    purposes.  Run this program in order to call JSON parser, user-defined
    physics settings to FPGA register space conversion, and prints used by
    Verilog test-bench for configuration parsing.
    """
    # Get the simulation and accelerator objects from the JSON parser
    file_list = [
        base_dir+"/configfiles/LCLS-II/default_accelerator.json",
        base_dir+"/configfiles/LCLS-II/LCLS-II_accelerator.json",
        base_dir+"/configfiles/LCLS-II/LCLS-II_append.json"]

    simulation = parseSim.ParseSimulation(file_list, verbose)

    sim_base = 0  # base address for vmod1, see larger.v line 33

    # Convert user input into FPGA registers
    regmap, error_cnt, c_reg_base = getFPGADict(simulation)

    # Pseudo-random generator initialization, see tt800v.v and prng.v
    prng_seed = "pushmi-pullyu"

    prng_iva = regmap["cavity_0_prng_iva"]
    prng_ivb = regmap["cavity_0_prng_ivb"]
    prng_random_run = regmap["cavity_0_prng_random_run"]

    if (prng_seed is not None):
        from readjson_accelerator import push_seed
        from hashlib import sha1
        # print "# PRNG subsystem seed is '%s'"%prng_seed
        hf = sha1()
        hf.update(prng_seed)
        push_seed(prng_iva.address+sim_base, hf)
        push_seed(prng_ivb.address+sim_base, hf)
        # print "%d 1  # turn on PRNG"%(prng_random_run.address+sim_base)

    # Just hack in a few quick values for the controller
    # This should really be another construction as above, maybe in a separate Python module?
    # static DDS config, 7/33 as above
    wave_samp_per = 1
    wave_shift = 3

    reg_list = []

    # Variables defined by hand, should really come from JSON controller configuration
    piezo_dc = 0
    ph_offset = -150800
    sel_en = 1
    sel_thresh = 5000
    lp1a_kx = 20486
    lp1a_ky = -20486
    chan_keep = 4080

    ctl_regmap = get_map(base_dir+"/../_autogen/regmap_llrf_shell.json")

    reg = Register(**get_reg_info(ctl_regmap,[],'wave_samp_per'))
    reg.value = wave_samp_per
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'wave_shift'))
    reg.value = wave_shift
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'piezo_dc'))
    reg.value = piezo_dc
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'sel_thresh'))
    reg.value = sel_thresh
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'ph_offset'))
    reg.value = ph_offset
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'sel_en'))
    reg.value = sel_en
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'lp1a_kx'))
    reg.value = lp1a_kx
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'lp1a_ky'))
    reg.value = lp1a_ky
    reg_list.append(reg)

    reg = Register(**get_reg_info(ctl_regmap,[],'chan_keep'))
    reg.value = chan_keep
    reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'setmp'))
    # reg.name = 'set_X'
    # reg.address = reg.address + 0
    # reg.value = int(set_X)
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'setmp'))
    # reg.name = 'set_P'
    # reg.address = reg.address + 1
    # reg.value = int(set_P)
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'coeff'))
    # reg.name = 'coeff_X_I'
    # reg.address = reg.address + 0
    # reg.value = coeff_X_I
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'coeff'))
    # reg.name = 'coeff_X_P'
    # reg.address = reg.address + 1
    # reg.value = coeff_X_P
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'coeff'))
    # reg.name = 'coeff_Y_I'
    # reg.address = reg.address + 2
    # reg.value = coeff_Y_I
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'coeff'))
    # reg.name = 'coeff_Y_P'
    # reg.address = reg.address + 3
    # reg.value = coeff_Y_P
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'lim'))
    # reg.name = 'lim_X_hi'
    # reg.address = reg.address + 0
    # reg.value = lim_X_hi
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'lim'))
    # reg.name = 'lim_Y_hi'
    # reg.address = reg.address + 1
    # reg.value = lim_Y_hi
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'lim'))
    # reg.name = 'lim_X_lo'
    # reg.address = reg.address + 2
    # reg.value = lim_X_lo
    # reg_list.append(reg)

    # reg = Register(**get_reg_info(ctl_regmap,[],'lim'))
    # reg.name = 'lim_Y_lo'
    # reg.address = reg.address + 3
    # reg.value = lim_Y_lo
    # reg_list.append(reg)

    addr = get_reg_info(ctl_regmap,[],'lim')['base_addr']
    # Variables needed

    # reg_list.extend(delay_set(0, addr, amp_max))            # 52 is the address of lim_X_hi
    # reg_list.extend(delay_set(duration*8, addr+2, amp_max))   # 54 is the address of lim_X_lo
    # reg_list.extend(delay_set(0, addr, 0))                  # 52 is the address of lim_X_hi
    # reg_list.extend(delay_set(0, addr+2, 0))                  # 54 is the address of lim_X_lo

    # for jx in range(6):
    #    reg_list.extend(delay_set(0,0,0))

    for item in reg_list:
        if item.name != '':
                regmap[item.name] = item

    if (error_cnt > 0):
      print "# %d scaling errors found"%error_cnt
      exit(1)

    return regmap


if __name__=="__main__":

    # Convert user-defined configuration into FPGA registers and print (just like param.py used to do)
    reg_dict_out = gen_reg_list(verbose=False)
    print_regmap(reg_dict_out)
    # print 'Now print out...'
    # set_reg_dict(reg_dict_out2, 0)
