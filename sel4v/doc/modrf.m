% Show how RF is modulated to generate sinusoidal Lorentz force
fm=120; % Hz modulation
dt=1e-4; % simulation time step
t=[0:1000]'*dt;
wm=2*pi*fm;
depth=0.7;  % unitless modulation depth of V^2
a=1-depth/2;
b=depth/2;
Vp = 16e6; % V cavity field at peak of modulation
V = Vp*sqrt(a + b*sin(wm*t));
% differentiate analytically
dVdt = Vp^2*b*wm*cos(wm*t)./(2*V);

% assume no detuning (or equivalently, an SEL that follows detuning
% without adding power) and no beam loading
wf = 2*pi*32;  % radians/sec cavity bandwidth
w0 = 2*pi*1300e6;  % radians/sec cavity center
RoverQ = 1036;  % Ohms
%R1 = (w0/wf/2)*RoverQ;  % Ohm coupling impedance
%K = (V+dVdt/wf)/(2*sqrt(R1));
k0 = 1/(2*sqrt(w0*RoverQ/2));
K = k0 * (V*sqrt(wf)+dVdt/sqrt(wf));
plot(t,K)
%plot(t,V,t,dVdt/wf)

% Forget Vp and k0 for a moment, let c=sqrt(wf), and
% f(t) = sqrt(1 + b*sin(wm*t))
% where we have assumed a=1 without loss of generality.
% K = f(t) * c + b*wm*cos(wm*t)./(2*f(t)) / c
% look for the peak value of K with t, and minimize w.r.t. c.
% Finding the peak requires solving a 4th order polynomial in sin(t).
% also set wm=1, will require rescaling of c to get sqrt(wf).

% sed -e 's/^% //' <<%eot | maxima -q; echo
% display2d:false;
% linel:1000;
% f(t):=sqrt(1+b*sin(t));
% d(t):=diff(f(t),t);
% d(t);
% s1:diff( f(t)*c + d(t)/c, t);
% s2:ratsimp(s1);
% s3:subst(x,sin(t),s2);
% s4:subst(sqrt(1-x^2),cos(t),s3);
% s5:ratsimp(s4);
% r1:num(s5);
% r2:subst(y,sqrt(1-x^2),r1);
% r3:rhs(first(solve(r2=0,y)));
% d1:denom(r3);
% n1:num(r3);
% r4:ratsimp(d1^2*(1-x^2)-n1^2);
%eot
