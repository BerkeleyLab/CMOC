#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_phase_cali_one_cav import LaserPhase
from matplotlib import pyplot as plt
from random import randint
import time,sys
import numpy as np
MAX = sys.maxint
class LaserLockControl(LaserPhase):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockControl, self).__init__(**kwargs)
        #self.target_location=425#498#, 380
        #self.matrix=np.loadtxt('april29_c1_d1.txt')
        self.cav_num=2
        self.avg_time=20
        self.piezo_interval=[2.81,5.3,2.81,3.5]
        self.cav_state=[np.zeros(5),np.zeros(5),np.zeros(5),np.zeros(5)]
        
        self.count=0
        self.entry_ratio=3
        self.height_limit=self.avg_time*70
        
        self.feedback_gain=0.4
        self.bias=[0,0,0]
        self.timestart=time.time()
        self.lock_flag=False
        self.lock_flag2=True
        #self.phase_error=[[],[],[]]
        self.last_time=time.time()
        self.speed=20
        self.previous_move=[0]#[0,0,0,0]
        self.previous_max=150
        self.previous_min=1000
        self.previous_ratio=0.5
        self.randcount=0
        self.scancount=0
        self.step=self.piezo_interval[self.cav_num]*30
        self.limit=int(self.piezo_interval[self.cav_num]*5)
        self.min_search=300
        self.bias_flag=False
       
        #addr0 = self.get_adc_bg_address(0,1)
        #addrp = self.get_adc_selected_address(0,30,self.stack_cycle,1)
        #addrn = self.get_adc_selected_address(0,31,self.stack_cycle,1)
        #addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,6)
        #self.addr_list = [addrp,addr0,addrn,addr_cali]
    



    @defer.inlineCallbacks
    def amplitude_lock_update(self,length=0):
        cav_num = self.cav_num
        peak_list = []
        ratio_list = []
        first_pulse =[]
        count = 0
        start_time=time.time()
        if length==0:
            length=MAX
        while len(peak_list)<length:
            print_flag = (count%31==25) if length==MAX else False
            count=count+1
            input_info={self.cav_addr[cav_num]:int(self.piezo_center[cav_num])}
            input_info[self.bias_addr]=int(self.bias_center)
            if self.bias_flag:
                switch_flag=count%2
                #print switch_flag
                if switch_flag==0:
                    input_info[self.switch_addr1]=self.switch_val1[0]
                    input_info[self.switch_addr0]=self.switch_val0[0]
                    self.write_slowdac_wfm(input_info)
                    d1 = defer.Deferred().addCallback(self.read_bias_output)
                    reactor.callLater(self.adc_delay,d1.callback,'')
                    control = yield d1
                    self.bias=control[0:3]
                    self.bias_flag=self.bias_update(control[0:3])
                    #current_pulse=control[1]
                elif switch_flag==1:
                    self.write_slowdac_wfm(input_info)
                    self.cav_state=[np.zeros(5),np.zeros(5),np.zeros(5),np.zeros(5)]
                    for i in xrange(self.avg_time):
                        d2 = defer.Deferred().addCallback(self.read_diode_output,cav_num)
                        reactor.callLater(self.adc_delay,d2.callback,'')
                        control = yield d2
                        self.cav_state[cav_num]=self.cav_state[cav_num]+np.array(control[0])
                    #print 'control',self.control[cav_num]
                    if self.feedback_gain==0:
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num],False)
                    else:
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num],True)
                    temp=time.time()
                    self.speed= 1./(temp-self.last_time)
                    self.last_time=temp
                    if print_flag==True:
                        if self.lock_flag:
                            self.print_info(cav_num)
                        else:
                            print 'searching',self.piezo_center
                    if self.lock_flag:
                        peak_list.append(max_value)
                        ratio_list.append(ratio)
                        first_pulse.append(first_value)

            else:
            #print index.next()
                input_info[self.switch_addr1]=self.switch_val1[0]
                input_info[self.switch_addr0]=self.switch_val0[0]
                self.write_slowdac_wfm(input_info)
                d0 = defer.Deferred().addCallback(self.read_bias)
                reactor.callLater(self.adc_delay,d0.callback,'')
                control = yield d0
                self.bias_flag=self.bias_update(control[0:3])
                self.bias=control[0:3]
                if print_flag==True:
                    print 'slow dac',self.bias_center, control
        return_group=(peak_list,ratio_list,first_pulse,time.time()-start_time,count)
        defer.returnValue(return_group)


    def piezo_peak(self,dat,flag=True):
        cav_num=self.cav_num
        corr=[0]
        peak_value=dat[2]
        monitor_value=dat[1]+dat[3]
        ratio=float(peak_value)/(float(monitor_value)+0.5)
        start_value=dat[0]
        #ind = 0 if start_num==3 else 3
        if flag==False:
            pass
        elif self.lock_flag==False:
            self.scancount=self.scancount+1
            if peak_value > self.height_limit and ratio >self.entry_ratio: 
                self.lock_flag=True
                print 'locked',peak_value,ratio
                self.randcount=0
            else:
                corr[0]=self.step
        else:
            if peak_value < self.height_limit-100 or ratio < self.entry_ratio:
                self.lock_flag=False
                print 'Unlocked', peak_value
                self.scancount=0
                self.piezo_center[cav_num]=self.piezo_center[cav_num]-self.step*2
            elif ratio < self.previous_ratio or peak_value< self.height_limit-20:
                if self.lock_flag2==False:
                    #for num in xrange(start_num,4):
                    corr[0]=-self.previous_move[0]
                    self.lock_flag2=True
                else :
                    self.previous_ratio=ratio
                    self.lock_flag2=False
                    #for num in xrange(start_num,4):
                    self.previous_move[0]=-self.previous_move[0]
            else: 
               self.lock_flag2=False
   
               #corr0=randint(-2,2) if self.randcount%21==7 else 0
               #corr1=randint(-2,2) if self.randcount%17==2 else 0
               #corr[2]=randint(-ind,ind) if self.randcount%5==3 else 0
               corr[0]=randint(-self.limit,self.limit)
               #corr=[corr0,corr1,corr2,corr3]
               self.randcount=self.randcount+1
               self.previous_move=corr
               self.previous_ratio=ratio
        #for num in xrange(start_num,4):
        self.piezo_center[cav_num]=self.piezo_center[cav_num]+corr[0]
        if self.piezo_center[cav_num]<0:
            self.piezo_center[cav_num]=3890
            self.lock_flag=False
        if self.piezo_center[cav_num]>4095:
            self.piezo_center[cav_num]=200
            self.lock_flag=False
            #print 'Move ', correction, self.piezo_center
        return [peak_value,monitor_value,ratio,start_value]

    def print_info(self,cav_num,flag=True):
        current_pulse=self.cav_state[cav_num]/float(self.avg_time)
        peak_value=current_pulse[2]
        monitor_value=current_pulse[1]+current_pulse[3]+0.001
        ratio=peak_value/monitor_value
        print 'current pulse',[int(i) for i in current_pulse]
        print 'control', self.bias,' and ',self.bias_center
        print 'piezo', self.piezo_center
        print 'result', monitor_value,peak_value,ratio
        print 'time',1000*(time.time()-self.timestart)
        print 'speed (Hz)',self.speed
