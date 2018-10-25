#!/usr/bin/python
# TODO:
# 1. Register read/write inside ethio shoud be abstracted away. The client app
# must be able to provide a way to read and write them, if the default
# mechanism isn't suited
# 2. Initialization parameter names can be first searched from such an
# interface as above
# 3. Read back from the FPGA mirror needs to be supported, based on the rw
# flags inside the map
# 4. get_waveform can be overridden to call param_auto under certain
# conditions
# BONUS Stuff
# * Hierarchy support?

import os
import sys
from twisted.internet import defer
base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
from pspeps_io.utilities import print_reg, decode_2s_comp
from pspeps_io.llrfapp import LLRFCommonApp
from pspeps_io.registers import RegMapExpand

build_dir = os.path.join(base_dir, '../submodules/build/')
if build_dir not in sys.path:
    sys.path.insert(0, build_dir)

from read_regmap import get_map, get_reg_info

json_dir = os.path.join(base_dir, 'parameters')
if json_dir not in sys.path:
    sys.path.insert(0, json_dir)

from parameters.to_fpga import PhysicsToFPGA
from parameters.data import reg_data_list_of_dicts as physics_regs

class Application(LLRFCommonApp):

    def __init__(self, **kwargs):
        super(Application, self).__init__(**kwargs)

    def init_llrf_settings(self):
	temp = get_map(os.path.join(base_dir, 'parameters/llrf_core_expand.json'))
	temp = temp['cryomodule']['regmap']
	self.app_reg_prefix = 'cryomodule_'

        self.wave_samp_per_name = get_reg_info(temp, [0], 'wave_samp_per')['name'].replace(self.app_reg_prefix, '')
        self.wave_shift_name = get_reg_info(temp, [0], 'wave_shift')['name'].replace(self.app_reg_prefix, '')
        self.chan_keep_name = get_reg_info(temp, [0], 'chan_keep')['name'].replace(self.app_reg_prefix, '')

        json_path = os.path.join(base_dir, 'parameters/llrf_core_expand.json')
        self.core_llrf = RegMapExpand(base=0, add_prefix=False, path=json_path)
        self.regmap.update(self.core_llrf.regmap)
        self.regmap_short.update(self.core_llrf.regmap_short)
        self.reg_addr_dict.update(self.core_llrf.reg_addr_dict)

        # see llrf_core.json
        self._cbuf_flip_name = 'DSP_CBUF_FLIP'
        self._slow_name = 'DSP_SLOW'
        self._cbuf_name = 'DSP_CBUF'
        self._cbuf_mode_channel_name = 'DSP_CBUF_MODE'
        self.config_rom_name = 'DSP_CONFIG_ROM'

        self.buf_dw = 16
        self.cbuf_width = 13
        self.adc_bits = 16
        self.shift_base = 1  # ccfilt.v
        self.wave_samp_per = 1
        self.wave_shift = 3
        self.num_dds = 7
        self.den_dds = 33
        self.clk_freq = 75e6
        self.chn_names = ['Field', 'Forward', 'Reflected', 'PhRef']
        self.chn_names.extend(['Null'] * 2)
        self.slow_buf_len = 2*len(self.chn_names) + 2
        self.cbuf_mode_list = ['default'] + ['Counter'] + self.chn_names[:3] + ['Drive']
        self.chn_sel = self.chn_names[:4]
        self.prng_data = {}
        # self.init_llrf_settings()
        self.to_fpga = PhysicsToFPGA(**{x['name']:x['value'] for x in physics_regs})
        self.cic_period = self.den_dds
        # channel FIR configurations may vary
        self.FIR_GAIN = 1.
        self.mon_gains, self.fir_gains = {}, {}

        for ch in self.chn_names:
            self.mon_gains[ch] = self.FIR_GAIN
            self.fir_gains[ch] = self.FIR_GAIN
        self.lo_gain = int((1 << 15) / self.CORDIC_GAIN)
        self.lo_dds_gain = self.lo_gain * 4 * self.CORDIC_GAIN / (1 << 17)
        self.adc_freq = 150e6
        self.time_step_adc = 1./self.adc_freq
        self.time_step_mon = self.wave_samp_per / self.clk_freq
        self.trace_len = (1 << 11)/len(self.chn_sel)

    def set_init_regs(self):
        init_reg_all = dict(self.init_reg)
        init_reg_all.update(self.init_reg_hide)
        # self.write_app_reg_dict(init_reg_all)
        self.init_regs()

    def setup_gui_params(self):
        wave_shift, time_step = self.calc_xscale()
        chan_keep_reg = self.set_chan_keep_reg(self.chn_sel)

    def prep_init_regs(self, level=0):
        # init_reg = gen_reg_list()
        init_reg = {}
        if level == 0:
            self.setup_gui_params()
        elif level == 1:
            exit('There is something seriously wrong!')
        return init_reg, {}

    def update_physics(self, update):
        for name, value in update.iteritems():
            print self.to_fpga.duration
            print 'physics register {} changed to {}'.format(name, value)
            setattr(self.to_fpga, name, value)
            print self.to_fpga.duration
        write_regs = []
        for r in self.to_fpga(self.lim_reg_addr):
            # Register format:
            # r = [register_pseudonym, register_hierarchy, register_value]
            ethio_reg = self.get_reg_info(r[0], r[1])
            if type(r[2]) is list:
                for i, x in enumerate(r[2]):
                    v = decode_2s_comp(x, bits=ethio_reg.width,
                                       signed=(ethio_reg.sign == 'signed'))
                    write_regs.append((ethio_reg.address+i, v))
            else:
                v = decode_2s_comp(r[2], bits=ethio_reg.width,
                                   signed=(ethio_reg.sign == 'signed'))
                write_regs.append((ethio_reg.address, v))
        return write_regs

    def init_regs(self, level=0):
        """ write initial regs"""
        self.set_cbuf_mode('IQ')
        write_regs = []
        self.lim_reg_addr = self.get_reg_info('lim', [0]).address
        for r in self.to_fpga(self.lim_reg_addr):
            # Register format:
            # r = [register_pseudonym, register_hierarchy, register_value]
            ethio_reg = self.get_reg_info(r[0], r[1])
            if type(r[2]) is list:
                for i, x in enumerate(r[2]):
                    v = decode_2s_comp(x, bits=ethio_reg.width,
                                       signed=(ethio_reg.sign == 'signed'))
                    write_regs.append((ethio_reg.address+i, v))
            else:
                v = decode_2s_comp(r[2], bits=ethio_reg.width,
                                   signed=(ethio_reg.sign == 'signed'))
                write_regs.append((ethio_reg.address, v))
        self.write_regs(write_regs)
        self.prep_init_regs()

    def get_init_regmap_dict(self):
        """ Return sorted regmap dict for higher level (GUI) use """
        reg_view_dict = {}
        self.lim_reg_addr = self.get_reg_info('lim', [0]).address
        for r in self.to_fpga(self.lim_reg_addr):
            # Register format:
            # r = [register_pseudonym, register_hierarchy, register_value]
            reg = self.get_reg_info(r[0], r[1])
            reg = self.get_reg_by_addr(reg.address)
            # XXX GUI and regmap are seperated here:
            reg_dict = {}
            # remove app prefix for comfort display
            short_regname = reg.name[len(self.app_reg_prefix):]
            reg_dict['name'] = short_regname
            reg_dict['virtual'] = False
            reg_dict['value'] = reg.value
            reg_dict['vmin'] = reg.min
            reg_dict['vmax'] = reg.max
            reg_dict['unit'] = ''
            reg_dict['callback'] = None
            reg_view_dict[short_regname] = reg_dict
        for r in physics_regs:
            r['virtual'] = True
            r['callback'] = self.update_physics
            reg_view_dict[r['name']] = r
        print [reg_view_dict[x]['value'] for x in reg_view_dict]
        return reg_view_dict

    def get_config_rom(self):
        return self.get_lbnl_rom(self.get_reg_addr(self.config_rom_name))

    def play_prng_data(self):
        # should call push_seed()
        for key in self.prng_data:
            dlist = self.prng_data[key]
            alist = [key] * len(dlist)
            self.write_lb_list(alist, dlist)

    @defer.inlineCallbacks
    def read_buf_rdy(self):
        d = yield self.read_lb_reg(self.get_reg_addr(self.config_rom_name))
        cbuf_rdy = d >> 10 & 1
        slow_rdy = d >> 11 & 1
        defer.returnValue((slow_rdy, cbuf_rdy))

    def get_waveform(self, iq_mode=True, length=256, cal=False):
        # self.play_prng_data()
        return super(Application, self).get_waveform(iq_mode=iq_mode, length=length, cal=cal)

    def calc_yscale(self, cal=False):
        # TODO: XXX fix me
        return 128

def main(argv):
    target1 = Application()
    target1.init_regs()
    # print_reg(target1.regmap)
    print_reg(target1.regmap['DSP_CONFIG_ROM'])
    print_reg(target1.regmap['DSP_CBUF_FLIP'])
    print_reg(target1.regmap['DSP_CBUF_MODE'])
    print_reg(target1.regmap['DSP_CBUF'])

if __name__ == "__main__":
    main(sys.argv[1:])
