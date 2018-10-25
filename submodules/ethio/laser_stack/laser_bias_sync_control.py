#!/usr/bin/python
from laser_stack_sync import LaserStackSync
import time

class LaserBiasSynCtrl(LaserStackSync):
    """ Laser Bias Control """
    def __init__(self, **kwargs):
        super(LaserBiasSynCtrl, self).__init__(**kwargs)
        self.bias_center = 2033
        self.adc_delay = 0.0001
        self.time_start = time.time()
        self.time_last = self.time_start
        self.print_flag = False
        self.time_limit = 120
        self.time_cost = 0
        # Address definition
        addr0 = self.get_adc_bg_address(0,1)
        addrp = self.get_adc_selected_address(0,34,self.stack_cycle,1)
        addrn = self.get_adc_selected_address(0,35,self.stack_cycle,1)
        addr_c0_min = self.get_adc_selected_address(0,-5,1,20)
        addr_c1_min = self.get_adc_selected_address(1,-5,1,20)
        addr_c0_max = self.get_adc_selected_address(0,-15,1,10)
        addr_c1_max = self.get_adc_selected_address(1,-15,1,10)

        self.addr_list_min = [addrp,addr0,addrn,addr_c0_min,addr_c1_min]
        self.addr_list_max = [addrp,addr0,addrn,addr_c0_max,addr_c1_max]

        self.addr_list = self.addr_list_min
        
        #self.control = False

    def process_adc(self):
        dat = self.read_adc_wfm_addr(self.addr_list)
        result = self.process_adc_group(dat)
        self.time_cost=(time.time()-self.time_start)*1000
        return result

    def bias_control_loop(self,find_min=True):
        flag = False
        cflag = self.bias_direction
        print_int = 200 if find_min else 10
        self.addr_list = self.addr_list_min if find_min else self.addr_list_max
        while flag is False:
            self.print_flag = True #if int(time.time()*200-self.time_start*200)%print_int == 11 else False
            flag = True if time.time()-self.time_start>self.time_limit else False
            control = self.process_adc()
            if self.print_flag is True:
                print 'control data',control[0:3]
                if find_min:
                    print 'channel 0',control[3]
                    print 'channel 1',control[4]
                    print 'bias_center',self.bias_center
                    print 'sum 0',sum(control[3][5:15])
                    print 'sum 1',sum(control[4][5:15])
                else:
                    print 'chan 0',sum(control[3])
                    print 'chan 1',sum(control[4])
                    print 'bias_center',self.bias_center
                    print 'time',self.time_cost
            if control[0] > control[1] > control[2]:
                diff = 5 if cflag else -5
                #  print self.bias_center, 'move ', diff
            elif control[0] < control[1] < control[2]:
                diff = -5 if cflag else 5
                #  print self.bias_center, 'move', diff
            elif find_min is True and control[1]-self.bottom_limit > 0:
                diff = 250 if self.bias_center < 2010 else 250
                #  print self.bias_center,'in the top & move', diff
            elif find_min is False and control[1]-self.bottom_limit < 0:
                diff = 250 if self.bias_center < 2010 else 250
            else:
                difference = self.Kp_bottom*(control[0]-control[2])
                if difference > 2:
                    difference = 2
                if difference < -2:
                    difference = -2
                diff = difference if cflag else -difference
                #  print 'in the bottom',self.bias_center,'move', diff
            #temp = time.time()
            #if self.print_flag:
            #    print 'Operating at',1./(temp-self.time_last),' Hz.'
            #self.time_last = temp
            self.bias_center = self.bias_center + diff if find_min else self.bias_center-diff
            if self.bias_center > 4095:
                self.bias_center = 10
            elif self.bias_center < 0:
                self.bias_center = 4085
            self.write_slowdac_wfm({200:int(self.bias_center),0x701:0,0x700:0})
        return control

    def process_adc_group(self,dat):
        data = [sum(dat[0]), sum(dat[1]), sum(dat[2]),dat[3],dat[4]]
        #  print 'data after process',data
        return data
