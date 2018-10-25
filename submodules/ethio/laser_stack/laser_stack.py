#!/usr/bin/python
import os, sys
base_dir = os.path.dirname(os.path.abspath(__file__)) or '.'
pspeps_dir = os.path.join(base_dir, '..')
if pspeps_dir not in sys.path: sys.path.insert(0, pspeps_dir)

from twisted.internet import reactor, defer, task
from laser_stack_app import LaserStackApp
from pspeps_io.utilities import *
import time
import logging
logger = logging.getLogger(__name__)

def start_io(addr, port, init):
    target = LaserStackApp(ip=addr, port=port)
    target.get_config_rom().addCallback(target.print_lbnl_rom)
    if init:
        target.init()
        reactor.callLater(0.3,target.read_diag)
        reactor.callLater(0.4,target.read_mon)
        reactor.callLater(0.8, reactor.stop)
    else:
        if (0):
            t1 = task.LoopingCall(target.read_adc_print)
            reactor.callLater(0.8, reactor.stop)
        else:
            pass
            target.prep_plot()
            t1 = task.LoopingCall(target.read_adc_plot)
        t1.start(0.1)

        #from itertools import cycle
        #i = cycle([{200:int(1.0*v/2.5)} for v in range(0,2<<11,400)])
        #t2 = task.LoopingCall(target.write_slowdac_wfms, i)
        #t2.start(0.1)


def main(argv):
    FORMAT = "%(levelname)-8s %(module)s: %(message)s"
    try:
        opts, args = getopt.getopt(argv, 'hoa:t:id',['help','target='])
    except getopt.GetoptError as err:
        print str(err)
        sys.exit(2)
    remote_host = 'ml605'
    init = False
    debug = False
    port = 3000
    for opt,arg in opts:
        if opt in ('-h', '--help'):
            print '<file_name>.py -t <target> [-i]'
            sys.exit()
        elif opt in ('-t', '--target'):
            remote_host = arg
        elif opt in ('-i', '--init'):
            init = True
        elif opt in ('-d', '--debug'):
            debug = True
    if debug:
        logging.basicConfig(level=logging.DEBUG, format=FORMAT)
    else:
        logging.basicConfig(level=logging.INFO, format=FORMAT)
    reactor.resolve(remote_host).addCallback(start_io, port, init)
    reactor.run()

if __name__ == "__main__":
    import sys,getopt
    main(sys.argv[1:])
