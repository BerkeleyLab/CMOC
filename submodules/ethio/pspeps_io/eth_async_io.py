from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor, defer, task
from eth_io import EthIO
from datetime import datetime
import socket

class EtherAsyncIO(DatagramProtocol, EthIO):
    """
    Asynchronous UDP IO class for PSPEPS local bus access through mem_gateway
    """
    def __init__(self, **kwargs):
        self.cb_set = {}
        super(EtherAsyncIO, self).__init__(**kwargs)

    def make_connection(self, max_packet_size=8192):
        # self.udp = reactor.listenUDP(
        #     self.port_num, self, maxPacketSize=max_packet_size)
        # self.startProtocol()
        pass

    def close_connection(self, *args):
        self.stopProtocol()

    def startProtocol(self):
        self.host = socket.gethostbyname(self.ip)
        self.transport.connect(self.host, self.port_num)

    def datagramReceived(self, data, (host, port)):
        """
        Fire Deferred callback function based on packet head
        Reload parent class
        """
        p_head = data[0:8]
        if p_head in self.cb_set:
            d = self.cb_set[p_head]  # Deferred object
            if d is not None:
                d.callback(data)  # data includes head
            del self.cb_set[p_head]  # don't need to handle it again
        else:
            raise ValueError("Stray Rx head", "".join(["%2.2x" % ord(x) for x in p_head]))

    def send_packets(self, payload):
        if (len(payload) < 10):
            raise ValueError('UDP payload size %d < 10' % len(payload))
        if not self.transport:
            raise ValueError('Connection not made.')
        p_head = self.build_head()
        self.transport.write(p_head + payload)
        return p_head

    def write_mem_gate(self, alist, dlist):
        """
        Write memory gateway dat is zipped pair list of
        addr,val. len(alist) < 256
        """
        p_head = self.write_mem_gate_cmd(alist, dlist)
        self.cb_set[p_head] = None

    def read_mem_gate(self, alist):
        """
        Non-blocking read from mem_gate
        Insert read request into queue
        Add callback for response data assembly
        """
        p_head = self.read_mem_gate_cmd(alist)
        d = defer.Deferred().addCallback(self.decode_read_dat)
        self.cb_set[p_head] = d
        return d

    def read_lb_buf(self, reg_addr, reg_size):
        """ Break long reading request into multiple readings at size of 0x80 """
        alist = xrange(reg_addr, reg_addr + reg_size)
        dlist = [self.read_mem_gate(ax) for ax in self.chunks(alist, 0x80)]
        return defer.gatherResults(dlist, consumeErrors=True).addCallback(self.flatten_darray)

    @defer.inlineCallbacks
    def read_lb_reg(self, reg_addr):
        """ Read single register """
        d = yield self.read_mem_gate([reg_addr])
        defer.returnValue(d[1])
