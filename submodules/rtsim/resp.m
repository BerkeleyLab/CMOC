system('make vmod1.dat')
f_clk=100e6;  % as listed in param.py
dt=33/f_clk;  % updates printed by vmod1_tb
yscale=32768;  % 16-bit virtual ADC, fine points of CIC DAQ already handled in sample_cic

% parameters must match param.py
% XXX if this were python, this setup could be shared
cav_adc_max = 1.2;    % sqrt(W)
rfl_adc_max = 180.0;  % sqrt(W)
fwd_adc_max = 160.0;  % sqrt(W)
df_scale = 9;         % see cav4_freq.v
RoverQ = 1036.0;      % Ohm, pi mode
Q_0 = 1e10;           % pi mode
Q_1 = 8.1e4;          % pi mode
Q_2 = 2e9;            % pi mode
net_coupling = 3.03e-8; % Hz / V^2
f0 = 1.3e9;           % Hz

d=load('vmod1.dat');
cav = (d(:,1)+j*d(:,2))/yscale * cav_adc_max;  % sqrt(W)
fwd = (d(:,3)+j*d(:,4))/yscale * fwd_adc_max;  % sqrt(W)
rfl = (d(:,5)+j*d(:,6))/yscale * rfl_adc_max;  % sqrt(W)

cav = cav * sqrt(Q_2*RoverQ);  % V
dVdt = [0; cav(3:end)-cav(1:end-2); 0]/(2*dt);
Q_L = 1/(1/Q_0+1/Q_1+1/Q_2);
omega_f = 2*pi*f0/(2*Q_L);
x1 = 2 * fwd * sqrt(Q_1*RoverQ);
x2 = dVdt/omega_f;

npt=length(cav);
t=[0:npt-1]'*dt*1e6;  % microseconds
plot(t,abs(cav)*1e-4,t,abs(fwd),t,abs(rfl))
legend('cav','fwd','rfl')
xlabel('t ({\mu}s)')
ylabel('sqrt(W)')

% To make the following plots useful and comprehensible,
% suggest adjusting param.py to:
%   turn on Lorentz force
%   turn off ADC noise
%   turn off 8pi/7 mode
if 1
  figure(2)
  df = d(:,7) * 2^(df_scale-32) * f_clk;
  lorentz = abs(cav).^2*net_coupling;
  plot(t,lorentz, t,-df)
  legend('k_LV^2','-{\Delta}f')
  xlabel('t ({\mu}s)')
  ylabel('f (Hz)')
  figure(3)
  omega_d = 2*pi*df;
  x3 = cav .* (1-j*omega_d/omega_f);
  ix = find(t>3)(1:end-1);
  plot(real(cav),imag(cav),real(x2(ix)),imag(x2(ix)),real(x3),imag(x3)) %,real(x2+x3),imag(x2+x3))
  legend('V','dV/dt/\omega_f','V*(1-j\omega_d/\omega_f)')
  axis([-1 1 -1 1]*7e5,'square')
  title('\pi mode Volts')
end

for px=[]
  figure(px)
  set (get (gca, 'xlabel'), 'fontweight', 'bold')
  set (get (gca, 'ylabel'), 'fontweight', 'bold')
  set (get (gca, 'title'), 'fontweight', 'bold')
  set (get (gca, 'children'), 'linewidth', 2)
  set (gca, 'linewidth', 1)
  print(sprintf('plot%d.pdf',px), '-dpdf')
end

figure(1)
