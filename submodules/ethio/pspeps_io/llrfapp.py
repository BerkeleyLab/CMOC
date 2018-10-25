#!/usr/bin/python
from __future__ import division
from twisted.internet import defer
from interfaces import LocalbusInterface
from utilities import decode_twos_comp
import numpy as np
import logging
logger = logging.getLogger().getChild(__name__)

class LLRFCommonApp(LocalbusInterface):
    """
    Common LLRF application methods shared between projects that have lbnl style
    conveyor belt CIC filter waveform monitoring structure, hooked up with kivy
    GUI interfaces
    """
    def __init__(self, **kwargs):
        super(LLRFCommonApp, self).__init__(**kwargs)
        self.init_common_llrf_settings()
        self.init_llrf_settings()
        self.init_reg, self.init_reg_hide = self.prep_init_regs()

    def init_common_llrf_settings(self):
        """ Common constants """
        self.CORDIC_GAIN = 1.64676
        self.cbuf_retry_delay = 0.008
        self._max_retry = 4

    def init_llrf_settings(self):
        self.buf_dw = 16
        self.cbuf_width = 13
        self.shift_base = 1  # ccfilt.v
        self.adc_bits = 14
        self.app_reg_prefix = ''
        self.FIR_GAIN = 1.0
        self.num_dds = 2
        self.den_dds = 11
        self.wave_samp_per = 2
        self.clk_freq = 500.e6*11/12/2

        self._cbuf_flip_name = 'LLRF_SHELL_DSP_CBUF_FLIP'
        self._slow_name = 'LLRF_SHELL_DSP_SLOW'
        self._cbuf_name = 'LLRF_SHELL_DSP_CBUF'
        self._cbuf_mode_channel_name = 'LLRF_SHELL_DSP_CBUF_MODE'
        self.config_rom_name = 'LLRF_SHELL_DSP_CONFIG_ROM'

        self.wave_samp_per_name = 'dsp_wave_samp_per'
        self.wave_shift_name = 'dsp_wave_shift'
        self.chan_keep_name = 'dsp_chan_keep'

        self.chn_names = ['Ch'+str(i) for i in xrange(8)]
        self.chn_sel = self.chn_names[:1]

        self.mon_gains = {}
        self.fir_gains = {}

        self.cbuf_mode_list = ['default'] + self.chn_names + ['Drive']
        self.slow_buf_len = 2*len(self.chn_names) + 2
        self.adc_freq = self.clk_freq
        # default cbuf mode is interleaved IQ in baseband
        self._cbuf_mode_name = self.cbuf_mode_list[0]
        self.cal_count2volt = {}
        self.cic_period = self.den_dds

        # channel FIR configurations may varry
        for ch in self.chn_names:
            self.fir_gains[ch] = self.FIR_GAIN
            self.mon_gains[ch] = self.FIR_GAIN
        self.lo_gain = int((1 << 15) / self.CORDIC_GAIN)
        self.lo_dds_gain = self.lo_gain * 4 * self.CORDIC_GAIN / (1 << 17)
        self.time_step_adc = 1./self.adc_freq
        self.time_step_mon = self.wave_samp_per / self.clk_freq
        self.trace_len = (1 << 11)/len(self.chn_sel)
        self.gui_prefix_substitutions = {}

    def get_view_name(self, name):
        for k, v in self.gui_prefix_substitutions.iteritems():
            name = name.replace(k, v)
        return name

    def prep_init_regs(self, prefix='dsp_'):
        (wave_shift, time_step) = self.calc_xscale()
        chan_keep_reg = self.calc_chan_keep_reg(self.chn_sel)
        init_reg = {}
        init_reg[prefix + 'wave_samp_per'] = self.wave_samp_per
        init_reg[prefix + 'wave_shift'] = wave_shift
        init_reg[prefix + 'chan_keep'] = chan_keep_reg

        phase_step, modulo = self.calc_dds(self.num_dds, self.den_dds)
        init_reg_hide = {}
        init_reg_hide[prefix + 'phase_step'] = phase_step
        init_reg_hide[prefix + 'modulo'] = modulo
        return init_reg, init_reg_hide

    def set_init_regs(self):
        """ write initial regs"""
        init_reg_all = self.init_reg
        init_reg_all.update(self.init_reg_hide)
        self.write_app_reg_dict(init_reg_all)
        self.set_cbuf_mode('IQ')

    def get_chan_info(self):
        """
        Return available monitor channel names, with selected names
        """
        return (self.chn_names, self.chn_sel, self.cbuf_mode_list[1:])

    def calc_chan_keep_reg(self, chn_sel):
        # convert from selected channel list to chan_keep register for IQ masking
        self.chn_sel = chn_sel
        chan_mask_array = [c in chn_sel for c in self.chn_names]
        # expand to IQ pairs
        chan_mask_iq = ''.join('1' if x else '0' for x in np.array(
            [[i, i] for i in chan_mask_array]).flatten())
        chan_keep_reg = int(chan_mask_iq, 2)
        return chan_keep_reg

    def set_chan_keep_reg(self, chan_sel):
        chan_keep_reg = self.calc_chan_keep_reg(chan_sel)
        logger.info('Setting register chan_keep to value: %#x' % chan_keep_reg)
        self.write_app_reg_dict({self.chan_keep_name: chan_keep_reg})

    def get_timestep_adc(self):
        return self.time_step_adc

    def get_app_reg_by_name(self, reg_name):
        """ Get reg by name prefixed with self.app_reg_prefix """
        return self.get_reg_by_name(self.app_reg_prefix + reg_name)

    def get_init_regmap_dict(self):
        """ Return sorted regmap dict for higher level (GUI) use """
        regs = map(self.get_app_reg_by_name, self.init_reg)
        # XXX GUI and regmap are seperated here:
        reg_view_dict = {}
        for reg in regs:
            reg_dict = {}
            # remove app prefix for comfort display
            short_regname = reg.name[len(self.app_reg_prefix):]
            reg_dict['name'] = short_regname
            reg_dict['virtual'] = False
            reg_dict['value'] = reg.value
            reg_dict['vmin'] = reg.min
            reg_dict['vmax'] = reg.max
            reg_dict['unit'] = ''
            reg_view_dict[short_regname] = reg_dict
        return reg_view_dict

    def write_app_reg_dict(self, reg_dict):
        """ Append dsp reigister prefix to reg_dict """
        reg_app_dict = {}
        for key in reg_dict:
            reg_app_dict[self.app_reg_prefix + key] = reg_dict[key]
        del reg_dict
        self.write_reg_dict(reg_app_dict)

    @defer.inlineCallbacks
    def get_waveform(self, iq_mode=True, length=256, cal=False):
        """
        Parameters:
            iq_mode:return data format is iq_arrays
                    return data format is [raw_data]
            length: return trace length per channel
            cal:    False to use raw data in 'Count' unit
                    True  to use physical units
        """
        try:
            if iq_mode:
                n_chan_keep = len(self.chn_sel)
                # multiply by 2 to cover I and Q
                arrays_raw = yield self.read_cbuf(length=length*n_chan_keep*2, dw=self.buf_dw)
                if arrays_raw is not None:
                    res_arrays = self.calc_iq_arrays(arrays_raw, length)
                    if cal:
                        res_arrays = self.convert_unit(self.chn_sel, res_arrays)
                else:
                    logger.warn('Got empty data from cbuf, perhaps 0 channels are selected')
                    res_arrays = None
            else:
                res_arrays = yield self.read_cbuf_raw_wfm(length)
                if res_arrays is not None:
                    if cal:
                        res_arrays = self.convert_unit([self._cbuf_mode_name], res_arrays)
                else:
                    raise TypeError('read_cbuf returned None, data dropped')
            defer.returnValue(res_arrays)
        except (TypeError, AttributeError) as err:
            logger.info('get_waveform: %r' % err)

    @defer.inlineCallbacks
    def read_cbuf_raw_wfm(self, length):
        arrays_raw = yield self.read_cbuf(length=length, dw=16)
        arrays = np.array([arrays_raw/4])  # 16 bits to 14 bits
        defer.returnValue(arrays)

    def convert_unit(self, chn_names, arrays):
        """
        Use calibration polynomials to convert raw amplitude to physical units.
        Polynomial factors should be from measurements
        and provided by application class.
        MP, IQ, RAW mode amplitude unit:  Volt
        FFT, FFT_IQ mode amplitude unit:  Volt^2
        """
        try:
            p_array = [self.cal_count2volt[ch] for ch in chn_names]
            return np.array([p*array for (p, array) in zip(p_array, arrays)])
        except KeyError as err:
            logger.warning('convert_unit: %r' % err)

    def calc_dds(self, num_dds, den_dds):
        m, modulo = divmod(4096, den_dds)
        r = (1 << 20) * num_dds
        phase_step_h = int(r/den_dds)
        phase_step_l = int(r % den_dds * m)
        phase_step = (phase_step_h << 12) + phase_step_l
        return phase_step, modulo

    def calc_iq_arrays(self, varray, length):
        try:
            n_chan_data = int(len(varray) / length)
            if n_chan_data == 2*len(self.chn_sel):
                darray = varray.reshape(-1, n_chan_data).T
                iq_arrays = np.array([
                    (darray[ix*2] + 1j * darray[ix*2+1]) / self.mon_gains[ch]
                    for ix, ch in enumerate(self.chn_sel)])
                return iq_arrays
            else:
                raise TypeError('Different length of data dropped.')
        except TypeError as err:
            logger.info('calc_iq_arrays %r' % err)

    def get_cbuf_mode(self):
        return self._cbuf_mode_name

    def set_cbuf_mode(self, chan_str='default'):
        """ 0: iq interleaved waveform, 'default'
            1: adc 0, 2: adc2, ..., 'channel name'
        """
        self._cbuf_mode_name = chan_str
        if self._cbuf_mode_name in self.cbuf_mode_list:
            val = self.cbuf_mode_list.index(chan_str)
            self.write_reg_dict({self._cbuf_mode_channel_name: val})
            return True
        else:
            return False

    def calc_yscale(self, cal=False):
        """
        Calculate and return data limit
            cal:    False to use raw data in 'Count' unit
                    True  to use calibration data in physical unit
                    return calibrated full scale count using mean of coeffs
        """
        fs_signed_count = 1 << (self.adc_bits - 1)
        if not cal:
            return fs_signed_count
        else:
            return np.max(self.cal_count2volt.values()) * fs_signed_count

    def set_xscale(self, wave_samp_per):
        self.wave_samp_per = wave_samp_per
        (wave_shift, time_step) = self.calc_xscale()
        self.write_app_reg_dict({
            self.wave_samp_per_name: self.wave_samp_per,
            self.wave_shift_name: wave_shift})
        return (wave_shift, time_step)

    def get_wave_samp_per(self):
        return self.wave_samp_per

    def get_wave_samp_per_range(self):
        reg = self.get_app_reg_by_name(self.wave_samp_per_name)
        return (reg.min, reg.max)

    def calc_xscale(self):
        """
        Calculate monitor channel gain by combining LO, CIC and data
        truncations. Called after time scale change.
        Returns register for ccfilter.v, total gain and xscale
        """
        shift_min = 2 * np.log2(
            self.wave_samp_per * self.cic_period * np.sqrt(
                self.lo_dds_gain * max(self.FIR_GAIN, 1.)) /
            float(1 << int((16-self.adc_bits)/2)))
        wave_shift = int(np.ceil((np.ceil(shift_min) - self.shift_base) / 2)) - 1
        self.calc_mon_gain(self.wave_samp_per, wave_shift)
        self.time_step_mon = self.wave_samp_per * self.cic_period / self.clk_freq
        return (wave_shift, self.time_step_mon)

    def calc_mon_gain(self, wave_samp_per, wave_shift):
        """ Calculate monitoring gain """
        cic_gain = (
            ((wave_samp_per * self.cic_period)**2) /
            float(1 << int(2*wave_shift + self.shift_base - 1)))
        mon_gain = (self.lo_dds_gain * cic_gain) / (1 << 4)
        for ch in self.chn_names:
            self.mon_gains[ch] = mon_gain * self.fir_gains[ch]
        return mon_gain

    @defer.inlineCallbacks
    def read_slow_buf(self, retry=0, decode=True):
        """
        Read slow buffer, 16 bits per address
        """
        (slow_rdy, cbuf_rdy) = yield self.read_buf_rdy()
        if slow_rdy:
            dat = yield self.read_lb_buf(
                self.get_reg_addr(self._slow_name),
                self.slow_buf_len*2).addErrback(self.eb_print)
            res = self.decode_slow_data(dat) if decode else dat
        else:
            if retry <= self._max_retry:
                res = yield self.call_later(
                    self.read_slow_buf,
                    self.cbuf_retry_delay, retry=retry+1)
            else:
                raise ValueError('read_slow_buf exceeds max retries: %d' % retry)
        defer.returnValue(res)

    def decode_slow_data(self, dat):
        """
        Reload this method for different flavor of slow data content.
        assemble bytes of raw data to words
        default content: {cirle_count, circle_stat, chn1_min, ch1_max, ...}
        Returns dictionary of name:value pairs
        """
        slow_raw_words = np.array([
            dat[2*ix]*256 + dat[2*ix+1] for ix in xrange(self.slow_buf_len)])
        slow_val = decode_twos_comp(slow_raw_words)
        mdict = {}
        mdict['cbuf count'] = dat[0]*256 + dat[1]
        mdict['cbuf stat'] = slow_val[1]
        for i, ch in enumerate(self.chn_names):
            mdict[ch+' Min'] = slow_val[2*i + 2]
            mdict[ch+' Max'] = slow_val[2*i+1 + 2]
        return mdict

    def flip_circle_buffer(self):
        """
        Convenience for override capability
        """
        return self.write_reg_dict({self._cbuf_flip_name: 1})

    @defer.inlineCallbacks
    def read_cbuf(self, length=256, dw=16, retry=0):
        """
        Recursively retry reading circular buffer and return the result if
        cbuf_rdy bit is set, otherwise raise exceptions to be handled in errback
        TODO: update slow data together with waveform
        """
        (slow_rdy, cbuf_rdy) = yield self.read_buf_rdy()
        if cbuf_rdy:
            logger.debug('read_cbuf, retry: %d' % retry)
            data_val = yield self.read_lb_buf(
                self.get_reg_addr(self._cbuf_name), length).addErrback(self.eb_print)
            if len(data_val) != 0:
                if hasattr(self, 'cavity_n') and self.cavity_n == 1:
                    data_val = [x >> 16 for x in data_val]
                data_val = np.bitwise_and(data_val, (2**dw) - 1)
                wfm_val = decode_twos_comp(data_val, bits=dw)
            else:
                wfm_val = None
            # Reading done. Flip buffer for next data
            self.flip_circle_buffer()
            if slow_rdy:
                dat = yield self.read_lb_buf(
                    self.get_reg_addr(self._slow_name), self.slow_buf_len*2).addErrback(self.eb_print)
                circle_count = dat[0]*256 + dat[1]
                logger.debug('Circle buffer Count: {:d}'.format(circle_count))
        else:
            if retry <= self._max_retry:
                delay = self.get_cbuf_delay()
                logger.debug('get_cbuf_delay: {:.5f}'.format(delay))
                wfm_val = yield self.call_later(self.read_cbuf, delay, length=length, dw=dw, retry=retry+1)
            else:
                raise ValueError('read_cbuf exceeds max retries: %d' % retry)
        defer.returnValue(wfm_val)

    def get_cbuf_delay(self):
        return max(self.time_step_mon * (1 << self.cbuf_width), self.cbuf_retry_delay) / 8

    @defer.inlineCallbacks
    def read_buf_rdy(self):
        d = yield self.read_lb_reg(self.get_reg_addr(self.config_rom_name))
        cbuf_rdy = d >> 8 & 1
        slow_rdy = d >> 9 & 1
        defer.returnValue((slow_rdy, cbuf_rdy))

    def read_chassis_mon(self):
        """ Place holders for chassis monitoring"""
        mon_dict = {}
        return mon_dict

    def init_chassis(self):
        """ Place holders for chassis level init """
        return []
