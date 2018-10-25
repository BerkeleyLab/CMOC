import sys
import re
class register:
	def __init__(self,source,name,typech,default=0,addr=-1,length=-1,start=-1,stop=-1):
		self.source=source
		self.name=name
		self.typech=typech
		self.length=(length)
		self.default=(default)
		self.addr=(addr)
		self.start=(start)
		self.stop=(stop)
	def setaddr(self,addr=-1,start=-1,stop=-1):
		self.addr=addr
		self.stop=stop
		self.start=start

class regspace:
	def __init__(self,length,width,blackout=[0,127]):
		self.space=length*[(1<<width)-1]
		self.length=length
		self.width=width
		self.spaceavail=[self.countspace(s) for s in self.space]
		for addr in blackout:
			self.usebit(addr,0,width-1)

	def countspace(self,s):
		dirlist=[{'width':m.end()-m.start(),'start':self.width-m.end()} for m in list(re.finditer('1+',str(bin(s))[2:]))]
		sortdirlist=sorted(dirlist,key=lambda k:k['start'])
		return sortdirlist

	def findspace(self,length,startaddr=0):
		addr=startaddr
		for s in self.spaceavail[startaddr:]:
			for d in s:
				if d['width']>=length:
					return {'addr':addr,'start':d['start'],'stop':d['start']+length-1}
			addr=addr+1
		print 'no space of %d found \n'%length


	def releasebit(self,addr,start,stop):
		pass

	def usebit(self,addr,start,stop):
		if ((0<=start < self.width) and (0<=stop < self.width) and (0<=addr < self.length)):
			for bit in range(start,stop+1):
				# print bit
				if ((self.space[addr]&(1<<bit))):
					mask=((1<<self.width)-1)^(1<<bit)
					#print bin(mask)
					self.space[addr] &= mask
				else:
					print 'ERROR: bit used for addr=%d, %dbit'%(addr,bit)
			self.spaceavail[addr]=self.countspace(self.space[addr])
		else:
			print 'ERROR, invalid bit addr %d, start %d stop %d'%(addr,start,stop)


class regin:
	def __init__(self,fin,fout,reg_length=128,reg_width=32):
		self.regs={}
		self.regspace=regspace(reg_length,reg_width)

	def readinput(self,fin):
		s=fin.readlines()

		for l in s:
			if len(l)>0 :
				m=re.match(r'(\S*.[vh?]):'+r'`'+'(REG|EVT|STB)'+'_(\S*)'+r'\s+//'+'\s*([usea])\s*'+'(\d+[\[\d+:\d+\]]*)\s+(\d+|-)',l)
				#m=re.match(r'(.*?[vh?]):'+r'`REG_(\S*)'+r'\s+//'+'\s*([usea])\s*'+'(\d+[\[\d+:\d+\]]*)\s+(\d+|-)',l)
				if (m):
					#print m.groups()
					source=m.group(1)
					typehead=m.group(2)
					name=m.group(3)
					typech=m.group(4)
					if typehead=='REG':
						if not(typech=='u' or typech=='s'):
							print ' REG SHOULD BE u or s in %s,treat as u \n'%l
							typech='u'
					elif typehead=='EVT':
						if not(typech=='e'):
							print ' EVT SHOULD BE e  in %s \n'%l
							typech='u'
					elif typehead=='STB':
						if not(typech=='a'):
							print ' STB SHOULD BE a  in %s \n'%l
							typech='a'
					else:
						print 'not understand, should nothappen\n'

					m5=re.match('(\d+)\[(\d+):(\d+)\]',m.group(5))
					if m5:
						#print m5.groups()
						addr=int(m5.group(1))
						stop=int(m5.group(2))
						start=int(m5.group(3))
						length=int(stop)-int(start)+1
					else:
						if (typech=='a'):
							addr=int(m.group(5))
							start=0
							stop=self.regspace.width-1
							length=1
						else:
							addr=-1
							start=-1
							stop=-1
							length=int(m.group(5))

					if m.group(6).isdigit():
						default=int(m.group(6))
					else:
						default=0

					if self.regs.has_key(name):
						print 'duplicate register, ignoring %s \n %s'%(source,l)
					else:
						self.regs[name]=(register(source=source,name=name,typech=typech,length=length,default=default,start=start,stop=stop,addr=addr))
				else:
					print 'Error: not understand line: %s'%l

	def assign_addr(self,startaddr=0):
		regauto=[]
		for name in self.regs.keys():
			reg=self.regs[name]
			if ((reg.addr>=0)&(reg.start>=0)&(reg.stop>=0)):
				self.regspace.usebit(addr=reg.addr,start=reg.start,stop=reg.stop)
			else:
				regauto.append(reg)
		regautosort=sorted(regauto,key=lambda reg:(reg.length,reg.name),reverse=True)
		for reg in regautosort:
			# print reg.length,reg.name
			addrauto=self.regspace.findspace(reg.length,startaddr=startaddr)
			self.regspace.usebit(**addrauto)
			reg.setaddr(**addrauto)

	def sortreg(self):
		return sorted(self.regs.keys(),key=lambda k: (self.regs[k].addr,self.regs[k].start))

	def writereg(self,fout):
		sout='#addr type[ stop:start] default_value            name    source\n'
		for name in self.sortreg():
			reg=self.regs[name]
			sout+='%d   %s[%d:%d]       %13s %20s # from %s\n'%((reg.addr), reg.typech, reg.stop,reg.start,reg.default,reg.name,reg.source)
		f=open(fout,'w')
		f.write(sout)
		f.close()

if __name__=='__main__':
	if len(sys.argv)==3:
		try:
			regs=regin(sys.argv[1],sys.argv[2])
			infd=open(sys.argv[1])
			regs.readinput(fin=infd)
			infd.close()
			regs.assign_addr(startaddr=100)
			regs.writereg(fout=sys.argv[2])
		except Exception, e:
			print str(e)
	elif len(sys.argv)==2:
		try:
			regs=regin(sys.stdin,sys.argv[1])
			regs.readinput(fin=sys.stdin)
			regs.assign_addr(startaddr=100)
			regs.writereg(fout=sys.argv[1])
		except Exception, e:
			print str(e)
	else:
		print 'usage: [stdin |] python regin.py [fin] fout\n'
