#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_phase_cali import LaserPhaseCali
from matplotlib import pyplot as plt
import time
import numpy as np
class LaserLockControl(LaserPhaseCali):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockControl, self).__init__(**kwargs)
        self.step = kwargs['stp'] if 'stp' in kwargs else 100
        self.bias_center=1506
        self.timestart=time.time()
        self.lock_flag=False
        self.open_loop=True
        self.piezo_center=2048
        self.target_location=498#, 380
        self.matrix=np.loadtxt('april5.txt')
        self.matrix_len=len(self.matrix)
        self.timestart=time.time()
        self.lock_flag=False
        self.phase_error=[]
        self.slowdac_delay=0.0058
        self.feedback_gain=0.15
        self.last_time=time.time()
    @defer.inlineCallbacks
    def amplitude_lock_loop(self,length):
        # XXX automatic register map decoding
        #d = yield self.bias_control_loop()
        #print 'Slow_Count',d[0],d[1],d[2]
        #flag=False
        #while flag==False: 
        phase_error,time_record=[],[]
        timestart=time.time()
        print 'target angle before',int(self.target_location/float(self.matrix_len)*360)
        for i in range(length):
            data_control = yield self.dac_update()
            self.bias_update(data_control[0:3])
            d= yield self.piezo_update(data_control[3])
            angel_error=d[0]/float(self.matrix_len)*360.
            phase_error.append(angel_error)
            time_record.append((time.time()-timestart)*1000)
            if self.open_loop and i==0:
                self.piezo_center=self.piezo_center+int(d[0])
            if i==0:
                print 'piezo_step',int(d[0])
            #print 'current pulse',[int(i) for i in data_control[3][0:13]]
            #print 'control', data_control[0:3],' and ',self.bias_center
            #print 'piezo',self.piezo_center,' and',d[0], ' and ',d[1]
            #print 'bias',self.bias_center
            #print 'time',time.time()-self.timestart
        print 'angle_error',phase_error
        print 'time_record',time_record
        self.target_location=self.target_location+self.step
        if self.open_loop==False:
            print 'gain',self.feedback_gain,'slowdac_delay',self.slowdac_delay
        if self.target_location>self.matrix_len:
            self.target_location=self.target_location-self.matrix_len
        if self.target_location<36: 
            self.target_location=50
        if self.target_location>self.matrix_len-36:
            self.target_location=self.matrix_len-50
        print 'target angle after',int(self.target_location/float(self.matrix_len)*360)
        #yield time.sleep(0.2)
        #dd = yield self.read_adc_wfm()
        #print 'PhotoDiode_Cavity',dd[0]
        #print 'PhotoDiode_BeforeCavity',dd[1]
        #self.write_data2file(dd[0],dd[1],'PhotoDiode_Cavity','PhotoDiode_BeforeCavity')

    @defer.inlineCallbacks
    def process_adc_PM(self, foo):
        d0 = yield self.read_adc_wfm_background(0,2).addCallback(self.process_adc_sum)
        dp = yield self.read_adc_wfm_selected(0,6,self.stack_cycle,2).addCallback(self.process_adc_sum)
        dn = yield self.read_adc_wfm_selected(0,7,self.stack_cycle,2).addCallback(self.process_adc_sum)
        d1 = yield self.read_adc_wfm_selected(1,0,self.stack_cycle,13)
        d=[dp,d0,dn,d1]
        defer.returnValue(d)



    @defer.inlineCallbacks
    def dac_update(self):
        val= int(self.piezo_center)
        val2=int(self.bias_center)
            #time.sleep(1)
        self.write_slowdac_wfm({201:val,200:val2})
            #self.write_slowdac_wfm({200:self.bias_center})
        d = defer.Deferred().addCallback(self.process_adc_PM)
        reactor.callLater(self.slowdac_delay, d.callback, '')
        control = yield d
        defer.returnValue(control)
    def piezo_update(self,dat):
        length=len(self.matrix)
        M=self.matrix
        #current_location=[]
        close_location=0
        vector=dat
        close_distance=100000
        if self.lock_flag==False:
            #print 'xx'
            for i in range(0,self.matrix_len,7):
                distance=np.linalg.norm(vector[5:13]-M[i,5:13])
                close_location=i if distance < close_distance else close_location
                close_distance=distance if distance < close_distance else close_distance
        else:
            #print 'aa'
            for i in range(self.target_location-35,self.target_location+35):
                distance=np.linalg.norm(vector[5:13]-M[i,5:13])
                close_location=i if distance < close_distance else close_location
                close_distance=distance if distance < close_distance else close_distance
        target=self.target_location
        if target==close_location:            
            act_diff=0
            #print 'At the right spot!'
        else:
            difference=target-close_location
            if abs(difference)>(self.matrix_len)/2:
                difference=self.matrix_len-difference if difference>0 else difference+self.matrix_len
            #print difference
            act_diff=difference
            difference = 300 if difference > 300 else difference
            difference = -300 if difference < -300 else difference
            if difference >30 or difference < -30:
                self.lock_flag=False    
            if difference <10 and difference >-10:
                self.lock_flag=True
            if self.open_loop==False:
                correction=int(self.feedback_gain*difference)
                self.piezo_center=self.piezo_center+correction
            #print 'Move ', str(difference),close_location
        return [act_diff,close_location]

