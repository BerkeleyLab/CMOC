#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_phase_cali_cav_one import LaserPhase
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
        self.matrix=['z',np.loadtxt('dec2_c1.txt'),'z','z']
        self.target_angle=['n',271,'z','z']
        
        self.dist_threshold=350
        self.previous_dist=10000
        self.previous_change=[0]
        self.cav0_lockflag=False
        self.cav0_lockflag2=False
        self.dist_stored=0

        self.cav_num=[1,2]
        self.avg_time=14
        
        self.piezo_interval=[2.81,5.27778,2.81,3.5]
        self.target_location=['n',1596,'n','n']
        self.full_range=np.array(self.piezo_interval)*200
        self.cav_state=[np.zeros(self.pulse_number)]*4
        self.piezo_temp=[0,0]

        self.piezo_amp=np.array([self.full_range[self.cav_num[0]],self.full_range[self.cav_num[1]]])
        
        self.count=0
        self.entry_ratio=0.8
        self.height_limit=self.avg_time*200
        
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
        self.limit=15
        self.bias_flag=False
       
        #addr0 = self.get_adc_bg_address(0,1)
        #addrp = self.get_adc_selected_address(0,30,self.stack_cycle,1)
        #addrn = self.get_adc_selected_address(0,31,self.stack_cycle,1)
        #addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,6)
        #self.addr_list = [addrp,addr0,addrn,addr_cali]

    @defer.inlineCallbacks
    def amplitude_lock_update(self,length=0):
        cav_num_1 = self.cav_num[1]
        cav_num_0 = self.cav_num[0]
        peak_list = []
        ratio_list = []
        first_pulse =[]
        count = 0
        start_time=time.time()
        if length==0:
            length=MAX
        max_value,ratio='not available','not available'
        while len(peak_list)<length:
            print_flag = (count%31==25) if length==MAX else False
            count=count+1
            input_info={self.cav_addr[cav_num_1]:int(self.piezo_center[cav_num_1])}
            input_info[self.cav_addr[cav_num_0]]=int(self.piezo_center[cav_num_0])
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
                    input_info[self.switch_addr1]=self.switch_val1[cav_num_0+1]
                    input_info[self.switch_addr0]=self.switch_val0[cav_num_0+1]
                    self.write_slowdac_wfm(input_info)
                    self.cav_state=[np.zeros(self.pulse_number)]*4
                    for i in xrange(self.avg_time):
                        d2 = defer.Deferred().addCallback(self.read_cav_output,cav_num_0)
                        reactor.callLater(self.adc_delay,d2.callback,'')
                        d3 = defer.Deferred().addCallback(self.read_diode_output,cav_num_1)
                        reactor.callLater(self.adc_delay,d3.callback,'')
                        cav_0 = yield d2
                        cav_1 = yield d3
                        self.cav_state[cav_num_0]=self.cav_state[cav_num_0]+np.array(cav_0[0])
                        self.cav_state[cav_num_1]=self.cav_state[cav_num_1]+np.array(cav_1[0])
                    if self.feedback_gain==0:
                        self.dist_stored,correction = self.piezo_pattern(self.cav_state[cav_num_0],False)
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num_1],False)
                    else:
                        self.dist_stored,correction = self.piezo_pattern(self.cav_state[cav_num_0],True)
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num_1],True)
                    temp=time.time()
                    self.speed= 1./(temp-self.last_time)
                    self.last_time=temp
                    if print_flag==True:
                        if self.lock_flag:
                            self.print_info(cav_num_1)
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
                    print 'slow dac',self.bias_center
                    print 'max:',max_value,'ratio',ratio
        return_group=(peak_list,ratio_list,first_pulse,time.time()-start_time,count)
        defer.returnValue(return_group)

    def piezo_pattern(self,dat_in,flag=True):
        corr=[0]
        dat = dat_in/self.avg_time
        cav_num0 = self.cav_num[0]
        target_loc = int(self.target_location[cav_num0])
        target = self.matrix[cav_num0][target_loc,:]
        dist = np.linalg.norm(target-dat)
        #print 'cav0 dist',dist
        #ind = 0 if start_num==3 else 3
        if flag==False:
            pass
        elif self.lock_flag==False:
            if dist < self.dist_threshold: 
                self.cav0_lockflag=True
                print 'cav0 locked',dist
                #self.randcount=0
            else:
                #self.scancount=self.scancount+1
                self.piezo_center[cav_num0]=self.piezo_center[cav_num0]+40
        else:
            if dist > self.dist_threshold+120:
                self.cav0_lockflag=False
                print 'Unlocked', dist
                #self.scancount=0
                self.piezo_center[cav_num0]=self.piezo_center[cav_num0]-200
            elif dist > self.previous_dist:
                if self.cav0_lockflag2==False:
                    corr[0]=-self.previous_change[0]
                    self.cav0_lockflag2=True
                else :
                    self.previous_dist=dist
                    self.cav0_lockflag2=False
                    self.previous_change[0]=-self.previous_change[0]
            else: 
                self.cav0_lockflag2=False
                corr[0]=randint(-self.limit,self.limit) 
                #self.randcount=self.randcount+1
                self.previous_change=corr
                self.previous_dist=dist
            self.piezo_center[cav_num0]=self.piezo_center[cav_num0]+corr[0]
            if self.piezo_center[cav_num0]<0:
                self.piezo_center[cav_num0]=3890
                self.cav0_lockflag=False
            if self.piezo_center[cav_num0]>4095:
                self.piezo_center[cav_num0]=200
                self.cav0_lockflag=False
            #print 'Move ', correction, self.piezo_center
        return [dist,corr[0]]

    def piezo_peak(self,dat,flag=True):
        corr=[0]
        cav_num1=self.cav_num[1]
        peak_value=dat[4]
        monitor_value=dat[3]+dat[5]
        ratio=float(peak_value)/(float(monitor_value)+0.5)
        start_value=dat[0]
        #ind = 0 if start_num==3 else 3
        if flag==False:
            pass
        elif self.lock_flag==False:
            if peak_value > self.height_limit and ratio >self.entry_ratio: 
                self.lock_flag=True
                print 'locked',peak_value,ratio
                self.randcount=0
            else:
                self.scancount=self.scancount+1
                self.piezo_center[cav_num1]=self.piezo_center[cav_num1]+30
        else:
            if peak_value < self.height_limit-100 or ratio < self.entry_ratio-0.3:
                self.lock_flag=False
                print 'Unlocked', peak_value
                self.scancount=0
                self.piezo_center[cav_num1]=self.piezo_center[cav_num1]-200
            elif ratio < self.previous_ratio or peak_value< self.height_limit:
                if self.lock_flag2==False:
                    corr[0]=-self.previous_move[0]
                    self.lock_flag2=True
                else :
                    self.previous_ratio=ratio
                    self.lock_flag2=False
                    self.previous_move[0]=-self.previous_move[0]
            else: 
                self.lock_flag2=False
                corr[0]=randint(-self.limit,self.limit) 
                self.randcount=self.randcount+1
                self.previous_move=corr
                self.previous_ratio=ratio
            self.piezo_center[cav_num1]=self.piezo_center[cav_num1]+corr[0]
            if self.piezo_center[cav_num1]<0:
                self.piezo_center[cav_num1]=3890
                self.lock_flag=False
            if self.piezo_center[cav_num1]>4095:
                self.piezo_center[cav_num1]=200
                self.lock_flag=False
            #print 'Move ', correction, self.piezo_center
        return [peak_value,monitor_value,ratio,start_value]

    def print_info(self,cav_num,flag=True):
        current_pulse=self.cav_state[cav_num]/float(self.avg_time)
        peak_value=current_pulse[4]
        monitor_value=current_pulse[3]+current_pulse[5]+0.001
        ratio=peak_value/monitor_value
        print 'dist value', self.dist_stored
        print 'current pulse',[int(i) for i in current_pulse]
        print 'control', self.bias,' and ',self.bias_center
        print 'piezo', self.piezo_center
        print 'result', monitor_value,peak_value,ratio
        print 'time',1000*(time.time()-self.timestart)
        print 'speed (Hz)',self.speed
