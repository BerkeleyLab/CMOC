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
        self.piezo_center=[2400,2400,2400,2400] 
        self.diode_offset=[2,1,2]
        self.vector=[]
        self.pulse_number=11
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

    def piezo_update_lookup(self,dat_in,cav_num,avg_time,flagin,feedback_flag=True,pos=(0,7)):
        dat=dat_in/avg_time
        mat = self.matrix[cav_num]
        mat_len = mat.shape[0]
        scan_stp = int(mat_len**0.5/2)
        #print 'scan_stp',scan_stp
        interval = mat_len/360.
        angle = self.target_location[cav_num]
        angle = angel +360 if angle<0 else angle
        target = int(interval*angle)
        #print 'target',target
        min_dist = 2 **62
        posx,posy = pos
        best_match = 10000
        returnflag = False
        threshold = 7
        if flagin==False:
            for i in range(0,mat_len,scan_stp):
                dist = np.linalg.norm(dat[posx:posy]-mat[i,posx:posy])
                best_match = i if dist < min_dist else best_match
                min_dist = dist if dist < min_dist else min_dist
            print 'min_dist 0', min_dist,best_match
            angdiff = (target-best_match)/interval
            diff_list = [angdiff,360.+angdiff,angdiff-360.]
            diff = reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
            returnflag = True if abs(diff) < 50 else False
            #print 'diff 0',diff
        if flagin==True:
            begin,end = (int(target-100*interval),
                         int(target+100*interval))
            trimx,trimy = 0,0
            if end > mat_len:
                trimx,trimy = 0, end-mat_len
                end = mat_len
                trimflag = True
            if begin < mat_len:
                trimx,trimy = 0, end-mat_len
                begin = 0
                trimflag = True
            for i in range(begin,end):
                dist = np.linalg.norm(dat[posx:posy]-mat[i,posx:posy])
                best_match = i if dist < min_dist else best_match
                min_dist = dist if dist < min_dist else min_dist
            angdiff = (target-best_match)/interval
            diff = angdiff
            if trimflag:
                for i in range(trimx,trimy):
                    dist = np.linalg.norm(dat[posx:posy]-mat[i,posx:posy])
                    best_match = i if dist < min_dist else best_match
                    min_dist = dist if dist < min_dist else min_dist
                angdiff = (target-best_match)/interval
                diff_list = [angdiff,360.+angdiff,angdiff-360.]
                diff = reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
            print 'min_dist1', min_dist,best_match
            returnflag = True if min_dist < threshold else False
        correction=int(self.feedback_gain*diff*interval)
        if correction>self.piezo_limit:
            correction =self.piezo_limit
        if correction<-self.piezo_limit:
            correction =-self.piezo_limit
        if feedback_flag:
            self.piezo_center[cav_num]=self.piezo_center[cav_num]+correction
            if self.piezo_center[cav_num]<0:
                self.piezo_center[cav_num],returnflag=2040,False
            if self.piezo_center[cav_num]>4095:
                self.piezo_center[cav_num],returnflag=2040,False
        return [returnflag,diff,correction]
 
    def piezo_update_larry(self,dat,cav_num,length=13):
        flag=True
        vec=self.vector[cav_num]
        interval=self.piezo_interval[cav_num]
        target_angle=self.target_location[cav_num]
        amplitude=np.array(dat[0:length])
        match_unit=amplitude.dot(vec)
        angle=np.angle(match_unit)/np.pi*180.
        current_angle=angle[0]
        diff_list=[target_angle-current_angle,360.+target_angle-current_angle,target_angle-current_angle-360.]
        diff= reduce(lambda x,y: x if abs(x)<abs(y) else y, diff_list)
        correction=int(self.feedback_gain*diff*interval)
        if correction>self.piezo_limit:
            correction = self.piezo_limit
        if correction<-self.piezo_limit:
            correction = -self.piezo_limit/2
        if abs(diff)>self.lock_limit:
            flag = False
        self.piezo_center[cav_num]=self.piezo_center[cav_num]+correction
        if self.piezo_center[cav_num]<0:
            self.piezo_center[cav_num],flag = 2040,False
            #self.lock_flag=False
        if self.piezo_center[cav_num]>4095:
            self.piezo_center[cav_num],flag = 2040,False
        return [flag,diff,correction]
