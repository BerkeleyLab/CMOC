import socket
from eth_io import EthIO

class EtherSyncIO(EthIO):
    def __init__(self, **kwargs):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        super(EtherSyncIO, self).__init__(**kwargs)

    def make_connection(self):
        self.socket.connect((self.ip, self.port_num))

    def close_connection(self, *args):
        self.socket.close()

    def send_packets(self, payload):
        if (len(payload) < 10):
            raise ValueError('UDP payload size %d < 10' % len(payload))
        p_head = self.build_head()
        self.socket.send(p_head + payload)
        return p_head

    def receive_data(self, p_head):
        dat, addr = self.socket.recvfrom(1024+8)
        if (dat[0:8] != p_head[0:8]):
            raise ValueError('Header mismatch!')
        return dat

    def write_mem_gate(self, alist, dlist):
        """
        Write memory gateway dat is zipped pair list of
        addr,val. len(alist) < 256
        """
        p_head = self.write_mem_gate_cmd(alist, dlist)
        self.receive_data(p_head)

    def read_mem_gate(self, alist):
        """
        Blocking read from mem_gate
        """
        p_head = self.read_mem_gate_cmd(alist)
        dat = self.receive_data(p_head)
        return self.decode_read_dat(dat)

    def read_lb_buf(self, reg_addr, reg_size):
        """ Break long reading request into multiple readings at size of 0x80 """
        alist = xrange(reg_addr, reg_addr + reg_size)
        dat = [self.read_mem_gate(ax) for ax in self.chunks(alist, 0x80)]
        return self.flatten_darray(dat)

    def read_lb_reg(self, reg_addr):
        """ Read single register """
        return self.read_mem_gate([reg_addr])[1]

def main():
    start_addr = 0x90003
    length = 3
    target = EtherSyncIO(ip="192.168.1.7", port=3000)
    dat = target.read_lb_buf(start_addr, length)
    print [hex(i) for i in dat]

if __name__ == "__main__":
    main()
