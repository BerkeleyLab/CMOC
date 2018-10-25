#!/usr/bin/python
import sys
import socket
import struct
import time
import logging
import sys,getopt
import os
import random
import numpy
from matplotlib import pyplot as plt


IPADDR = os.environ.get('IP_ADDR')
if IPADDR is None: IPADDR = 'rflab1.lbl.gov'  # 128.3.128.122

PORTNUM = 3000

global plot_ena, slow_ena
plot_ena=0
slow_ena=0

def three_bytes(ad):
    " encode an integer as three bytes "
    adx = struct.pack('!i',ad)
    return adx[1:4]

def mem_gate_write_prep(alist, dlist):
    " write register through mem_gateway "
    p  = struct.pack('!I',random.getrandbits(32))
    p += struct.pack('!I',random.getrandbits(32))
    for ix,ad in enumerate(alist):
            # read commands include space for result
            # print dlist[ix]
            p += '\x00' + three_bytes(ad) + struct.pack('!I',dlist[ix])
    #print p.encode('hex')
    return p

def mem_gate_write(s,p):
    s.send(p)
    r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
    #print r.encode('hex')
    if (r[0:8] != p[0:8]):
            print "header mismatch"
            sys.exit(2)
    #res=[]  # build up result list here
    #for ix in range(0, len(alist)):
    #        rh = (r[12+8*ix:16+8*ix])
    #        res.append(struct.unpack('!I',rh)[0])
    ##        print "%6.6x: %s"%(alist[ix], rh.encode('hex'))
    #return res

def mem_gate_read(s, alist):
    " read config_romx "
    p  = struct.pack('!I',random.getrandbits(32))
    p += struct.pack('!I',random.getrandbits(32))
    for ad in alist:
            # read commands include space for result
            p += '\x10' + three_bytes(ad) + 4*' '
    s.send(p)
    r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
    if (r[0:8] != p[0:8]):
            print "header mismatch"
            sys.exit(2)
    ra = r[ 8:12]
    if (alist[0] + 0x10000000 != int(ra.encode('hex'),16)):
        print 'echo first address %x %x'%(alist[0],int(ra.encode('hex'),16))
    res=[]  # build up result list here
    for ix in range(0, len(alist)):
            rv = r[12+8*ix:16+8*ix]
            int_value=int(rv.encode('hex'),16)
            res.append(int_value)
    return res

def decode_lbnl_rom(dat):
    " decode content of config_romx "
    d = numpy.bitwise_and(dat, 0xff)
    if (d[0] == 85):

        user_l={1:"ldoolitt",2:"cswanson",3:"kasemir",4:"hengjie",5:"crofford",6:"meddeler",7:"baptiste",8:"llrf_oper",9:"hyaver",10:"dim",11:"begcbp",12:"ghuang",13:"luser",14:"kstefan",15:"cserrano",16:"asalom",17:"du",18:"yangjin",19:"lilima",20:"ernesto"}
	user = user_l[d[9]] if d[9] in user_l else "unknown"

        board_l={1:"mebt",2:"interim",3:"fcm",4:"avnet",5:"uxo",6:"llrf4",7:"av5t",8:"sp601",9:"sp605",10:"ml505",11:"ml506",12:"fllrf",13:"spec",14:"lx150t",15:"cute_wr",17:"ac701",18:"ml605",19:"kc705",99:"test"}
	board = board_l[d[10]] if d[10] in board_l else "unknown"

        print "DSP flavor: %d"%d[1]
        print "build date: %4.4d-%2.2d-%2.2d"%(d[2]+2000,d[3],d[4])
        print "build time: %2.2d:%2.2d UTC"%(d[5],d[6])
        print "tool rev:   %d.%d"%(d[8]/16,d[8]%16)
        print "user:       %d (%s)"%(d[9],user)
        print "board type: %d (%s)"%(d[10],board)
        gs=""
        for ix in range(0,20):
            gs+=chr(d[12+ix])
        print "git commit: %s"%(gs.encode('hex'))
        if d[32] == 170:
            print "circle_aw:    %d"%d[33]
            print "mode_count:   %d"%d[34]
            print "mode_shift:   %d"%d[35]
            print "n_mech_modes: %d"%d[36]
            print "df_scale:     %d"%d[37]
            print "simple_demo:  %d"%d[38]
    else:
        print "no magic found %d"%d[0]

# circle_count, circle_stat, adc min/max (6 words), tag_now, tag_old, timestamp
def slow_decode(aux):
    a = [aux[2*ix]*256+aux[2*ix+1] for ix in range(0,2)]  # circle_buf.v
    b = [aux[2*ix]*256+aux[2*ix+1] for ix in range(2,8)]
    b = [bb if bb<32767 else bb-65536 for bb in b]  # 3 x ADC min/max
    tag_now = aux[16]
    tag_old = aux[17]
    c = aux[26:17:-1]  # timestamp.v
    t = 0
    for cc in c: t=t*256+cc
    t = t/32   # five false bits at bottom; this converts to actual clock ticks
    #if not plot_ena:
    if 1:
	 print a, b, tag_now, tag_old, t

# New!
def acknowledge_buffer(s):
    mem_gate_write(s,mem_gate_write_prep([0,0,0,0,0,0x3800,0],[0,0,0,0,0,1,0]));

def read_mem_buf(s):
    res=[]
    while (not mem_gate_read(s,range(0,32))[0]>>8&1):
        print 'circular buffer not ready yet'
        time.sleep(0.02)
    aux = mem_gate_read(s,range(0x2011,0x2031)) # "slow" readout registers
    if slow_ena:
        slow_decode(aux)
    for index in range(0x4000,0x6000,0x40):
        res.extend(mem_gate_read(s,range(index,index+0x40)))
    # assume 8 bits selected in ch_keep
    acknowledge_buffer(s)
    return [res,aux]

def setup_sock():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    s.connect((IPADDR, PORTNUM))

    # set up for address decoder in cryomodule.v, not larger.v
    rom = mem_gate_read(s, range(0x10000,0x10000+48))
    decode_lbnl_rom(rom)
    return s

# Main procedure
def main(argv):
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    s = setup_sock()
    if argv[0] == "config":
        exit(0)

    if plot_ena:
        fig=plt.figure(1)
        fig.show()

    # send the address/value pairs created by param.py to the hardware
    with open('larger_in.dat', 'r') as f:
        addr_value=f.read().split('\n')
    addr=[]
    value=[]
    for line in addr_value:
        #if line:
        #    (ad, vd) = map(int, line.split())
        #    addr.append(ad)
        #    value.append(vd)
        aa=line.split()
        if aa:
            addr.append(int(aa[0]))
            v=int(aa[1])
            if (v<0): v += 2**32
            value.append(v)
    mem_gate_write(s,mem_gate_write_prep(addr,value));

    fcnt=0;
    while (fcnt < 10 or plot_ena):
        #mem_gate_write(s,mem_gate_write_prep(addr,value));
        [res,aux]=read_mem_buf(s)
        varray=numpy.array([x-65536 if x>32767 else x for x in res]).reshape([1024,8])
#        numpy.savetxt("live%d.dat"%fcnt,res,'%6.0f')
        fcnt += 1
        if plot_ena:
            plt.plot(varray)
            fig.canvas.draw()
            fig.clf()
        else:
            print "not a plot",fcnt
    s.close()

if __name__ == "__main__":
    argv = sys.argv[1:]
    plot_ena = 'plot' in argv
    slow_ena = 'slow' in argv
    if plot_ena: from matplotlib import pyplot as plt
    main(argv)
