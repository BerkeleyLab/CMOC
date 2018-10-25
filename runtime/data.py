#!/usr/bin/python
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
from PyQt4 import QtCore, QtGui, Qwt5
import paramhg
sys.path.append('../runtime')
import eth_test
import posix_ipc
import mmap,time,pylab
import struct

class udpio():
	#write_mq=posix_ipc.MessageQueue("/Write_Down",posix_ipc.O_CREAT,1000,1000)
	oldumask=os.umask(0)
	write_mq=posix_ipc.MessageQueue(name="/Write_Down",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
	os.umask(0)
	exit_mq=posix_ipc.MessageQueue(name="/Exit_Up",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
	os.umask(oldumask)
	def __init__(self,name):
		oldumask=os.umask(0)
		self.memUp=posix_ipc.SharedMemory("Up",posix_ipc.O_CREAT,mode=0666,size=32768)
		self.memAux=posix_ipc.SharedMemory("Aux",posix_ipc.O_CREAT,mode=0666,size=1024)
		os.umask(oldumask)
		self.mfUp=mmap.mmap(self.memUp.fd,self.memUp.size)
		self.mfAux=mmap.mmap(self.memAux.fd,self.memAux.size)
		self.s = eth_test.setup_sock()
		[res,aux]=eth_test.read_mem_buf(self.s)

	def run(self):
		exit=False
		#write_str=''
		#for index in range(60):
		while (not exit):
			try:
				exit_str=self.exit_mq.receive(0)
				#print exit_str,exit_str[0]
				if exit_str[0]=="Exit_Up":
					exit=True
			except posix_ipc.BusyError:
				pass
				#print 'busy'
			except Exception as inst:
				print 'exit mq error'
				print type(inst)
				print inst.args
				print inst
			try:
				for index in range(self.write_mq.current_messages-1):
					self.write_mq.receive(0)
				write_str=self.write_mq.receive(0)
				print 'received write_str',len(write_str[0])
				eth_test.mem_gate_write(self.s,write_str[0])
			except posix_ipc.BusyError:
				pass
				#print 'busy'
			except Exception as inst:
				print 'write_mq error'
				print type(inst)
				print inst.args
				print inst
			[res,aux]=eth_test.read_mem_buf(self.s)
			#print len(res),type(res),res
			res_str=struct.pack('!%sI'%len(res),*res)
			aux_str=struct.pack('!%sB'%len(aux),*aux)
			self.mfUp.seek(0)
			self.mfAux.seek(0)
			self.mfUp.write(res_str)
			self.mfAux.write(aux_str)
			time.sleep(0.01)  # leave some CPU for other processes
#   for i in range(9):
#   mfUp.write(str(index)+',')
#      self.mfUp.write(s)
#      time.sleep(0.1)
	def __del__(self):
		try:
			self.exit_mq.close()
			self.exit_mq.unlink()
		except:
			pass
		try:
			self.write_mq.close()
			self.write_mq.unlink()
		except:
			pass
		try:
			self.s.close()
		except:
			pass
		try:
			self.memUp.close_fd()
			self.memUp.unlink()
		except:
			pass
		try:
			self.memAux.close_fd()
			self.memAux.unlink()
		except:
			pass

a=udpio("Up")
a.run()

