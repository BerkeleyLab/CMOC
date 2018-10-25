% LCLS-II with 145 MHz output IF with 188.57 MS/s DAC
% 203/132 = 3/2 + 5/132

% If we take IQ multiplexed data, and two multiplier
%
%         LO1
%          |
%       /--X--(1+z^(-1))--> I
%   IQ -|
%       \--X--(1+z^(-1))--> Q
%          |
%         LO2
%
% We "consume" two LO values per cycle.  Good thing a CORDIC
% produces two outputs (sin and cos) per cycle.
% So in two consecutive cycles, send
%   cos(theta)   and sin(theta)   to LO1, and
%   sin(theta+p) and -cos(theta+p) to LO2.
% where theta steps 5/132*2*pi per cycle, or 5/66*2*pi per two cycles,
% and p = 5/132/2*2*pi (half-a-cycle phase advance).

% Tsinghua TXGLS equivalent: 158.7 MHz output IF with 202.3 MS/s DAC
% 80/51 = 3/2 + 7/102

% We'll post-process by -(1+z^(-1)) filtering alternating cycles.

npt = 4096;  % number of IQ pairs
if 1  % LCLS-II
  ps = -2*5/132*2*pi;  % phase step, radians, per pair of FPGA clock cycles
  f_s = 1320/7;  % MS/s DAC
else  % TXGLS
  ps = -2*7/102*2*pi;  % phase step, radians, per pair of FPGA clock cycles
  f_s = 119*17/10;  % MS/s DAC
end
ix = [0:npt]';
lo1 = exp(i*ix*ps);
lo2 = i*exp(i*ps*(ix+1/4));
% Suppose this is driven with I only, so use real(lo).
% If you set K to -sec(ps/2) in the interpolation formula,
% the output spectrum for a static input should be perfect.
% But -1 is close enough, and saves two multipliers.
K = -1;  %-sec(ps/2);
v_i1 = real(lo1);  v_i2 = (v_i1(1:end-1) + v_i1(2:end))/2*K;
v_q1 = real(lo2);  v_q2 = (v_q1(1:end-1) + v_q1(2:end))/2*K;
dac = reshape([v_i1(1:end-1) v_q1(1:end-1) v_i2 v_q2]',npt*4);

ss = fft(dac.*hanning(4*npt));
ss = ss/max(abs(ss));
f = [0:npt*4-1]'/(npt*4)*f_s;
plot(f,log10(abs(ss))*20)
ylim([-60 0])
xlabel('f (MHz)')
ylabel('dBc')
% result is clean close-in
% Besides the inevitable alias at 43.57 MHz,
% other lines are -40 dB at
%    3.57 MHz    5/132
%   90.71 MHz  127/132
%   97.86 MHz  137/132
%  185.00 MHz  259/132
