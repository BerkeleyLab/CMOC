#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_bias_control import LaserBiasCtrl
from numpy import mean
from matplotlib import pyplot as plt
import time
class LaserAmplitudeCali(LaserBiasCtrl):
    """ Laser Amplitude Calibration """
    def __init__(self, **kwargs):
        super(LaserAmplitudeCali, self).__init__(**kwargs)

    @defer.inlineCallbacks
    def write_amplitude_cali(self,index):
        # XXX automatic register map decoding
        d = yield self.bias_control_loop()
        print 'Slow_Count',d[0],d[1],d[2]
        #yield time.sleep(0.2)
#        self.write_data2file_slow(d[1],'Slow_Count')
        v = index.next()
        print 'index=',v
        d0 = self.prep_pm_data2(self.dac_len,v)
        d1 = self.prep_am_data(self.dac_len,v)
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        print 'd0',d0
        print 'd1',d1
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)
        dd = yield self.read_adc_wfm()
        #print 'ADC_Read_from_Laser',dd[0][100:400]
        #print 'FastDAC_Write_to_Modulator',dd[1][100:400]
        #self.write_data2file(dd[0],dd[1],d[1],'ADC_Read_from_Laser','FastDAC_Write_to_Modulator','slowdac reading')

    def write_data2file(self,data0,data1,data2,name0='',name1='',name2=''):
        f_name0=name0+'.txt'
        f=open(f_name0,'a')
        for i in data0:
            f.write("%.10f\n"%i)
        f.close()
        f_name1=name1+'.txt'
        f=open(f_name1,'a')
        for i in data1:
            f.write("%.10f\n"%i)
        f.close()
        f_name2=name2+'.txt'
        f=open(f_name2,'a')
        f.write("%.10f\n"%data2)
        f.close()
        pass

#    def write_data2file_slow(self,data,name=''):
#        f_name=name+'.txt'
#        f=open(f_name,'a')
#        f.write("%.10f\n"%data)
#        f.close()
#        pass
