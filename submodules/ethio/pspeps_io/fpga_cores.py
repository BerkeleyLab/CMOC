#!/usr/bin/python
from registers import RegMapExpand
import os
base_dir = os.path.dirname(os.path.realpath(__file__)) or '.'

class SipFmc110(RegMapExpand):
    """
    4DSP FMC110
    """
    def __init__(self, **kwargs):
        super(SipFmc110, self).__init__(**kwargs)

    def decode_ads5400_temp(self, temp_cnts):
        res = {}
        res['ADS5400_0 Temp'] = '{:.0f} C'.format(temp_cnts[0] - 78)
        res['ADS5400_1 Temp'] = '{:.0f} C'.format(temp_cnts[1] - 78)
        return res

class SipFmc112Fmc150(RegMapExpand):
    """
    4DSP FMC112 + FMC150
    4DSP sip_fmc150:
    FREQ_CNT_SELECT: 0 cmd_clk, 1 adc out sample, 2 dac out (sample/4), 3 trigger,
                     6 DAC ref (sample/2)
    4DSP sip_fmc112:
    FREQ_CNT_SELECT: 0 cmd_clk, 1 dco adc0, 2 dco adc1, 3 dco adc2,
                     5 clk_to_fpga
    """
    def __init__(self, **kwargs):
        super(SipFmc112Fmc150, self).__init__(**kwargs)

    def decode_dac3283_temp(self, temp_cnt, prefix=''):
        res = {}
        res[prefix + 'DAC3283 Temp'] = '{:.3f} C'.format(temp_cnt)
        return res

    def decode_housekeeping(self, dat, prefix=''):
        def g1(x):
            return '{:.3f} V'.format(2.5 * 2.0 * (x & 0xfff) / 0xfff)

        def g2(x):
            return '{:.3f} A'.format(2.5 * 1.0 * (x & 0xfff) / 0xfff)

        def g3(x):
            return '{:.3f} dBm'.format(2.5 * 1.0 * (x & 0xfff) / 0xfff)

        def g4(x):
            return '{:.3f} C'.format(2.6 * 0.61 * (x & 0xfff) - 273.0)
        amc7823 = {}
        amc7823[prefix+'LO (+2dBm)'] = g3(dat[5])
        amc7823[prefix+'Current'] = g2(dat[6])
        amc7823[prefix+'3.3V D'] = g1(dat[7])
        amc7823[prefix+'Temp'] = g4(dat[8])
        return amc7823

    def decode_amc7823(self, dat, prefix=''):
        def g1(x):
            return '{:.3f} V'.format(2.5 * 2.0 * (x & 0xfff) / 0xfff)

        def g2(x):
            return '{:.3f} V'.format(2.5 * 1.0 * (x & 0xfff) / 0xfff)

        def g3(x):
            return '{:.3f} V'.format(2.5 * 5.7 * (x & 0xfff) / 0xfff)

        def g4(x):
            return '{:.3f} C'.format(2.6 * 0.61 * (x & 0xfff) - 273.0)
        amc7823 = {}
        amc7823[prefix + '3.3V A'] = g1(dat[0])
        amc7823[prefix + '3.3V C'] = g1(dat[1])
        amc7823[prefix + '1.8V A'] = g2(dat[2])
        amc7823[prefix + '1.8V D'] = g2(dat[3])
        amc7823[prefix + '12V'] = g3(dat[4])
        amc7823[prefix + '3.3V'] = g1(dat[5])
        amc7823[prefix + 'VADJ'] = g1(dat[6])
        amc7823[prefix + '3.8V'] = g1(dat[7])
        amc7823[prefix + 'Temp'] = g4(dat[8])
        return amc7823

    def decode_adt7411(self, dat, prefix=''):
        def g1(msb, lsb):
            return '{:.3f} C'.format(((msb << 2) + (lsb & 0x3))/4.0)

        def g2(msb, lsb):
            return '{:.3f} V'.format(((msb << 2) + ((lsb >> 2) & 0x3))*3.11*2.197/1e3)

        def g3(msb, lsb):
            return '{:.3f} V'.format(((msb << 2) + (lsb & 0x3))*3.3/1024)

        def g4(msb, lsb):
            return '{:.3f} V'.format(((msb << 2) + ((lsb >> 2) & 0x3))*3.3/1024)

        def g5(msb, lsb):
            return '{:.3f} V'.format((((msb << 2) + ((lsb >> 4) & 0x3))*3.3/1024) * 2)

        def g6(msb, lsb):
            return '{:.3f} V'.format(((msb << 2) + ((lsb >> 6) & 0x3))*3.3/1024 * 5.7 - 4.7*3.3)

        def g7(msb, lsb):
            return '{:.3f} V'.format(((msb << 2) + ((lsb >> 6) & 0x3))*3.3/1024 * 2)
        adt7411 = {}
        print dat
        adt7411[prefix + 'Temp'] = g1(dat[4], dat[0])
        adt7411[prefix + 'VDD(3.3V)'] = g2(dat[3], dat[0])
        adt7411[prefix + '1.8V[2]'] = g3(dat[5], dat[1])
        adt7411[prefix + '1.8V[3]'] = g4(dat[6], dat[1])
        adt7411[prefix + '1.8V[D]'] = g5(dat[7], dat[1])
        adt7411[prefix + '-3.3V'] = g6(dat[8], dat[1])
        adt7411[prefix + '1.8V[1]'] = g3(dat[9], dat[2])
        adt7411[prefix + '1.8V[0]'] = g4(dat[10], dat[2])
        adt7411[prefix + '3.3V[C]'] = g5(dat[11], dat[2])
        adt7411[prefix + '3.3V'] = g7(dat[12], dat[2])
        return adt7411

class SipFmc116Fmc112(SipFmc112Fmc150):
    """
    4DSP FMC116 + FMC112
    4DSP sip_fmc116:
    FREQ_CNT_SELECT: 0 cmd_clk, 1 dco adc0, 2 dco adc1, 3 dco adc2, 4 dco adc3,
                     5 clk_to_fpga
    4DSP sip_fmc112:
    FREQ_CNT_SELECT: 0 cmd_clk, 1 dco adc0, 2 dco adc1, 3 dco adc2,
                     5 clk_to_fpga
    """
    def __init__(self, **kwargs):
        super(SipFmc116Fmc112, self).__init__(**kwargs)
