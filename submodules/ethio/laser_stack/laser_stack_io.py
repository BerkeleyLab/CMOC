#!/usr/bin/python
import abc
import numpy as np
import os
import sys

base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
pspeps_dir = os.path.join(base_dir, '..')
if pspeps_dir not in sys.path:
    sys.path.insert(0, pspeps_dir)

from pspeps_io.utilities import decode_2s_comp, encode_2s_comp

class LaserStackIO(object):
    """ ML605 + FMC110  Application"""
    def __init__(self, **kwargs):
        super(LaserStackIO, self).__init__(**kwargs)
        self.adc_addr_list = [0x51000+200,0x61000+200]
        self.adc_n_chan = len(self.adc_addr_list)
        self.adc_bits = 12
        self.adc_len = 1024  # 128
        self.adc_read_len = 128
        self.dac_len = 128
        self.adc_freqs = [400.]*self.adc_n_chan
        self.am_pm_delay = 6
        self.Kp_bottom = 0.01 if False else 0.07
        self.bottom_limit = 500   # 3000 300
        #  self.start_location=26 # 0 comes from initialization
        self.stack_cycle = 1

        self.cav_addr = [201,203,204,202]
        self.bias_addr = 200
        self.Kp_bottom = 0.01 if False else 0.07
        self.bottom_limit = 100
        self.start_location_list = [30,34]
        self.stack_cycle = 1

        self.switch_addr1 = 0x701
        self.switch_addr0 = 0x700

        self.switch_val1 = [0,0,1,1]
        self.switch_val0 = [0,1,0,1]

        self.bias_direction = False
    
    @abc.abstractmethod 
    def read_adc_wfm(self):
        """ read adc data from addr_list with length """
        return 

    @abc.abstractmethod 
    def read_adc_wfm_addr(self,addr_list):
        """ read adc wfm data based on addr_list"""
        return
    @abc.abstractmethod
    def write_slowdac_wfms(self,input_dicts):
        pass
    
    @abc.abstractmethod
    def write_slowdac_wfm(self,input_dict):
        pass

    def get_adc_dpram_address(self,start_addr,interval,length):
        return range(start_addr,start_addr+interval*length,interval)

    def get_adc_bg_address(self,channel,length):
        if length > 20:
            raise ValueError('Background data length cannot exceed 20')
        return self.get_adc_dpram_address(
            self.adc_addr_list[channel]+self.start_location_list[channel]-20,
            1,length)

    def get_adc_selected_address(self,channel,offset,interval,length):
        return self.get_adc_dpram_address(
            self.adc_addr_list[channel]+self.start_location_list[channel]+offset,
            interval,length)

    def calc_adc_wfm(self, adc_in, bits=12):
        lines = [map(decode_2s_comp,chan_dat,[bits]*len(chan_dat)) for chan_dat in adc_in]
        return np.array(lines)

    def calc_adc_wfm_seperate(self, adc_in, index_in, bits=16):
        lines = map(decode_2s_comp,adc_in,[bits]*len(adc_in))
        #  print 'adc_in',adc_in
        data = [lines[index[0]:index[1]] for index in index_in]
        #  print 'data_out',data
        return np.array(data)


    def prep_arb_data(self, samples, n, bits=16):
        dat = [15000,-15000]*1+[0]*(96+30)
        # h = self.read_data('Convolution_h.txt')
        # h = array(h)*10
        # h = list(h)i
        # dat = np.convolve(h,dat)
        # a = [1.0,-0.995]
        # b = [0.99741488*1.2,-0.99741488*1.2]
        # dat = signal.lfilter(a,b,dat)
        return map(encode_2s_comp, dat)

    def prep_zeros_data(self,samples):
        dat = [0]*samples
        return map(encode_2s_comp, dat)

    def prep_pulse_data(self,samples):
        dat = [10000]+[0]*25+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_step_data1(self,samples):
        dat = [4000,-4000]*6+[0]*14+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_step_data2(self,samples):
        dat = [10000]*13+[0]*13+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_pm_data13(self, samples, n, bits=16):
        #  dat_input = n*step
        #  dat = [0,dat_input,-dat_input]*8+[0]*(96+8)
        #  dat =[0,9874,-8305]*5+[0]*(96+17)
        #  input origin
        #  dat=[0]*n+[379,7272,15492,-8183,16155,9103,7745,2050,-11538,5526,-11335,-6570,108]+[0]*(115-n)
        #  input stable
        #  dat=[0]*n+[493,7426,15952,-8425,16633,9373,7975,2111,-11881,5689,-11672,-6765,68]+[0]*(115-n)
        #  input middle
        #  dat=[0]*n+[512,7711,16566,-8749,17274,9734,8283,2192,-12338,5909,-12121,-7025,68]+[0]*(115-n)
        #  input high
        dat = [0]*n+[545,8211,17649,-9316,18393,10364,8819,2334,-13137,6291,-12906,-7480,100]+[0]*(115-n)
        return map(encode_2s_comp, dat)

    def prep_am_data13(self, samples, bits=16):
        #  dat = [5149,-6100,5452,3097,-8387,9991,-9873,9998,-9970,10017,-10001,9999,-10000]+[0]*13+[5000,-5000]*20+[0]*67
        dat = [5273,-6314,5601,-3123,9005,-11154,10985,-11165,11123,-11192,11168,-11165,11166]+[0]*13+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_am_one_cav(self,samples):
        dat = [5113,-3574,5113,-7418,11166]+[0]*21+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_pm_one_cav(self, samples, n):
        dat = [0]*(n)+[0,0,0,0,-13916]+[0]*(115+8-n)
        return map(encode_2s_comp, dat)

    def prep_pm_one_cav_new(self, samples, n, off_percent=0):
        phase_data=[118.83,7277.82,118.829]
        off_factor=1+off_percent/100.
        dat_key=[int(data*off_factor) for data in phase_data]
        dat = [0]*(n)+dat_key+[0]*(115+8-n)
        return map(encode_2s_comp, dat)

    def prep_am_one_cav_new(self,samples):
        dat = [13206,-11266,10896]+[0]*23+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_pm_two_cav_new(self, samples, n, off_percent=0):
        phase_data=[15032.17,10185.73,6520.38,-10962.23,118.83]
        off_factor=1+off_percent/100.
        dat_key=[int(data*off_factor) for data in phase_data]
        dat = [0]*(n)+dat_key+[0]*(113+8-n)
        return map(encode_2s_comp, dat)

    def prep_am_two_cav_new(self,samples):
        dat = [13206,-11266,10896,-11986,10886]+[0]*21+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

    def prep_pm_four_cav_new(self, samples, n, off_percent=0):
        phase_data = [14804.718, 3585.87,-9232.3,12248.92,
                14220.42, 7804.726, 15979.17 -5500.029, 118.829]
        off_factor = 1+off_percent/100.
        dat_key = [int(data*off_factor) for data in phase_data]
        dat = [0]*(n)+dat_key+[0]*(109+8-n)
        return map(encode_2s_comp, dat)

    def prep_am_four_cav_new(self,samples):
        dat = [13206,-11266,10896,-11986,10986,-11900,
                11876,-11856,11656]+[0]*17+[2000,-2000]*20+[0]*67
        return map(encode_2s_comp, dat)

