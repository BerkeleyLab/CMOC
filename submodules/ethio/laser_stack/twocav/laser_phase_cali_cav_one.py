#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_phase_two_cav import LaserPhase
from matplotlib import pyplot as plt
import time
import numpy as np
class LaserPhaseCali(LaserPhase):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserPhaseCali, self).__init__(**kwargs)
        self.adc_delay=0.0015 
        self.cav_num=[1,2]
    @defer.inlineCallbacks
    def write_phase_cali(self,length):
        v = self.am_pm_delay
        #d0 = self.prep_pm_data13(self.dac_len,v)
        #d1 = self.prep_am_data13(self.dac_len,v)
        d0 = self.prep_pm_two_cav_new(self.dac_len,v,0)#PM for zero
        d1 = self.prep_am_two_cav_new(self.dac_len)
        #d1= self.prep_am_datalong(self.dac_len,v)
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)
        #time.sleep(5)
        d_PM = yield self.PM_control_loop(length)
        #print 'Count_PM',d_PM
        #yield time.sleep(0.2)

    @defer.inlineCallbacks
    def read_from_cav(self, foo,num):
        d1 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d2 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d3 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d=[d1[0],d2[0],d3[0]]
        defer.returnValue(d)

    @defer.inlineCallbacks
    def PM_control_loop(self,length):
        slowdac_vals = range(0,0+length)
        d = yield self.PM_scan(slowdac_vals)
        defer.returnValue(d)

    @defer.inlineCallbacks
    def PM_scan(self, slowdac_vals):
        res_list=[]
        bias=int(self.bias_center)
        for val in slowdac_vals:
            #time.sleep(1)
            flag=False
            cavnum=self.cav_num[0] # 0,1,2
            while flag==False:
                self.write_slowdac_wfm({self.cav_addr[cavnum]:val,self.bias_addr:bias,self.switch_addr1:self.switch_val1[0],self.switch_addr0:self.switch_val0[0]}) # 1 for 1% mirror diode
                d1 = defer.Deferred().addCallback(self.read_bias)
                reactor.callLater(self.adc_delay, d1.callback, '')
                control = yield d1
                flag=self.bias_update(control)
                bias=int(self.bias_center)
                print bias
                if flag:
                    self.write_slowdac_wfm({self.switch_addr1:self.switch_val1[cavnum+1],self.switch_addr0:self.switch_val0[cavnum+1]})
                    d2 = defer.Deferred().addCallback(self.read_cav_multi,cavnum)
                    reactor.callLater(self.adc_delay, d2.callback, '')
                    dat = yield d2
                    diode_data=np.zeros(self.pulse_number)
                    for i in xrange(10):
                        d3 = defer.Deferred().addCallback(self.read_diode_output,cavnum)
                        reactor.callLater(self.adc_delay, d3.callback, '')
                        diode = yield d3
                        diode_data=diode_data+np.array(diode[0])
                    print 'Diode:',[int(i) for i in diode_data]
                    print 'control data',control
                    print 'Pulse1:',[int(i) for i in dat[0]]
                    print 'Pulse2:',[int(i) for i in dat[1]]
                    print 'Pulse3:',[int(i) for i in dat[2]]
                    print 'data_update:',val
                else:
                    print 'slow dac:',bias,control
            #time.sleep(1)
            #res_list.append(read_val)
        defer.returnValue(res_list)
 
