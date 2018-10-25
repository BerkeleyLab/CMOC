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
        self.piezo_center=3048
        self.target_location=240#498#, 380
        self.matrix=np.loadtxt('may22_c1.txt')
        self.vector=np.load('may22_c1.npy')
        self.matrix_len=len(self.matrix)
        self.piezo_interval=float(self.matrix_len)/360.
        angle=float(self.target_location)/float(self.matrix_len)*360.
        self.target_angle= angle if angle < 180 else angle -360 
        self.timestart=time.time()
        self.lock_flag=False
        self.lock_flag2=False
        self.phase_error=[]
        self.slowdac_delay=0.0018
        self.feedback_gain=0.25
        self.last_time=time.time()
        self.speed=0
        
        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,30,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,31,self.stack_cycle,1)
        addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,13)
        self.addr_list=[addrp,addr0,addrn,addr_cali]
    @defer.inlineCallbacks
    def amplitude_lock_loop(self,index):
        flag1=(index.next()%97==31)   
        control = yield self.dac_update()
        data_control=control[0]
        flag2=self.bias_update(data_control[0:3])
        feedback =  self.piezo_update(data_control[3])
        flag4=(index.next()%300==99)
        if self.lock_flag==True:
            angel_error=(feedback[0])/float(len(self.matrix))*360.
            self.phase_error.append(angel_error)
            temp=time.time()
            self.speed= 1./(temp-self.last_time)
            self.last_time=temp
        if len(self.phase_error)>500:
            del self.phase_error[0]
        if flag1==True:
            print 'current pulse',[int(i) for i in data_control[3][0:13]]
            print 'control', data_control[0:3],' and ',self.bias_center
            print 'piezo',self.piezo_center,' and',feedback[0], ' and ',feedback[1]
            print 'time',int(time.time()-self.timestart)
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

    def read_adc(self, foo):
        d=self.read_adc_wfm_addr(self.addr_list).addCallback(self.process_adc_data)
        return d


    @defer.inlineCallbacks
    def dac_update(self):
        value_list=[]
        val= int(self.piezo_center)
        val2=int(self.bias_center)
        for num in xrange(0,1):
            self.write_slowdac_wfm({201:val,200:val2,0x701:1})
            d = defer.Deferred().addCallback(self.read_adc)
            reactor.callLater(self.slowdac_delay, d.callback, '')
            read_val = yield d
            value_list.append(read_val)
        defer.returnValue(value_list)
    def piezo_update(self,dat):
        M=self.matrix
        V=self.vector
        #current_location=[]
        close_location=0
        close_distance=1000
        vector=dat
        if self.lock_flag==False:
            print 'dd'
            match=np.array(vector).dot(V)
            angle=np.angle(match)/np.pi*180.
            current_angle=angle[0]
            diff_list=[self.target_angle-current_angle,360.+self.target_angle-current_angle,self.target_angle-current_angle-360.]
            diff= reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
            difference=int(diff*self.piezo_interval)
            close_distance=abs(np.absolute(match)-1)*50
        else:
            gap,interval=60,1
            #print 'aa'
            begin,end=self.target_location-gap,self.target_location+gap
            begin2,end2=0,0
            if end>self.matrix_len:
                begin2,end2=0,end-self.matrix_len
                end=self.matrix_len
            if begin<0: 
                begin2,end2=begin,0
                begin=0
            for i in range(begin,end):
                distance=np.linalg.norm(vector[8:13]-M[i,8:13])
                close_location=i if distance < close_distance else close_location
                close_distance=distance if distance < close_distance else close_distance
            for i in range(begin2,end2):
                distance=np.linalg.norm(vector[8:13]-M[i,8:13])
                close_location=i if distance < close_distance else close_location
                close_distance=distance if distance < close_distance else close_distance 
            difference=self.target_location-close_location 
            if abs(difference)>self.matrix_len/2:
                difference=self.matrix_len-difference if difference>0 else difference+self.matrix_len
        if False:
            pass
            #print 'At the right spot!'
        else:
            #difference = 300 if difference > 300 else difference
            #difference = -300 if difference < -300 else difference
            if difference >50 or difference < -50:
                self.lock_flag=False
            if difference <20 and difference >-20:
                self.lock_flag=True
            correction=self.feedback_gain*difference
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
        return [difference,close_distance]

