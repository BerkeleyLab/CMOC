#!/usr/bin/python
import struct
import zlib
from twisted.internet import defer, reactor, task
from eth_sync_io import EtherSyncIO
from eth_async_io import EtherAsyncIO
from utilities import encode_2s_comp
from registers import RegMap
from numpy import bitwise_and
from datetime import datetime
from binascii import hexlify
import time
import logging
logger = logging.getLogger().getChild(__name__)

class LocalbusInterface(RegMap):
    """
    Integration of blocking and non-blocking implementation of EthIO with same
    interface.
    """
    def __init__(self, **kwargs):
        self._async = kwargs.get('use_async', True)
        self._port_num = kwargs.get('port', 3000)
        super(LocalbusInterface, self).__init__(**kwargs)
        if self._async:
            self.protocol = EtherAsyncIO(**kwargs)
        else:
            self.protocol = EtherSyncIO(**kwargs)

    def start_io(self):
        if self._async:
            self.port = reactor.listenUDP(self._port_num, self.protocol, maxPacketSize=8192)
        self.protocol.make_connection()

    def stop_io(self):
        if self._async:
            self.port.stopListening()

    def close_connection(self, *args):
        return self.protocol.close_connection(*args)

    def write_mem_gate(self, alist, dlist):
        return defer.maybeDeferred(self.protocol.write_mem_gate, alist, dlist)

    def read_lb_reg(self, reg_addr):
        return defer.maybeDeferred(self.protocol.read_lb_reg, reg_addr)

    def read_mem_gate(self, alist):
        return defer.maybeDeferred(self.protocol.read_mem_gate, alist)

    def read_lb_buf(self, reg_addr, reg_size):
        return defer.maybeDeferred(self.protocol.read_lb_buf, reg_addr, reg_size)

    def write_lb_list(self, alist, dlist):
        return defer.maybeDeferred(self.protocol.write_lb_list, alist, dlist)

    def write_dac_dpram(self, dac_addr, dac_data):
        """write arbitary waveform to dac buffer """
        alist = range(dac_addr, dac_addr+len(dac_data))
        self.write_lb_list(alist, dac_data)

    def get_json_rom(self, addr=0, length=2048):
        return defer.maybeDeferred(self.read_lb_buf, addr, length).addCallback(self.decode_json_rom)

    def decode_json_rom(self, dat):
        a = dat
        rec_num = 0
        result = []
        while len(a):
            clen = a[0]
            flag = clen >> 14
            clen = clen & 0x3fff
            data = a[1:clen+1]
            a = a[clen+1:]
            # print clen, flag
            if flag == 0:
                break
            print("Record %d type %d length %d" % (rec_num, flag, clen))
            if flag == 1:
                # print struct.pack("!"+"H"*len(data), *data)
                result += [struct.pack("!"+"H"*len(data), *data)]
            elif flag == 2:
                # print "".join([format(x, "04x") for x in data])
                result += ["".join([format(x, "04x") for x in data])]
            elif flag == 3:
                zipped = struct.pack("!"+"H"*len(data), *data)
                result += [zlib.decompress(zipped)]
            rec_num += 1
        return result

    def get_lbnl_rom(self, addr=0):
        return defer.maybeDeferred(self.read_mem_gate, xrange(addr, addr+0x30)).addCallback(self.decode_lbnl_rom)

    def decode_lbnl_rom(self, dat):
        """ Decode content of config_romx """
        d = bitwise_and(dat, 0xff)
        _rom_board = {
            0: "unknown",
            1: "mebt", 2: "interim", 3: "fcm", 4: "avnet", 5: "uxo", 6: "llrf4",
            7: "av5t", 8: "sp601", 9: "sp605", 10: "ml505", 11: "ml506",
            12: "fllrf", 13: "spec", 14: "lx150t", 15: "cute_wr",
            17: "ac701", 18: "ml605", 19: "kc705", 20: "bmb7", 99: "test"}
        _rom_user = {
            1: "ldoolitt", 2: "cswanson", 3: "kasemir", 4: "hengjie",
            5: "crofford", 6: "meddeler", 7: "baptiste", 8: "llrf_oper",
            9: "hyaver", 10: "dim", 11: "begcbp", 12: "ghuang", 13: "luser",
            14: "kstefan", 15: "cserrano", 16: "asalom", 17: "du",
            21: "vkvytla", 0: "unknown"}
        rom = {}
        if (d[0] == 85):
            dtime = datetime(d[2]+2000, d[3], d[4], d[5], d[6])
            rom['DSP flavor'] = '{:d}'.format(d[1])
            rom['Build date'] = '{:%Y-%m-%d}'.format(dtime)
            rom['Build time'] = '{:%H:%M:%S} UTC'.format(dtime)
            rom['Tool rev'] = '{0:d}.{1:d}'.format(d[8]/16, d[8] % 16)
            rom['User'] = '{0:d} ({1})'.format(d[9], _rom_user[d[9]])
            rom['Board type'] = '{0:d} ({1})'.format(d[10], _rom_board[d[10]])
            gs = "".join(chr(d[12+ix]) for ix in xrange(0, 20))
            rom['git commit'] = hexlify(gs)[:6]
            if d[32] == 170:
                rom['circle_aw'] = '{:d}'.format(d[33])
                rom['mode_count'] = '{:d}'.format(d[34])
                rom['mode_shift'] = '{:d}'.format(d[35])
                rom['n_mech_modes'] = '{:d}'.format(d[36])
                rom['df_scale'] = '{:d}'.format(d[37])
                rom['simple_demo'] = '{:d}'.format(d[38])
        return rom

    def write_reg_dict(self, reg_dict):
        """ Write register list based on name:value dictionary """
        assert isinstance(reg_dict, dict)
        al = []
        dl = []
        for (k, v) in reg_dict.iteritems():
            reg = self.get_reg_by_name(k)
            reg.value = v
            al.append(reg.address)
            dl.append(encode_2s_comp(reg.value, reg.width))
        # logger.debug('name: %r\n zip(alist, dlist): %r\n', reg_dict.keys(), zip(al, dl))
        self.write_lb_list(al, dl)

    def write_regs(self, regs):
        """
        Write register list on to the device.
        First update the DB, then issue a write to the device
        regs: A list of [(address/name, value) .. ] pairs
        """
        assert isinstance(regs, list)
        al = []
        dl = []
        written_regs = []
        for r in regs:
            if type(r[0]) is int:
                reg = self.get_reg_by_addr(r[0])
            else:
                reg = self.get_reg_by_name(r[0])
            reg.value = r[1]
            written_regs.append(reg)
            al.append(reg.address)
            dl.append(encode_2s_comp(reg.value, reg.width))
        logger.debug('name: %r\n zip(alist, dlist): %r\n', regs, zip(al, dl))
        self.write_lb_list(al, dl)
        return written_regs

    def print_lbnl_rom(self, rom_dict):
        for key in rom_dict.keys():
            print("%s, %s" % (key, rom_dict[key]))

    def read_lb_regs(self, reg_names):
        """Read multiple registers in a list"""
        reg_addrs = map(self.get_reg_addr, reg_names)
        return self.read_mem_gate(reg_addrs)

    def read_lb_regname(self, reg_name):
        """Read multiple registers in a list"""
        reg_addr = self.get_reg_addr(reg_name)
        return self.read_lb_reg(reg_addr)

    def eb_print(self, failure):
        r = failure.trap(ValueError, TypeError)
        if r is ValueError:
            logger.warning('Failed retrying: %r', failure.getErrorMessage())
        else:
            logger.warning('Failed reading: %r', failure.getErrorMessage())

    @defer.inlineCallbacks
    def call_later(self, f, delay, *arg, **kw):
        """Wrapper of a common err handler to retry a deferred reading """
        retry = kw.get('retry', 0)
        logger.debug("Retrying %s with delay %f, retry %d at %r" % (
            arg, delay, retry, str(datetime.now())))
        result = yield task.deferLater(reactor, delay, f, *arg, **kw).addErrback(self.eb_print)
        defer.returnValue(result)

class WormholeInterface(LocalbusInterface):
    def __init__(self, **kwargs):
        super(WormholeInterface, self).__init__(**kwargs)
        self.retry_delay = 0.000001

    @defer.inlineCallbacks
    def read_cmd_regs(self, reg_names):
        """ Read cmd reg one by one """
        read_val_list = []
        for key in reg_names:
            read_val = yield self.read_cmd_ack(key)
            read_val_list.append(read_val)
        defer.returnValue(read_val_list)

    @defer.inlineCallbacks
    def read_cmd_reg(self, reg_name):
        """ Read cmd reg one by one """
        reg_names = [reg_name] * 2
        d = yield self.read_cmd_regs(reg_names)
        defer.returnValue(d[1])

    def write_i2c_dict(self, reg_dict):
        """ Write register one by one with extra waiting time """
        for key, val in reg_dict.iteritems():
            logger.debug("writing %s 0x%x" % (key, val))
            self.write_reg_dict({key: val})
            time.sleep(0.01)

    def write_spi_dict(self, reg_dict):
        """ Write register one by one with waiting time """
        for key, val in reg_dict.iteritems():
            logger.debug("writing %s 0x%x" % (key, val))
            self.write_reg_dict({key: val})
            time.sleep(0.0001)

    def decode_freq_cnt(self, freq_cnt, freq_name=''):
        res = {}
        res[freq_name + ' Freq'] = '{:3.3f} MHz'.format(125 * (freq_cnt + 1) / 8192.0)
        return res

    @defer.inlineCallbacks
    def get_fmc_fcnt(self, bd_name, freq_dict):
        """ Read frequency count"""
        reg_set = bd_name + '_FREQ_CNT_SELECT'
        cmd_dict = {reg_set: 0}
        res_dict = {}
        for key, val in freq_dict.iteritems():
            cmd_dict[reg_set] = val
            self.write_reg_dict(cmd_dict)
            time.sleep(0.001)
            reg_want = bd_name + '_FREQ_CNT_VALUE'
            d = yield self.read_cmd_reg(reg_want).addCallback(
                self.decode_freq_cnt, bd_name+'_'+key)
            res_dict.update(d)
        defer.returnValue(res_dict)

    @defer.inlineCallbacks
    def read_cmd_ack(self, reg_name, retry=0):
        """Asynchronous reading cmd_ack register and update data with any readback"""
        reg_ask_addr = self.get_reg_addr(reg_name)
        if retry == 0:
            self.read_mem_gate([self.get_reg_addr(reg_name)])
            [read_addr, read_val] = yield self.call_later(
                self.read_mem_gate,
                self.retry_delay,
                [self.get_reg_addr('_CMD_RD_ACK'), self.get_reg_addr(reg_name)])
        else:
            # read_addr = yield self.read_lb_reg(self.get_reg_addr('_CMD_RD_ACK'))
            [read_addr, read_val] = yield self.read_mem_gate(
                [self.get_reg_addr('_CMD_RD_ACK'), self.get_reg_addr(reg_name)])

        if read_addr == reg_ask_addr & 0xfffff:
            self.get_reg_by_addr(reg_ask_addr).value = read_val
        else:
            if retry <= 32:
                read_val = yield self.call_later(
                    self.read_cmd_ack, self.retry_delay, reg_name, retry=retry+1)
            else:
                raise ValueError('read_cmd_ack exceeds max retries: %d' % retry)
        defer.returnValue(read_val)

    def read_reg_list_by_name(self, reg_names):
        """Read multiple registers in a list"""
        dlist = map(self.read_cmd_ack, reg_names)
        return defer.gatherResults(dlist, consumeErrors=True)
