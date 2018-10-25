d = load('chirp.out');
dt = 1e-8;  % s, just for example
drive = d(:,1)+j*d(:,2);
cav   = d(:,3)+j*d(:,4);
npt = length(cav);
t = [0:npt-1]'*dt;

ds = 1/max(abs(drive));  % drive scale
cs = 1/max(abs(cav));  % cavity scale
plot(t*1e6,ds*real(drive)-1,t*1e6,ds*imag(drive)-1,t*1e6,cs*real(cav)+1,t*1e6,cs*imag(cav)+1)
legend('Re(drive)','Im(drive)','Re(cavity)','Im(cavity)')
xlabel('t ({\mu}s)')
xlim([0 45])
ylim([-2.2 2.2])

octaveplotformat
print('chirp.eps','-depsc2')
