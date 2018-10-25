#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from matplotlib import pyplot as plt
import time
class LaserPhaseCali(LaserStackApp):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserPhaseCali, self).__init__(**kwargs)
        self.bias_center=3090
        self.adc_delay=0.005
        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,30,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,31,self.stack_cycle,1)
        addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,20)
        self.addr_list=[addrp,addr0,addrn,addr_cali]
        #self.am_pm_delay=6 
    @defer.inlineCallbacks
    def write_phase_cali(self,length):
        # XXX automatic register map decoding
        #d = yield self.bias_control_loop()
        #print 'Slow_Count',d[0],d[1],d[2]
        v = self.am_pm_delay
        #d0 = self.prep_pm_data13(self.dac_len,v)
        #d1 = self.prep_am_data13(self.dac_len,v)
        d0 = self.prep_zeros_data(self.dac_len)#PM for zero
        d1 = self.prep_pulse_data(self.dac_len)
        #d1= self.prep_am_datalong(self.dac_len,v)
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)
        #time.sleep(5)
        d_PM = yield self.PM_control_loop(length)
        #print 'Count_PM',d_PM
        #yield time.sleep(0.2)
        #dd = yield self.read_adc_wfm()
        #print 'PhotoDiode_Cavity',dd[0]
        #print 'PhotoDiode_BeforeCavity',dd[1]
        #self.write_data2file(dd[0],dd[1],'PhotoDiode_Cavity','PhotoDiode_BeforeCavity')
    @defer.inlineCallbacks
    def read_from_adc(self, foo):
        #d = [ d1[0], d1[1], d1[2]]
        #print d1[3]
        d1 = yield self.read_adc_wfm_addr(self.addr_list).addCallback(self.process_adc_data)
        d2 = yield self.read_adc_wfm_addr(self.addr_list).addCallback(self.process_adc_data)
        d3 = yield self.read_adc_wfm_addr(self.addr_list).addCallback(self.process_adc_data)
        d=[d1,d2,d3]
        defer.returnValue(d)

    @defer.inlineCallbacks
    def PM_control_loop(self,length):
        self.d = defer.Deferred()
        slowdac_vals = range(0,0+length)
        d = yield self.PM_scan(slowdac_vals)
        defer.returnValue(d)

    @defer.inlineCallbacks
    def PM_scan(self, slowdac_vals):
        res_list=[]
        val2=int(self.bias_center)
        for val in slowdac_vals:
            #time.sleep(1)
            flag=False
            while flag==False:
                self.write_slowdac_wfm({201:val,200:val2,0x701:0,0x700:0}) # 1 for 1% mirror diode
                #self.write_slowdac_wfm({200:self.bias_center})
                d = defer.Deferred().addCallback(self.read_from_adc)
                reactor.callLater(self.adc_delay, d.callback, '')
                dat = yield d
                #print dat
                control = self.process_reading(dat)
                flag=self.bias_update(control[0:3])
                val2=int(self.bias_center)
                #print val2
                if flag:
                    print 'control data',control[0:3]
                    print 'Pulse1:',[int(i) for i in control[3]]
                    print 'Pulse2:',[int(i) for i in control[4]]
                    print 'Pulse3:',[int(i) for i in control[5]]
                    print 'data_update:',val
                else:
                    print 'slow dac:',val2
            #time.sleep(1)
            #res_list.append(read_val)
        defer.returnValue(res_list)
    def bias_update(self, control):
        cflag=self.bias_direction
        if control[0]>control[1]>control[2]:
            diff = 4 if cflag else -4
        elif control[0]<control[1]<control[2]:
            diff = -4 if cflag else 4
        elif control[1]>self.bottom_limit:
            diff = 190 if self.bias_center<2048 else 190
        else:
            diff=self.Kp_bottom*(control[0]-control[2])
            if diff>15:
                diff=15
            if diff<-15:
                diff=-15
            diff=diff if cflag else -diff
        self.bias_center = self.bias_center+diff
        if self.bias_center>4095:
            self.bias_center=4095-2400
            return False
        elif self.bias_center<0:
            self.bias_center=2400
            return False
        if abs(diff)<1:
            #print 'control', control,' and ',self.bias_center
            return True
        else:
            #print diff
            return False
    def process_adc_data(self,dat):
        data = [sum(dat[0]),sum(dat[1]),sum(dat[2]),dat[3]]
        return data
    def process_reading(self,data):
        dp=(data[0][0]+data[1][0]+data[2][0])/3
        d0=(data[0][1]+data[1][1]+data[2][1])/3
        dn=(data[0][2]+data[1][2]+data[2][2])/3
        control=[dp,d0,dn,data[0][3],data[1][3],data[2][3]]
        return control
 
