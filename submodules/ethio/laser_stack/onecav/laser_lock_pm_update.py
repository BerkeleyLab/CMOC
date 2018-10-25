#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_lock_one_cav import LaserLockControl
from matplotlib import pyplot as plt
from random import randint
import numpy as np
class LaserLockPMUpdate(LaserLockControl):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockPMUpdate, self).__init__(**kwargs)
        #self.target_location=425#498#, 380
        #self.matrix=np.loadtxt('april29_c1_d1.txt')
    
        self.offset=0
        self.previous_offset_change=0
        self.previous_save_ratio=10

    @defer.inlineCallbacks
    def pm_lock_update(self,index):
        ind = index.next()
        offset_change=0
        if ind%5==2:
            offset_change=randint(-3,3)
            self.offset=self.offset+offset_change
            print 'offset_change',offset_change
        cav_num = self.cav_num
        v = self.am_pm_delay
        d0 =self.prep_pm_one_cav_new(self.dac_len,v,self.offset)
        dac0_addr = 0x31000
        self.count=0
        self.write_dac_dpram(dac0_addr,d0)
        return_group = yield self.amplitude_lock_update(100)
        ratio=return_group[1]
        first=np.mean(return_group[2])/self.avg_time
        peak=np.mean(return_group[0])/self.avg_time
        print 'current ratio',np.mean(ratio)
        print 'current peak',np.mean(peak)
        print 'first pulse',np.mean(first)
        print 'time',return_group[3]*1000
        print 'scan',return_group[4]
        if ind%5==2 and ratio<self.previous_save_ratio:
            self.offset=self.offset-offset_change
            print 'bad move',offset_change
        elif ind%5==2:
            print 'good move',offset_change
        else:
            pass
        self.previous_save_ratio=ratio
        print 'current offset',self.offset

