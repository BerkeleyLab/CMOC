system('make -C .. larger_tb && make -C .. larger_p.dat')
wave_samp_per=1;  % see param.py
yscale=34848;  % see param.py output
f_clk=100e6;  % as listed in param.py
dt=33*wave_samp_per*2/f_clk;

d=load('../larger_p.dat');
% cim_12 wiring in llrf_dsp.v:
%   adca(a_field), .adcb(a_forward), .adcc(a_reflect),
%  .adcd(16'b0), .outm(16'b0), .adcx(16'b0),
% implies the 12 output channels are real and imag parts of
% a_field  a_forward  a_reflect  0  0  0
% and given the ch_keep setting of 0xff0 in param.py,
% the eight columns input here correspond to real and imag parts of
%  a_field  a_forward  a_reflect  0
cav = (d(:,1)+j*d(:,2))/yscale;
fwd = (d(:,3)+j*d(:,4))/yscale;
rfl = (d(:,5)+j*d(:,6))/yscale;

npt=length(cav);
t=[0:npt-1]'*dt*1e6;  % microseconds
plot(t,abs(cav),t,abs(fwd),t,abs(rfl))
legend('cav','fwd','rfl')
xlabel('t ({\mu}s)')

if 1
  figure(2)
  ix = find((t>4).*(t<60));
  plot(t(ix),arg(cav(ix))-2,t(ix),arg(fwd(ix))+2.3)
  legend('cav','fwd')
  xlabel('t ({\mu}s)')
  figure(1)
end
