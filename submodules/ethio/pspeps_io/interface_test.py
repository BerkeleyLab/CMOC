#!/usr/bin/python
import sys
from interfaces import LocalbusInterface
from optparse import OptionParser
import time
from twisted.internet import reactor
import numpy as np

length = 1024
start_addr = 0x80000
#length = 1
#start_addr = 0x90100
use_async = False

def print_time(dat, start_time):
    now = time.time()
    dt_sec = now - start_time
    dat = np.array(dat)
    print dat
    # assert dat.size == length * n_query

    print 'received data shape:', dat.shape
    total_bytes = dat.size * 8

    print('received length (bytes): %d, delay(ms): %.3f:' % (
        total_bytes, dt_sec * 1e3))
    print('Rx throughput %.3f Gbps' % (
        total_bytes * 8 / dt_sec * 1e-9))

def err_cb(err):
    print err

def stop_reactor(dat):
    reactor.stop()

def start_io(addr, port):
    interface = LocalbusInterface(ip=addr, port=port, use_async=use_async)
    interface.start_io()
    print('reading length: %d' % length)
    start_time = time.time()
    d = interface.read_lb_buf(start_addr, length)
    d.addCallback(print_time, start_time).addCallback(interface.close_connection)
    d.addCallbacks(stop_reactor, err_cb)

def main(argv):
    parser = OptionParser()
    parser.add_option("-t", dest="target",
                      default='192.168.21.81', help="target host/IP")
    parser.add_option("-p", dest="port",
                      default=3000, help="UDP port")
    (opts, args) = parser.parse_args()
    start_io(opts.target, opts.port)
    if use_async:
        reactor.run()

if __name__ == "__main__":
    main(sys.argv[1:])
