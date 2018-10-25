#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
# async recording
#from laser_phase_single_asyn import LaserPhase
# sync recording
from laser_phase_single_syn import LaserPhase
from matplotlib import pyplot as plt
import time
import numpy as np
class LaserLockControl(LaserPhase):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockControl, self).__init__(**kwargs)
        self.piezo_center = 2048
        self.matrix_length = 1016
        self.target_angle = 170
        self.piezo_interval=self.matrix_length/360.
        self.vector=np.load('aug9_c1.npy')
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

    def piezo_update(self,dat):
        V=self.vector
        #print len(V)
        #print V.shape()
        #current_location=[]
        amplitude=np.array(dat)
     
        match_unit=amplitude.dot(V)
        #self.noise_flag= True if  np.absolute(match_unit)<1+self.match_threshold and np.absolute(match_unit)>1-self.match_threshold else False
        #print self.noise_flag
        current_angle=np.angle(match_unit)/np.pi*180.
        #print current_angle
        current_angle=current_angle[0]
        diff_list=[self.target_angle-current_angle,360.+self.target_angle-current_angle,self.target_angle-current_angle-360.]
        diff= reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
        #diff = diff if diff>-160 else 360+diff
        #print 'diff',diff
        if abs(diff) <40: self.integral = self.integral+diff
        #else: self.integral = self.integral+30 if diff>0 else self.integral-30 
        correction=int((self.p_gain*diff+self.i_gain*self.integral)*self.piezo_interval)
        
        if correction>5: correction =5
        if correction<-5: correction =-5
        self.piezo_center=self.piezo_center+correction
        if self.piezo_center<0:
            self.piezo_center=900
            #self.lock_flag=False
        if self.piezo_center>4095:
            self.piezo_center=4095-940
            #self.lock_flag=False
        #print 'Current difference ', diff
        return [diff,correction]

