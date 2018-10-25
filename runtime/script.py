import eth_test
import sys,os
import posix_ipc,mmap,numpy,struct
oldumask=os.umask(0)
write_mq=posix_ipc.MessageQueue(name="/Write_Down",flags=posix_ipc.O_CREAT,mode=0666,max_messages=10,max_message_size=1500)
os.umask(oldumask)
val = int(sys.argv[1])
print val
write_mq.send(eth_test.mem_gate_write_prep([22,22,22],[val,val,val]),1,2)
memUp=posix_ipc.SharedMemory('Up')
mfUp=mmap.mmap(memUp.fd,memUp.size)
mfUp.seek(0)
res_str=mfUp.read(memUp.size)
res=struct.unpack('!%dI'%((len(res_str))/4),res_str)
data_array=numpy.array([x-65536 if x>32767 else x for x in res]).reshape([-1,8])
print data_array
