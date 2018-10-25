#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_phase_cali import LaserPhaseCali
from matplotlib import pyplot as plt
from random import randint
import time
import numpy as np
class LaserLockControl(LaserPhaseCali):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockControl, self).__init__(**kwargs)
        self.piezo_center=3048
        self.target_location=425#498#, 380
        self.matrix=np.loadtxt('april29_c1_d1.txt')
        self.vector=np.load('april29_c1_d1.npy')
        self.matrix_len=len(self.matrix)
        self.piezo_interval=float(self.matrix_len)/360.
        self.target_angle=float(self.target_location)/float(self.matrix_len)*360. if self.target_location<self.matrix_len/2. else float(self.target_location)/float(self.matrix_len)*360.-360
        self.height_limit=200 
        self.timestart=time.time()
        self.lock_flag=False
        self.lock_flag2=True
        self.lock_location=8
        self.phase_error=[]
        self.slowdac_delay=0.0018
        self.feedback_gain=0.1
        self.last_time=time.time()
        self.speed=20
        self.previous_move=0
        self.previous_value=0
    @defer.inlineCallbacks
    def amplitude_lock_loop(self,index):
        flag1=(index.next()%97==31)   
        data_control = yield self.dac_update()
        flag2=self.bias_update(data_control[0:3])
        d= yield self.piezo_update(data_control[3])
        flag4=(index.next()%300==99)
        if self.lock_flag==True:
            angel_error=(d[0])/float(len(self.matrix))*360.
            self.phase_error.append(angel_error)
            temp=time.time()
            self.speed= 1./(temp-self.last_time)
            self.last_time=temp
        if len(self.phase_error)>500:
            del self.phase_error[0]
        if flag1==True:
            print 'current pulse',[int(i) for i in data_control[3][0:13]]
            print 'control', data_control[0:3],' and ',self.bias_center
            print 'piezo',self.piezo_center,' and',d[0], ' and ',d[1]
            print 'time',int(time.time()-self.timestart)
            print 'Target angle',self.target_angle
        if flag4==True:
            rms_angle_error = np.sqrt(np.mean(np.square(self.phase_error)))
            print 'rms_angle_error',rms_angle_error
            print 'speed (Hz)',self.speed
            #print 'length_angle',len(self.phase_error)
            temp=time.time()
        #yield time.sleep(0.2)
        #dd = yield self.read_adc_wfm()
        #print 'PhotoDiode_Cavity',dd[0]
        #print 'PhotoDiode_BeforeCavity',dd[1]
        #self.write_data2file(dd[0],dd[1],'PhotoDiode_Cavity','PhotoDiode_BeforeCavity')

    @defer.inlineCallbacks
    def process_adc_PM(self, foo):
        d0 = yield self.read_adc_wfm_background(0,1).addCallback(self.process_adc_sum)
        dp = yield self.read_adc_wfm_selected(0,34,self.stack_cycle,1).addCallback(self.process_adc_sum)
        dn = yield self.read_adc_wfm_selected(0,35,self.stack_cycle,1).addCallback(self.process_adc_sum)
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
        V=self.vector
        vector=dat
        num=self.lock_location
        correction=0
        if self.lock_flag==False:
            match=np.array(vector).dot(V)
            angle=np.angle(match)/np.pi*180.
            current_angle=angle[0]
            diff_list=[self.target_angle-current_angle,360.+self.target_angle-current_angle,self.target_angle-current_angle-360.]
            diff= reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
            print 'diff',diff
            difference=diff*self.piezo_interval
            correction=int(self.feedback_gain*difference)
            if difference <60 and difference >-60: 
                self.lock_flag=True
                print 'locked', difference
        else:
            if vector[num]< self.height_limit:
                self.lock_flag=False
                print 'Unlocked', vector[num]
            elif vector[num] < self.previous_value:
                if self.lock_flag2==False:
                    correction=-self.previous_move
                    self.lock_flag2=True
                    print 'Return back'
                else:
                    print 'Original data worse from', self.previous_value,'down to',vector[num]
                    self.previous_value=vector[num]
                    self.lock_flag2=False
                    self.previous_move=-self.previous_move
            else: 
               self.lock_flag2=False
               correction=randint(-1,1)
               self.previous_move=correction
               self.previous_value=vector[num]
               print 'Improved, and new move try',correction,vector[num] 
            #difference = 300 if difference > 300 else difference
            #difference = -300 if difference < -300 else difference
        if correction>5: correction=5
        if correction<-5: correction=-5
        self.piezo_center=self.piezo_center+correction
        if self.piezo_center<0:
            self.piezo_center=self.matrix_len*2
            self.lock_flag=False
        if self.piezo_center>4095:
            self.piezo_center=4095-self.matrix_len*2
            self.lock_flag=False
            #print 'Move ', correction, self.piezo_center
        return [correction,self.previous_value]

