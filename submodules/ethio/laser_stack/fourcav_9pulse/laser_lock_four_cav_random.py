#!/usr/bin/python`
from twisted.internet import defer, reactor
from laser_stack_app import LaserStackApp
from laser_phase_four_cav import LaserPhase
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
        self.avg_time=10
        self.piezo_interval=[2.81,5.3,2.81,2.8]
        self.full_range=np.array(self.piezo_interval)*200
        self.cav_state=[np.zeros(self.pulse_number)]*4
        self.piezo_temp=[0,0]

        
        self.count=0
        self.entry_ratio=1.0
        self.height_limit=self.avg_time*400
        
        self.feedback_gain=0.4
        self.bias=[0,0,0]
        self.timestart=time.time()
        self.lock_flag=False
        self.lock_flag2=True
        #self.phase_error=[[],[],[]]
        self.last_time=time.time()
        self.speed=20
        self.previous_move=[0,0,0,0]
        self.previous_max=150
        self.previous_min=1000
        self.previous_ratio=0.5
        self.randcount=0
        self.scancount=0
        self.limit=[15,20,15,10]
        self.min_search=300
        self.bias_flag=False
       
        #addr0 = self.get_adc_bg_address(0,1)
        #addrp = self.get_adc_selected_address(0,30,self.stack_cycle,1)
        #addrn = self.get_adc_selected_address(0,31,self.stack_cycle,1)
        #addr_cali = self.get_adc_selected_address(1,0,self.stack_cycle,6)
        #self.addr_list = [addrp,addr0,addrn,addr_cali]

    @defer.inlineCallbacks
    def amplitude_lock_update(self,length=0):
        cav_num_last = 3
        peak_list, peak_rms = [],[]
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
            input_info={}
            for cav_num in range(4):
                input_info[self.cav_addr[cav_num]]=int(self.piezo_center[cav_num])
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
                    self.cav_state=[np.zeros(self.pulse_number)]*4
                    for i in xrange(self.avg_time):
                        d2 = defer.Deferred().addCallback(self.read_diode_output,cav_num_last)
                        reactor.callLater(self.adc_delay,d2.callback,'')
                        control = yield d2
                        data = control[0]
                        #print data
                        self.cav_state[cav_num_last]=self.cav_state[cav_num_last]+np.array(control[0])
                    if self.feedback_gain==0:
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num_last],False)
                    else:
                        max_value,min_value,ratio,first_value=self.piezo_peak(self.cav_state[cav_num_last],True)
                    temp=time.time()
                    self.speed= 1./(temp-self.last_time)
                    self.last_time=temp
                    if print_flag==True:
                        if self.lock_flag:
                            self.print_info(cav_num_last)
                        else:
                            current_pulse=self.cav_state[cav_num]/float(self.avg_time)
                            print 'pulse now:',[int(pulse) for pulse in
                                    current_pulse]
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


    def piezo_peak(self,dat,flag=True):
        corr=[0,0,0,0]
        peak_value=dat[8]
        #print peak_value
        monitor_value=dat[5]+dat[6]+dat[7]+dat[9]
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
                self.piezo_center[0]=2700+self.full_range[0]*np.sin(0.55*0.8*self.scancount/300.)
                self.piezo_center[1]=2500+self.full_range[1]*np.sin(0.55*self.scancount/300.)
                self.piezo_center[2]=2500+self.full_range[2]*np.sin(0.8*self.scancount/300.)
                self.piezo_center[3]=2300+self.full_range[3]*np.sin(1.0*self.scancount/300.)
        else:
            if peak_value < self.height_limit*0.7 or ratio <self.entry_ratio-0.5:
                self.lock_flag=False
                print 'Unlocked', peak_value
                self.scancount=0
                #for num in range(4):
                #    self.piezo_center[num]=2400
            elif ratio < self.previous_ratio or peak_value< self.height_limit:
                if self.lock_flag2==False:
                    for i in range(4):
                        corr[i]=-self.previous_move[i]
                    self.lock_flag2=True
                else :
                    self.previous_ratio=ratio
                    self.lock_flag2=False
                    for i in range(4):
                        self.previous_move[i]=-self.previous_move[i]
            else: 
               self.lock_flag2=False
   
               corr[0]=randint(-self.limit[0],self.limit[0]) if self.randcount%11==7 else 0
               corr[1]=randint(-self.limit[1],self.limit[1]) if self.randcount%7==2 else 0
               corr[2]=randint(-self.limit[2],self.limit[2]) if self.randcount%5==3 else 0
               corr[3]=randint(-self.limit[3],self.limit[3]) 
               self.randcount=self.randcount+1
               self.previous_move=corr
               self.previous_ratio=ratio
            for num in range (4):
                self.piezo_center[num]=self.piezo_center[num]+corr[num]
                if self.piezo_center[num]<0:
                    self.piezo_center[num]=3890
                    self.lock_flag=False
                if self.piezo_center[num]>4095:
                    self.piezo_center[num]=200
                    self.lock_flag=False
            #print 'Move ', correction, self.piezo_center
        return [peak_value,monitor_value,ratio,start_value]

    def print_info(self,cav_num,flag=True):
        current_pulse=self.cav_state[cav_num]/float(self.avg_time)
        peak_value=current_pulse[8]
        monitor_value=current_pulse[6]+current_pulse[7]+current_pulse[9]+0.001
        ratio=peak_value/monitor_value
        print 'current pulse',[int(i) for i in current_pulse]
        print 'control', self.bias,' and ',self.bias_center
        print 'piezo', self.piezo_center
        print 'result', monitor_value,peak_value,ratio
        print 'time',1000*(time.time()-self.timestart)
        print 'speed (Hz)',self.speed
