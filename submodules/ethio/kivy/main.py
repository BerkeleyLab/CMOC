import numpy as np
from twisted.internet import task
from twisted.internet.defer import CancelledError, TimeoutError
from kivy.app import App
from kivy.logger import Logger
from kivy.config import ConfigParser
from kivy.properties import NumericProperty, ListProperty, BooleanProperty, ObjectProperty
from kivy.clock import Clock
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.listview import ListView, ListItemButton, ListItemLabel, CompositeListItem
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.gridlayout import GridLayout
from kivy.uix.screenmanager import Screen
from kivy.uix.slider import Slider
from kivy.uix.togglebutton import ToggleButton
from kivy.uix.behaviors import FocusBehavior, CompoundSelectionBehavior
from kivy.adapters.listadapter import ListAdapter
from kivy.adapters.models import SelectableDataItem
from trace_plot import TracesPlotMP, TracesPlotIQ, TracesPlotRAW, TracesPlotFFT, TracesPlotFFTIQ, TracesPlotBode
from target_io import PspepsIO, FileIO
from kivy.support import install_twisted_reactor
install_twisted_reactor()
from twisted.internet import reactor


class DevinfoItem(SelectableDataItem):
    """Target device data item structure"""
    def __init__(self, **kwargs):
        super(DevinfoItem, self).__init__()
        self.name = kwargs.get('name', '')
        self.data = kwargs.get('data', '')


class RegSelectItem(SelectableDataItem):
    """FPGA register data item structure"""
    def __init__(self, **kwargs):
        super(RegSelectItem, self).__init__()
        self.name = kwargs.get('name', '')
        self.value = kwargs.get('value', 0)
        self.vmin = kwargs.get('vmin', 0)
        self.vmax = kwargs.get('vmax', 1)
        self.unit = kwargs.get('unit', '')
        self.step = kwargs.get('step', 1)


class DictInfoView(BoxLayout):
    """Dictionary view of target IO info and rom info if available"""
    def __init__(self, **kwargs):
        super(DictInfoView, self).__init__(**kwargs)
        adapter_data = self.prep_adpter_data({})

        def args_converter(index, rec):
            return {'text': rec.name,
                    'data': str(rec.data),
                    'size_hint_y': None,
                    'height': 25}

        self.list_adapter = ListAdapter(
            data=adapter_data,
            args_converter=args_converter,
            template='CustomListItem')
        self.add_widget(ListView(adapter=self.list_adapter))

    def prep_adpter_data(self, info_dict):
        self.info_dict = info_dict
        rominfo_list_of_dicts = [
            {'name': key, 'data': info_dict[key]} for key in sorted(info_dict.keys())]
        rom_data_items = [DevinfoItem(**d) for d in rominfo_list_of_dicts]
        return rom_data_items

    def update(self, data):
        self.list_adapter.data = self.prep_adpter_data(data)

    def get_data(self):
        return self.info_dict


class RegDictView(BoxLayout):
    """Register dictionary view. Should be replaced by RecycleView after kivy 1.9.2"""

    def __init__(self, **kwargs):

        def items_args_converter(row_index, rec):
            return {
                'text': rec.name,
                'value': str(rec.value),
                'unit': rec.unit,
                'size_hint_y': None, 'height': 20,
                'cls_dicts': [{
                    'cls': ListItemButton,
                    'kwargs': {
                        'text': rec.name,
                        'size_hint_x': 0.6,
                        'is_representing_cls': True}},
                    {'cls': ListItemLabel,
                     'kwargs': {'text': str(rec.value)[:6], 'size_hint_x': 0.3}},
                    {'cls': ListItemLabel,
                     'kwargs': {'text': rec.unit, 'size_hint_x': 0.1}}]}

        self.list_adapter = ListAdapter(
            data={},
            args_converter=items_args_converter,
            selection_mode='single',
            allow_empty_selection=True,
            propagate_selection_to_data=True,
            cls=CompositeListItem)
        self.list_adapter.bind(on_selection_change=self.reg_selection_changed)
        super(RegDictView, self).__init__(**kwargs)
        self.add_widget(ListView(adapter=self.list_adapter))
        self.slider_view = RegSliderView(reg_index=0, list_adapter=self.list_adapter)
        self.add_widget(self.slider_view)

    def reg_selection_changed(self, list_adapter, *args):
        if not list_adapter.selection:
            Logger.debug('No selection')
        else:
            self.slider_view.redraw(list_adapter.selection[0].index)

    def prep_adpter_data(self, info_dict):
        self.info_dict = info_dict
        info_list_of_dicts = [info_dict[key] for key in sorted(info_dict.keys())]
        reg_data_items = [RegSelectItem(**d) for d in info_list_of_dicts]
        return reg_data_items

    def update(self, data, has_virtual=False):
        data = {k: v for k, v in data.items() if v['virtual'] == has_virtual}
        self.list_adapter.data = self.prep_adpter_data(data)

class FocusSlider(FocusBehavior, Slider):
    def keyboard_on_key_down(self, window, keycode, text, modifiers):
        Logger.debug('on_key_down %r' % keycode[1])
        if keycode[1] == 'left':
            if (self.value >= self.min + self.step):
                self.value -= self.step
        elif keycode[1] == 'right':
            if (self.value <= self.max - self.step):
                self.value += self.step
        return True


class RegSliderView(FocusBehavior, BoxLayout):
    """Slider inside of RegDictView"""
    slider_widget = ObjectProperty()
    label_widget = ObjectProperty()
    ti_widget = ObjectProperty()
    list_adapter = ObjectProperty()
    reg_info = ListProperty([])
    value = NumericProperty(0)

    def __init__(self, **kwargs):
        self.list_adapter = kwargs.get('list_adapter', '')
        self.reg_index = kwargs.get('reg_index', 0)
        super(RegSliderView, self).__init__(**kwargs)
        # self.reg = self.list_adapter.data[self.reg_index]

    def redraw(self, reg_index):
        self.reg_index = reg_index
        self.reg = self.list_adapter.data[reg_index]
        if self.reg:
            self.label_widget.text = self.reg.name
            self.ti_widget.text = str(self.reg.value)
            self.slider_widget.value = int(self.reg.value)
            self.slider_widget.max = self.reg.vmax
            self.slider_widget.min = self.reg.vmin
            self.slider_widget.range = (self.reg.vmin, self.reg.vmax)
            self.slider_widget.step = self.reg.step

    def slider_value_changed(self, value):
        try:
            self.value = int(value)
        except ValueError:
            return
        self.reg.value = self.value
        self.list_adapter.data[self.reg_index] = self.reg
        self.reg_info = [self.reg.name, self.reg.value]

    def keyboard_on_key_down(self, window, keycode, text, modifiers):
        Logger.debug('on_key_down', keycode[1])
        if keycode[1] == 'left':
            if (self.value >= self.reg.vmin + self.reg.step):
                self.value -= self.reg.step
        elif keycode[1] == 'right':
            if (self.value <= self.reg.vmax - self.reg.step):
                self.value += self.reg.step
        elif keycode[1] == 'up':
            step = self.reg.step * 100
            if (self.value <= self.reg.vmax - step):
                self.value += step
        elif keycode[1] == 'down':
            step = self.reg.step * 100
            if (self.value >= self.reg.vmin + step):
                self.value -= step
        elif keycode[1] == 'pageup':
            step = (self.reg.vmax - self.reg.vmin) / 20
            if (self.value <= self.reg.vmax - step):
                self.value += step
        elif keycode[1] == 'pagedown':
            step = (self.reg.vmax - self.reg.vmin) / 20
            if (self.value >= self.reg.vmin + step):
                self.value -= step
        return True


class TargetInfoScreen(Screen):
    io_info_view = ObjectProperty()
    dev_info_view = ObjectProperty()

    def __init__(self, **kwargs):
        super(TargetInfoScreen, self).__init__(**kwargs)
        io_info = kwargs.get('io_info', {})
        dev_info = kwargs.get('dev_info', {})
        self.io_info_view.update(io_info)
        self.dev_info_view.update(dev_info)


class SelectableGrid(CompoundSelectionBehavior, GridLayout):
    selected = ObjectProperty()

    def __init__(self, **kwargs):
        self.options = kwargs.get('options', ['None'])
        selects = kwargs.get('selects', [])
        self.multiselect = kwargs.get('multiselect', True)
        group_name = kwargs.get('group', 'group')
        super(SelectableGrid, self).__init__(**kwargs)
        for idx, option in enumerate(self.options):
            state = 'down' if option in selects else 'normal'
            if self.multiselect:
                c = ToggleButton(text=option, state=state)
            else:
                c = ToggleButton(text=option, state=state, group=group_name)
            if option in selects:
                self.select_node(c)
            c.bind(on_touch_down=self.do_touch)
            self.add_widget(c)

    def on_selected_nodes(self, grid, nodes):
        if nodes:
            if self.multiselect:
                self.selected = [x.text for x in nodes]
            else:
                self.selected = nodes[0].text
            # Logger.info("Selected options: %s" % str(self.selected))
        else:
            self.selected = ''

    def do_touch(self, instance, touch):
        if instance.collide_point(*touch.pos):
            if (instance in self.selected_nodes):
                self.deselect_node(instance)
            else:
                self.select_node(instance)


class MasterView(FloatLayout):
    fps = NumericProperty(0)
    trace_len = NumericProperty(0)
    time_step_iq = NumericProperty(0)
    sm = ObjectProperty()
    plot_avg_en = BooleanProperty(False)

    phys_reg_view = ObjectProperty()
    reg_view = ObjectProperty()
    client_view = ObjectProperty()
    traces_view = ObjectProperty()
    slider_xscale = ObjectProperty()
    plt_cfg_view = ObjectProperty()
    chan_sel_view = ObjectProperty()
    chan_sel_raw_view = ObjectProperty()
    plot_sel_view = ObjectProperty()

    init_view = ObjectProperty()
    meas_view = ObjectProperty()
    slow_view = ObjectProperty()
    chassis_view = ObjectProperty()

    def __init__(self, config, **kwargs):
        super(MasterView, self).__init__(**kwargs)
        self.reg_view.slider_view.bind(reg_info=self.cb_reg)
        self.phys_reg_view.slider_view.bind(reg_info=self.cb_reg)
        self.targets = {}
        for i in [k for k in config.sections() if 'target' in k]:
            if config.getboolean(i, 'enabled'):
                io_info = dict(config.items(i))
                if io_info['protocol'] == 'PSPEPS':
                    target = PspepsIO(config=io_info, viewer=self)
                elif io_info['protocol'] == 'FILE':
                    target = FileIO(config=io_info)
                else:
                    Logger.error('No valid target found in config.ini.')
                    reactor.stop()
                    App.get_running_app().stop()

                self.targets[io_info['id']] = target
                self.sm.add_widget(
                    TargetInfoScreen(name=io_info['id'], io_info=io_info))
                target.bind(on_devinfo=self.cb_devinfo)
                target.bind(on_trace=self.cb_trace)
                target.bind(on_slowdata=self.cb_slowdata)
                target.bind(on_slow_raw=self.cb_slow_raw_data)
                target.bind(on_chassis_data=self.cb_chassis_data)
                target.bind(on_chassis_init=self.cb_chassis_init)
                target.bind(on_start=self.cb_start_io)
        self.target = self.targets[self.sm.current]

        self.update_rate = config.getfloat('graph', 'update_rate')
        self.data_fname = self.targets['trace_data_file'].config['fname']
        self.trace_len = int(config.get('graph', 'trace_len'))
        self.measure_log_en = config.getboolean('graph', 'measure_log_en')
        self.measure_log_fname = config.get('graph', 'measure_log_fname')

        self.target.start_io()

    def cavity_switch_toggled(self, active):
        cavity_n = 1 if active else 0
        self.target.app.change_cavity_n(cavity_n)

    def avg_switch_toggled(self, active):
        self.plot_avg_en = active
        length = 16 if active else 1
        self.traces_plot.set_average_length(length)

    def unit_switch_toggled(self, active):
        """
        Calculate new yscale and update unit
        """
        self.has_yunit = active
        self.yscale = self.target.calc_yscale(cal=self.has_yunit)
        self.traces_plot.set_axes_ylim(self.yscale)
        self.traces_plot.set_axes_yunit(self.has_yunit)

    def chassis_view_collapsed(self, val):
        if not val:
            self.t4 = task.LoopingCall(self.target.get_chassis_mon)
            self.t4.start(5.0/self.update_rate)
            Logger.info('Chassis reading task started')
        else:
            self.t4.stop()
            Logger.info('Chassis reading task stoped')

    def slow_view_collapsed(self, val):
        """
        TODO: Synchronize waveform and slow data update
        """
        if not val:
            self.t2 = task.LoopingCall(self.update_slow)
            self.t2.start(1.0/self.update_rate)
            Logger.info('Slow reading task started')
        else:
            self.t2.stop()
            Logger.info('Slow reading task stoped')

    def update_meas(self, data, mode):
        """
        Decode MP measurements acording to adc channel names
        TODO: Move to plotting class
        """
        mdict = {}
        if mode == 'MP':
            mag_mean = np.mean(data[0], axis=1)  # mag_arrays
            phs_mean = np.mean(data[1], axis=1)  # phs_arrays
            for i, (d, ch) in enumerate(zip(data[0], self.chan_keep_names)):
                mdict[ch+' Mag'] = '{:.3f}'.format(mag_mean[i])
                mdict[ch+' Phs'] = '{:.3f}'.format(phs_mean[i])
        elif mode == 'RAW':
            chn_names = [self.chan_sel_raw_view.selected]
            for ch, d in zip(chn_names, data):
                mdict[ch+' RawMax'] = '{:.3f}'.format(d.max())
                mdict[ch+' RawMin'] = '{:.3f}'.format(d.min())
        elif mode in ['FFT', 'FFT_IQ']:
            if mode == 'FFT':
                chn_names = [self.chan_sel_raw_view.selected]
            else:
                chn_names = self.chan_keep_names
            freq, pxxs = data
            for ch, d in zip(chn_names, pxxs):
                mdict[ch+' Peak'] = '{:.3f}'.format(d.max())
                mdict[ch+' Peak Freq'] = '{:>.3e}'.format(freq[d.argmax()])
        self.meas_view.update(mdict)

        if (self.measure_log_en):
            with open(self.measure_log_fname, "a+") as measure_log_file:
                mstring = ',\t'.join(['%s %.3f' % (k, v) for (k, v) in mdict.items()])+'\n'
                measure_log_file.write(mstring)

    def channel_selection_changed(self, instance, chan_names):
        if self.plot_mode in ['MP', 'IQ', 'FFT_IQ']:
            self.chan_keep_names = [i for i in self.chan_names if i in chan_names]
            Logger.info('Channel selection changed to :%s.' % self.chan_keep_names)
            # write registers to target and update UI
            chan_keep_val = self.target.set_chan_keep(self.chan_keep_names)
            self.reg_view_dict[self.target.app.chan_keep_name]['value'] = chan_keep_val

            self.traces_plot.clear_all()
            self.traces_plot.prep_plot(
                self.chan_keep_names, self.trace_len, self.yscale, self.has_yunit)

    def channel_raw_selection_changed(self, instance, chan_name):
        if self.plot_mode in ['RAW', 'FFT']:
            self.target.set_cbuf_mode(chan_name)
            self.traces_plot.set_title(chan_name)
            if self.plot_mode == 'FFT':
                self.traces_plot.clear_average_cache()

    def client_selection_changed(self, instance, client_name):
        print instance, client_name
        if client_name in self.target.clients:
            self.client_name = client_name
            self.client_initialized = False
        else:
            Logger.warning("client name not found")

    def plot_mode_changed(self, instance, mode):
        if self.get_trace_id:
            self.get_trace_id.cancel()
        self.plot_mode = mode
        Logger.info('Plot mode changed to: %s.' % mode)
        self.slider_xscale.disabled = mode not in ['MP', 'IQ', 'FFT_IQ', 'Bode']
        self.chan_sel_view.disabled = mode not in ['MP', 'IQ', 'FFT_IQ']
        self.chan_sel_raw_view.disabled = mode not in ['RAW', 'FFT']
        self.traces_view.clear_widgets()

        if mode in ['RAW', 'FFT']:
            name = self.chan_sel_raw_view.selected
            self.target.set_cbuf_mode(name)
        else:
            self.target.set_cbuf_mode('default')

        if self.traces_plot:
            self.traces_plot.clear_all()
        if mode == 'RAW':
            self.traces_plot = TracesPlotRAW(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_adc,
                yscale=self.yscale,
                has_yunit=self.has_yunit)
        elif mode == 'FFT':
            self.traces_plot = TracesPlotFFT(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_adc,
                yscale=self.yscale,
                has_yunit=self.has_yunit,
                avg_en=self.plot_avg_en)
        elif mode == 'FFT_IQ':
            self.traces_plot = TracesPlotFFTIQ(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_iq,
                yscale=self.yscale,
                has_yunit=self.has_yunit,
                avg_en=self.plot_avg_en)
        elif mode == 'MP':
            self.traces_plot = TracesPlotMP(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_iq,
                yscale=self.yscale,
                has_yunit=self.has_yunit)
        elif mode == 'IQ':
            self.traces_plot = TracesPlotIQ(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_iq,
                yscale=self.yscale,
                has_yunit=self.has_yunit)
        elif mode == 'Bode':
            self.traces_plot = TracesPlotBode(
                chan_keep_names=self.chan_keep_names,
                length=self.trace_len,
                time_step=self.time_step_iq,
                yscale=self.yscale,
                has_yunit=self.has_yunit,
                reg_dict=self.reg_view_dict)

        self.traces_view.add_widget(self.traces_plot)
        self.ask_next_trace()

    def xscale_value_changed(self, instance, val):
        """
        Update time scale for MP, IQ and FFT_IQ plotting
        """
        if self.plot_mode in ['MP', 'IQ', 'FFT_IQ', 'Bode']:
            wave_samp_per_val = int(val)
            (wave_shift_val, self.time_step_iq) = self.target.set_xscale(wave_samp_per_val)

            x_data, y_data = self.traces_plot.prep_xy_data(self.trace_len, self.time_step_iq)
            self.traces_plot.set_axes_xdata(x_data)
            Logger.info('wave_samp_per: %d, wave_shift: %d, ts = %.3f us' % (
                wave_samp_per_val, wave_shift_val, self.time_step_iq * 1e6))
            # write registers to target and update UI
            for regname, regval in zip(
                    [self.target.app.wave_samp_per_name,
                     self.target.app.wave_shift_name],
                    [wave_samp_per_val, wave_shift_val]):
                self.reg_view_dict[regname]['value'] = regval
                self.target.write_reg(regname, regval)

    def update_slow(self):
        self.target.get_slow_data()

    def eb_read_cancel(self, failure):
        failure.trap(CancelledError)
        Logger.warning('Cancelled reading.')

    def eb_read_timeout(self, failure):
        """ mainly for WIFI """
        failure.trap(TimeoutError)
        Logger.warning('Timeout reading. Retry...')
        self.ask_next_trace()

    def ask_next_trace(self):
        """
        Ask for next trace depending on update rate and plot mode
        """
        self.get_trace_id = task.deferLater(
            reactor, 1.0/self.update_rate,
            self.target.get_trace, self.plot_mode, self.trace_len, self.has_yunit)
        # self.get_trace_id.addErrback(self.eb_read_cancel)
        try:
            self.get_trace_id.addTimeout(.3, reactor).addErrback(self.eb_read_timeout)
        except Exception as e:
            Logger.debug('Needs Twisted 16.5.0 for addTimeout(), %r', e)

    def cb_start_io(self, *args):
        self.has_yunit = False

        # plot parameters
        (self.chan_names, self.chan_keep_names, cbuf_mode_list) = self.target.get_chan_info()
        self.yscale = self.target.calc_yscale(cal=self.has_yunit)
        self.plot_mode, plot_mode_options = self.target.get_plot_mode()

        # xscale slider
        self.slider_xscale.disabled = not self.target.get_xscale_enable()
        # Client select panel
        self.client_view.clear_widgets()
        self.client_name = ''
        self.slow_raw_data = []
        self.client_initialized = False
        self.client_sel_view = SelectableGrid(
            cols=3, multiselect=False,
            size_hint_y=0.1,
            options=self.target.client_options,
            selects=[],
            group='client_sel_view')
        self.client_sel_view.bind(selected=self.client_selection_changed)
        self.client_view.add_widget(self.client_sel_view)

        # Plot config panel
        self.plt_cfg_view.clear_widgets()
        self.plt_cfg_view.add_widget(
            Label(text='Plot Mode Selection:', height=20, size_hint_y=None))
        self.plot_sel_view = SelectableGrid(
            cols=3, multiselect=False,
            size_hint_y=0.1,
            options=plot_mode_options,
            selects=[self.plot_mode],
            group='plot_sel_view')
        self.plt_cfg_view.add_widget(self.plot_sel_view)
        self.plot_sel_view.bind(selected=self.plot_mode_changed)

        self.plt_cfg_view.add_widget(
            Label(text='Waveform Channel Selections:', height=20, size_hint_y=None))
        self.chan_sel_view = SelectableGrid(
            cols=4, multiselect=True,
            size_hint_y=0.2,
            options=self.chan_names,
            selects=self.chan_keep_names)
        self.plt_cfg_view.add_widget(self.chan_sel_view)
        self.chan_sel_view.bind(selected=self.channel_selection_changed)

        self.plt_cfg_view.add_widget(
            Label(text='Raw Channel Selection:', height=20, size_hint_y=None))
        self.chan_sel_raw_view = SelectableGrid(
            cols=4, multiselect=False,
            size_hint_y=0.2,
            options=cbuf_mode_list,
            selects=cbuf_mode_list[:1],
            group='chan_sel_raw_view')
        self.plt_cfg_view.add_widget(self.chan_sel_raw_view)
        self.chan_sel_raw_view.bind(selected=self.channel_raw_selection_changed)

        # init plot
        self.get_trace_id = None
        self.traces_plot = None

        if self.target.config['protocol'] == 'PSPEPS':
            self.target.app.start_io()
            if self.target.config['init'] == '1':
                self.target.app.set_init_regs()
        self.time_step_adc = self.target.get_time_step_adc()
        self.reg_view_dict = self.target.get_init_regmap_dict()
        self.reg_view.update(self.reg_view_dict)
        self.phys_reg_view.update(self.reg_view_dict, has_virtual=True)
        self.target.get_target_info()
        if not self.slider_xscale.disabled:
            self.slider_xscale.value = self.target.get_xscale_value()
            (self.slider_xscale.min, self.slider_xscale.max) = self.target.get_xscale_range()
            self.slider_xscale.bind(value=self.xscale_value_changed)

        (wave_shift_val, self.time_step_iq) = self.target.set_xscale(self.slider_xscale.value)
        self.plot_mode_changed('', self.plot_mode)

    def cb_slowdata(self, instance, mdict):
        self.slow_view.update(mdict)

    def cb_slow_raw_data(self, instance, val):
        """
        Update slow_raw_data for clients
        """
        self.slow_raw_data = val

    def init_chassis(self):
        self.target.init_chassis()

    def cb_chassis_init(self, instance, val):
        self.init_view.update(dict(val))

    def cb_chassis_data(self, instance, val):
        self.chassis_view.update(val)

    def update_clients(self, data):
        client_code = None
        if self.client_name:
            if not self.client_initialized:
                client_mtime = self.target.get_client_mtime(self.client_name)
                if client_mtime > self.target.clients[self.client_name][1]:
                    self.target.load_client(self.client_name, client_mtime)
                self.client_generator = self.target.clients[self.client_name][0].run(self.target)
                self.client_generator.send(None)
                self.client_initialized = True
                self.t3 = task.LoopingCall(self.target.get_slow_raw_data)
                self.t3.start(1.0/self.update_rate)
            else:
                try:
                    if self.slow_raw_data != []:
                        client_code = self.client_generator.send((data, self.slow_raw_data))
                except StopIteration:
                    Logger.warning('StopIteration received from Client. Stopping Client!')
                    self.client_name = ''
                    self.client_initialized = False
                    self.t3.stop()
            if client_code == -1:
                Logger.warning('Explicit STOP received from Client. Stopping Client!')
                self.client_name = ''
                self.client_initialized = False
                self.t3.stop()

    def cb_trace(self, instance, data, mode):
        if data is not None:
            self.trace_data = self.traces_plot.update_wfm_with_mode(data, mode)
            self.update_meas(self.trace_data, mode)
            if isinstance(self.trace_data, np.ndarray):
                self.update_clients(data)
        self.ask_next_trace()

    def cb_reg(self, instance, reginfo):
        [reg_name, reg_val] = reginfo
        if self.reg_view_dict[reg_name]['value'] == reg_val:
            print('ignoring setting value, since the value is the same')
            return
        if self.reg_view_dict[reg_name]['virtual']:
            self.target.write_regs(self.reg_view_dict[reg_name]['callback']({reg_name: reg_val}))
        else:
            self.target.write_reg(reg_name, reg_val)
        self.reg_view_dict[reg_name]['value'] = reg_val
        if self.plot_mode == 'Bode':
            self.traces_plot.update_reg(self.reg_view_dict)

    def cb_devinfo(self, instance, devinfo):
        self.sm.current_screen.dev_info_view.update(devinfo)

    def update_fps(self, dt):
        self.fps = Clock.get_fps()

    def capture_trace(self):
        if self.plot_mode in ['MP', 'IQ', 'FFT_IQ']:
            chn_names = self.chan_keep_names
        else:
            chn_names = [self.chan_sel_raw_view.selected]
        try:
            with file(self.data_fname, 'w') as ofile:
                sys_info = {}
                sys_info['plot_mode'] = self.plot_mode
                sys_info['chan_names'] = self.chan_names
                sys_info['chan_keep_names'] = self.chan_keep_names
                sys_info['time_step_iq'] = self.time_step_iq
                sys_info['time_step_adc'] = self.time_step_adc
                sys_info['yscale'] = self.yscale
                # for key in sys_info:
                #     ofile.write('# %s: %s\n'%(key,sys_info[key]))
                ofile.write('# %s\n' % sys_info)
                reg_dict = {}
                for key, val in self.reg_view_dict.items():
                    reg_dict[key] = val['value']
                ofile.write('# %s\n' % reg_dict)
                if self.plot_mode in ['MP', 'IQ', 'RAW']:
                    length = self.trace_len
                    dat = self.trace_data.reshape(-1, length).transpose()
                elif self.plot_mode in ['FFT', 'FFT_IQ']:
                    ofile.write('#')
                    ofile.write('%15s' % 'Frequency')
                    freq, pspec = self.trace_data
                    for name, d in zip(chn_names, pspec):
                        ofile.write('%17s' % name)
                    ofile.write('\n')
                    length = self.trace_len / 2 + 1
                    dat = np.concatenate((np.array([freq]), pspec), axis=0).transpose()
                np.savetxt(ofile, dat, fmt='%16.8f')
                Logger.info('wrote to file %s .' % self.data_fname)
        except (ValueError, TypeError) as err:
            Logger.warning('%r' % err)

    def set_data_source(self, instance, select):
        if self.traces_plot:
            self.traces_plot.clear_all()
        if self.get_trace_id:
            self.get_trace_id.cancel()
        self.target.stop_io()
        self.sm.current = select
        self.target = self.targets[select]
        self.target.start_io()
        self.ask_next_trace()
        Logger.info('Data source changed to: %s.' % self.target.config['id'])


class KivyGuiApp(App):
    def build_config(self, config):
        """
        Default example if no 'kivygui.ini' file exists.
        Same section will be updated from actual kivygui.ini
        """
        config.setdefaults('live_target', {
            'id': 'als_llrf',
            'app_path': '../../../gui/llrf',
            'async': 1,
            'ip': '192.168.1.7',
            'port': 3000,
            'init': 1,
            'protocol': 'PSPEPS',
            'enabled': 1})
        config.setdefaults('file_target', {
            'id': 'trace_data_file',
            'fname': './live.dat',
            'protocol': 'FILE',
            'enabled': 1})
        config.setdefaults('graph', {
            'update_rate': '10.0',
            'trace_len': 1024,
            'measure_log_en': False,
            'measure_log_fname': './measure_log_en.txt'})

    def build_settings(self, settings):
        settings.add_json_panel('IO Config', self.config, 'kivy_cfg/io_cfg.json')
        settings.add_json_panel('Graphics Config', self.config, 'kivy_cfg/graphics_cfg.json')

    def build(self):
        self.master_view = MasterView(self.config)
        Clock.schedule_interval(self.master_view.update_fps, 1)
        return self.master_view

    def on_config_change(self, config, section, key, value):
        """ Overload config change event to re-configure IO if necessary """
        if config is self.config:
            if 'target' in section:
                target = self.master_view.targets[self.config.get(section, 'id')]
                target.config = dict(self.config.items(section))
                target.start_io()

if __name__ == '__main__':
    KivyGuiApp().run()
