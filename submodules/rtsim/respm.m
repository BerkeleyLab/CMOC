% mechanical modes by themselves
% step-function excitation by piezo
system('make vmod1.dat')
f_clk=100e6;  % as listed in param.py
dt=33/f_clk;  % updates printed by vmod1_tb

d=load('vmod1.dat');
disp0=d(:,7);
disp1=d(:,8);
disp2=d(:,9);

npt=length(disp0);
t=[0:npt-1]'*dt*1e6;  % microseconds

% Match the following two lines to param.py
freq=100000; % Hz
Q=5; % unitless
amp=6750;

% SI version
w = 2*pi*freq*1e-6;
a = -w/(2*Q);
b = w*sqrt(1-1/(4*Q^2));
%theory = amp*(1-cos(b*t).*exp(a*t));
theory = amp*sin(b*t).*exp(a*t);

% mechanical computer time quantum version
n_res_mode = 14;
mech_tstep = n_res_mode / f_clk / 2;
w1 = 2*pi*freq * mech_tstep;
a1 = -w1/(2*Q);
b1 = w1*sqrt(1-1/(4*Q^2));
z_pole = exp(a1+b1*j)  % matches param.py debug output
ix = [0:460]';
emul = amp*imag(z_pole.^ix);

t_offset=3.5;
plot(t,disp2,t+t_offset,theory,ix*mech_tstep*1e6+t_offset,emul)
legend('vmod1','analytic','stepped')
xlabel('t ({\mu}s)')
