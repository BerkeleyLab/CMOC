import abc
from struct import pack
from random import getrandbits
from binascii import hexlify

class EthIO(object):
    """
    Abstract protocal of PSPEPS
    """
    __metaclass__ = abc.ABCMeta

    def __init__(self, **kwargs):
        super(EthIO, self).__init__()
        self.ip = kwargs.get('ip', '')
        self.port_num = kwargs.get('port', 3000)

    def encode_address(self, address):
        """ Encode an integer as three bytes """
        return pack('!i', address)[1:4]

    def build_head(self):
        p_head = pack('Q', getrandbits(64))
        return p_head

    @abc.abstractmethod
    def close_connection(self, *args):
        pass

    @abc.abstractmethod
    def send_packets(self, payload):
        pass

    @abc.abstractmethod
    def write_mem_gate(self, alist, dlist):
        pass

    @abc.abstractmethod
    def read_mem_gate(self, alist, dlist):
        return

    def write_mem_gate_cmd(self, alist, dlist):
        """
        Write local bus address list
        [8bytes header, 4bytes addr, 4bytes data, 4byts addr, ...]
        """
        dat = zip(alist, dlist)
        # min udp length requires at least two query
        if len(dat) < 2:
            dat.append(dat[0])
        payload = ''.join([
            '\x00' + self.encode_address(ad) + pack('!I', val) for ad, val in dat])
        p_head = self.send_packets(payload)
        return p_head

    def chunks(self, l, n):
        """Yield successive n-sized chunks from l."""
        for i in xrange(0, len(l), n):
            yield list(l)[i:i+n]

    def write_lb_list(self, alist, dlist):
        """
        Breakdown long writes into atom actions of 128 length
        """
        al = self.chunks(alist, 0x80)
        dl = self.chunks(dlist, 0x80)
        for ax, dx in zip(al, dl):
            self.write_mem_gate(ax, dx)

    @abc.abstractmethod
    def read_lb_buf(self, reg_addr, reg_size):
        pass

    def read_mem_gate_cmd(self, alist):
        """
        Read local bus address list
        [8bytes header, 4bytes addr, 4bytes data, 4byts addr, ...]
        """
        if (len(alist) > 128):
            raise ValueError('read_mem_gate_cmd length %d > 128' % len(alist))
        # min udp length requires at least two query
        if len(alist) < 2:
            alist.append(alist[0])
        payload = ''.join(['\x10' + self.encode_address(ad) + 4*' ' for ad in alist])
        return self.send_packets(payload)

    def flatten_darray(self, dat):
        return [item for sublist in dat for item in sublist]

    def decode_read_dat(self, dat):
        """
        Assemble read response data, format:
        [8bytes header, 4bytes addr, 4bytes data, 4byts addr, ...]
        """
        return [int(hexlify(dat[12+8*ix:16+8*ix]), 16) for ix in
                xrange(0, (len(dat) - 8) / 8)]
