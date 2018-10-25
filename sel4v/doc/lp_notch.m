% How to generate a low-latency notch filter in DSP,
% intended to keep the nearby passband mode of an SRF cavity
% from creating spurious oscillations in high-gain feedback
% or SEL operations modes.

% This simulation set up for the -800 kHz offset of the 8*pi/9
% mode of a TTF cavity.
% Note that every cavity's nearby mode is at a slightly different
% frequency (have to love that sheet metal!), so the FPGA parameters
% need to be tunable at runtime.

% There is a second purpose to the filtering system, and that is
% to limit the broadband noise sent to the high power amplifier.
% A simple 300 kHz bandwidth requirement is assumed here, and the
% two filters' implementations are intertwined.

% This analysis starts in the s (Laplace) domain.  The actual FPGA
% implementation is in the z domain, shown later.

% Larry Doolittle, LBNL, July 2013
% z-domain added February, 2014

df=0.015;
f=[-6:df:6]';  % MHz
f=[-3:df:3]';  % MHz
w=2*pi*f;
s=i*w;

fl=0.3;   % MHz of noise-limiting low-pass filter
fn=0.8;   % MHz offset of nearby mode to be rejected

Al=1./(1+s/(2*pi*fl));  % low-pass filter, cutoff fl

Af=2*pi*fl./(s+2*pi*fl+2*pi*i*fn);  % first order filter, complex-valued pole,
% same bandwidth as the low-pass filter

Al0=1/(1-2*pi*i*fn/(2*pi*fl));  % constant complex number

A=Al-Al0*Af;  % final system gain

% Transfer function should have a notch at -fn
figure(1)
plot(f,abs(Al),f,abs(Af),f,abs(A))
legend('low-pass','offset low-pass','total with notch')
xlabel('f offset from carrier (MHz)')

% Compute group delay of low-pass only
gdl=-diff(unwrap(arg(Al)))/(df*2*pi)*1e3;

% Compute and plot the group delay
% Result is 600 ns at the carrier; that value needs to be
% used in the feedback loop design.  Note that 530 ns comes
% from the centered low-pass filter, and 70 ns from the
% additional term to create the notch.
fx=0.5*(f(2:end)+f(1:end-1));
gd=-diff(unwrap(arg(A)))/(df*2*pi)*1e3;
figure(2)
plot(fx,gd,fx,gdl)
legend('low-pass','total with notch')
ylim([0 700])
ylabel('group delay (ns)')
xlabel('f offset from carrier (MHz)')

% z-domain version
T=4/102.143;  % us (APEX2-compatible)
z=exp(s*T);
zlp=exp(-2*pi*fl*T)
zbp=exp(-2*pi*(fl+i*fn)*T)
figure(3)
Alz=(1-zlp)./(z-zlp);
Afz=(1-zlp)./(z-zbp);
zn=exp(-fn*2*pi*i*T);
Al0z=(zn-zbp)/(zn-zlp)
Az=Alz-Al0z*Afz;
Ah=(1+2*sqrt(z)+z)/4;  % half-band filter option 2
Ah=(1+sqrt(z))/2;  % half-band filter option 1
if 1
  Alz_x=(1-zlp)./(z-1-z.^(-1)*(zlp-1));
  Afz_x=(1-zlp)./(z-1-z.^(-1)*zbp*(zbp-1));
  Al0z_x=(zn-1-zn^(-1)*zbp*(zbp-1))/(zn-1-zn^(-1)*(zlp-1))
  Az_x=Alz_x-Al0z_x*Afz_x;
end
plot(f,abs(A),f,abs(Az),f,abs(Az_x))
xlabel('f offset from carrier (MHz)')
legend('s-plane','z-plane','z-plane pipelined')

figure(1)

% z implementation has some challenges:
%  1/(z-zp) becomes
%  y_new = y_old*zp + x
% and if zp is complex (as in zbp), and both x and y are complex
% (that's a given), there's a complex multiply-add to perform in a
% single cycle.  Well, presumably at least two cycles if real and
% imaginary components are multiplexed as I'm wont to do.  But for
% the feedback data path to work with pipelined multipliers, probably
% need to decimate by at least another factor of two.  Hence the factor
% of 4 in the expression above for T.
