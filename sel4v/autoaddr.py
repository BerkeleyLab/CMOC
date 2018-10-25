#!/usr/bin/python
import sys
import re,copy,math
from os.path import dirname
import numpy
class port():
	def __init__(self,module_name,name,io=0,sign=0,msb=0,lsb=0,length=1,addr_msb=None,addr_lsb=None,gen_index=None,port=None,addr=None,start_bit=None):
		self.module_name= (module_name+'_' )if (module_name) else ''
		self.given_name= name
		self.name=self.module_name+self.given_name
		self.use_ram=False
		self.io=port.io if port else io;
		self.gen_index=port.gen_index if port else gen_index
		self.sign= port.sign if port else (sign if sign else '')
		self.msb=port.msb if port else msb
		self.lsb=port.lsb if port else lsb
		self.data_width=self.msb-self.lsb+1
		self.addr_msb=port.addr_msb if port else addr_msb
		self.addr_lsb=port.addr_lsb if port else addr_lsb

		self.addr_width= 0 if (self.addr_msb==None or self.addr_lsb==None) else  self.addr_msb-self.addr_lsb+1
		self.addr=addr
		self.start_bit=start_bit
		self.stop_bit= None if self.start_bit==None else self.start_bit+self.data_width-1
	def get_addr(self):
		return self.addr
	def get_start_bit(self):
		return self.start_bit
	def set_addr(self,addr,start_bit):
		self.addr=addr
		self.start_bit=start_bit
		self.stop_bit=self.start_bit+self.data_width-1
	def set_use_ram(self):
		self.use_ram=True
	def get_name(self):
		return self.name
	def decode(self):
		decode_str=''
		if self.io =='input':
			decode_def = "wire we_%s=lb_write&(`ADDR_HIT_%s);"%(self.name,self.name)
			if (not self.use_ram):
				decode_str=decode_def+"reg [%d:%d] %s=0; always @(posedge clk) if (we_%s) %s <= lb_data;"%(self.msb,self.lsb,self.name,self.name,self.name)
			else:
				addr_range=r"[%s:%s]"%(self.addr_msb,self.addr_lsb)
				data_range=r"[%s:%s]"%(self.msb,self.lsb)
				wire_def = "wire %s %s_addr;wire %s %s;"%(addr_range,self.name,data_range,self.name)
				dpram_a = ".clka(clk),.addra(lb_addr%s),.dina(lb_data%s),.wena(we_%s)"%(addr_range,data_range,self.name)
				dpram_b = ".clkb(clk),.addrb(%s_addr),.doutb(%s)"%(self.name,self.name)
				dpram_def = "dpram #(.aw(%d),.dw(%d)) dp_%s(%s,%s);"%(self.addr_width,self.data_width,self.name,dpram_a,dpram_b)
				decode_str=wire_def+decode_def+dpram_def
		return decode_str;
	def self_port(self):
		self_port_str="%s %s [%s:%s] %s"%(self.io,self.sign,self.msb,self.lsb,self.name)
		return self_port_str;
	def instance_port(self,gvar=None):
		if gvar is None:
			return_str= ".%s(%s)"%(self.given_name,self.name)
		else:
			return_str=".%s(%sarray_%s[%s])"%(self.given_name,self.module_name,self.given_name,gvar)
		return return_str
	def construct_map(self,gen_cnt):
		#print "// construct_map",sig,msb,lsb,inst,name,gcnt
		map_str="wire %s [%d:%d] %sarray_%s [0:%d];"%(self.sign,self.msb,self.lsb,self.module_name,self.given_name,gen_cnt-1)
		for gen_index in range(gen_cnt):
			array_el = "%sarray_%s[%d]"%(self.module_name,self.given_name,gen_index)
			expanded = "%s%d_%s"%(self.module_name,gen_index,self.given_name)
			if self.io == "input":
				map_str+=(" assign %s = %s;"%(array_el,expanded))
			else:
				map_str+=(" assign %s = %s;"%(expanded,array_el))
		return map_str
class verilog_module():
	def __init__(self,filename,name='',top=False,gen_var=None,gen_index=None):
		self.ports={};
		self.submodules={};
		self.name=name + (('_'+str(gen_index)) if gen_index !=None else '')
		self.top=top
		self.gen_var=gen_var
		self.gen_index=gen_index
		self.filename=filename
		self.searchpath=dirname(filename)
		if (self.searchpath == ""):
			self.searchpath = "."
		self.module_type=filename.split('/')[-1].split('.')[0]
		self.parse_vfile();
		for submodule_name in self.submodules.keys():
			submoduleports=self.submodules[submodule_name].ports_up(self.name)
			self.ports.update(submoduleports)
		self.register_or_dpram()
	def construct_map(self):
		map_str=''
		for module in self.submodules.keys():
			map_str+=self.submodules[module].construct_map()
		return map_str

	def ports_up(self,module_name):
		ports={}
		for port_name in self.ports.keys():
			newport=port(module_name=module_name,name=self.ports[port_name].get_name(),port=self.ports[port_name])
			ports[newport.get_name()]=newport
		return ports

	def get_name(self):
		return self.name

	def find_module(self,module_type):
		return self.searchpath+'/'+module_type+'.v'

	def set_gen_var(self,var):
		self.gen_var=var

	def parse_vfile(self):
		f=open(self.filename)
		s=f.read()
		f.close()
		for l in s.split('\n'):
			m_submodule=re.search(r'^\s*(\w+)\s+(#\(.*\) *)?(\w+)\s*//\s*auto\(*(\w*),*(\d*)\)*',l)
			if m_submodule:
				submodule_type=m_submodule.group(1)
				submodule_param=m_submodule.group(2)
				submodule_name=m_submodule.group(3)
				submodule_gvar=m_submodule.group(4) if len(m_submodule.group(4)) else None
				submodule_gcnt=int(m_submodule.group(5)) if len(m_submodule.group(5)) else None
				submodule_filename=self.find_module(submodule_type)
				if submodule_gcnt:
					new_modules=gen_verilog_module(filename=submodule_filename,parent_name=self.name,name=submodule_name,gen_var=submodule_gvar,gen_cnt=submodule_gcnt)
					if not self.submodules.has_key(new_modules.get_name()):
						self.submodules[new_modules.get_name()]=new_modules
				else:
					new_module=verilog_module(filename=submodule_filename,name=submodule_name)
					if not self.submodules.has_key(new_module.get_name()):
						self.submodules[new_module.get_name()]=new_module

			m_external_port=re.search(r'\b(input|output)\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+),?\s*//\s*external',l)
			if m_external_port:
				io=m_external_port.group(1)
				sign=m_external_port.group(2)
				msb=int(m_external_port.group(3))
				lsb=int(m_external_port.group(4))
				port_name=m_external_port.group(5)
				newport=port(io=io,sign=sign,msb=msb,lsb=lsb,module_name=self.name,name=port_name)
				self.ports[newport.get_name()]=newport

	def register_or_dpram(self):
		for port_name in [key for key in self.ports.keys() if self.ports.has_key(key+'_addr')]:
			if self.ports[port_name+'_addr'].io=='output':
				self.ports[port_name].addr_msb=self.ports[port_name+'_addr'].msb
				self.ports[port_name].addr_lsb=self.ports[port_name+'_addr'].lsb
				self.ports[port_name].set_use_ram()
	def self_ports(self):
		self_ports_str=", ".join(self.ports[port].self_port() for port in sorted(self.ports.keys()))
		return self_ports_str
	def decode_ports(self):
		return_str= " ".join([self.ports[port].decode() for port in sorted(self.ports.keys())])
		return return_str
	def instance(self):
		return_str=''
		for module in self.submodules.keys():
			return_str+=self.submodules[module].instance_ports()
		return return_str
	def instance_ports(self):
		return_str=''
		return_str+='`define AUTOMATIC_%s '%self.name+ ",".join([self.ports[port].instance_port() for port in sorted(self.ports.keys())])+'\n'
		return return_str
	def auto_vh_gen(self):
		print self.instance()
		print r'''// machine-generated by newad.py %s
`ifdef LB_DECODE_%s
`include "addr_map.vh"
`define AUTOMATIC_self input [31:0] lb_data, input lb_write, input [15:0] lb_addr
`define AUTOMATIC_decode %s
`else
`define AUTOMATIC_self %s
`define AUTOMATIC_decode
`endif
`define AUTOMATIC_map %s'''%(self.filename,self.module_type,self.decode_ports(),self.self_ports(),self.construct_map())


	def print_sub(self):
		print
		print 'inst:',self.name,'module type:',self.module_type
		print sorted(self.ports.keys())
		for module in self.submodules.keys():
			self.submodules[module].print_sub()
	def print_ports(self):
		#for portname in  sorted(self.ports.keys(),key=lambda x:(self.ports[x].use_ram,self.ports[x].name), reverse=True):
		sortport=sorted(sorted(self.ports.keys(), key = lambda y: (self.ports[y].start_bit),reverse= True ),key= lambda y:self.ports[y].addr );
		for portname in sortport:
			port=self.ports[portname]
			print 'name=',port.name,'\tuse_ram=',port.use_ram,'\twidth=',port.data_width, '\taddr_width=', port.addr_width,'\taddr=',port.addr,'\tstart_bit=',port.start_bit,'\tstop_bits=',port.stop_bit
	def get_ports(self):
		return self.ports


class gen_verilog_module():
	def __init__(self,filename,parent_name,name,gen_var,gen_cnt):
		self.modules=[];
		self.name=name;
		self.gen_var=gen_var
		self.gen_cnt=gen_cnt
		self.base_module=verilog_module(filename=filename,name=name)
		for  gen_index in range(gen_cnt):
			new_module=verilog_module(filename=filename,name=name,gen_index=gen_index)
			self.modules.append(new_module)
	def construct_map(self):
		map_str=''
		for port in self.base_module.ports.keys():
			map_str+=self.base_module.ports[port].construct_map(gen_cnt=self.gen_cnt)
		for module in self.modules:
			map_str+=module.construct_map()
		return map_str

	def ports_up(self,module_name):
		ports={}
		for module in self.modules:
			ports.update(module.ports_up(module_name))
		return ports
	def module_name(self):
		pass
	def self_ports(self):
		return_str=''
		for module in self.modules:
			return_str+=module.self_ports()
		return return_str
	def decode_ports(self):
		return_str=''
		for module in self.modules:
			return_str+=module.decode_ports()
		return return_str
	def instance_ports(self):
		return_str=''
		return_str+='`define AUTOMATIC_%s '%self.name+ ",".join([self.base_module.ports[port].instance_port(self.gen_var) for port in sorted(self.base_module.ports.keys())])+'\n'
		return return_str
	def print_sub(self):
		for module in self.modules:
			module.print_sub()
	def get_name(self):
		return self.name



#if __name__=="__main__":
if 0:
	testmodule=verilog_module(filename=sys.argv[1],top=True)
	testmodule.auto_vh_gen()
	print 'print_sub'
	testmodule.print_sub()
	print 'top ports'
	testmodule.print_ports()
	testmodule.assign_addr(None)

	print 'sorted ports'
	print sorted('%s %s [%s:%s] %s'%(testmodule.ports[port].io,testmodule.ports[port].sign,testmodule.ports[port].msb,testmodule.ports[port].lsb,testmodule.ports[port].name) for port in testmodule.ports.keys())
	print testmodule.name

import sys
import re,copy,math
from os.path import dirname
class address_map():
	def __init__(self,addr_width=32,data_width=32):
		self.addr_width=addr_width
		self.data_width=data_width
		self.data_bit_addr=int(math.log(data_width,2))
		self.data_bit_mask=2**self.data_bit_addr-1
		print 'debug 5 data_bit_addr %d,addr_width%d'%(self.data_bit_addr,self.addr_width)
		self.maps=2**(addr_width+self.data_bit_addr)*[False] # False mean vacant
		print 'init', len(self.maps)
	def set_addr(self,addr,bit,data_width,addr_width=0,share_addr=False):
		print 'set_addr debug ',addr_width
		start_addr=addr
		stop_addr=start_addr+2**(addr_width)
		print 'mark occupied at addr=%d,data_width=%d,data_bit_addr=%d,start=%d,stop=%d,bit=%d,share_addr=%d'%(addr, data_width,self.data_bit_addr,start_addr,stop_addr,bit,share_addr)
		print 'length=%d,start_addr=%d,stop_addr=%d'%(len(data_width*[True]),start_addr,stop_addr)
		for address in range(start_addr,stop_addr):
			width=data_width if share_addr else self.data_width
			start_bit_addr=(address<<self.data_bit_addr)+bit
			stop_bit_addr=(address<<self.data_bit_addr)+bit+width
			print 'set_addr debug',address,address+bit,address+bit+data_width,len(self.maps[address+bit:address+bit+data_width])
			print 'start_bit_addr %d, stop_bit_addr=%d,orig len=%d,replace len=%d'%(start_bit_addr,stop_bit_addr,len(self.maps[start_bit_addr:stop_bit_addr]),len(width*[True]))
			self.maps[start_bit_addr:stop_bit_addr]=width*[True] # True means occupied
	def find_addr(self,data_width,addr_mask_bits=None):
		use_addr=None
		if addr_mask_bits==None:
			if data_width>=self.data_width:
				bit_addr_step=2**self.data_bit_addr
			else:
				bit_addr_step=1
		else:
			bit_addr_step=2**(addr_mask_bits+self.data_bit_addr);
		print 'debug 4',bit_addr_step,len(self.maps)
		for addr in range(0,len(self.maps),bit_addr_step):
			#print 'debug 1', addr,self.data_bit_addr
			if self.vacant_cnt(addr,data_width):
				use_addr=addr;
				print 'found_address at',addr,use_addr
				break
		else:
			print 'not found'
		print 'debug 2',use_addr
		if use_addr!=None:
			(addr,bit)=(use_addr>>self.data_bit_addr,use_addr&self.data_bit_mask)
		else:
			(addr,bit)=(None,None)
		print 'found',(addr,bit)
		return (addr,bit)

	def vacant_cnt(self,bit_addr,length):
		vacant_cnt=self.maps[bit_addr:bit_addr+length].count(False)
		#print 'debug 3',len(self.maps),bit_addr,vacant_cnt,length,self.maps[bit_addr:bit_addr+length]
		return vacant_cnt==length
	def load_file(self):
		pass

	def assign_addr(self,ports):
		#read file, parse addr file format return a port addr list
		# assign address for all dprams, sorted by addr length, then name, then width
		dprams=sorted(sorted([x for x in ports.keys() if ports[x].use_ram], key = lambda y: (ports[y].addr_width),reverse= True ),key= lambda y:ports[y].name );
		for portname in dprams:
			port=ports[portname]
			print 'try to assign address for port: %s data_width %d, addr_width %d'%(port.name,port.data_width,port.addr_width)
			self.addr_dpram(port);
		registers=sorted(sorted([x for x in ports.keys() if not ports[x].use_ram], key = lambda y: (ports[y].addr_width),reverse= True ),key= lambda y:ports[y].name );
		# assign address for all register
		for portname in registers:
			port=ports[portname]
			print 'try to assign address for port: %s data_width %d, addr_width %d'%(port.name,port.data_width,port.addr_width)
			self.addr_register(port);
	def addr_dpram(self,port):
		(addr,bit)=self.find_addr(port.data_width,addr_mask_bits=port.addr_width)
		self.set_addr(addr,bit,port.data_width,port.addr_width,share_addr=False)
		port.set_addr(addr,bit)
		print 'debug 7',port.name,port.use_ram,port.msb,port.lsb, port.addr_msb, port.addr_lsb
	def addr_register(self,port):
		(addr,bit)=self.find_addr(port.data_width)
		self.set_addr(addr,bit,port.data_width,share_addr=True)
		port.set_addr(addr,bit)
		print 'debug 6',port.name,port.use_ram,port.msb,port.lsb, port.addr_msb, port.addr_lsb
		pass
	#print port.name,port.use_ram,port.msb,port.lsb, port.addr_msb, port.addr_lsb



if __name__=="__main__":
	testmodule=verilog_module(filename=sys.argv[1],top=True)
	test_map=address_map(5,32)
	#test_map.set_addr(5,16)
	#test_map.set_addr(24,8)
	ports=(testmodule.get_ports())
	sub={}
	#for k in ports.keys()[0:3]:
	#  sub[k]=ports[k]
	#print type(sub),sub.keys()
	test_map.assign_addr(ports)
	numpy.set_printoptions(threshold='nan')
	reshape_map=numpy.array(test_map.maps).reshape(2**5,32)
	for index in range(32):
		print index,reshape_map[index,:]
	testmodule.print_ports()
	#test_map.find_addr(1)
