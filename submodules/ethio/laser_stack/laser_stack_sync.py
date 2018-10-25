#!/usr/bin/python
import os
import sys
import numpy as np
import logging

base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
pspeps_dir = os.path.join(base_dir, '..')
if pspeps_dir not in sys.path:
    sys.path.insert(0, pspeps_dir)
from pspeps_io.utilities import CommonUtilities
from pspeps_io.sync_interface import LocalbusInterface
from pspeps_io.fpga_cores import SipFmc110
from twisted.internet import defer
from laser_stack_io import LaserStackIO
logger = logging.getLogger(__name__)

class LaserStackSync( LocalbusInterface, LaserStackIO, CommonUtilities):
    """ ML605 + FMC110  Application"""
    def __init__(self, **kwargs):
        LocalbusInterface.__init__(self,**kwargs)
        LaserStackIO.__init__(self,**kwargs)
        self.core_fmc110 = SipFmc110(base=0x100000)
        self.regmap.update(self.core_fmc110.regmap)

        #self.control = False


    def read_adc_wfm(self):
        dat = self.read_adc_dpram(self.adc_addr_list, self.adc_read_len)
        result=self.calc_adc_wfm(dat, self.adc_bits)
        return result

    def read_adc_wfm_addr(self,addr_list):
        addrall,indexlist = [],[]
        length = 0
        for addr in addr_list:
            index = (length,length+len(addr))
            indexlist.append(index)
            length = length + len(addr)
            addrall = addrall + addr
        #  print 'addall',addrall
        #  print 'indexlist',indexlist
        dat = self.read_adc_dpram_detail(addrall)
        result = self.calc_adc_wfm_seperate(dat,indexlist,self.adc_bits)
        return result

    def write_dac_wfm0(self):
        # XXX automatic register map decoding
        d0 = self.prep_sin_data(self.dac_len)
        d1 = self.prep_sin_data(self.dac_len)
        d0 = [0]*64+d0[0:64]
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)

    def write_slowdac_wfms(self,input_dicts):
        self.write_slowdac_wfm(input_dicts.next())

    def write_slowdac_wfm(self,input_dict={200:0x42,201:0x321,202:0x67d,203:0x8fa,204:0xb03,205:0xca5,206:0xd0d,207:0xfff}):
        alist = input_dict.keys()
        dlist = input_dict.values()
        self.write_mem_gate(alist,dlist)

    def get_config_rom(self):
        return self.get_lbnl_rom(0x200000)

    def get_fmc110_fcnt(self):
        freq_dict = {
            'CMD_CLK': 0,'ADC0': 1,'DAC0':2,
            'TRIGGER':3,'ADC1':4,'DAC1':5,'TO_FPGA':6}
        d = self.get_fmc_fcnt('FMC110',freq_dict)
        return d

