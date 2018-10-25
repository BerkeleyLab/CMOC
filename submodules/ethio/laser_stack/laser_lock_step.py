#!/usr/bin/python
from twisted.internet import reactor, defer, task
from laser_stack_app import LaserStackApp
from laser_lock_step_response import LaserLockControl
from pspeps_io.utilities import *
import time
import logging
logger = logging.getLogger(__name__)

def start_io(addr, port, argv) :
    step=eval(argv[0])
    target = LaserLockControl(ip=addr, port=port, stp=step)
    reactor.listenUDP(0, target)
    target.get_config_rom().addCallback(target.print_lbnl_rom)
    length=200
    reactor.callLater(0.2,target.amplitude_lock_loop,length)
    time_wait=int(length*0.025)
    reactor.callLater(time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(2*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(3*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(4*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(5*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(6*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(7*time_wait,target.amplitude_lock_loop,length)
    reactor.callLater(8*time_wait,reactor.stop)
    
    #t1 = task.LoopingCall(target.amplitude_lock_loop,i)
    #t1.start(20)

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
    reactor.resolve(remote_host).addCallback(start_io, port, argv)
    reactor.run()

if __name__ == "__main__":
    import sys,getopt
    main(sys.argv[1:])
