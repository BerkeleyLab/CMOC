#!/usr/bin/python

# ifconfig eth0 up 192.168.21.1
# route add -net 192.168.8.0 netmask 255.255.255.0 dev eth0

# also see ~/llrf/eth_2012/lantest
# and ~/llrf/eth_2012/UDP_TxRx_test.lua

# Winbond W25X16, W25X32, W25X64
# See w25x.pdf and spi_flash_engine.v

import socket
import struct
import time
import logging
import sys,getopt
import os
import random

# instruction set
READ_STATUS_1  = '020500'.decode('hex')         # 05 dd              Read Status Register
READ_STATUS_2  = '023500'.decode('hex')
READ_JEDEC_ID  = '049f000000'.decode('hex')     # 9F dd dd dd        Read JEDEC ID
READ_DEVICE_ID = '06900000000000'.decode('hex') # 90 00 00 00 dd dd  Read Device ID

ERASE_SECTOR   = '0420'.decode('hex')           # 20 nn nn nn        Erase Sector (4kB)
ERASE_BLOCK_32 = '0452'.decode('hex')           # 52 nn nn nn        Erase Block  (32kB)
ERASE_BLOCK_64 = '04d8'.decode('hex')           # d8 nn nn nn        Erase Block  (64kB)
READ_FAST      = '0d0b'.decode('hex')           # 0b nn nn nn        Fast Read (261 bytes)
READ_DATA      = '0c03'.decode('hex')           # 03 nn nn nn        Read Data (260 bytes)
PAGE_PROG      = '0c02'.decode('hex')           # 02 nn nn nn dd     Page program (260 bytes)
WRITE_DISABLE  = '0104'.decode('hex')           # 04                 Write Disaable
WRITE_ENABLE   = '0106'.decode('hex')           # 06                 Write Enable
WRITE_STATUS   = '0201'.decode('hex')           # 05 dd              Write Status Register

# ICAP_SPARTAN6 commands
# UG380 table 7-1
ICAP_DUMMY     = 'ffff'.decode('hex')           # DUMMY
ICAP_SYNC_H    = 'aa99'.decode('hex')
ICAP_SYNC_L    = '5566'.decode('hex')
ICAP_W_GEN1    = '3261'.decode('hex')
ICAP_W_GEN2    = '3281'.decode('hex')
ICAP_W_GEN3    = '32a1'.decode('hex')
ICAP_W_GEN4    = '32c1'.decode('hex')
ICAP_W_CMD     = '30a1'.decode('hex')
ICAP_IPROG     = '000e'.decode('hex')
ICAP_NOOP      = '2000'.decode('hex')           # NO OP for IPROG

# GENERAL 3,4, where Golden image lives
#GOLDEN_AD      = 0x10000
GOLDEN_AD      = 0x0

# addressing information of target
# grep "ip =" board_support/xilinx/ether_mc.vh
IPADDR = '192.168.21.116'
PORTNUM = 4000
WAIT = 0.05
# 1  1000       client_rx (LEDs) + client_tx (Hello World)
# 2  2000       client_thru
# 3  3000       mem_gateway
# 4  4000+4001  scaffold (SPI)
# 1814 for XC6SLX16, could also get this from JEDEC status
FILE_LENGTH_PAGES = 1814
PAGE = 256

# Reverse bits within a byte
def byterev(n):
	unib=n>>4
	lnib=n&0x0f
	mapper="084c2a6e195d3b7f"  # bit-reversed nibble lookup
	return (mapper[lnib]+mapper[unib]).decode('hex')

def decode_lbnl_rom(d):
	if (d[0] == 85):
		board={1:"mebt",2:"interim",3:"fcm",4:"avnet",5:"uxo",6:"llrf4",7:"av5t",8:"sp601",9:"sp605",10:"ml505",11:"ml506",12:"fllrf",13:"spec",14:"lx150t",15:"cute_wr",99:"test"}
		user={1:"ldoolitt",2:"cswanson",3:"kasemir",4:"hengjie",5:"crofford",6:"meddeler",7:"baptiste",8:"llrf_oper",9:"hyaver",10:"dim",11:"begcbp",12:"ghuang",13:"luser",14:"kstefan",15:"cserrano",16:"asalom",17:"du"}
		print "DSP flavor: %d"%d[1]
		print "build date: %4.4d-%2.2d-%2.2d"%(d[2]+2000,d[3],d[4])
		print "build time: %2.2d:%2.2d UTC"%(d[5],d[6])
		print "tool rev:   %d"%d[8]
		print "user:       %d (%s)"%(d[9],user[d[9]])
		print "board type: %d (%s)"%(d[10],board[d[10]])
		gs=""
		for ix in range(0,20):
			gs+=chr(d[12+ix])
		print "git commit: %s"%(gs.encode('hex'))
	else:
		print "no magic found %d"%d[0]

# Read Manufacturer ID, JEDEC ID and Device ID
def read_id(s):
	logging.info('Reading ID... ')
	p = READ_STATUS_1
	p += READ_STATUS_2
	p += READ_STATUS_1
	p += READ_JEDEC_ID
	p += READ_DEVICE_ID
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	print r.encode('hex')
	stat_out = r[1]
	manu_id = r[len(r)-2]
	dev_id = r[len(r)-1]
	capacity = r[len(r)-8]
	mem_type = r[len(r)-9]
	logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' %(addr, len(p), len(r)))
	print 'Manufacturer ID: %s' %(manu_id.encode('hex'))
	print 'Device ID:       %s' %(dev_id.encode('hex'))
	print 'Memory Type:     %s' %(mem_type.encode('hex'))
	print 'Capacity:        %s' %(capacity.encode('hex'))
	print 'Status:          %s' %(stat_out.encode('hex'))
	return


# Read status reg 1 for 8 times
# must exceed 18 octets minimum PSPEPS UDP packet length
def read_status(s):
	p = READ_STATUS_1
	p += 7*READ_STATUS_1
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	status_reg = r[len(r)-1]
	logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' %(addr, len(p), len(r)))
	logging.info('Check Status Reg: %s' %(status_reg.encode('hex')))
	return (~(ord(status_reg)))

#  20 nn nn nn   Sector Erase (4 kB)
#  05 rr         Read status register until completion, S0=0
def erase_mem(s,ad,size):
	if size == 'SECTOR':
		p = ERASE_SECTOR
	elif size == '32KB':
		p = ERASE_BLOCK_32
	elif size == '64KB':
		p = ERASE_BLOCK_64
	else:
		logging.error('Wrong buffer size to erase.')
	logging.info('Erasing at address 0x%x...',ad)
	p += three_bytes(ad) + 5*READ_STATUS_1
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	status_reg = r[len(r)-1]
	logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' %(addr, len(p), len(r)))
	logging.debug('Check Status Reg: %s' %(status_reg.encode('hex')))
	return (~(ord(status_reg)))

#  06/04         Write Enable/Disable
#  05 rr         Read status register until completion, S0=0
def write_enable(s,enable):
	if (enable == True):
		p = WRITE_ENABLE
		logging.debug('Enabling Write Register')
	else:
		p = WRITE_DISABLE
		logging.debug('Disabling Write Register')
	p += 6*READ_STATUS_1
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	status_reg = r[len(r)-1]
	logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' %(addr, len(p), len(r)))
	logging.debug('Check Write Enable Status Reg: %s' %(status_reg.encode('hex')))
	return ((ord(status_reg)&0x3)==0x2)

# encode an integer as three bytes
# used to specify addresses when building SPI commands
def three_bytes(ad):
	adx = struct.pack('!i',ad)
	return adx[1:4]

#  0b nn nn nn xx dd dd ... dd  Fast Read (261 bytes)
def page_read(s,ad):
	# note that the first octet '0d' codes for SPI packet length 261
	p = READ_FAST + three_bytes(ad) + 257*'\x00'
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	if (len(r) != 261): logging.warning('length error %d reading address %d\n'%(len(r),ad))
	block = r[5:262]
	return block

def read_data(s,ad):
	# note that the first octet '0c' codes for SPI packet length 260
	p = READ_DATA + three_bytes(ad) + PAGE*'\x00'
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	if (len(r) != 260): logging.warning('length error %d reading address %d\n'%(len(r),ad))
	block = r[4:261]
	return block

def page_program(s,ad,bd):
	# 256 bytes of data 'bd' to be writen to page at address 'ad'
	if (len(bd) != PAGE):
		logging.warning('length of data %d not equal to 256'%(len(bd)))
		# pad with 0xff
		bd += (PAGE-len(bd))*'\xFF'
		logging.warning('padded length now %d'%(len(bd)))
	logging.debug('Page Programming at %d...',ad)
	#sys.stdout.write('.')
	p = PAGE_PROG + three_bytes(ad) + bd
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	time.sleep(0.00055)
	logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' %(addr, len(p), len(r)))
	return

# Write Status Register
def write_status(s,v):
	p = WRITE_ENABLE+WRITE_STATUS
	vx = struct.pack('!i',v)
	p += vx[3]
	p += 7*READ_STATUS_1
	print p.encode('hex')
	logging.info('Write Status')
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	print r.encode('hex')

# Read flash content and dump
def flash_dump(s,file_name, ad):
	size = FILE_LENGTH_PAGES<<8
	logging.info('Dumping flash content from add 0x%x to add 0x%x into %s, length = 0x%x...'
	%(ad, ad+size, file_name, size))
	f=open(file_name,'w')
	for ba in xrange(ad>>8, (ad+size)>>8):
		bd=page_read(s,ba<<8)
		f.write(bd)
	f.close()
	return

# Read local file and write to flash from FF to 00
def remote_program(s, file_name, ad, size):
	logging.info('Programming file %s to %s from add 0x%x to add 0x%x, length = 0x%x...'
	%(file_name, IPADDR, ad, (((ad+size)>>8)+1)<<8, size))
	f=open(file_name,'r')
	# assume that '.bin' file size is always less than whole pages
	for ba in reversed(xrange(ad>>8, ((ad+size)>>8)+1)):
		f.seek((ba<<8) - ad)
		bd=f.read(PAGE)
		while not (write_enable(s,True)):
			time.sleep(WAIT)
		page_program(s,ba<<8,bd)
	f.close
	return

# Erase flash from 00 to FF, step 64KB
def remote_erase(s, ad, size):
	logging.info('Erasing flash %s from add 0x%x to add 0x%x, length = 0x%x...'
	%(IPADDR, ad, (((ad+size)>>16)+1)<<16, size))
	for ba in range(ad>>16, ((ad+size)>>16)+1):
		while not (write_enable(s,True)):
			time.sleep(WAIT)
		erase_mem(s,ba<<16,'64KB')
	return

def mem_gate_read(s, alist):
	p  = struct.pack('!I',random.getrandbits(32))
	p += struct.pack('!I',random.getrandbits(32))
	for ad in alist:
		# read commands include space for result
		p += '\x10' + three_bytes(ad) + 4*' '
	# print p.encode('hex')
	s.connect((IPADDR, 3000))
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	# print r.encode('hex')
	if (r[0:8] != p[0:8]):
		print "header mismatch"
		sys.exit(2)
	res=[]  # build up result list here
	for ix in range(0, len(alist)):
		rh = (r[12+8*ix:16+8*ix])
		res.append(struct.unpack('!I',rh)[0])
		#print "%6.6x: %s"%(alist[ix], rh.encode('hex'))
	s.connect((IPADDR, PORTNUM))
	return res

def reboot_fpga(s,ad):
	logging.info('Rebooting FPGA %s to add 0x%x...' %(IPADDR, ad))
	#    88ffffffffffffaa9955663261xxxx328103xx32a1xxxx32c103xx30a1000e
	#p = '88ffffffffffffaa995566326100003281030132a1000032c1031030a1000e'.decode('hex')
	p = '\x88' + 3*ICAP_DUMMY + ICAP_SYNC_H + ICAP_SYNC_L
	ad1 = struct.pack('!i',ad)
	ad2 = struct.pack('!i',GOLDEN_AD)
	p += ICAP_W_GEN1 + ad1[2:4] + ICAP_W_GEN2 + READ_DATA[1] + ad1[1]
	p += ICAP_W_GEN3 + ad2[2:4] + ICAP_W_GEN4 + READ_DATA[1] + ad2[1]
	p += ICAP_W_CMD + ICAP_IPROG
	print p.encode('hex')
	p += 113*ICAP_NOOP
	if (len(p) != 257):
		print "internal error"
		sys.exit()
	if 0:
		# This is now implemented in FPGA gateware
		print "bit-reversing bytes\n"
		prev=p[0]
		for ix in range(1,len(p)):   # don't bit-swap the length byte
			b = ord(p[ix])
			prev+=byterev(b)
		p=prev
	s.send(p)
	# if the reboot succeeds, we don't get an answer.
	# could read with a timeout, as a way to report failure to reboot.
	#r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	#print r.encode('hex')
	return

# Test client_tx.v output to verify which firmware is running
def test_tx(s):
	s.connect((IPADDR, 1000))
	p = '\x00'
	s.send(p)
	r, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
	print r
	s.connect((IPADDR, PORTNUM))
	return

def usage():
	print 'usage: spi_test.py [commands]'
	print 'Commands:'
	print '-h, --help'
	print '-a, --add <address in hex>'
	print '-d, --dump <filename>'
	print '-m, --mem_read # Read ROM info'
	print '-p, --program <filename>'
	print '-e, --erase <size in hex (min 64KB)>'
	print '-i, --id'
	print '-s, --status <new_value in hex>'
	print '-t, --test_tx'
	print '-r, --reboot'

# Main procedure
def main(argv):
	logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
	# initialize a socket, think of it as a cable
	# SOCK_DGRAM specifies that this is UDP
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
	s.bind(('192.168.21.1', 0))
	# connect the socket, think of it as connecting the cable to the address location
	s.connect((IPADDR, PORTNUM))
	try:
		opts, args = getopt.getopt(argv, "hie:td:p:ra:s:m", ["dump=", "program=", "erase=","add=", "size=", "id", "test_tx", "reboot","status=","mem_read"])
	except getopt.GetoptError as err:
		print str(err)
		usage()
		sys.exit(2)

	# default starting adress
	ad = 0x0
	if len(argv)==0 :
		usage()
		sys.exit()

	for opt,arg in opts:
		if opt in ("-a", "--add"):
			ad = int(arg, base=16)

	for opt,arg in opts:
		if opt in ("-h","--help"):
			usage()
			sys.exit()
		elif opt in ("--dump","-d"):
			dump_file = arg
			flash_dump(s,dump_file, ad)
		elif opt in ("--program","-p"):
			prog_file = arg
			fileinfo = os.stat(prog_file)
			size = fileinfo.st_size
			remote_erase(s, ad, size)
			remote_program(s, prog_file, ad, size)
		elif opt in ("--erase","-e"):
			size = int(arg, base=16)
			remote_erase(s, ad, size)
		elif opt in ("--id","-i"):
			read_id(s)
			read_status(s)
		elif opt in ("--test_tx","-t"):
			test_tx(s)
		elif opt in ("--status_write","-s"):
			ws = int(arg, base=16)
			write_status(s,ws)
		elif opt in ("--mem_read'","-m"):
			res=mem_gate_read(s,range(0,32))
			decode_lbnl_rom(res)
		elif opt in ("--reboot","-r"):
			reboot_fpga(s,ad)
		#else:
		# assert False, "unhandled option"
	logging.info('Done.')

	# close the socket
	s.close()

if __name__ == "__main__":
   main(sys.argv[1:])
