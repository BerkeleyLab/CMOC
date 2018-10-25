import abc
import ast
import os
import importlib
import numpy as np
import sys
from datetime import datetime
from kivy.logger import Logger
from kivy.event import EventDispatcher
from kivy.base import EventLoop
from kivy.core.window import Window
EventLoop.ensure_window()


class TargetIO(EventDispatcher):
    """Hybird IO communication of configurable targets"""
    def __init__(self, **kwargs):
        self.client_options = []
        self.register_event_type('on_devinfo')
        self.register_event_type('on_trace')
        self.register_event_type('on_start')
        self.register_event_type('on_slowdata')
        self.register_event_type('on_slow_raw')
        self.register_event_type('on_chassis_data')
        self.register_event_type('on_chassis_init')
        super(TargetIO, self).__init__(**kwargs)
        self.config = kwargs.get('config', {})
        self.protocol = self.config['protocol']

    def on_devinfo(self, *args):
        pass

    def on_trace(self, *args):
        pass

    def on_slowdata(self, *args):
        pass

    def on_slow_raw(self, *args):
        pass

    def on_chassis_data(self, *args):
        pass

    def on_chassis_init(self, *args):
        pass

    def on_start(self, *args):
        pass

    @abc.abstractmethod
    def stop_io(self, *args):
        pass

    def start_io(self):
        """ Config target """
        if 'id' in self.config:
            Window.set_title(self.config['id'])
        self.dispatch('on_start')

    def get_init_regmap_dict(self):
        """ Query and return target init regmap """
        return {}

    def get_target_info(self):
        """ Query and return target configuration info """
        dat = {}
        self.dispatch('on_devinfo', dat)
        return dat

    def write_reg(self, reg_name, reg_val):
        """ update register """
        pass

    def read_slow_buf(self):
        """ Query and return slow data dictionary """
        self.dispatch('on_slowdata', {})
        return {}

    def get_chassis_data(self):
        """ Query and return chassis monitor dictionary """
        dat = {}
        self.dispatch('on_chassis_data', dat)
        return dat

    def init_chassis(self):
        """ Return dictionary of chassis init status """
        dat = {}
        self.dispatch('on_chassis_init', dat)
        return dat

    def set_cbuf_mode(self, mode):
        pass

    def get_plot_mode(self):
        """ Returns default plot mode and available modes """
        options = ['MP']
        mode = options[0]
        return (mode, options)

    def get_max_waveform_delay(self):
        """ Returns max delay (seconds) between waveform data ready """
        return 1


class PspepsIO(TargetIO):
    def __init__(self, **kwargs):
        self.viewer = kwargs.get('viewer', None)
        super(PspepsIO, self).__init__(**kwargs)

    def get_plot_mode(self):
        options = ['MP', 'IQ', 'RAW', 'FFT', 'FFT_IQ', 'Bode']
        mode = options[0]
        return (mode, options)

    def start_io(self):
        self.start_pspeps(
            self.config['ip'], int(self.config['port']),
            self.config['id'],
            self.config['app_path'],
            self.config.get('async', '1') == '1')

    def start_pspeps(self, ip_addr, port, firmware_id, app_path, use_async=True):
        """ Demux different projects """
        if app_path and firmware_id:
            base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
            import pkgutil
            self.app_dir = os.path.join(base_dir, app_path)
            if self.app_dir not in sys.path:
                sys.path.insert(0, self.app_dir)
            from app import Application
            Window.set_title(firmware_id)
            self.app = Application(ip=ip_addr, port=port, use_async=use_async)
            self.clients = {}
            for loader, name, ispkg in pkgutil.iter_modules(path=[self.app_dir+'/clients']):
                if not ispkg:
                    mtime = self.get_client_mtime(name)
                    self.clients[name] = (importlib.import_module('clients.' + name), mtime)
            self.client_options = self.clients.keys()
            self.dispatch('on_start')
        else:
            Logger.error('No valid firmware_id found. Quit now...')

    def load_client(self, name, mtime):
        self.clients[name] = (reload(self.clients[name][0]), mtime)

    def get_client_mtime(self, client_name):
        return os.stat(self.app_dir + '/clients/' + client_name + '.py').st_mtime

    def stop_io(self, *args):
        return self.app.stop_io()

    def get_trace(self, plot_mode='MP', length=256, cal=False):
        Logger.debug('getting trace with mode %s...' % plot_mode)
        iq_mode = plot_mode in ['MP', 'IQ', 'FFT_IQ', 'Bode']
        return self.app.get_waveform(iq_mode, length, cal).addCallback(self.got_trace, plot_mode)

    def got_trace(self, dat, plot_mode):
        if dat is not None:
            Logger.debug('got_trace length %d, %s' % (len(dat), datetime.now()))
        self.dispatch('on_trace', dat, plot_mode)
        return dat

    def get_chassis_mon(self):
        self.app.get_chassis_mon().addCallback(
            self.got_chassis_data, 'on_chassis_data')

    def got_chassis_data(self, dat, event):
        self.dispatch(event, dat)
        return dat

    def get_slow_data(self):
        self.app.read_slow_buf().addCallback(self.got_slow_data)

    def got_slow_data(self, dat):
        if dat is not None:
            self.dispatch('on_slowdata', dat)
            return dat

    def get_slow_raw_data(self):
        self.app.read_slow_buf(decode=False).addCallback(self.got_slow_raw_data)

    def got_slow_raw_data(self, dat):
        if dat is not None:
            self.dispatch('on_slow_raw', dat)
            return dat

    def get_target_info(self):
        self.app.get_config_rom().addCallback(self.got_config_rom)

    def got_config_rom(self, dat):
        self.dispatch('on_devinfo', dat)
        return dat

    def write_reg(self, reg_name, reg_val):
        Logger.info('Updating register %s to value: %d' % (reg_name, reg_val))
        self.app.write_app_reg_dict({reg_name: reg_val})

    def get_reg_by_addr(self, addr):
        return self.app.get_reg_by_addr(addr)

    def write_regs(self, reg_list):
        written_regs = self.app.write_regs(reg_list)
        if self.viewer is not None:
            for r in written_regs:
                short_name = self.app.get_view_name(r.name)
                if short_name in self.viewer.reg_view_dict:
                    self.viewer.reg_view_dict[short_name]['value'] = r.value
            self.viewer.reg_view.update(self.viewer.reg_view_dict)

    def get_init_regmap_dict(self):
        return self.app.get_init_regmap_dict()

    def get_time_step_adc(self):
        return self.app.get_timestep_adc()

    def set_xscale(self, val):
        return self.app.set_xscale(val)

    def get_xscale_value(self):
        return self.app.get_wave_samp_per()

    def get_xscale_range(self):
        return self.app.get_wave_samp_per_range()

    def get_xscale_enable(self):
        return True

    def calc_yscale(self, cal=False):
        return self.app.calc_yscale(cal)

    def set_cbuf_mode(self, mode):
        Logger.info('Updating cbuf mode to: %s' % mode)
        self.app.set_cbuf_mode(mode)

    def get_chan_info(self):
        return self.app.get_chan_info()

    def set_chan_keep(self, chans):
        return self.app.set_chan_keep_reg(chans)

    def init_chassis(self):
        self.app.init_chassis().addCallback(
            self.got_chassis_data, 'on_chassis_init')

    def get_max_waveform_delay(self):
        return self.app.get_cbuf_delay()

class RedisIO(TargetIO):
    def __init__(self, **kwargs):
        super(RedisIO, self).__init__(**kwargs)

    def start_io(self):
        import redis_client  # module used to read data from redis
        if 'id' in self.config:
            Window.set_title(self.config['id'])
        self.app = redis_client.RedisClient(
            self.config['ip'], int(self.config['port']))
        self.app.set_fpga_register(
            'stream:fpga:feed', 'frameRate', self.config['frame_rate'])
        self.dispatch('on_start')

    def get_trace(self, mode='MP', length=256):
        Logger.debug('getting trace...')
        dat = self.app.read_values(self.config['hash_samples'])
        self.dispatch('on_trace', dat, mode)
        return dat


class FileIO(TargetIO):
    def __init__(self, **kwargs):
        super(FileIO, self).__init__(**kwargs)

    def start_io(self):
        if 'id' in self.config:
            Window.set_title(self.config['id'])
        with file(self.config['fname'], 'r') as rfile:
            line = rfile.readline()
            if line[0] == '#':
                self.sysinfo = ast.literal_eval(line.strip(' #'))

        self.dispatch('on_start')

    def get_trace(self, mode='MP', length=256, has_unit=False):
        dat = np.loadtxt(self.config['fname'])
        n_chan = len(self.sysinfo['chan_keep_names'])
        if mode in ['MP', 'IQ']:
            traces = dat.transpose().reshape(2, n_chan, -1)
        else:
            traces = []
        self.dispatch('on_trace', traces, mode)
        return dat

    def get_time_step_adc(self):
        return self.sysinfo['time_step_adc']

    def get_chan_info(self):
        return (self.sysinfo['chan_names'], self.sysinfo['chan_keep_names'], [])

    def calc_xscale(self, val):
        return (val, self.sysinfo['time_step_iq'])

    def get_xscale_value(self):
        return 0

    def get_xscale_enable(self):
        return False

    def calc_yscale(self, cal=False):
        return self.sysinfo['yscale']

    def get_plot_mode(self):
        """ only 1 option """
        options = [self.sysinfo['plot_mode']]
        mode = options[0]
        return (mode, options)
