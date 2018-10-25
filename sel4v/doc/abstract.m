f_samp = 100e6/2;  % 100 MHz clock, process IQ pairs

% "make fdbk_core_check" finds 78 cycle delay, that's 39 double cycles.
% It covers CORDIC and cic8_5 (8 cycles), so assign 31 cycles to CORDIC.
% Add 8 (double) cycles for the path through mp_proc.
if 1  % time-forshortened simulation
  f_lpf = 1e6;  % Hz
  f_cav = 10e3;  % Hz
  f_int = 30e3;  % Hz
  delay = 39;  % cycles
  prop_gain = 10;  % stability limit at 21
else  % real-life with plant delays
  f_lpf = 300e3;
  f_cav = 20;
  f_int = 12e3;
  delay = 39+70;
  prop_gain = 1500; % stability limit at 3500
end

% Fifth-order CIC filter N=4, see iq_chain4, iq_intrp4.v, and boxes.eps
cic8=ones(1,4)/4;
cic8_2=conv(cic8,cic8);
cic8_4=conv(cic8_2,cic8_2);
cic8_5=conv(cic8,cic8_4);

dsp_num = cic8_5;
dsp_den = [1 zeros(1,delay+length(dsp_num))];

% Low-pass filter
s_pole = -(2*pi*f_lpf);
z_pole = exp(s_pole/f_samp);
lpf_den = [1 -z_pole]/(1-z_pole);

% Cavity
s_pole = -(2*pi*f_cav);
z_pole = exp(s_pole/f_samp);
cav_den = [1 -z_pole]/(1-z_pole);
cav_num = [1 1]/2;

% Integral term
s_zero = -(2*pi*f_int);
z_zero = exp(s_zero/f_samp);
int_num = [1 -z_zero];
int_den = [1 -1];

f = 10.^[1:.01:7]';
z = exp(2*pi*i*f/f_samp);

loop_num = conv(int_num,dsp_num) * prop_gain;
loop_den = conv(int_den,lpf_den);
loop_den = conv(loop_den,dsp_den);
loop_num = conv(loop_num,cav_num);
loop_den = conv(loop_den,cav_den);

% foo = loop/(1+loop)
foo_num = loop_num;
foo_den = loop_den + [zeros(1,length(loop_den)-length(loop_num)) loop_num];

A_int = polyval(int_num,z)./polyval(int_den,z);
A_fdbk = prop_gain*A_int.*polyval(dsp_num,z)./polyval(conv(lpf_den,dsp_den),z);
A_cav = polyval(cav_num,z)./polyval(cav_den,z);
A_loop = polyval(loop_num,z)./polyval(loop_den,z);
A_foo = polyval(foo_num,z)./polyval(foo_den,z);
%A_foo = A_loop./(1+A_loop);
stab_crit = max(abs(roots(foo_den)));
fprintf('max pole radius %.5f',stab_crit)
if (stab_crit>1) fprintf(' unstable!'); end
fprintf('\n')

figure(1)
loglog(f,abs(A_fdbk),f,abs(A_cav),f,abs(A_loop),f,abs(A_foo))
legend('feedback','cavity','product','closed-loop')
xlabel('f (Hz)')
ylim([1e-2 1e4])

if 0
  figure(2)
  semilogx(f,angle(A_fdbk),f,angle(A_cav))
end

if 1
  % step response
  figure(3)
  npt=4000;
  t=[0:npt-1]/f_samp;
  x=ones(npt,1);
  y=filter(foo_num,foo_den,x);
  plot(t,y)
  xlabel('t (s)')
end
