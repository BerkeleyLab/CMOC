#!/usr/bin/python
from twisted.internet import defer, reactor
#from laser_phase_single_asyn import LaserPhase
from laser_phase_single_syn import LaserPhase
from matplotlib import pyplot as plt
import time
import numpy as np
class LaserLockControl(LaserPhase):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockControl, self).__init__(**kwargs)
        self.piezo_center=2048
        self.matrix_length=540
        self.target_angle=-170
        self.piezo_interval=self.matrix_length/360.
        self.vector=np.load('aug11_c2_single.npy')
        self.time_start=time.time()
        self.time_last=self.time_start
        self.lock_flag=False
        #self.noise_flag=False
        self.phase_error=[]
        self.slowdac_delay=0.00015
        self.write_delay=0.0001
        self.p_gain=0.02
        self.i_gain=0.00
        self.integral=0
         
        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,34,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,35,self.stack_cycle,1)
        addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,13)
        self.addr_list=[addrp,addr0,addrn,addr_cali]
        #self.match_threshold=0.2
    def update_print(self,count):
        return True

    def print_info(self,data_control,phase_diff,correction):
        print 'time ',self.time_cost*1000
        print 'phase_error', phase_diff
        return

    def piezo_update(self,dat):
        V=self.vector
        amplitude=np.array(dat)
     
        match_unit=amplitude.dot(V)
        current_angle=np.angle(match_unit)/np.pi*180.
        current_angle=current_angle[0]
        diff_list=[self.target_angle-current_angle,360.+self.target_angle-current_angle,self.target_angle-current_angle-360.]
        diff= reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
        if abs(diff) <40: self.integral = self.integral+diff
        #else: self.integral = self.integral+30 if diff>0 else self.integral-30 
        correction=int((self.p_gain*diff+self.i_gain*self.integral)*self.piezo_interval)
        if correction>5: correction =5
        if correction<-5: correction =-5
        #self.piezo_center=self.piezo_center+correction
        if self.piezo_center<0:
            self.piezo_center=900
            #self.lock_flag=False
        if self.piezo_center>4095:
            self.piezo_center=4095-940
            #self.lock_flag=False
        #print 'Current difference ', diff
        return [diff,correction]

