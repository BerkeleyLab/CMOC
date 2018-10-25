#!/usr/bin/python
from twisted.internet import defer, reactor
from laser_lock_one_cav import LaserLockControl
from matplotlib import pyplot as plt
import numpy as np
class LaserLockPMScan(LaserLockControl):
    """ Laser Phase Calibration """
    def __init__(self, **kwargs):
        super(LaserLockPMScan, self).__init__(**kwargs)
        #self.matrix=np.loadtxt('april29_c1_d1.txt')
        self.peak_list=[]
        self.ratio_list=[]

    @defer.inlineCallbacks
    def pm_cali_lock_loop(self,index):
        ind = index.next()
        print ind
        self.peak_list=[]
        self.ratio_list=[]
        cav_num = self.cav_num
        v = self.am_pm_delay
        d0 =self.prep_pm_one_cav_new(self.dac_len,v,ind)
        dac0_addr = 0x31000
        self.count=0
        self.write_dac_dpram(dac0_addr,d0)
        peak_list,ratio_list,first_list,time,count= yield self.amplitude_lock_update(200)
        ratio = np.mean(ratio_list)
        peak = np.mean(peak_list)
        first = np.mean(first_list)
        print 'ind: ',ind,'peak: ',peak,'ratio: ',ratio,'first: ',first
        print 'time:',time*1000,' count:',count
        self.peak_list.append(peak)
        self.ratio_list.append(ratio)

