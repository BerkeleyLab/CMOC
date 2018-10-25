from __future__ import division
import numpy as np
from scipy import signal
from collections import deque
from kivy.uix.boxlayout import BoxLayout
from kivy.logger import Logger
from kivy.garden.matplotlib.backend_kivyagg import FigureCanvas
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.ticker as ticker
from matplotlib.ticker import MultipleLocator
from matplotlib.backends.backend_pdf import PdfPages
from mpl_toolkits.mplot3d import Axes3D
# http://matplotlib.org/users/dflt_style_changes.html
# mpl.style.use('classic')
mpl.rcParams['lines.linewidth'] = 1.0
# mpl.rcParams['legend.fontsize'] = 10
# mpl.rcParams.update({'font.size': 9})

class TracesPlot(BoxLayout):
    def time_formatter(self, x, pos):
        return '{:.1f}'.format(x * 1e3)

    def freq_formatter(self, x, pos):
        return '{:.3f}'.format(x * 1e-6)

    def log10_formatter(self, y, pos):
        return '{:.1f}'.format(np.log10(y))

    def __init__(self, **kwargs):
        super(TracesPlot, self).__init__(**kwargs)
        self.mode = 'FFT'
        self._cids = []
        self.lines = {}

        self.time_format = ticker.FuncFormatter(self.time_formatter)
        self.freq_format = ticker.FuncFormatter(self.freq_formatter)
        self.log10_format = ticker.FuncFormatter(self.log10_formatter)
        chan_keep_names = kwargs.get('chan_keep_names', [])
        length = kwargs.get('length', 256)
        self.time_step = kwargs.get('time_step', 1)
        self.full_scale = kwargs.get('yscale', 8192)
        self.has_yunit = kwargs.get('has_yunit', False)
        avg_en = kwargs.get('avg_en', False)
        avg_num = 16 if avg_en else 1
        self.avg_fifo = deque(maxlen=avg_num)  # FIFO for averaging
        self.clear_all()
        self.prep_plot(chan_keep_names, length, self.full_scale, self.has_yunit)

    def prep_xy_data(self, time_length, time_step):
        """ Common for IQ mode plots """
        self.time_step = time_step
        x_data = np.arange(0., time_step*time_length, time_step)
        y_data = np.zeros(time_length)
        return x_data, y_data

    def save_pdf_fig(self, pdf_name):
        with PdfPages(pdf_name) as pp:
            pp.savefig()

    def set_average_length(self, length=16):
        del self.avg_fifo
        self.avg_fifo = deque(maxlen=length)

    def clear_average_cache(self):
        self.avg_fifo.clear()

    def clear_all(self):
        self.clear_average_cache()
        self.clear_widgets()
        plt.close('all')
        self.disconnect_evt()

    def set_axes_xdata(self, xdata):
        """ Common for RAW, FFT, FFT_IQ mode """
        self.x_data = xdata
        xmax = max(xdata)
        for line in self.lines:
            line.set_xdata(xdata)
        for ax in self.axes:
            ax.set_xlim(0, xmax)

    def set_axes_xdata_2line(self, xdata):
        """ Common for MP """
        self.x_data = xdata
        xmax = max(xdata)
        for line_grp in self.lines:
            for line in line_grp:
                line.set_xdata(xdata)
        for ax in self.axes:
            ax.set_xlim(0, xmax)

    def set_axes_ylim(self, val=8192, has_yunit=False, yscale=145):
        """ Common for FFT, FFT_IQ mode """
        self.full_scale = val
        major_locator = MultipleLocator(10)
        minor_locator = MultipleLocator(2)
        self.axes[0].yaxis.set_major_locator(major_locator)
        self.axes[0].yaxis.set_minor_locator(minor_locator)
        if not has_yunit:
            self.axes[0].set_ylabel('Power Spectrum [(dBFS)]')
            ymax = 0
        else:
            # in dBm
            ymax = 10*np.log10(val**2/50*1e3)
            self.axes[0].set_ylabel('Power Spectrum [dBm]')
            self.axes[0].set_yscale('linear')
        ymin = ymax - yscale
        Logger.info('Set full scale to: %8.3f, %8.3f' % (ymin, ymax))
        self.axes[0].set_ylim(ymin, ymax)

    def set_axes_yunit(self, has_yunit=False):
        self.has_yunit = has_yunit
        self.set_axes_ylim(self.full_scale, has_yunit)

    def disconnect_evt(self):
        for cid in self._cids:
            self.fig.canvas.mpl_disconnect(cid)

    def post_prep_plot(self, x_data, yscale, has_yunit):
        self.set_axes_xdata(x_data)
        self.set_axes_ylim(yscale)
        self.set_axes_yunit(has_yunit)
        self.fig.canvas.figure.patch.set_facecolor('white')
        self.add_widget(FigureCanvas(self.fig))
        c1 = self.fig.canvas.mpl_connect('figure_enter_event', self.enter_fig)
        c2 = self.fig.canvas.mpl_connect('figure_leave_event', self.leave_fig)
        self._cids.extend([c1, c2])

    def enter_fig(self, event):
        Logger.debug('%s:' % event.name)
        for ax in self.axes:
            ax.set_autoscaley_on(True)
            ax.relim()
            ax.autoscale_view(scalex=False, scaley=True)
        event.canvas.draw()

    def leave_fig(self, event):
        Logger.debug('%s:' % event.name)
        for ax in self.axes:
            ax.set_autoscaley_on(False)
        self.set_axes_ylim(self.full_scale, self.has_yunit)
        event.canvas.draw()

    def update_wfm_with_mode(self, darray, mode):
        if mode == self.mode:
            return self.update_wfm(darray)
        else:
            Logger.warning(
                'Mismatched data mode. data mode = %s, current plot mode= %s' % (mode, self.mode))
            return None

    def calc_spectra(self, varray, den_dds=22):
        """
        TODO: pass den_dds from llrfapp
        Returns RMS linear spectrum in counts
        Use real part for single sided spectrum and correct scalling.
            See signal/spectral.py
        """
        try:
            pxxs = []
            mod = varray.shape[-1] % den_dds
            r = varray if mod == 0 else varray[:, :-mod]
            for x in r.real:
                freq, p_spec = signal.periodogram(
                    x, 1./self.time_step, 'flattop', scaling='spectrum')
                pxxs.append(p_spec)
            return freq, np.array(pxxs)
        except TypeError as err:
            Logger.info('calc_spectra: %r' % err)

    def convert_cnt2_to_dbfs(self, cnt2):
        """
        Convert from cnt^2 to dBFS
        Amplitude of sinusoidal component is sqrt(2)*(rms amplitude)
        """
        c2 = 2*cnt2.clip(min=1e-15)  # avoid divide by 0
        fs_cnt2 = self.full_scale**2
        return 10 * (np.log10(c2) - np.log10(fs_cnt2))

    def convert_vrms2_to_dbm(self, vrms2):
        """
        Convert from V_rms^2 to dBm
        Amplitude of sinusoidal component is sqrt(2)*(rms amplitude)
        """
        v2 = 2*vrms2.clip(min=1e-15)  # avoid divide by 0
        return 10 * np.log10(v2 / 50. * 1e3)

    def update_wfm(self, darray):
        # f, [fft1, fft2, ...] for FFT, FFT_IQ mode
        f, yarrays = self.calc_spectra(darray)
        if self.has_yunit:
            # adc count to vrms2 is done at llrfapp
            yarrays = self.convert_vrms2_to_dbm(yarrays)
        else:
            yarrays = self.convert_cnt2_to_dbfs(yarrays)
        self.avg_fifo.append(np.array(yarrays))
        yarrays_mean = np.mean(self.avg_fifo, axis=0)
        try:
            for line, ydata in zip(self.lines, yarrays_mean):
                line.set_data(f, ydata)
            self.fig.canvas.draw()
            return f, yarrays_mean
        except Exception as err:
            Logger.warning('update_fft_wfm: %r' % err)

class TracesPlotMP(TracesPlot):
    def __init__(self, **kwargs):
        super(TracesPlotMP, self).__init__(**kwargs)
        self.mode = 'MP'

    def set_axes_xdata(self, xdata):
        return self.set_axes_xdata_2line(xdata)

    def set_axes_ylim(self, val=8192, has_yunit=False):
        self.full_scale = val
        Logger.info('Set full scale to: %8.3f' % val)
        self.axes[0].set_ylim(0, val)
        self.axes[1].set_ylim(-np.pi, np.pi)

    def set_axes_yunit(self, has_yunit=False):
        self.has_yunit = has_yunit
        label_unit = 'Count' if not has_yunit else 'V'
        self.axes[0].set_ylabel('Magnitude ['+label_unit+']')
        self.axes[1].set_ylabel('Phase [Radian]')

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length, self.time_step)
        # Magnitude and phase subplots, each containing multiple lines
        self.fig, self.axes = plt.subplots(nrows=2, sharex=True)

        def add_zero_lines(ax):
            return [ax.plot(x_data, y_data, label=chn)[0] for chn in chan_keep_names]
        self.lines = [add_zero_lines(ax) for ax in self.axes]
        # self.axes[0].set_title('Magnitude')
        self.axes[0].legend(loc='upper center', ncol=4,
                            bbox_to_anchor=(0., 1.12, 1., .101),
                            mode="expand",
                            borderaxespad=0.)
        # self.axes[1].set_title('Phase')
        self.axes[1].set_xlabel('Time [ms]')
        self.axes[1].get_xaxis().set_major_formatter(self.time_format)
        for ax in self.axes:
            ax.grid(color='grey', alpha=.5, linestyle='--')

        self.post_prep_plot(x_data, yscale, has_yunit)

    def calc_mp_traces(self, iq_arrays, length):
        try:
            mag_trace = np.abs(iq_arrays)
            phase_trace = np.angle(iq_arrays)  # - self.mon_phs
            return np.array([mag_trace, phase_trace])
        except TypeError as err:
            Logger.info('calc_mp_traces: %r' % err)

    def update_wfm(self, iq_traces):
        mp_traces = self.calc_mp_traces(iq_traces, len(iq_traces[0]))
        # [[m1,m2...],[p1,p2...]]
        try:
            if mp_traces.any():
                for line_grp, data_grp in zip(self.lines, mp_traces):
                    # zip channels
                    for line, ydata in zip(line_grp, data_grp):
                        line.set_ydata(ydata)
                self.fig.canvas.draw()
            return mp_traces
        except Exception as err:
            Logger.warning('update_mp_wfm: %r' % err)

class TracesPlotIQ(TracesPlot):
    def __init__(self, **kwargs):
        super(TracesPlotIQ, self).__init__(**kwargs)
        self.mode = 'IQ'

    def set_axes_xdata(self, xdata):
        self.x_data = xdata
        xmax = max(xdata)
        for line in self.lines:
            line.set_3d_properties(xdata, 'x')
        self.axes3d.set_xlim3d(0, xmax)

    def set_axes_ylim(self, val=8192, has_yunit=False):
        self.full_scale = val
        Logger.info('Set full scale to: %8.3f' % val)
        self.axes3d.set_zlim3d(-val, val)
        self.axes3d.set_ylim3d(-val, val)

    def set_axes_yunit(self, has_yunit=False):
        self.has_yunit = has_yunit
        label_unit = 'Count' if not has_yunit else 'V'
        self.axes3d.set_ylabel('I ' + '['+label_unit+']')
        self.axes3d.set_zlabel('Q ' + '['+label_unit+']')

    def enter_fig(self, event):
        Logger.info('enter_fig event %s:' % event)
        self.axes3d.view_init(0, 0)
        event.canvas.draw()

    def leave_fig(self, event):
        Logger.info('leave_fig event %s:' % event)
        self.axes3d.view_init()
        event.canvas.draw()

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length, self.time_step)
        self.fig = plt.figure('iq')
        self.axes3d = self.fig.gca(projection='3d')
        self.axes3d.set_xlabel('Time [ms]')
        self.axes3d.get_xaxis().set_major_formatter(self.time_format)

        self.lines = [self.axes3d.plot(y_data, y_data, x_data, label=chn)[0] for chn in chan_keep_names]
        self.post_prep_plot(x_data, yscale, has_yunit)
        self.axes3d.mouse_init()
        self._cids.extend(self.axes3d._cids)

    def update_wfm(self, darray):
        # [[i1,i2...],[q1,q2...]]
        darray = np.array([darray.real, darray.imag])
        try:
            for line, idata, qdata in zip(self.lines, darray[0], darray[1]):
                line.set_data(idata, qdata)
                line.set_3d_properties(self.x_data, 'x')
            self.fig.canvas.draw()
            return darray
        except Exception as err:
            Logger.warning('update_iq_wfm: %r' % err)

class TracesPlotRAW(TracesPlot):
    def time_formatter(self, x, pos):
        return '{:.1f}'.format(x * 1e6)

    def __init__(self, **kwargs):
        super(TracesPlotRAW, self).__init__(**kwargs)
        self.mode = 'RAW'

    def set_title(self, title):
        self.axes[0].set_title(title)

    def set_axes_ylim(self, val=8192, has_yunit=False):
        self.full_scale = val
        Logger.info('Set full scale to: %8.3f' % val)
        self.axes[0].set_ylim(-val, val)

    def set_axes_yunit(self, has_yunit=False):
        self.has_yunit = has_yunit
        label_unit = 'Count' if not has_yunit else 'V'
        self.axes[0].set_ylabel('Raw ADC Value ['+label_unit+']')

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length, self.time_step)
        # Single window with sigle or multiple lines
        self.fig, ax = plt.subplots()
        self.axes = [ax]
        ax.set_xlabel('Time [$\mu$s]')
        ax.get_xaxis().set_major_formatter(self.time_format)
        ax.grid(color='grey', alpha=.5, linestyle='--')

        self.lines = [ax.plot(x_data, y_data)[0]]
        self.set_title(chan_keep_names[0])
        self.post_prep_plot(x_data, yscale, has_yunit)

    def update_wfm(self, yarray):
        # [[y]]
        try:
            for line in self.lines:
                line.set_ydata(yarray[0])
            self.fig.canvas.draw()
            return yarray
        except Exception as err:
            Logger.warning('update_raw_wfm: %r' % err)

class TracesPlotFFT(TracesPlot):
    def __init__(self, **kwargs):
        super(TracesPlotFFT, self).__init__(**kwargs)
        self.mode = 'FFT'

    def set_title(self, title):
        self.axes[0].set_title(title)

    def prep_xy_data(self, time_length, time_step):
        self.time_step = time_step
        x_length = int(time_length/2 + 1)
        x_step = (1/time_step)/x_length/2
        x_data = np.arange(0., x_step*x_length, x_step)
        y_data = np.ones(x_length)*.01
        return x_data, y_data

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length, self.time_step)
        self.fig, ax = plt.subplots()
        self.axes = [ax]
        ax.set_xlabel('Frequency [MHz]')
        ax.grid(color='grey', alpha=.5, linestyle='--')

        self.lines = [ax.plot(x_data, y_data)[0]]
        self.set_title(chan_keep_names[0])
        self.post_prep_plot(x_data, yscale, has_yunit)
        ax.get_xaxis().set_major_formatter(self.freq_format)

class TracesPlotFFTIQ(TracesPlotFFT):
    def freq_formatter(self, x, pos):
        return '{:.2f}'.format(x * 1e-3)

    def __init__(self, **kwargs):
        super(TracesPlotFFTIQ, self).__init__(**kwargs)
        self.mode = 'FFT_IQ'

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length, self.time_step)
        self.fig, ax = plt.subplots()
        self.axes = [ax]
        ax.set_xlabel('Frequency [kHz]')
        ax.set_xscale('log')
        ax.grid(color='grey', alpha=.5, linestyle='--')

        self.lines = [ax.plot(x_data, y_data, label=chn)[0] for chn in chan_keep_names]
        ax.legend(
            loc='upper center', ncol=4,
            bbox_to_anchor=(0., 1.01, 1., .101),
            mode="expand",
            borderaxespad=0.)
        self.post_prep_plot(x_data, yscale, has_yunit)
        ax.get_xaxis().set_major_formatter(self.freq_format)

class TracesPlotBode(TracesPlotFFT):
    """
    ALS SRRF LLRF specific, for now
    """
    def __init__(self, **kwargs):
        """ hard coded pulse_len """
        super(TracesPlotBode, self).__init__(**kwargs)
        self.mode = 'Bode'
        reg_dict = kwargs.get('reg_dict', {})
        self.update_reg(reg_dict)

    def update_reg(self, reg_dict):
        self.reg_dict = {}
        for key, val in reg_dict.items():
            self.reg_dict[key] = val['value']

        self.hybrid_mode = self.reg_dict.get('dsp_hybrid_mode', 2)
        self.pulse_len = self.reg_dict.get('dsp_pulse_high_len', 512)
        self.amp_base_setp = self.reg_dict.get('dsp_pigain_setpoint_1', 100)
        self.phs_base_setp = self.reg_dict.get('dsp_pigain_setpoint_3', 0)
        self.amp_delta_enable = self.reg_dict.get('dsp_pigain_delta_enable_1', 0)
        self.phs_delta_enable = self.reg_dict.get('dsp_pigain_delta_enable_3', 0)
        self.amp_delta_setp = self.reg_dict.get('dsp_pigain_setpoint_delta_1', 1000) * self.amp_delta_enable
        self.phs_delta_setp = self.reg_dict.get('dsp_pigain_setpoint_delta_3', 0) * self.phs_delta_enable
        self.amp_intg_gbw = self.reg_dict.get('dsp_pigain_intg_gbw_1', 0)
        self.phs_intg_gbw = self.reg_dict.get('dsp_pigain_intg_gbw_3', 0)
        self.amp_prop_gbw = self.reg_dict.get('dsp_pigain_prop_gbw_1', 0)
        self.phs_prop_gbw = self.reg_dict.get('dsp_pigain_prop_gbw_3', 0)
        self.amp_prop_pole = self.reg_dict.get('dsp_pigain_prop_pole_1', 10000)
        self.phs_prop_pole = self.reg_dict.get('dsp_pigain_prop_pole_3', 10000)
        self.amp_close = self.amp_intg_gbw > 0 or self.amp_prop_gbw > 0
        self.phs_close = self.phs_intg_gbw > 0 or self.phs_prop_gbw > 0
        self.amp_base_setp = self.amp_base_setp if self.amp_close else 1000  # TODO
        self.phs_base_setp = self.phs_base_setp if self.phs_close else 0

    def set_axes_ylim(self, val=8192, has_yunit=False, yscale=100):
        """ Common for FFT, FFT_IQ mode """
        self.full_scale = val
        major_locator = MultipleLocator(10)
        minor_locator = MultipleLocator(2)
        self.axes[0].yaxis.set_major_locator(major_locator)
        self.axes[0].yaxis.set_minor_locator(minor_locator)
        self.axes[0].set_ylabel('Amplitude[(dB)]')
        ymax = 50
        ymin = ymax - yscale
        Logger.info('Set full scale to: %8.3f, %8.3f' % (ymin, ymax))
        self.axes[0].set_ylim(ymin, ymax)
        self.axes[1].set_ylim(-np.pi, np.pi)

    def set_axes_xdata(self, xdata):
        self.x_data = xdata
        xmax = max(xdata)
        for line_grp in self.lines:
            for line in line_grp:
                line.set_xdata(xdata)
        for ax in self.axes:
            ax.set_xlim(xdata[1], xmax)

    def prep_plot(self, chan_keep_names, length, yscale, has_yunit):
        x_data, y_data = self.prep_xy_data(length/4, self.time_step)
        self.fig, self.axes = plt.subplots(nrows=2, sharex='col')
        for ax in self.axes:
            ax.grid(color='grey', alpha=.5, linestyle='--')
        # self.axes[0].set_ylim([-50, 10])
        self.axes[0].set_ylabel('Amplitude [dB]')
        self.axes[1].set_ylabel('Phase [Radian]')
        self.axes[1].set_xscale('log')
        self.axes[1].set_xlabel('Frequency [MHz]')
        # self.axes[1].set_xlim([freq[1], freq[-1]])
        fft_trace_names = ['Open', 'Close', 'Cav Mux']

        def add_zero_lines(ax):
            return [ax.plot(x_data, y_data, label=chn)[0] for chn in
                    fft_trace_names]
        self.lines = [add_zero_lines(ax) for ax in self.axes]
        self.axes[0].legend(bbox_to_anchor=(0., 1.02, 1., .102), loc=4,
                            ncol=3, mode="expand", borderaxespad=0.)

        self.fig.subplots_adjust(hspace=0.05)
        self.post_prep_plot(x_data, yscale, has_yunit)
        self.axes[1].get_xaxis().set_major_formatter(self.freq_format)

    def calc_controller(self, i_gbw, p_gbw, pole, npt=512):
        i_gbw = i_gbw / (1 << 15)
        p_gbw = p_gbw / (1 << 14)
        pole = pole / (1 << 10)
        num = [(i_gbw+p_gbw), (i_gbw+p_gbw)*(pole-1), -pole*p_gbw]
        den = [1, pole-2, -pole+1]
        w, h = signal.freqz(num, den, worN=npt)
        return (w, h)

    def calc_freq_resp(self, traces):
        hybrid_gain = 2.498995  # from simulation
        poff_fdbk = -1.99925      # phase gain from fdbk view
        poff_fdbk = poff_fdbk + .9857  # XXX unknown offset
        poff_0 = -2.32135
        poff_1 = 0.4284

        npt = traces.shape[-1]
        # transform setp from fdbk view to original
        amp_setp = (self.amp_base_setp + self.amp_delta_setp) / hybrid_gain
        amp_base = self.amp_base_setp / hybrid_gain
        phs_setp = 2*np.pi*(self.phs_base_setp + self.phs_delta_setp)/(1 << 18) - poff_fdbk
        phs_base = 2*np.pi*(self.phs_base_setp)/(1 << 18) - poff_fdbk
        base = amp_base * np.exp(1.j * phs_base)
        pulse = amp_setp * np.exp(1.j * phs_setp)
        setp = np.concatenate((np.ones(self.pulse_len) * pulse, np.ones(npt-self.pulse_len) * base))

        cav1 = traces[0] * np.exp(1.j * -poff_0)
        cav2 = traces[1] * np.exp(1.j * -poff_0)
        fwd2 = traces[2] * np.exp(1.j * -poff_1)
        cavm = (np.abs(cav1) + np.abs(cav2))/2
        cavm = cavm * np.exp(1.j * (np.angle(fwd2)))

        close_h = np.divide(np.fft.fft(cavm), np.fft.fft(setp))

        amp_w, amp_freqz = self.calc_controller(
            self.amp_intg_gbw, self.amp_prop_gbw,
            self.amp_prop_pole, npt=close_h.size)

        phs_w, phs_freqz = self.calc_controller(
            self.amp_intg_gbw, self.amp_prop_gbw,
            self.amp_prop_pole, npt=close_h.size)
        open_h = np.divide(close_h, (1-close_h))

        fft_array = np.array([open_h, close_h, amp_freqz, phs_freqz])
        return fft_array

    def calc_bode_traces(self, varray, den_dds=22):
        """
        TODO: hard coded everything
        Must select 3 channels, hybrid mode == 2, cav1 cell, cav2 cell, cav2 fwd
        interleave means pulse_len is 1/4 of waveform length, or 512/2048
        """
        interleave = True
        if varray.shape[0] == 3 and self.hybrid_mode == 2:
            try:
                mod = varray.shape[-1] % den_dds
                varray = varray[:, :-mod]
                fft_array = self.calc_freq_resp(varray)
                # only positive frequencies
                freq = np.fft.rfftfreq(fft_array.shape[-1], d=self.time_step)
                fft_array = fft_array[:, :freq.size]
                if interleave:
                    freq = freq[::4]
                    fft_array = fft_array[:, 1::4]
                    m_trace = 20 * np.log10(np.abs(fft_array))
                    p_trace = np.angle(fft_array)
                else:
                    m_trace = 20 * np.log10(np.abs(fft_array))
                    p_trace = np.angle(fft_array)
                return freq, [m_trace, p_trace]
            except TypeError as err:
                Logger.info('calc_bode_traces: %r' % err)

    def update_wfm(self, iq_array):
        # freq, [fft1, fft2, ...]
        try:
            freq, mp_fft_traces = self.calc_bode_traces(iq_array)
            for line_grp, data_grp in zip(self.lines, mp_fft_traces):
                for line, ydata in zip(line_grp, data_grp):
                    line.set_data(freq, ydata)
            self.fig.canvas.draw()
            return freq, mp_fft_traces
        except Exception as err:
            Logger.warning('update_fft_wfm: %r' % err)
