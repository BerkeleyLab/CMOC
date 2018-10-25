d=load("trace1.dat");
npt=size(d,1);
dt=20e-3; % us (two clock cycles per IQ pair)
t=[0:npt-1]'*dt;
cg=sqrt(prod(1+0.5.^[0:20].^2));  % CORDIC gain

vscale=2^17;

drv=d(:,1)+i*d(:,2);
cav=d(:,3)+i*d(:,4);

set_x1=29000;  % set X in fdbk_sys_tb.v
set_x2=30000;  % set X in fdbk_sys_tb.v
set_x=set_x1+(t>70)*(set_x2-set_x1);

figure(1)
plot(t,abs(drv)/vscale,t,abs(cav)/vscale,t,t*0+set_x*2/cg/vscale,t,d(:,7)/vscale,t,d(:,8)/vscale)
legend('drive','cavity','set','I drv','Q drv')
xlim([0 max(t)])
xlabel('t (us)')
ylabel('normalized amplitude')
octaveplotformat
print('sima_m.eps','-depsc2')

figure(2)
plot(t,angle(drv),t,angle(cav),t,t*0,t,d(:,9)*pi/2^17); %,t,d(:,8)/vscale*pi)
legend('drive','cavity','set','pdet')
xlim([0 max(t)])
ylim([-0.5 0.9])
xlabel('t (us)')
ylabel('angle (radians)')
octaveplotformat
print('sima_p.eps','-depsc2')

if 0
  figure(3)
  plot(drv,'-*')
  axis([-1 1 -1 1]*20000,'square')
end

if 0
  % used to check for cross-coupling of amplitude and phase loops
  figure(3)
  ix=find(t>100);
  plot(cav(ix)-37650)
  axis([-1 1 -1 1]*5000,'square')
end

figure(1)
