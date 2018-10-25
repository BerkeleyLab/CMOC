f=10.^[1:.01:6]';
s=2*pi*i*f;

pcav=2*pi*20;
cav=1./(1+s/pcav);

% Includes filters, amplifiers, ADC, some computation, cables, waveguides, ...
T=800e-9; % s
sys_delay=exp(-s*T);

plant=cav.*sys_delay;

Kp=3000;
Ki=Kp*(2*pi*20e3)./s;
plp=2*pi*300e3;
lpfilt=1./(1+s/plp);  % note this contributes 1/plp = 530 ns delay

control=(Kp+Ki).*lpfilt;

loop=1./(plant.*control+1);

unity=plant*0+1;

figure(1)
loglog(f,abs(plant),f,abs(control),f,abs(plant.*control),f,abs(loop),f,unity)
xlabel('f (Hz)')
legend('plant','control','plant*control','noise gain')
octaveplotformat
print('over.eps','-depsc2')

figure(2)
plot(plant.*control,'r',-1+1e-8i,'*')
legend('plant*control')
axis([-1 1 -1 1]*2,'square')

loop2=zeros(length(loop),4);
T2s=[0 600 1200 1800]*1e-9;
for ix=[1:length(T2s)]
  T2=T2s(ix);
  control2=(Kp+Ki.*exp(-s*T2)).*lpfilt;
  loop2(:,ix)=1./(plant.*control2+1);
end

figure(3)
loglog(f,abs(loop2))
xlabel('f (Hz)')
xlim([1e4 1e6])
ylim([1e-1 3])
legend('0', '600ns', '1200ns', '1800ns')
octaveplotformat
print('delays.eps','-depsc2')
