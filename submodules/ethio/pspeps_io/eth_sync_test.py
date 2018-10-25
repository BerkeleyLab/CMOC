#!/usr/bin/python
import sys
import time
import numpy as np
from optparse import OptionParser
from eth_sync_io import EtherSyncIO

length = 1024 * 8
length = 13
n_query = 1000
start_addr = 0x84000

def print_time(dat, start_time):
    now = time.time()
    dt_sec = now - start_time
    dat = np.array(dat)
    # assert dat.size == length * n_query

    print 'received data shape:', dat.shape
    total_bytes = dat.size * 8

    print('received length (bytes): %d, delay(ms): %.3f:' % (
        total_bytes, dt_sec * 1e3))
    print('Rx throughput %.3f Gbps' % (
        total_bytes * 8 / dt_sec * 1e-9))

def start_io(addr, port):
    target = EtherSyncIO(ip=addr, port=port)
    target.make_connection()

    print('reading length: %d, repeat %d times...' % (length, n_query))
    start_time = time.time()
    dat = [target.read_lb_buf(start_addr, length) for ix in xrange(n_query)]
    print_time(dat, start_time)
    target.close_connection()

def main(argv):
    parser = OptionParser()
    parser.add_option("-t", dest="target",
                      default='192.168.21.81',
                      help="target host/IP")
    parser.add_option("-p", dest="port",
                      default=3000,
                      help="UDP port")
    (opts, args) = parser.parse_args()
    start_io(opts.target, opts.port)

if __name__ == "__main__":
    main(sys.argv[1:])
