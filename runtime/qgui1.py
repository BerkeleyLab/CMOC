#!/usr/bin/python

#from PyQt4.QtCore import *
#from PyQt4.QtGui import *
#from PyQt4.Qwt5 import *

import socket
import struct
import logging
import sys,getopt
import os
import random
import numpy
from matplotlib import pyplot as plt
import threading
import sys, time
from PyQt4 import QtCore, QtGui, Qwt5,Qt
import paramhg
sys.path.append('../runtime')
import eth_test

class qgui(QtGui.QWidget):
	def __init__(self,regs=None):
		QtGui.QWidget.__init__(self)

		self.setGeometry(300, 300, 1000, 600)
		self.setWindowTitle('qgui')
		self.fig1=Qwt5.QwtPlot()
		self.fig1.setParent(self)
		self.fig1.setGeometry(300,0,400,300)
		self.fig2=Qwt5.QwtPlot()
		self.fig2.setParent(self)
		self.fig2.setGeometry(300,300,400,300)
		self.curves1=[]
		self.curves2=[]
		pens=[QtCore.Qt.red,
				QtCore.Qt.black,
				QtCore.Qt.cyan,
				QtCore.Qt.darkCyan,
				QtCore.Qt.darkRed,
				QtCore.Qt.magenta,
				QtCore.Qt.darkMagenta,
				QtCore.Qt.green,
				QtCore.Qt.darkGreen,
				QtCore.Qt.yellow,
				QtCore.Qt.darkYellow,
				QtCore.Qt.blue,
				QtCore.Qt.darkBlue,
				QtCore.Qt.gray,
				QtCore.Qt.darkGray,
				QtCore.Qt.lightGray]

		for index in range(16): #up to 16 curves here
			self.curves1.append(Qwt5.QwtPlotCurve())
			self.curves1[index].attach(self.fig1)
			self.curves1[index].setPen(QtGui.QPen(pens[index]))
			self.curves2.append(Qwt5.QwtPlotCurve())
			self.curves2[index].attach(self.fig2)
			self.curves2[index].setPen(QtGui.QPen(pens[index]))
		self.layout = QtGui.QVBoxLayout(self)
		self.layout.setContentsMargins(0,0,0,0)
		self.layout.setSpacing(0)
		self.slider={}
		self.param={}
		index=0
		for reg in regs:
			self.slider[index]=param_slider(self,name=reg.name,process=self.test1,y0=index*30,init=reg.value,s_min=reg.min_value,s_max=reg.max_value)
			self.param[reg.name]=reg.value
			#self.slider[index].connect(self.test1)
			#print self.slider[index],index
			#self.layout.addWidget(self.slider[index])
			index=index+1
		print self.param
		self.socket = eth_test.setup_sock()
		write=write_thread(self.param,self.socket)#self.sender().addr,self.sender().value)
		write.start()

		self.read=read_and_plot_thread(self.socket)
		self.read.signal_got_new_data.connect(self.replot)
		self.read.start()
	def replot(self,value):
		index=0
		value=value.transpose()
		cav=value[0,:]+1j*value[1,:]
		fwd=value[2,:]+1j*value[3,:]
		ref=value[4,:]+1j*value[5,:]
		self.curves1[0].setData(range(value.shape[-1]),numpy.abs(cav))
		self.curves1[1].setData(range(value.shape[-1]),numpy.abs(fwd))
		self.curves1[2].setData(range(value.shape[-1]),numpy.abs(ref))
		self.curves2[0].setData(range(value.shape[-1]),numpy.angle(cav))
		self.curves2[1].setData(range(value.shape[-1]),numpy.angle(fwd))
		self.curves2[2].setData(range(value.shape[-1]),numpy.angle(ref))
		#print value,len(value.shape)
		#if len(value.shape)==1:
		#  self.curves1[index].setData(range(value.shape[-1]+1),value)
		#else:
		#  for line in value:
		#    #print index,line,value.shape[1]
		#    self.curves1[index].setData(range(value.shape[-1]),line)
		#    index=index+1
		self.fig1.replot()
		self.fig2.replot()
	def __del__(self):
		self.socket.close()
		print 'quitting qgui'
		try:
			QtGui.QWidget.__del__(self)
		except:
			pass
		#self.wait()
		return
	def closeEvent(self,event):
		self.read.stop()
		event.accept()

	def test1(self):
		#print self.__class__.__name__
		#print obj.__class__.__name__
		self.param[self.sender().name]=self.sender().value
		write=write_thread(self.param,self.socket)#self.sender().addr,self.sender().value)
		write.start()
		return
import posix_ipc,mmap
class write_thread(QtCore.QThread):
	#write_mq=posix_ipc.MessageQueue("/Write_Down",posix_ipc.O_CREAT,100)
	oldumask=os.umask(0)
	write_mq=posix_ipc.MessageQueue(name="/Write_Down",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
	os.umask(oldumask)

	def __init__(self,param,socket):#,addr,value):
		QtCore.QThread.__init__(self)
		print param
		self.socket=socket
		[self.regs,err_cnt]=paramhg.gen_reg_list(**param)
		print 'regs size',len(self.regs)
		self.addr=[reg.addr for reg in self.regs]
		self.value=[reg.value for reg in self.regs]
		#self.strs=[reg.print_regs() for reg in self.regs]
		self.p=eth_test.mem_gate_write_prep(self.addr,self.value)
		#print '\n'.join(strs)
		#self.addr=addr
		#self.value=value
	def __del__(self):
		print 'quitting write thread'
		try:
			QtCore.QThread.__del__(self)
			self.write_mq.close()
			self.write_mq.unlink()
		except:
			pass
		self.wait()
		#return
	def run(self):
		#print 'write to hardware',self.strs
		try:
			print 'message size',len(self.p),self.write_mq.max_message_size
			self.write_mq.send(self.p,1,2)
		except Exception as inst:
			print type(inst)
			print inst.args
			print inst
		#eth_test.mem_gate_write(self.socket,addr,value)
		return
		#self.terminate()

class read_and_plot_thread(QtCore.QThread):
	signal_got_new_data=QtCore.pyqtSignal(numpy.ndarray)
	oldumask=os.umask(0)
	exit_mq=posix_ipc.MessageQueue(name="/Exit_Up",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
	os.umask(oldumask)
	def __init__(self,socket):
		QtCore.QThread.__init__(self)
		self.cont=True
		#rom=eth_test.mem_gate_read(s,range(0,32))
		#eth_test.decode_lbnl_rom(rom)
		#self.fig=plt.figure(1)
		#self.fig.show()
		self.socket=socket
		self.addr=[]
		self.value=[]
		self.rewrite_lock=False
		self.data_array=[]
		self.index=0
		try:
			self.memUp=posix_ipc.SharedMemory('Up')
		except:
			#self.memUp_thread=threading.Thread(target=read_from_hardware)
			#self.memUp_thread.start()
			os.system('python data.py &')
			time.sleep(2)
			self.memUp=posix_ipc.SharedMemory('Up')
		self.mfUp=mmap.mmap(self.memUp.fd,self.memUp.size)
#def rewrite(self,addr,value):
#  self.addr=addr
#  self.value=value
#  self.rewrite_lock=True
#  return
	def __del__(self):
		#print self.memUp_thread.isAlive()
		self.exit_mq.send('Exit_Up')
		print 'quitting read thread, message sent'
		try:
			self.exit_mq.close()
			self.exit_mq.unlink()
			self.memUp.unlink()
			QtCore.QThread.__del__(self)
		except:
			pass
		return
		#self.wait()
	def stop(self):
		print 'quit read'
		self.cont=False
	def get_new_data(self):
		#res=eth_test.read_mem_buf(self.socket)
		self.mfUp.seek(0)
		res_str=self.mfUp.read(self.memUp.size)
		res=struct.unpack('!%dI'%((len(res_str))/4),res_str)
		self.index=self.index+1
		self.data_array=numpy.array([x-65536 if x>32767 else x for x in res]).reshape([-1,8])
		#self.data_array=numpy.array(res).reshape([-1,8])
		#numpy.array([range(self.index,self.index+8),range(3,11)])
	def run(self):
		while (self.cont):
			self.get_new_data()
			self.signal_got_new_data.emit(self.data_array)
			time.sleep(0.1) # artificial time delay
		self.terminate()

			#print res[1,:]
			#print self.rewrite_lock
			#print eth_test.mem_gate_write(self.socket,self.addr,self.value)

#eth_test.mem_gate_write(s,addr,value);
#    if self.rewrite_lock:
#        self.rewrite_lock=False
#    else:
#        numpy.savetxt("live%d.dat"%fcnt,res,'%6.0f')
#        fcnt += 1
#        plt.plot(res)
#        self.fig.canvas.draw()
#        time.sleep(0.1)
#        self.fig.clf()
#        print 'read and plot thread'
		#return

class QELabel(QtGui.QLabel):
	def __init__(self,parent):
		QtGui.QLabel.__init__(self,parent)
		def mouseReleaseEvent(self,ev):
			self.emit(QtCore.SIGNAL('clicked()'))


class label_slider_value(QtGui.QWidget):
	def __init__(self,diag,name,process=None,init=0,s_min=0,s_max=100,x0=0,y0=0,dx=100,dy=30,mode=0):
		QtGui.QWidget.__init__(self);
		self.label=QELabel(diag)
		self.label.setText(name)
		self.sld = QtGui.QSlider(QtCore.Qt.Horizontal, diag)
		self.sld.setFocusPolicy(QtCore.Qt.NoFocus)
		self.sld.setMinimum(s_min)
		self.sld.setMaximum(s_max)
		self.value=(0 if init==None else init);
		self.sld.setValue(self.value)
		self.edit=QtGui.QLineEdit(diag)
		self.update_value()
		self.sld.valueChanged.connect(self.sld_changed)
		self.edit.textChanged.connect(self.text_changed)
		if process:
			self.connect(self,QtCore.SIGNAL('value_changed'),process)
		if (mode==0):
			xlabel=x0;ylabel=y0;dxlabel=dx;dylabel=dy;
			xslider=x0+dx;yslider=y0;dxslider=dx;dyslider=dy;
			xvalue=x0+dx+dx;yvalue=y0;dxvalue=dx;dyvalue=dy;
		self.label.setGeometry(xlabel,ylabel,dxlabel,dylabel)
		self.sld.setGeometry(xslider,yslider,dxslider,dyslider)
		self.edit.setGeometry(xvalue,yvalue,dxvalue,dyvalue)
		self.xymax=[min(xlabel,xslider,xvalue),max(ylabel,yslider,yvalue)+dy]

		self.sld.sliderPressed.connect(self.press)
		self.label.connect(self.label,QtCore.SIGNAL('clicked()'),self.buttonClicked)

	def send_sig(self):
		self.emit(QtCore.SIGNAL('value_changed'))
	def text_changed(self):
		self.value=float(self.edit.text())
		self.update_value()
	def sld_changed(self):
		self.value=float(self.sld.value())
		self.update_value()
	def update_value(self):
		self.edit.setText(str(self.value))
		self.sld.setValue(self.value)
		self.send_sig()
	def get_xymax(self):
			return self.xymax
	def setValue(self,value):
		self.sld.setValue(value)
	def press(self):
		self.sld.setFocus()
	def buttonClicked(self):
		self.sld.setFocus()

class param_slider(label_slider_value):
	def __init__(self,diag,name,process=None,init=0,s_min=0,s_max=100,x0=0,y0=0,dx=100,dy=30,mode=0):
		label_slider_value.__init__(self,diag,name,process,init,s_min,s_max,x0,y0,dx,dy,mode)
		self.name=name;
		self.value=init

class params():
	def __init__(self,name,nominal,min_value,max_value):
		self.value=nominal
		self.min_value=min_value
		self.max_value=max_value
		self.name=name
if __name__=='__main__':
	par=[params('mode1_foffset',0,-1e4,1e4),
		params('mode1_Q1',8.1e4,4.4e4,8.9e4),
		params('mmode1_freq',30e3,10e3,40e3),
		params('mmode1_Q',5.0,2,10),
		#params('net1_coupling',100,0,200),
		#params('net2_coupling',200,0,200),
		#params('net3_coupling',150,0,200),
		params('fwd_phase_shift',0,-180,180),
		params('rfl_phase_shift',0,-180,180),
		params('cav_phase_shift',0,-180,180),
		params('PRNG_en',1,0,1),
		params('sel_en',1,0,1),
		params('ph_offset',-13000,-131072,131071),  # -13300 ?
		params('amp_max',10000,10,32767),
		params('set_X',20000,0,32767),
		params('set_P',0,-131072,131071),
		params('k_PA',-200,-1000,0),
		params('k_PP',-200,-1000,0),
		params('maxq',0,0,12000),
		params('duration',2000,1,8200),
		params('piezo_dc',-900,-32768,32767)  # -1400 ?
		]
	#regs={'t1':{'name':'t1','addr':1,'value':3},
	#'t2':{'name':'t1','addr':2,'value':3},
	#'t3':{'name':'t1','addr':3,'value':3},
	#'t4':{'name':'t1','addr':4,'value':3},
	#'t5':{'name':'t1','addr':5,'value':3},
	#'t6':{'name':'t1','addr':6,'value':3}}

	app=QtGui.QApplication(sys.argv)
	test=qgui(par)
	test.show()
	print 'here'
	app.exec_()

