#!/usr/bin/python
from twisted.internet import reactor, defer, task
from laser_stack_app import LaserStackApp
from laser_bias_sync_control import LaserBiasSynCtrl
from pspeps_io.utilities import CommonUtilities
import time
import logging
logger = logging.getLogger(__name__)

def start_io(addr, port):
    target = LaserBiasSynCtrl(ip=addr, port=port)
    #reactor.listenUDP(0, target)
    #target.get_config_rom().addCallback(target.print_lbnl_rom)
    #t1 = task.LoopingCall(target.bias_control_loop,True)
    target.bias_control_loop(False)

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
