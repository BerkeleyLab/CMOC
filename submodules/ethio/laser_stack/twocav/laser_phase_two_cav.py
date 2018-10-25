#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from matplotlib import pyplot as plt
import time
import numpy as np
class LaserPhase(LaserStackApp):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserPhase, self).__init__(**kwargs)
        self.bias_center=3090
        self.adc_delay=0.0015
        self.piezo_center=[1200,1200,1200,1200] 
        self.diode_offset=[2,1,2]
        self.vector=[]
        self.pulse_number=7
        self.target_location=['N','N','N','N']
        self.piezo_interval=['N','N','N','N']
        self.feedback_gain=0.5
        self.piezo_limit=50
        self.lock_limit=7

        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,34,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,35,self.stack_cycle,1)
        addr_diode_0 = self.get_adc_selected_address(0,self.diode_offset[0],self.stack_cycle,self.pulse_number)
        addr_diode_1 = self.get_adc_selected_address(0,self.diode_offset[1],self.stack_cycle,self.pulse_number)
        addr_diode_2 = self.get_adc_selected_address(0,self.diode_offset[2],self.stack_cycle,self.pulse_number)
        addr_diode_output = self.get_adc_selected_address(1,0,self.stack_cycle,self.pulse_number)
        self.addr_bias=[addrp,addr0,addrn]
        self.addr_diode=[addr_diode_0,addr_diode_1,addr_diode_2]
        self.addr_diode_output=addr_diode_output
       
        self.addr_bias_output=[addrp,addr0,addrn]
       

    def read_bias(self, foo):
        d = self.read_adc_wfm_addr(self.addr_bias).addCallback(self.process_bias)
        return d
    def process_bias(self,dat):
        data = [sum(dat[0]),sum(dat[1]),sum(dat[2])]
        return data
    def read_bias_output(self, foo):
        d = self.read_adc_wfm_addr(self.addr_bias_output).addCallback(self.process_bias_output)
        return d
    def process_bias_output(self,dat):
        data = [sum(dat[0]),sum(dat[1]),sum(dat[2])]
        return data
    def read_cav_output(self,foo,num):
        addr=[self.addr_diode[num]]
        d = self.read_adc_wfm_addr(addr)#######
        return d

    def read_diode_output(self,foo,num):
        addr=[self.addr_diode_output]
        d = self.read_adc_wfm_addr(addr)#######
        return d


    @defer.inlineCallbacks
    def read_cav_multi(self, foo,num):
        d1 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d2 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d3 = yield self.read_adc_wfm_addr([self.addr_diode[num]])
        d=[d1[0],d2[0],d3[0]]
        defer.returnValue(d)

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

