#!/usr/bin/python
import sys
from twisted.internet import reactor
from app import Application
from optparse import OptionParser
import numpy as np
import logging

# use_async = False
use_async = True
length = 1024

def print_dat(dat):
    print dat

def print_cbuf(target):
    # np.set_printoptions(threshold=np.nan)
    return target.read_cbuf(length).addCallback(print_dat)

def start_io(addr, port):
    target = Application(ip=addr, port=port, use_async=use_async)
    target.get_config_rom().addCallback(target.print_lbnl_rom)
    target.init_regs()
    print_cbuf(target)
    reactor.callLater(.5, reactor.stop)

def main(argv):
    parser = OptionParser()
    parser.add_option("-t", dest="target",
                      default='192.168.1.173',
                      help="target host/IP")
    parser.add_option("-p", dest="port",
                      default=3000,
                      help="UDP port")
    (opts, args) = parser.parse_args()
    _format = "%(levelname)s [%(funcName)20s]: %(message)s"
    logging.basicConfig(level=logging.DEBUG, format=_format)
    start_io(opts.target, opts.port)
    if use_async:
        reactor.run()

if __name__ == "__main__":
    main(sys.argv[1:])
