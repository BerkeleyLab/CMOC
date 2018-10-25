% Supposedly = 1/4 - 5/264 = 61/264
% Based on DAC samples streaming at 188.57 MS/s, 188.57*(1-61/264) = 145 MHz
y = load('upconv2.dat');

if 1
  y = y(1:528);
  ss = fft(y);
else
  ss = fft(y.*hanning(length(y)));
end

npt = length(y);
ss = ss(1:npt/2);
ss = ss / max(abs(ss));

want = 61/264;
plot([0:npt/2-1]'/npt,20*log10(abs(ss)),want*[1 1],[-60 0])
%xlim([.2 .3])
ylim([-100 0])

[so, ix] = sort(abs(ss),'descend');
% Use some pretty deep knowledge about the result:
% peak at ix=123 out of 528 corresponds to 61/264
% accept the -40 dB sidebands at ix=11 and ix=255 because they are far away
%   ix    1st    2nd    Nyquist zone frequencies (MHz)
%   11    3.7  185.0
%  123   43.6  145.0
%  255   90.7   97.9
lines = ix(find(so>0.001));
closeness = abs(lines(2:end)-123);
if ix(1)==123 && length(lines) < 4 && so(2) < 0.012 && min(closeness)>100
  printf('PASS\n')
else
  printf('FAIL\n')
  exit(1)
end
