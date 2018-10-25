#!/usr/bin/python
import os,sys
base_dir = os.path.dirname(os.path.abspath(__file__) or '.')
stack_dir = os.path.join(base_dir,'..')
if stack_dir not in sys.path: sys.path.insert(0,stack_dir)

from twisted.internet import reactor, defer, task
from laser_stack_app import LaserStackApp
from laser_control_larry import LaserLockControl
from pspeps_io.utilities import *
import time
import logging
logger = logging.getLogger(__name__)

def start_io(addr, port):
    target = LaserLockControl(ip=addr, port=port)
    # async
    #target.get_config_rom().addCallback(target.print_lbnl_rom)
    #from itertools import cycle
    #i = cycle(range(10000000))
    #t1 = task.LoopingCall(target.lock_loop,False)

    # sync 
    target.lock_loop()
    t1.start(100)

def main(argv):
    FORMAT = "%(levelname)-8s %(module)s: %(message)s"
    try:
        opts, args = getopt.getopt(argv, 'hoa:t:id',['help','target='])
    except getopt.GetoptError as err:
        print str(err)
        sys.exit(2)
    remote_host = 'ml605'
    debug = False
    port = 3000
    for opt,arg in opts:
        if opt in ('-h', '--help'):
            print '<file_name>.py -t <target> [-i]'
            sys.exit()
        elif opt in ('-t', '--target'):
            remote_host = arg
        elif opt in ('-d', '--debug'):
            debug = True
    if debug:
        logging.basicConfig(level=logging.DEBUG, format=FORMAT)
    else:
        logging.basicConfig(level=logging.INFO, format=FORMAT)
    reactor.resolve(remote_host).addCallback(start_io, port)
    reactor.run()

if __name__ == "__main__":
    import sys,getopt
    main(sys.argv[1:])
