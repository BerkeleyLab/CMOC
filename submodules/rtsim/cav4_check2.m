d = load('cav4_elec.dat');
npt = size(d,1);

den = 33;
n2 = floor(npt/den);
ix = [1:n2*den]';
dt = 14/1320;  % us
t = dt*ix;

fwd_if = d(ix,1);
rfl_if = d(ix,2);
cav_if = d(ix,3);
freq   = d(ix,4);

lo = exp(ix*2*pi*i*7/den);
fwd1 = fwd_if.*lo;  fwd2 = reshape(fwd1(1:den*n2),den,n2)';  fwd_v=mean(fwd2,2);
rfl1 = rfl_if.*lo;  rfl2 = reshape(rfl1(1:den*n2),den,n2)';  rfl_v=mean(rfl2,2);
cav1 = cav_if.*lo;  cav2 = reshape(cav1(1:den*n2),den,n2)';  cav_v=mean(cav2,2);
t2 = dt*den*([1:n2]'-0.5);

plot(t2,real(rfl_v),t2,imag(rfl_v),t2,real(cav_v),t2,imag(cav_v),t,freq*30)
legend('reflected real','reflected imag','cavity real','cavity imag')
xlabel('t ({/Symbol m}sec)')
return
