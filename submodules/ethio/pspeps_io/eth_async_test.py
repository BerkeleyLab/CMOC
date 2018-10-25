#!/usr/bin/python
import sys
from optparse import OptionParser
import time
from twisted.internet import reactor, defer
from eth_async_io import EtherAsyncIO
from eth_sync_test import print_time

length = 1024 * 8
length = 13
n_query = 1000
def err_cb(err):
    print err

def stop_reactor(dat):
    reactor.stop()

def start_io(addr, port):
    protocol = EtherAsyncIO(ip=addr, port=port)
    reactor.listenUDP(port, protocol, maxPacketSize=8192)
    start_time = time.time()
    print('reading length: %d, repeat %d times...' % (length, n_query))
    if 1:
        dlist = [protocol.read_lb_buf(0x84000, length)] * n_query
    else:
        dlist = [protocol.read_mem_gate(xrange(0x84000, 0x84000+length))] * n_query
    defer.gatherResults(dlist).addCallback(print_time, start_time).addCallbacks(stop_reactor, err_cb)

def main(argv):
    parser = OptionParser()
    parser.add_option("-t", dest="target",
                      default='192.168.21.81', help="target host/IP")
    parser.add_option("-p", dest="port",
                      default=3000, help="UDP port")
    (opts, args) = parser.parse_args()
    reactor.resolve(opts.target).addCallback(start_io, opts.port)
    reactor.run()

if __name__ == "__main__":
    main(sys.argv[1:])
