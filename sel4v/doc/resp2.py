# Transcribed from resp.m
# I'm a lot less practiced with numpy than I am in Octave,
# so there's probably lots of room for improvement here.
import numpy as np
import math
import matplotlib.pyplot as plt
import sys
import os

os.system('make -C .. larger_tb && make -C .. larger_p.dat')

wave_samp_per=1  # see param.py
yscale=34848.0  # see param.py output
f_clk=100e6  # as listed in param.py

dt=33*wave_samp_per*2.0/f_clk

cav=[]
fwd=[]
rfl=[]
tim=[]
t=0

f=open('../larger_p.dat')
s=f.read().split('\n')
f.close()
for l in s:
	a=[int(x) for x in l.split()]
	if a:
		cav.append((a[0]+a[1]*1j)/yscale)
		fwd.append((a[2]+a[3]*1j)/yscale)
		rfl.append((a[4]+a[5]*1j)/yscale)
		t += dt*1e6
		tim.append(t)

if 1:
	plt.figure()
	plt.plot(tim,np.abs(cav), label='cav')
	plt.plot(tim,np.abs(fwd), label='fwd')
	plt.plot(tim,np.abs(rfl), label='rfl')
	plt.legend()
	plt.xlabel('t ($\\mu$s)')

if 1:
	plt.figure()
	ix=[]
	for i,t in enumerate(tim):
		if (t>4 and t<60): ix.append(i)
	plt.plot([tim[i] for i in ix],[np.angle(cav[i])-2.0 for i in ix], label='cav')
	plt.plot([tim[i] for i in ix],[np.angle(fwd[i])+2.3 for i in ix], label='fwd')
	plt.legend()
	plt.xlabel('t ($\\mu$s)')

plt.show()
