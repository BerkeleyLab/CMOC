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
from pspeps_io.interfaces import WormholeInterface, LocalbusInterface
from pspeps_io.fpga_cores import SipFmc110
from pspeps_io.utilities import print_reg
from twisted.internet import defer
from laser_stack_io import LaserStackIO
logger = logging.getLogger(__name__)

class LaserStackApp(LaserStackIO, WormholeInterface, CommonUtilities):
    """ ML605 + FMC110  Application"""
    def __init__(self, **kwargs):
        super(LaserStackApp, self).__init__(**kwargs)
        print self.dac_len
        json_path = os.path.join(pspeps_dir, 'pspeps_io/board_support.json')
        self.core_fmc110 = SipFmc110(base=0x100000, path=json_path, core_name='fmc110')
        self.regmap.update(self.core_fmc110.regmap)
        self.reg_addr_dict.update(self.core_fmc110.reg_addr_dict)

    @defer.inlineCallbacks
    def init(self):
        reg_dict = {'FMC110_CPLD_CTRL_REG0': 0x10}
        self.write_reg_dict(reg_dict)
        reg_dict = {
            'FMC110_AD9517_CTRL_REG0x199': 0x33,
            'FMC110_AD9517_CTRL_REG0x230': 0x1,
            'FMC110_AD9517_CTRL_REG0x230': 0x0,
            'FMC110_AD9517_CTRL_REG0x232': 0x1,}
        self.write_spi_dict(reg_dict)
        reg_dict = {
            'FMC110_ADS5400_CTRL0_REG0x5': 0xb8,  # enable sync mode
            'FMC110_ADS5400_CTRL1_REG0x5': 0xb8,}
        self.write_spi_dict(reg_dict)
        yield self.adc_init()
        self.dac_init()
        self.write_dac_wfm1()
        alist = [100,101,102]
        dlist = [3,self.adc_len, self.dac_len]
        self.write_mem_gate(alist,dlist)
        alist = [0]
        dlist = [1]
        self.write_mem_gate(alist,dlist)

    @defer.inlineCallbacks
    def adc_init(self):
        reg_dict = {
            'FMC110_ADS5400_CTRL0_REG0x6': 0xc4,  # enable test pattern
            'FMC110_ADS5400_CTRL1_REG0x6': 0xc4,}
        self.write_spi_dict(reg_dict)
        reg_dict = {
            'FMC110_ADS5400_PHY0_COMMAND': 0x3,  # reset clock buffer and idelay
            'FMC110_ADS5400_PHY1_COMMAND': 0x3,}
        self.write_spi_dict(reg_dict)
        reg_dict = {
            'FMC110_ADS5400_PHY0_COMMAND': 0x4,  # reset ISERDESs, when the clocks are stable
            'FMC110_ADS5400_PHY1_COMMAND': 0x4,}
        self.write_spi_dict(reg_dict)
        reg_dict = {
            'FMC110_ADS5400_PHY0_COMMAND': 0x8,    # start_align, io_reset, clk_reset, delay_reset
            'FMC110_ADS5400_PHY1_COMMAND': 0x8,    # start_align, io_reset, clk_reset, delay_reset
            'FMC110_ADS5400_PHY0_CONTROL': 0x10,   # phy pattern check clear
            'FMC110_ADS5400_PHY1_CONTROL': 0x10,}  # phy pattern check clear
        self.write_spi_dict(reg_dict)

        regs_want = []
        regs_want.append('FMC110_ADS5400_PHY0_COMMAND')
        regs_want.append('FMC110_ADS5400_PHY0_CONTROL')
        regs_want.append('FMC110_ADS5400_PHY1_COMMAND')
        regs_want.append('FMC110_ADS5400_PHY1_CONTROL')
        res = yield self.read_cmd_regs(regs_want)
        try:
            if (res[0] != 0x1fff0001):
                raise ValueError('ADCPHY0 align error: '+hex(res[0]))
            if (res[1] != 0x0):
                raise ValueError('ADCPHY0 pattern check error: '+hex(res[1]))
            if (res[2] != 0x1fff0001):
                raise ValueError('ADCPHY1 align error: '+hex(res[2]))
            if (res[3] != 0x0):
                raise ValueError('ADCPHY0 pattern check error: '+hex(res[3]))
        except ValueError as err:
            logger.error("ads5400_init : %r" % err)
#            raise
        reg_dict = {
            'FMC110_ADS5400_PHY0_COMMAND': 0x0,   # disable start_align
            'FMC110_ADS5400_PHY1_COMMAND': 0x0,   # disable start_align
            'FMC110_ADS5400_CTRL0_REG0x6': 0x4,   # disable traning pattern
            'FMC110_ADS5400_CTRL1_REG0x6': 0x4,}  # disable traning pattern
        self.write_spi_dict(reg_dict)
        regs_want.append('FMC110_ADS5400_PHY0_TAP_VAL0')
        regs_want.append('FMC110_ADS5400_PHY0_TAP_VAL1')
        regs_want.append('FMC110_ADS5400_PHY0_TAP_VAL2')
        regs_want.append('FMC110_ADS5400_PHY0_TAP_VAL3')
        regs_want.append('FMC110_ADS5400_PHY1_TAP_VAL0')
        regs_want.append('FMC110_ADS5400_PHY1_TAP_VAL1')
        regs_want.append('FMC110_ADS5400_PHY1_TAP_VAL2')
        regs_want.append('FMC110_ADS5400_PHY1_TAP_VAL3')
        res = yield self.read_cmd_regs(regs_want)
        for reg in zip(regs_want, map(hex, res)):
            logger.info(reg)

    def dac_init(self):
        reg_dict = {
            'FMC110_DAC5681Z_PHY0_CONTROL': 0x4,    # drive TXENABLE high
            'FMC110_DAC5681Z_PHY1_CONTROL': 0x4,}   # drive TXENABLE high
        self.write_spi_dict(reg_dict)

    def align_adc(self, adc_in, bits=16):
        clk4_div = 8  # ad9517 0x199
        adc_out = adc_in
        for i, dat in enumerate(adc_in):
            dat_sync = map(np.bitwise_and, dat[0:clk4_div], [0x1000]*clk4_div)
            first_index = list(dat_sync).index(0x1000)
            logger.debug("adc chan: %d, align_index: %d"%(i, first_index))
            print i, first_index
            adc_out[i] = np.append(adc_in[i][first_index:], [0]*first_index)
        return adc_out

    def print_adc_len(self, dat, bits=16):
        for chan_dat in dat:
            print 'length:',len(chan_dat)
            #  print map(decode_2s_comp,chan_dat,[bits]*len(chan_dat))
        return dat

    def read_adc_wfm(self):
        d = self.read_adc_dpram(self.adc_addr_list, self.adc_read_len)
        d.addCallback(self.calc_adc_wfm, self.adc_bits)
        return d

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
        d = self.read_mem_gate(addrall)
        d.addCallback(self.calc_adc_wfm_seperate,indexlist,self.adc_bits)
        return d


    def read_adc_print(self):
        d = self.read_adc_dpram(self.adc_addr_list, self.adc_read_len)
        d.addCallback(self.print_adc_wfm, self.adc_bits)

    def read_adc_plot(self):
        d = self.read_adc_dpram(self.adc_addr_list, self.adc_read_len)
        d.addCallback(self.align_adc, self.adc_bits)
        d.addCallback(self.update_adc_wfm, self.adc_bits)

    def write_dac_wfm0(self):
        # XXX automatic register map decoding
        d0 = self.prep_sin_data(self.dac_len)
        d1 = self.prep_sin_data(self.dac_len)
        d0 = [0]*64+d0[0:64]
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)

    def write_dac_wfm1(self):
        # XXX automatic register map decoding
        d0 = self.prep_zeros_data(self.dac_len)
        d1 = self.prep_zeros_data(self.dac_len)
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

    def get_ads5400_temp(self):
        reg_names = ['FMC110_ADS5400_CTRL0_REG0x8', 'FMC110_ADS5400_CTRL1_REG0x8']
        d = self.read_cmd_regs(reg_names).addCallback(self.core_fmc110.decode_ads5400_temp)
        return d

    def get_config_rom(self):
        return self.get_lbnl_rom(0x200000)

    def get_fmc110_fcnt(self):
        freq_dict = {
            'CMD_CLK': 0,'ADC0': 1,'DAC0':2,
            'TRIGGER':3,'ADC1':4,'DAC1':5,'TO_FPGA':6}
        d = self.get_fmc_fcnt('FMC110',freq_dict)
        return d

    @defer.inlineCallbacks
    def read_mon(self):
        d = yield self.get_fmc110_fcnt()
        print_reg(d)
        d = yield self.get_ads5400_temp()
        print_reg(d)

    @defer.inlineCallbacks
    def read_diag(self):
        regs_want = []
        for i in range(0,0x9+1):
            regs_want.append('FMC110_ADS5400_CTRL0_REG'+hex(i))
        #  for i in range(0,0x9+1):
        #      regs_want.append('FMC110_ADS5400_CTRL1_REG'+hex(i))
        regs_want.append('FMC110_ADS5400_PHY0_CONTROL')
        regs_want.append('FMC110_ADS5400_PHY0_COMMAND')
        regs_want.append('FMC110_ADS5400_PHY1_CONTROL')
        regs_want.append('FMC110_ADS5400_PHY1_COMMAND')
        regs_want.append('FMC110_FMC110_CTRL_CONTROL')
        res = yield self.read_cmd_regs(regs_want)
        for reg in zip(regs_want, map(hex, res)):
            logger.info(reg)

