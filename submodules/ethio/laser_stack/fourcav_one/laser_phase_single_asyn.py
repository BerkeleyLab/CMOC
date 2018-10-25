#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from matplotlib import pyplot as plt
import numpy as np
import time
class LaserPhase(LaserStackApp):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserPhase, self).__init__(**kwargs)
        self.bias_center=3090
        self.time_start=time.time()
        self.time_last = self.time_start
        self.cali_delay=0.005
        self.lock_delay=0.00001
        self.index_count=0
        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,34,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,35,self.stack_cycle,1)
        addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,20)
        self.addr_list=[addrp,addr0,addrn,addr_cali]
        self.speed = 0
        self.time_cost = 0

    def read_adc(self,foo):
        d = self.read_adc_wfm_addr(self.addr_list).addCallback(self.process_adc_data)
        self.time_cost = time.time()-self.time_start
        return d

    def piezo_update(self,dat):
        # to be fulfilled by different algorithm
        return [phase_diff,correction]
    
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
        if abs(diff)<2:
            #print 'control', control,' and ',self.bias_center
            return True
        else:
            #print diff
            return False
    @defer.inlineCallbacks
    def lock_loop(self,return_flag=False):
        flag = False
        while flag is False:
            #print 'first',(time.time()-self.time_start)*1000.
            print_flag = self.update_print(self.index_count)
            self.index_count = self.index_count+1
            d = defer.Deferred().addCallback(self.read_adc)
            reactor.callLater(self.lock_delay,d.callback, '')
            data_control = yield d
            bias_flag = self.bias_update(data_control[0:3])
            phase_diff,correction = self.piezo_update(data_control[3])
            val,val2 = int(self.piezo_center),int(self.bias_center)
            self.write_slowdac_wfm({203:val,200:val2,0x701:0,0x700:0})
            if abs(phase_diff)<180:
                self.phase_error.append(phase_diff)
            if len(self.phase_error)>500:
                del self.phase_error[0]
            temp = time.time()
            self.speed = 1./(temp-self.time_last)
            self.time_last=temp
            if print_flag is True:
                self.print_info(data_control,phase_diff,correction)
            #flag=True if abs(phase_diff)
        return

    def update_print(self,count):
        return True if count%500==37 else False
    
    def print_info(self,data_control,phase_diff,correction):
        print 'current pulse',[int(i) for i in data_control[3][0:13]]
        print 'control', data_control[0:3],' and ',self.bias_center
        print 'piezo',self.piezo_center,' and',phase_diff, ' and ', correction
        print 'Operate at',self.speed,'Hz'
        print 'ingral',self.integral
        rms_angle_error = np.sqrt(np.mean(np.square(self.phase_error)))
        print 'rms_angle_error',rms_angle_error
        return

    def process_adc_data(self,dat):
        data = [sum(dat[0]),sum(dat[1]),sum(dat[2]),dat[3]]
        return data

    def process_reading(self,data):
        dp=(data[0][0]+data[1][0]+data[2][0])/3
        d0=(data[0][1]+data[1][1]+data[2][1])/3
        dn=(data[0][2]+data[1][2]+data[2][2])/3
        control=[dp,d0,dn,data[0][3],data[1][3],data[2][3]]
        return control
        #self.am_pm_delay=6 
    @defer.inlineCallbacks
    def write_phase_cali(self,length):
        v = self.am_pm_delay
        d0 = self.prep_pm_data13(self.dac_len,v)
        d1 = self.prep_am_data13(self.dac_len,v)
        dac0_addr = 0x31000
        dac1_addr = 0x41000
        self.write_dac_dpram(dac0_addr, d0)
        self.write_dac_dpram(dac1_addr, d1)
        d_PM = yield self.PM_control_loop(length)
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
                reactor.callLater(self.cali_delay, d.callback, '')
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
